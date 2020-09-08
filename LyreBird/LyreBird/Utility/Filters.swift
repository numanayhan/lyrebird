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
     
    let filterImageView : UIImageView = {
        var iv  = UIImageView()
        iv.image = UIImage()
        iv.isUserInteractionEnabled = true
        iv.clipsToBounds = true
        iv.backgroundColor = .clear
        iv.contentMode = .scaleAspectFit
        
        return iv
    }()
    let imageView : UIImageView = {
        var iv = UIImageView()
        iv.image = UIImage(named: "kapadokya")!
        iv.contentMode = .scaleToFill
        return iv
    }()
    lazy  var histogramView: UIImageView = {
           var hv  = UIImageView()
           hv.backgroundColor = .white
           return hv
     }()
    @IBOutlet weak var close: UIBarButtonItem!
    @IBOutlet weak var save: UIBarButtonItem!
    @IBOutlet weak var customView: UIView!
    @IBOutlet weak var filterCV: UICollectionView!
    @IBOutlet weak var navbar: UINavigationItem!
    let request = Request()
    var filterResponse = [KeyFilter]()
    var initialCenterPoint = CGPoint()
    var realmFilter = try! Realm()
    var filterData = [FilterProtocol]()
    var dataArray = [FilterModal]()
    var lastRotation   = CGFloat()
    let context = CIContext()
    var rotateGesture  = UIRotationGestureRecognizer()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
    }
    @IBAction func savePhoto(_ sender: UIBarButtonItem) {
        // Resim asImage ile Convert edilip üstüne eklenen resimler ile birleştirilmesi yapıldı.
        // Tek bir context ile image oluşturuldu.
        guard let image = imageView.asImage() else { return  }
        saved(image)
        
    }
    //MARK: - Add image to Library
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            showAlertWith(title: "Resim kaydedilemedi", message: error.localizedDescription)
        } else {
            showAlertWith(title: "Kaydedildi", message: "Resim galeriye kaydedildi")
        }
    }
    
    func showAlertWith(title: String, message: String){
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    // Objeyi Tutma Metodu
    @objc func handlePinch(sender: UIPinchGestureRecognizer) {
        guard sender.view != nil else { return }
        
        if sender.state == .began || sender.state == .changed {
            sender.view?.transform = (sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale))!
            sender.scale = 1.0
        }
    }
    
    // Objeyi Çevirme Metodu
    @objc func handleRotation(sender: UIRotationGestureRecognizer) {
        guard sender.view != nil else { return }
        
        if sender.state == .began || sender.state == .changed {
            sender.view?.transform = sender.view!.transform.rotated(by: sender.rotation)
            sender.rotation = 0
        }
    }
    //Objeyi  Kaydırma Metodu
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
    func setupViews(){
        self.setPhotos()
        self.fetchFilters()
        self.filterCollectionView()
    }
    func filterCollectionView(){
        //Collection View Register edildi.
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
        // Resim galeriye kaydedilmesi yapıldı.
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        
    }
    func setPhotos(){
        
        // Defaul bir resim eklendi.
        // Eğer istenirse bu resim tap gesture ile aşağıda yazdığım kütüphaneden resim seçilmesi metotdu çağrılabilir. goChoose()
        
        customView.backgroundColor = UIColor.purple
        imageView.translatesAutoresizingMaskIntoConstraints = false
        customView.addSubview(imageView)
        imageView.anchor(top: customView.topAnchor, left: customView.leftAnchor, bottom:customView.bottomAnchor, right: customView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: customView.frame.width, height: customView.frame.height)
        customView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        imageView.addSubview(filterImageView)
        filterImageView.frame = CGRect.init(x: self.imageView.center.x, y: self.imageView.center.y,  width:100, height:100)
        
        
        
    }
    @objc func goChoose(){
        // Resim seçilmesi için extension ile galeri veya kamera açılması eklendi.
        ImagePickerManagerUpload().pickImage(self){ image in
            print(image)
            // Seçilen resim ise imageView ile ekrana basıldı.
            self.imageView.image = image
        }
    }
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    func fetchFilters(){
        //self.realmFilter.beginWrite()
        //realmFilter.delete(self.realmFilter.objects(KeyFilter.self))
        //try! self.realmFilter.commitWrite()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        // Filtre Rest Api için fetch metodu yapıldı.
        // İnternet kontrolü yapıldı.
        if Network.isConnectedToNetwork() == true {
            //Config.FILTERS ile Metot public bir class ile çağrıldı.
            request.getRequest( api: Config.FILTERS , completion : { response in
                DispatchQueue.main.async {
                    //DispatchQueue ile sync yapıldı.
                    let jsonDecoder = JSONDecoder()
                    //filterData model ile decode edilen bir liste olarak eklendi.
                    self.filterData = try! jsonDecoder.decode([FilterProtocol].self, from: response as! Data)
                    self.dataArray.append(FilterModal.init(title: "FX 1" , iconUrl: "none", previewUrl: "none"))
                    // liste her eleman için bir model atandı
                    // Url ile alınan elemanın değerleri FilterModal  ile dataArray listesine eklendi.
                    for (index,filter)  in (self.filterData as NSArray as! [FilterProtocol]).enumerated() {
                        self.dataArray.append(FilterModal.init(title: "FX " + String(index + 2), iconUrl: filter.overlayUrl!, previewUrl: filter.overlayPreviewIconUrl!))
                    }
                     //  Collection view içine alınacak data yenilendi.
                    self.filterCV.reloadData()
                    let filterModel = KeyFilter()
                    self.realmFilter.beginWrite()
                     //  Realm data base ile realmFilter listesine alınan Filtre verileri kaydedildi.
                    for filter in (self.filterData as NSArray as! [FilterProtocol]) {
                        filterModel.name = filter.overlayName
                        filterModel.id =  "\(filter.overlayId!)"
                        filterModel.previewIcon = filter.overlayPreviewIconUrl
                        filterModel.icon = filter.overlayUrl
                        self.realmFilter.add(filterModel)
                    }
                }
            })
        }else{
            /*let realm =  self.realmFilter.objects(KeyFilter.self)
             //print(realm)
             for item in realm{
             }*/
        }
    }
    
    
    @IBAction func makeHistogram(_ sender: UIBarButtonItem) {
        convertHistogram()
    }
    // Resmi Histogram Filtresi Dönüştürme
    @objc func convertHistogram(){
        
        let sourceCGImage = imageView.image?.cgImage
        let histData = calculateHistogram(fromImage: sourceCGImage!)
        // Resmi ARGB32Bitmap ile dönüştürme eklendi.
        let imageHist = CIImage(cgImage: imageFromARGB32Bitmap(pixels: histData, width: 256, height: 1)!)
        // Histogram cgImage ile filtre dönüşümü yapıldı.
        let histImage = histogramDisplayFilter(imageHist, height: 200, highLimit: 1.0, lowLimit: 0.0)
        let cgImage = context.createCGImage(histImage!, from: histImage!.extent)
        let uiImage = UIImage(cgImage: cgImage!)
        
        histogramView.image = uiImage
        imageView.addSubview(histogramView)
        histogramView.anchor(top: nil, left: nil, bottom:imageView.bottomAnchor, right: imageView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 50)
        histogramView.frame = CGRect.init(x: 0, y: 0, width: 100, height: 50)
        
    }
    // Histogram Filtrresi CIFilter özellikleri ile limitleri verildi. 100 ile 1 arasında değerler tanımlandı.
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
        // Collection view  elemanın boyutu verildi.
        return CGSize(width: 90, height: 120)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Filtre listesinin eleman sayısı verildi.
        return dataArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as! FilterCell
        // Filtre listesinin  ilk elemanı için resim locale asset içinden verildi
        if indexPath.row == 0{
            let margin:CGFloat = 12
            cell.iconView.image = UIImage.init(named: "none")!.withInset( UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin))
        }
        // Filtre listesinin  her  elemanı için resmin url alındı Alamofire ile donwload edildi ve öncesinde internet kontrolü yapıldı.
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // collection view içine FilterCell ile gelen her eleman extend edildi.
        if  let cell = collectionView.cellForItem(at: indexPath) as? FilterCell {
            //MARK
            // index ile gelen listeden ilk eleman çıkarıldı
            if indexPath.row != 0 {
                //MARK
                // İnternet kontrolü yapıldı
                if Network.isConnectedToNetwork() == true {
                    let imageURL = cell.iconUrl!
                    //MARK
                    // İnternetten resmin URL download edilmesi eklendi.
                    Alamofire.request(imageURL).responseImage { response in
                        if let image = response.result.value {
                            //MARK
                            //imageView filtredeki  resimler index sırasına göre eklendi.
                            self.filterImageView.image = image
                            self.filterImageView.frame = CGRect.init(x: self.imageView.center.x, y: self.imageView.center.y,  width: 200, height: 200)
                            //MARK
                            //imageView dokunme ve kontrol edilebilir özellik eklendi.
                            self.filterImageView.translatesAutoresizingMaskIntoConstraints = false
                            self.filterImageView.isUserInteractionEnabled = true
                            self.filterImageView.isMultipleTouchEnabled = true
                            self.imageView.addSubview(self.filterImageView)
                            //MARK
                            //imageView  merkezde olması eklendi.
                            self.imageView.centerXAnchor.constraint(equalTo: self.filterImageView.centerXAnchor).isActive = true
                            self.imageView.centerYAnchor.constraint(equalTo: self.filterImageView.centerYAnchor).isActive = true
                            //MARK
                            //Dönme kontrolü Gesture ile eklendi.
                            let rotate = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotation(sender:)))
                            self.filterImageView.addGestureRecognizer(rotate)
                            //MARK
                            //Büyütme kontrolü Gesture ile eklendi.
                            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(sender:)))
                            self.filterImageView.addGestureRecognizer(pinch)
                            //Kaydırma kontrolü Gesture ile eklendi.
                            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
                            self.filterImageView.addGestureRecognizer(panGesture)
                            
                        }
                    }
                }
            }else  if indexPath.row == 0{
                //MARK
                // ilk Filtre olmaması için UIImage() boş tanımlandı ve imageView içine eklendi
                self.imageView.addSubview(self.filterImageView)
                self.filterImageView.frame = CGRect.init(x: self.imageView.center.x, y: self.imageView.center.y,  width: 200, height: 200)
                self.filterImageView.image =  UIImage()
                
            }
            
        }
    } 
    
} 
class ImagePickerManagerUpload : NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    //MARK :
    // Resimler seçmek için picker ve navigation eklendi.
    // Sonra ise Galeri ve Kamera ile seçenek için alert eklendi.
    // Seçilen resim callback ile atandı.
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


