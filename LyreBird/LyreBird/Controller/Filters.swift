//
//  Filter.swift
//  LyreBird
//


import UIKit
import RealmSwift
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
    let imageView : UIImageView = {
        var imageView = UIImageView()
        imageView.image = UIImage(named: "playstore")!
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getPhotos()
        self.fetchFilters()
        print(Realm.Configuration.defaultConfiguration.fileURL)
    }
    func getPhotos(){
        
        customView.addSubview(getPhoto)
        getPhoto.translatesAutoresizingMaskIntoConstraints = false
        getPhoto.anchor(top: nil, left: customView.leftAnchor , bottom: customView.topAnchor, right: customView.rightAnchor, paddingTop: 0, paddingLeft:0, paddingBottom: 0, paddingRight:   0 , width: customView.frame.width, height:60)
        customView.bottomAnchor.constraint(equalTo: getPhoto.bottomAnchor,constant: 0).isActive = true
        
        let height: CGFloat = 50
        let bounds = self.navigationController!.navigationBar.bounds
        self.navigationController?.navigationBar.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height + height)
        self.customView.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 50, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: customView.frame.width, height: customView.frame.height)
        
        self.customView.backgroundColor = .lightGray
        
    }
    func filterView(){
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        stackView.backgroundColor = .blue
        view.addSubview(stackView)
        stackView.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width, height: 300)
    }
    @objc func goChoose(){
        print("choose")
        
        ImagePickerManagerUpload().pickImage(self){ image in
            print(image)
        }
        
    }
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    func fetchFilters(){
        //self.realmFilter.beginWrite()
        //realmFilter.delete(self.realmFilter.objects(KeyFilter.self))
        //try! self.realmFilter.commitWrite()
       
        
        if Network.isConnectedToNetwork() == true {
            request.getRequest( api: Config.FILTERS , completion : { response in
                DispatchQueue.main.async {
                    let jsonDecoder = JSONDecoder()
                    self.filterData = try! jsonDecoder.decode([FilterProtocol].self, from: response as! Data)
                    let filterModel = KeyFilter()
                   self.realmFilter.beginWrite()
                   
                    for filter in (self.filterData as NSArray as! [FilterProtocol]) {
                        
                        filterModel.name = filter.overlayName
                        filterModel.id =  "\(filter.overlayId!)"
                        filterModel.previewIcon = filter.overlayPreviewIconUrl
                        filterModel.icon = filter.overlayUrl
                        self.realmFilter.add(filterModel)
                        print(filterModel.name)
                    } 
                     
                }
            })
        }else{
            let realm =  self.realmFilter.objects(KeyFilter.self)
                   //print(realm)
            for item in realm{
                print(item.name)
            }
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
        pickImageCallback = callback;
        self.viewController = viewController;
        
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

