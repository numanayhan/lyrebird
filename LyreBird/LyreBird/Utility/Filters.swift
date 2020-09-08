//
//  Filters.swift
//  LyreBird 
import UIKit
import RealmSwift
import Alamofire
import AlamofireImage
import ImageIO
import CoreGraphics
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
    override func viewDidLoad() {
        super.viewDidLoad()
      
        
        self.setupViews()
         
               
    }
    @IBAction func savePhoto(_ sender: UIBarButtonItem) {
        saved()
       
        
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
        //self.fetchFilters()
        //self.filterCollectionView()
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
    
    func saved(){
        
         
               guard let selectedImage = imageView.image else {
                       print("Image not found!")
                       return
                   }
               UIImageWriteToSavedPhotosAlbum(selectedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
                
        
    }
    func getPhotos(){
        
          
        customView.backgroundColor = UIColor.purple
        imageView.translatesAutoresizingMaskIntoConstraints = false
        customView.addSubview(imageView)
        imageView.anchor(top: customView.topAnchor, left: customView.leftAnchor, bottom:customView.bottomAnchor, right: customView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: customView.frame.width, height: customView.frame.height)
        customView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        let renderer = UIGraphicsImageRenderer(size: CGSize.init(width: 200, height: 200))
        let image = renderer.image { (ctx) in
            let rectange  = CGRect(x: 0, y: 0, width: 200, height: 200)
            ctx.cgContext.setFillColor(UIColor.black.cgColor)
            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            ctx.cgContext.addRect(rectange)
            ctx.cgContext.drawPath(using: .fillStroke)
             
            let tour = UIImage.init(named: "playstore")!
            tour.draw(at: CGPoint.init(x: 50, y: 50))
        }
        
         customView.addSubview(filterImageView)
        self.filterImageView.image = UIImage.init(named: "playstore")!
        self.filterImageView.frame = CGRect.init(x: self.imageView.center.x, y: self.imageView.center.y,  width:100, height:100)
         
        
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
                    /* let filterModel = KeyFilter()
                     self.realmFilter.beginWrite()
                     
                     for filter in (self.filterData as NSArray as! [FilterProtocol]) {
                     
                     filterModel.name = filter.overlayName
                     filterModel.id =  "\(filter.overlayId!)"
                     filterModel.previewIcon = filter.overlayPreviewIconUrl
                     filterModel.icon = filter.overlayUrl
                     self.realmFilter.add(filterModel)
                     print(filterModel.name)
                     } */
                    
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
            print(imageURL)
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
    private func drawLogoIn(_ image: UIImage, _ logo: UIImage, position: CGPoint) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
            logo.draw(in: CGRect(origin: position, size: logo.size))
        }
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
                            //cell.iconView.image = image
                            
                            
                            self.filterImageView.image = image
                            self.filterImageView.frame = CGRect.init(x: self.imageView.center.x, y: self.imageView.center.y,  width: 200, height: 200)
                            self.filterImageView.translatesAutoresizingMaskIntoConstraints = false
                            self.filterImageView.transform = CGAffineTransform(scaleX: 2, y: 2)
                            self.filterImageView.transform = CGAffineTransform(translationX: -256, y: -256)
                            self.filterImageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                            self.filterImageView.transform = CGAffineTransform.identity
                            
                            self.customView.addSubview(self.filterImageView)
                            self.customView.centerXAnchor.constraint(equalTo: self.filterImageView.centerXAnchor).isActive = true
                            self.customView.centerYAnchor.constraint(equalTo: self.filterImageView.centerYAnchor).isActive = true
                            
                            let rotate = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotation(sender:)))
                            self.filterImageView.addGestureRecognizer(rotate)
                            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(sender:)))
                            self.filterImageView.addGestureRecognizer(pinch)
                            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
                            self.filterImageView.addGestureRecognizer(panGesture)
                            
                            self.filterImageView.isUserInteractionEnabled = true
                            self.filterImageView.isMultipleTouchEnabled = true
                            
                        }
                    }
                }
            }else  if indexPath.row == 0{
                
               self.imageView.addSubview(self.filterImageView)
                self.filterImageView.frame = CGRect.init(x: self.imageView.center.x, y: self.imageView.center.y,  width: 200, height: 200)
                self.filterImageView.image =  UIImage()
                
            }
            /*
             imageView.image = UIImage(cgImage: cgImage,
             scale: cell.iconView.image!.scale,
             orientation:  cell.iconView.image!.imageOrientation)
             */
            
        }
    }
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    func saveImage(image: UIImage) -> Bool {
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
            return false
        }
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return false
        }
        do {
            try data.write(to: directory.appendingPathComponent("fileName.png")!)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}
extension UIView {

    func asImage() -> UIImage? {
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            return renderer.image { rendererContext in
                layer.render(in: rendererContext.cgContext)
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
            defer { UIGraphicsEndImageContext() }
            guard let currentContext = UIGraphicsGetCurrentContext() else {
                return nil
            }
            self.layer.render(in: currentContext)
            return UIGraphicsGetImageFromCurrentImageContext()
        }
    }
       
}
class ImagePickerManagerUpload : NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    var picker = UIImagePickerController();
    var alert = UIAlertController(title: "Fotoğraf Seçin", message: nil, preferredStyle: .actionSheet)
    var viewController: UIViewController?
    var pickImageCallback : ((UIImage) -> ())?;
    
    override init(){
        super.init()
    }
    
    func pickImage(_ viewController: UIViewController, _ callback: @escaping ((UIImage) -> ())) {
        pickImageCallback = callback
        self.viewController = viewController
        let galleryAction = UIAlertAction(title: "Fotoğraflarım", style: .default){
            UIAlertAction in
            self.openGallery()
        }
        let cancelAction = UIAlertAction(title: "İptal", style: .cancel){
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


