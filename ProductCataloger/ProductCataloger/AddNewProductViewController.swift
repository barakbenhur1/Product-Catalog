//
//  AddNewProductViewController.swift
//  ProductCataloger
//
//  Created by Interactech on 20/03/2021.
//

import UIKit

class AddNewProductViewController: UIViewController {
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var categoryField: UITextField!
    @IBOutlet weak var addImageCover: UIButton!
    @IBOutlet weak var productImage: UIImageView!
    @IBOutlet weak var barcodeField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var vcTitle: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
//    private var currentTextField: UITextField?
    
    private var camera: Bool = true
    
    /// params
    var data: ProductDataTuple?
    var isEdit: Bool = false
    
    var addProductComplition: ((_ product: ProductDataTuple) -> ())?
    var editProductComplition: ((_ product: ProductDataTuple) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let data =  data {
            vcTitle.text = isEdit ? "Edit Product" : "Add Product"
            addImageCover.setTitle(isEdit ? "Edit Imgae" : "Add Image", for: .normal)
            nameField.text = data.name
            categoryField.text = data.category
            barcodeField.text = data.barcode
            productImage.image = data.image
            
            isFormFull()
            addButton.setTitle(isEdit ? "Save" : "Add", for: .normal)
            
            nameField.returnKeyType = .done
            categoryField.returnKeyType = .done
            barcodeField.returnKeyType = .done
        }
        
        productImage.layer.cornerRadius = 10
        productImage.layer.borderWidth = 0.2
        productImage.layer.borderColor = UIColor.black.cgColor
        
        nameField.delegate = self
        categoryField.delegate = self
        barcodeField.delegate = self
        
        nameField.autocorrectionType = .no
        categoryField.autocorrectionType = .no
        barcodeField.autocorrectionType = .no
        
        nameField.addTarget(self, action: #selector(isFormFull), for: .editingChanged)
        categoryField.addTarget(self, action: #selector(isFormFull), for: .editingChanged)
        barcodeField.addTarget(self, action: #selector(isFormFull), for: .editingChanged)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        barcodeField.isEnabled = false
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
            
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
           // if keyboard size is not available for some reason, dont do anything
           return
        }
      
      // move the root view up by the distance of keyboard height
      self.view.frame.origin.y = 0 - keyboardSize.height
    }

    @objc func keyboardWillHide(notification: NSNotification) {
      // move back the root view origin to zero
      self.view.frame.origin.y = 0
    }
    
    @IBAction func didClickAddImage(_ sender: UIButton) {
        let actionsheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        actionsheet.addAction(UIAlertAction(title: "Take a Photo", style: UIAlertAction.Style.default, handler: { (action) -> Void in
            let vc = UIImagePickerController()
            vc.sourceType = .camera
            vc.allowsEditing = true
            vc.delegate = self
            self.camera = true
            self.present(vc, animated: true)
        }))
        
        actionsheet.addAction(UIAlertAction(title: "Choose Exisiting Photo", style: UIAlertAction.Style.default, handler: { (action) -> Void in
            if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
                print("Button capture")
                let imagePicker = UIImagePickerController()
                imagePicker.allowsEditing = false
                imagePicker.sourceType = .photoLibrary
                imagePicker.delegate = self
                self.camera = false
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        
        actionsheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (action) -> Void in
            
        }))
        
        present(actionsheet, animated: true, completion: nil)
    }
    
    
    @objc private func tapOnBack(tapGestureRecognizer: UITapGestureRecognizer) {
        nameField.resignFirstResponder()
        categoryField.resignFirstResponder()
        barcodeField.resignFirstResponder()
    }
    
    @IBAction func addProduct(_ sender: UIButton) {
        let product = ProductDataTuple(image: productImage.image, name: nameField.text!, barcode: barcodeField.text!, category: categoryField.text!)
        isEdit ? editProductComplition?(product) : addProductComplition?(product)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didClickOnBack(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func isFormFull() {
        addButton.isEnabled = nameField.text?.isEmpty == false && categoryField.text?.isEmpty == false && barcodeField.text?.isEmpty == false && productImage.image != nil
    }
}

extension AddNewProductViewController: UITextFieldDelegate {
    
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        currentTextField = textField
//    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
}

extension AddNewProductViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[camera ? .editedImage : .originalImage] as? UIImage else {
            print("No image found")
            return
        }
        
        addImageCover.setTitle("Edit Image", for: .normal)
        productImage.image = image
        isFormFull()
    }
}
