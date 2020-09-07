//
//  Filter.swift
//  LyreBird
//


import UIKit
import RealmSwift
import Alamofire
import AlamofireImage
struct FilterModal {
    var title: String
    var iconUrl:String
    var previewUrl:String 
}
class Filters: UIViewController {
    
    let getPhoto : UIButton = {
        let photo = UIButton()
        photo.setTitle("Get Photo", for: .normal)
        photo.setTitleColor(UIColor.white, for: .normal)
        photo.addTarget(self, action: #selector(goChoose), for: .touchUpInside)
        photo.titleLabel?.textAlignment = .center
        photo.backgroundColor = .red
        return photo
    }()
    let filterImageView : UIImageView = {
        var imageView  = UIImageView()
        imageView.image = UIImage(named: "playstore")
        imageView.isUserInteractionEnabled = true
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    let imageView : UIImageView = {
        var imageView = UIImageView()
        imageView.image = UIImage(named: "playstore")!
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
    
    var realmFilter = try! Realm()
    var filterData = [FilterProtocol]()
    var dataArray = [FilterModal]()
    override func viewDidLoad() {
        super.viewDidLoad()
         
        
       
        self.setupViews()
        
    }
    @objc func handleImage(sender: UIRotationGestureRecognizer) {
        if let view = sender.view {
            view.transform = view.transform.rotated(by: sender.rotation)
            sender.rotation = 0
        }
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
    func getPhotos(){
        
        customView.addSubview(imageView)
        imageView.anchor(top: nil, left: customView.leftAnchor, bottom:nil, right: customView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: imageView.frame.width, height: imageView.frame.height)
        imageView.centerXAnchor.constraint(equalTo: customView.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: customView.centerYAnchor).isActive = true
        
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
                            
                            self.customView.addSubview(self.filterImageView)
                            self.filterImageView.anchor(top: nil, left: nil, bottom:nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 100)
                            self.filterImageView.image =  image
                            self.customView.contentMode = .center
                            
                            let rotate = UIRotationGestureRecognizer.init(target: self , action: #selector(self.handleImage(sender:)))
                            self.filterImageView.addGestureRecognizer(rotate)
                             
                        }
                    }
                }
            }else  if indexPath.row == 0{
                self.setupViews()
            }
            /*
             imageView.image = UIImage(cgImage: cgImage,
             scale: cell.iconView.image!.scale,
             orientation:  cell.iconView.image!.imageOrientation)
             */
            
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

