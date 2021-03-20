//
//  ViewController.swift
//  ProductCataloger
//
//  Created by Interactech on 20/03/2021.
//

import UIKit

typealias ProductDataTuple = (image: UIImage?, name: String, barcode: String, category: String)
typealias RemoveProductTuple = (key: String, index: Int)

class ProductsCatalogViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var removeButton: UIButton!
    
    ///parms
    private var productsDataSource: [String : [ProductDataTuple]]!
    
    private var productKeys: [String]!
    
    private let itemsPerRow: CGFloat = 3
    private let sectionInsets = UIEdgeInsets(
        top: 5,
        left: 20,
        bottom: 5,
        right: 20)
    
    private var removeOn = false
    
    private lazy var cancelRemoveByTap = UITapGestureRecognizer(target: self, action: #selector(cancelRemoveAction))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        productsDataSource = CoreDataManager.shared().load()
        
        productKeys = Array(productsDataSource.keys).sorted()
        
        for key in productKeys {
            self.productsDataSource[key]?.sort {
                $0.name < $1.name
            }
        }
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        removeButton.isHidden = productsDataSource.isEmpty
        self.collectionView.register(UINib(nibName: "ProductCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ProductCollectionViewCell")
        
        collectionView.register(UINib(nibName: "CollectionViewHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
    }
    
    @IBAction func addProduct(_ sender: UIButton) {
        removeOn = false
        collectionView.reloadData()
        let popup = BarcdeScanerPopup.showOn(view: self.view)
        
        popup.scanComplition = { [weak self] code in
            guard let code = code else {
                self?.scanFailed()
                return
            }
            print("code = \(code)")
            
            for products in Array(self!.productsDataSource.values) {
                for storedProduct in products {
                    if storedProduct.barcode == code {
                        let ac = UIAlertController(title:"", message: "Product already scanned", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .destructive))
                        self?.present(ac, animated: true)
                        return
                    }
                }
            }
            
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            guard let nextViewController = storyBoard.instantiateViewController(withIdentifier: "ProductVC") as? AddNewProductViewController else { return }
            nextViewController.data = (image: nil, name: "", barcode: code, category: "")
            
            nextViewController.addProductComplition = { [weak self] product in
                DispatchQueue.main.async {
                    self?.removeButton.isHidden = false
                    if self?.productsDataSource[product.category] == nil {
                        self?.productsDataSource[product.category] = [ProductDataTuple]()
                    }
                    
                    self?.productsDataSource[product.category]?.append(product)
                    
                    self?.productsDataSource[product.category]?.sort {
                        $0.name < $1.name
                    }
                    
                    self?.productKeys = Array((self?.productsDataSource.keys)!).sorted()
                    
                    CoreDataManager.shared().save(productTuple: product)
                    
                    self?.collectionView.reloadData()
                }
            }
            nextViewController.modalPresentationStyle = .fullScreen
            self?.present(nextViewController, animated:true, completion:nil)
        }
    }
    
    @IBAction func removeProduct(_ sender: UIButton) {
        
        if !removeOn {
            removeOn = true
            view.addGestureRecognizer(cancelRemoveByTap)
            removeButton.isHidden = true
        }
        
        collectionView.reloadData()
    }
    
    @objc private func cancelRemoveAction() {
        removeOn = false
        
        var hide = true
        
        for productArr in Array(productsDataSource.values) {
            if !productArr.isEmpty {
                hide = false
                break
            }
        }
        removeButton.isHidden = hide
        view.removeGestureRecognizer(cancelRemoveByTap)
        collectionView.reloadData()
    }
    
    func scanFailed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

extension ProductsCatalogViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if productsDataSource[productKeys[section]]?.isEmpty == false {
            return CGSize(width: collectionView.frame.width, height: 34)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind:
                            String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier:
                                                                        "header", for: indexPath) as! CollectionViewHeader
        header.title.text = productKeys[indexPath.section]
        return header
    }
}

extension ProductsCatalogViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return productKeys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let key = productKeys[section]
        return productsDataSource[key]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCollectionViewCell", for: indexPath) as? ProductCollectionViewCell else {
            return ProductCollectionViewCell()
        }
        
        let key = productKeys[indexPath.section]
        let products = productsDataSource[key]
        cell.name.text = products?[indexPath.row].name
        cell.category.text = products?[indexPath.row].category
        cell.barcode.text = products?[indexPath.row].barcode
        cell.productImage.image = products?[indexPath.row].image
        cell.isRemoveAction = removeOn
        
        if !removeOn {
            cell.isSelected = false
        }
        
        cell.didSelectForRemove = { [weak self] cell in
            guard let strongSelf = self, let indexPath = collectionView.indexPath(for: cell) else { return }
            let key = strongSelf.productKeys[indexPath.section]
            CoreDataManager.shared().remove(product: (strongSelf.productsDataSource[key]?[indexPath.row])!)
            strongSelf.productsDataSource[key]?.remove(at: indexPath.row)
            
            strongSelf.removeButton.isHidden = true
            
            collectionView.reloadData()
        }
        
        cell.delegate = self
        
        return cell
    }
}

// MARK: - Collection View Flow Layout Delegate
extension ProductsCatalogViewController: UICollectionViewDelegateFlowLayout {
    // 1
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 2
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    // 3
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // 4
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

import CoreData

class CoreDataManager {
    
    var products: [NSManagedObject] = []
    
    private static var inastance: CoreDataManager!
    
    static func shared() -> CoreDataManager {
        guard inastance != nil else {
            inastance = CoreDataManager()
            return inastance
        }
        
        return inastance
    }
    
    private init() {}
    
    func save(productTuple: ProductDataTuple) {
        
        guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        // 1
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        // 2
        let entity =
            NSEntityDescription.entity(forEntityName: "Product",
                                       in: managedContext)!
        
        let product = NSManagedObject(entity: entity,
                                      insertInto: managedContext)
        
        // 3
        product.setValue(productTuple.name, forKeyPath: "name")
        product.setValue(productTuple.category, forKeyPath: "category")
        product.setValue(productTuple.barcode, forKeyPath: "barcode")
        product.setValue(productTuple.image, forKeyPath: "image")
        
        // 4
        do {
            try managedContext.save()
            products.append(product)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func remove(product: ProductDataTuple) {
        
        guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Product")
        fetchRequest.predicate = NSPredicate(format: "barcode = %@", "\(product.barcode)")
        
        do {
            let objects = try managedContext.fetch(fetchRequest)
            for object in objects {
                managedContext.delete(object as! NSManagedObject)
            }
            try managedContext.save()
        } catch _ {
            // error handling
        }
    }
    
    func load() -> [String : [ProductDataTuple]] {
        //1
        guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
            return [String : [ProductDataTuple]]()
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Product")
        
        //3
        do {
            let managedProducts = try managedContext.fetch(fetchRequest)
            var products = [String : [ProductDataTuple]]()
            managedProducts.forEach { (managedProduct) in
                let product = ProductDataTuple(image: managedProduct.value(forKey: "image") as? UIImage, name: managedProduct.value(forKey: "name") as! String, barcode: managedProduct.value(forKey: "barcode") as! String, category: managedProduct.value(forKey: "category") as! String)
                
                if  products[product.category] == nil {
                    products[product.category] = [ProductDataTuple]()
                }
                
                products[product.category]?.append(product)
            }
            
            return products
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return [String : [ProductDataTuple]]()
        }
    }
}

extension ProductsCatalogViewController: ProductCollectionViewCellDelegate {
    func didSelect(cell: ProductCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        guard self.removeOn == false else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCollectionViewCell", for: indexPath) as? ProductCollectionViewCell else {
                return
            }
            cell.didSelectChechBox(UIButton())
            return
        }
        
        self.removeOn = false
        self.collectionView.reloadData()
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        guard let nextViewController = storyBoard.instantiateViewController(withIdentifier: "ProductVC") as? AddNewProductViewController else { return }
        let key = productKeys[indexPath.section]
        let products = self.productsDataSource[key]
        let product = products![indexPath.row]
        nextViewController.data = (image: product.image, name: product.name, barcode: product.barcode, category: product.category)
        nextViewController.isEdit = true
        
        nextViewController.editProductComplition = { [weak self] newProduct in
            self?.productsDataSource[product.category]?.remove(at: indexPath.row)
            CoreDataManager.shared().remove(product: product)
            if self?.productsDataSource[newProduct.category] == nil {
                self?.productsDataSource[newProduct.category] = [ProductDataTuple]()
            }
            self?.productsDataSource[newProduct.category]?.append(newProduct)
            self?.productKeys = Array((self?.productsDataSource.keys)!).sorted()
            
            self?.productsDataSource[newProduct.category]?.sort {
                $0.name < $1.name
            }
            CoreDataManager.shared().save(productTuple: newProduct)
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
            }
        }
        
        nextViewController.modalPresentationStyle = .overFullScreen
        self.present(nextViewController, animated:true, completion:nil)
    }
}

