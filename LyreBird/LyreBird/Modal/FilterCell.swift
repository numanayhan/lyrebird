//
//  FilterCell.swift
//  LyreBird


import UIKit

class FilterCell: UICollectionViewCell {
    @IBOutlet weak var borderFilterView: UIView!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var nameTitle: UILabel! 
    let margin:CGFloat = 16
    var iconUrl:String?
    var previewUrl: String?
    var index:Int?
    override func awakeFromNib() {
        super.awakeFromNib()
        self.iconView.layer.cornerRadius = 5
        self.iconView.layer.borderWidth = 2
        self.iconView.layer.borderColor =  UIColor.clear.cgColor
        self.borderFilterView.backgroundColor = .clear
        self.iconView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.nameTitle.textColor = UIColor.white
        
    }
    override var isSelected: Bool {
        didSet {
            if isSelected {
                nameTitle.textColor = UIColor.init(named: "selected")
                iconView.layer.borderWidth = 2
                iconView.layer.borderColor = UIColor.init(named: "selected")?.cgColor
            } else {
                nameTitle.textColor = UIColor.white
                iconView.layer.borderWidth = 0
                iconView.layer.borderColor = UIColor.clear.cgColor
            }
            
        }
    }
    static var nib:UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    static var identifier: String {
        return String(describing: self)
    }
    
}
