//
//  Filters.swift
//  LyreBird 
import UIKit
import RealmSwift
import Alamofire
import AlamofireImage
import ImageIO
import CoreGraphics
import Accelerate

struct FilterModal {
    var title: String
    var iconUrl:String
    var previewUrl:String
}
class Filters: UIViewController ,UIGestureRecognizerDelegate {
    
    let getPhoto : UIButton = {
        let photo = UIButton()
        photo.setTitle("Get Photo", for: .normal)
        photo.setTitleColor(UIColor.white, for: .normal)
        photo.addTarget(self, action: #selector(goChoose), for: .touchUpInside)
        photo.titleLabel?.textAlignment = .center
        photo.backgroundColor = .red
        return photo
    }()
    var rotateGesture  = UIRotationGestureRecognizer()
    var lastRotation   = CGFloat()
    let filterImageView : UIImageView = {
        var imageView  = UIImageView()
        imageView.image = UIImage()
        imageView.isUserInteractionEnabled = true
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
    let imageView : UIImageView = {
        var imageView = UIImageView()
        imageView.image = UIImage(named: "kapadokya")!
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    
    @IBOutlet weak var close: UIBarButtonItem!
    @IBOutlet weak var save: UIBarButtonItem!
    @IBOutlet weak var customView: UIView!
    @IBOutlet weak var filterCV: UICollectionView!
    let request = Request()
    var filterResponse = [KeyFilter]()
    @IBOutlet weak var navbar: UINavigationItem!
    var initialCenterPoint = CGPoint()
    var realmFilter = try! Realm()
    var filterData = [FilterProtocol]()
    var dataArray = [FilterModal]()
    
    let context = CIContext()
    lazy  var histogramView: UIImageView = {
        var hv  = UIImageView()
        hv.backgroundColor = .white
        return hv
        
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.setupViews()
        
        
    }
    @IBAction func savePhoto(_ sender: UIBarButtonItem) {
        //saved()
        guard let image = imageView.asImage() else { return  }
        saved(image)
        
        
    }
    //MARK: - Add image to Library
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            showAlertWith(title: "Save error", message: error.localizedDescription)
        } else {
            showAlertWith(title: "Saved!", message: "Your image has been saved to your photos.")
        }
    }
    
    func showAlertWith(title: String, message: String){
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    @objc func handlePinch(sender: UIPinchGestureRecognizer) {
        guard sender.view != nil else { return }
        
        if sender.state == .began || sender.state == .changed {
            sender.view?.transform = (sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale))!
            sender.scale = 1.0
        }
    }
    @objc func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            
            let translation = gestureRecognizer.translation(in: self.view)
            // note: 'view' is optional and need to be unwrapped
            gestureRecognizer.view!.center = CGPoint(x: gestureRecognizer.view!.center.x + translation.x, y: gestureRecognizer.view!.center.y + translation.y)
            gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
        }
        
    }
    
    @objc func pinchRecognized(pinch: UIPinchGestureRecognizer) {
        
        if let view = pinch.view {
            view.transform = view.transform.scaledBy(x: pinch.scale, y: pinch.scale)
            pinch.scale = 1
        }
    }
    
    @objc  func handleRotate(recognizer : UIRotationGestureRecognizer) {
        if let view = recognizer.view {
            view.transform = view.transform.rotated(by: recognizer.rotation)
            recognizer.rotation = 0
        }
    }
    @objc func gestureRecognizer(_: UIGestureRecognizer,
                                 shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
        return true
    }
    func setupViews(){
        self.getPhotos()
        self.fetchFilters()
        self.filterCollectionView()
    }
    func filterCollectionView(){
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.filterCV.collectionViewLayout = layout
        self.filterCV.isPagingEnabled = true
        self.filterCV.delegate = self
        self.filterCV.dataSource = self
        self.filterCV.register(FilterCell.nib, forCellWithReuseIdentifier: FilterCell.identifier)
    }
    
    func saved(_ image : UIImage){
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        
    }
    func getPhotos(){
        
        
        customView.backgroundColor = UIColor.purple
        imageView.translatesAutoresizingMaskIntoConstraints = false
        customView.addSubview(imageView)
        imageView.anchor(top: customView.topAnchor, left: customView.leftAnchor, bottom:customView.bottomAnchor, right: customView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: customView.frame.width, height: customView.frame.height)
        customView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        imageView.addSubview(filterImageView)
        filterImageView.frame = CGRect.init(x: self.imageView.center.x, y: self.imageView.center.y,  width:100, height:100)
      
         
        
    }
    func pixel(in image: UIImage, at point: CGPoint) -> (UInt8, UInt8, UInt8, UInt8)? {
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let x = Int(point.x)
        let y = Int(point.y)
        guard x < width && y < height else {
            return nil
        }
        guard let cfData:CFData = image.cgImage?.dataProvider?.data, let pointer = CFDataGetBytePtr(cfData) else {
            return nil
        }
        let bytesPerPixel = 4
        let offset = (x + y * width) * bytesPerPixel
        return (pointer[offset], pointer[offset + 1], pointer[offset + 2], pointer[offset + 3])
    }

   
    
    @objc func goChoose(){
        ImagePickerManagerUpload().pickImage(self){ image in
            print(image)
            self.imageView.image = image
        }
    }
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    func fetchFilters(){
        //self.realmFilter.beginWrite()
        //realmFilter.delete(self.realmFilter.objects(KeyFilter.self))
        //try! self.realmFilter.commitWrite()
        
        //print(Realm.Configuration.defaultConfiguration.fileURL)
        if Network.isConnectedToNetwork() == true {
            request.getRequest( api: Config.FILTERS , completion : { response in
                DispatchQueue.main.async {
                    let jsonDecoder = JSONDecoder()
                    self.filterData = try! jsonDecoder.decode([FilterProtocol].self, from: response as! Data)
                    self.dataArray.append(FilterModal.init(title: "FX 1" , iconUrl: "none", previewUrl: "none"))
                    for (index,filter)  in (self.filterData as NSArray as! [FilterProtocol]).enumerated() {
                        self.dataArray.append(FilterModal.init(title: "FX " + String(index + 2), iconUrl: filter.overlayUrl!, previewUrl: filter.overlayPreviewIconUrl!))
                        
                    }
                    self.filterCV.reloadData()
                    
                    let filterModel = KeyFilter()
                    self.realmFilter.beginWrite()
                    
                    for filter in (self.filterData as NSArray as! [FilterProtocol]) {
                        
                        filterModel.name = filter.overlayName
                        filterModel.id =  "\(filter.overlayId!)"
                        filterModel.previewIcon = filter.overlayPreviewIconUrl
                        filterModel.icon = filter.overlayUrl
                        self.realmFilter.add(filterModel)
                        print(filterModel.name!)
                    }
                    
                }
            })
        }else{
            /*let realm =  self.realmFilter.objects(KeyFilter.self)
             //print(realm)
             for item in realm{
             print(item.name)
             
             
             }*/
        }
    }
    @objc func handleRotation(sender: UIRotationGestureRecognizer) {
        guard sender.view != nil else { return }
        
        if sender.state == .began || sender.state == .changed {
            sender.view?.transform = sender.view!.transform.rotated(by: sender.rotation)
            sender.rotation = 0
        }
    }
    @objc func handlePan(_ pan: UIPanGestureRecognizer) {
        if pan.state == .began {
            self.initialCenterPoint = self.filterImageView.center
        }
        
        let translation = pan.translation(in: view)
        
        if pan.state != .cancelled {
            let newCenter = CGPoint(x: initialCenterPoint.x + translation.x, y: initialCenterPoint.y + translation.y)
            self.filterImageView.center = newCenter
        } else {
            self.filterImageView.center = initialCenterPoint
        }
    }
    
    func setupLayout() {
        NSLayoutConstraint.activate([
            self.filterImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            self.filterImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            self.filterImageView.widthAnchor.constraint(equalToConstant: 200),
            self.filterImageView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    @IBAction func makeHistogram(_ sender: UIBarButtonItem) {
        convertHistogram()
    }
    @objc func convertHistogram(){
           
         let sourceCGImage = imageView.image?.cgImage
               let histData = calculateHistogram(fromImage: sourceCGImage!)
               let imageHist = CIImage(cgImage: imageFromARGB32Bitmap(pixels: histData, width: 256, height: 1)!)
               
               let histImage = histogramDisplayFilter(imageHist, height: 200, highLimit: 1.0, lowLimit: 0.0)
               let cgImage = context.createCGImage(histImage!, from: histImage!.extent)
               let uiImage = UIImage(cgImage: cgImage!)
        
        histogramView.image = uiImage
        imageView.addSubview(histogramView)
        histogramView.anchor(top: nil, left: nil, bottom:imageView.bottomAnchor, right: imageView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 50)
        histogramView.frame = CGRect.init(x: 0, y: 0, width: 100, height: 50)
         
    }
    func histogramDisplayFilter(_ input: CIImage, height: Float = 100, highLimit: Float = 1.0, lowLimit: Float = 0.0) -> CIImage?
    {
        let filter = CIFilter(name:"CIHistogramDisplayFilter")
        filter?.setValue(input,     forKey: kCIInputImageKey)
        filter?.setValue(height,    forKey: "inputHeight")
        filter?.setValue(highLimit, forKey: "inputHighLimit")
        filter?.setValue(lowLimit,  forKey: "inputLowLimit")
        return filter?.outputImage
    }
    
    func calculateHistogram(fromImage image: CGImage) -> [PixelData] {
    
        var hist : [IntData] = Array(repeating: IntData(), count: 256)
        
        let pixelData = image.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        for i in 0..<Int(image.width * image.width) {
            hist[ Int(data[i*4+0]) ].r += 1
            hist[ Int(data[i*4+1]) ].g += 1
            hist[ Int(data[i*4+2]) ].b += 1
        }
        let maxValue : Int = hist.reduce(0) { max($0, $1.maxRGB) }
        return hist.map { PixelData($0, div: maxValue) }
    }
    func imageFromARGB32Bitmap(pixels: [PixelData], width: Int, height: Int) -> CGImage? {
        
        guard width > 0 && height > 0 else             { return nil }
        guard pixels.count == width * height else     { return nil }
        let size = MemoryLayout<PixelData>.size
        var data = pixels
        guard let provider = CGDataProvider(data: NSData(bytes: &data, length: data.count * size) )
            else { return nil }
        
        guard let cgImage = CGImage(
            width:                 width,
            height:             height,
            bitsPerComponent:     8 * size / 4,
            bitsPerPixel:         8 * size,
            bytesPerRow:         width * size,
            space:                 CGColorSpaceCreateDeviceRGB(),
            bitmapInfo:         CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue),
            provider:             provider,
            decode:             nil,
            shouldInterpolate:     true,
            intent:             .defaultIntent
            )
            else { return nil }
        
        return cgImage
    }
}
extension Filters : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 90, height: 120)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as! FilterCell
        if indexPath.row == 0{
            let margin:CGFloat = 12
            cell.iconView.image = UIImage.init(named: "none")!.withInset( UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin))
        }
        if (self.dataArray[indexPath.row].previewUrl  != ""){
            let imageURL = self.dataArray[indexPath.row].previewUrl
            if Network.isConnectedToNetwork() == true {
                Alamofire.request(imageURL).responseImage { response in
                    if let image = response.result.value {
                        cell.iconView.image = image
                        cell.iconUrl = self.dataArray[indexPath.row].iconUrl
                    }
                }
            }
        }
        
        if self.dataArray[indexPath.item].title != ""{
            cell.nameTitle.text = self.dataArray[indexPath.item].title
        }
        return cell
    }
    func imageRecolor(image: UIImage, withColor color: UIColor) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(CGSize.init(width: image.size.width, height: image.size.height), false, image.scale)
        let context = UIGraphicsGetCurrentContext()
        color.set()
    context!.translateBy(x: 0, y: image.size.height)
    context!.scaleBy(x: 1, y: -1)
    let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
    context!.clip(to: rect, mask: image.cgImage!)
    context!.fill(rect)
        let coloredImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    return coloredImage!
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if  let cell = collectionView.cellForItem(at: indexPath) as? FilterCell {
            if indexPath.row == 0 {
                cell.isSelected = false
            }
            if indexPath.row != 0 {
                if Network.isConnectedToNetwork() == true {
                    let imageURL = cell.iconUrl!
                    Alamofire.request(imageURL).responseImage { response in
                        if let image = response.result.value {
                            
                            self.filterImageView.image = image
                            self.filterImageView.frame = CGRect.init(x: self.imageView.center.x, y: self.imageView.center.y,  width: 200, height: 200)
                            self.filterImageView.translatesAutoresizingMaskIntoConstraints = false
                            self.filterImageView.isUserInteractionEnabled = true
                            self.filterImageView.isMultipleTouchEnabled = true
                            
                            self.imageView.addSubview(self.filterImageView)
                            self.imageView.centerXAnchor.constraint(equalTo: self.filterImageView.centerXAnchor).isActive = true
                            self.imageView.centerYAnchor.constraint(equalTo: self.filterImageView.centerYAnchor).isActive = true
                            
                            let rotate = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotation(sender:)))
                            self.filterImageView.addGestureRecognizer(rotate)
                            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(sender:)))
                            self.filterImageView.addGestureRecognizer(pinch)
                            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
                            self.filterImageView.addGestureRecognizer(panGesture)
                               
                        }
                    }
                }
            }else  if indexPath.row == 0{
                
                self.imageView.addSubview(self.filterImageView)
                self.filterImageView.frame = CGRect.init(x: self.imageView.center.x, y: self.imageView.center.y,  width: 200, height: 200)
                self.filterImageView.image =  UIImage()
                
            }
            
        }
    } 
     
} 
class ImagePickerManagerUpload : NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    var picker = UIImagePickerController();
    var alert = UIAlertController(title: "Select Photo", message: nil, preferredStyle: .actionSheet)
    var viewController: UIViewController?
    var pickImageCallback : ((UIImage) -> ())?;
    
    override init(){
        super.init()
    }
    
    func pickImage(_ viewController: UIViewController, _ callback: @escaping ((UIImage) -> ())) {
        pickImageCallback = callback
        self.viewController = viewController
        let galleryAction = UIAlertAction(title: "Photos", style: .default){
            UIAlertAction in
            self.openGallery()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel){
            UIAlertAction in
        }
        picker.delegate = self
        alert.addAction(galleryAction)
        alert.addAction(cancelAction)
        alert.popoverPresentationController?.sourceView = self.viewController!.view
        viewController.present(alert, animated: true, completion: nil)
    }
    
    func openGallery(){
        alert.dismiss(animated: true, completion: nil)
        picker.sourceType = .photoLibrary
        self.viewController!.present(picker, animated: true, completion: nil)
    }
    func openCamera(){
        alert.dismiss(animated: true, completion: nil)
        picker.sourceType = .camera
        self.viewController!.present(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerController.InfoKey.originalImage.rawValue] as! UIImage
        
        pickImageCallback?(image)
    }
    
}


