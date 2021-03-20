//
//  ProductCollectionViewCell.swift
//  ProductCataloger
//
//  Created by Interactech on 20/03/2021.
//

import UIKit

protocol ProductCollectionViewCellDelegate: class {
    func didSelect(cell: ProductCollectionViewCell)
}

class ProductCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var productImage: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var category: UILabel!
    @IBOutlet weak var barcode: UILabel!
    @IBOutlet weak var checkBox: UIButton!
    @IBOutlet weak var closeWrapper: UIView!
    
    weak var delegate: ProductCollectionViewCellDelegate?
    
    var isRemoveAction = false {
        didSet {
            closeWrapper.isHidden = !isRemoveAction
        }
    }
    
    var didSelectForRemove: ((_ cell: ProductCollectionViewCell) -> ())?
    
    override func awakeFromNib() {
        layer.borderColor = UIColor.gray.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 10
        productImage.layer.cornerRadius = 10
        closeWrapper.layer.cornerRadius = checkBox.frame.width / 2.2
        checkBox.setImage(UIImage(named: "x"), for: .normal)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didSelectCell))
        addGestureRecognizer(tap)
    }
    
    @objc private func didSelectCell() {
        delegate?.didSelect(cell: self)
    }
    
    @IBAction func didSelectChechBox(_ sender: UIButton) {
        didSelectForRemove?(self)
    }
}
