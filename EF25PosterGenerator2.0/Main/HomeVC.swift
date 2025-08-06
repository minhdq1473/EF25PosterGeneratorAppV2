//
//  HomeVC.swift
//  EF25PosterGenerator2.0
//
//  Created by iKame Elite Fresher 2025 on 1/8/25.
//

import UIKit
import PhotosUI

class HomeVC: UIViewController {
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var resultPlaceholder: UILabel!
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var generateBtn: UIButton!
    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var numberOfImagesTextField: UITextField!
    @IBOutlet weak var inputCollectionView: UICollectionView!
    
    private var listImage: [UIImage] = [] {
        didSet {
            updateInputImages()
            updateUI()
        }
    }
    
    private var listLabel: [NSAttributedString] {
        return inputTexts.enumerated().map { index, text in
            .init(string: text, attributes: textAttributes)
        }
    }
    
    private var isGenerate: Bool = false {
        didSet {
            if isGenerate {
                generateBtn.setTitle("Save to Photo Library", for: .normal)
                addBtn.setTitle("Add new photos", for: .normal)
            } else {
                generateBtn.setTitle("Generate Poster", for: .normal)
                addBtn.setTitle("Add photos", for: .normal)
            }
        }
    }
    
    private var inputImages: [UIImage?] = []
    private var inputTexts: [String] = []
    private var resultImg: UIImage?
    private var numberOfImg = 3
    private var selectedImg: Int?
    
    private let numberPicker = UIPickerView()
    private let availableNumbers = Array(2...7)
    
    lazy var textAttributes: [NSAttributedString.Key : Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: UIColor.neutral5,
            .paragraphStyle: paragraphStyle
        ]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNumberPicker()
        setupCollectionView()

        setupBtn()
        setupImages()
        initializeArrays()
        notificationLabel.text = "Add \(numberOfImg) photos to create poster"
        notificationLabel.textColor = .systemGray
 //        notificationLabel.text = "Select number of photos, default is 3"
    }
    
    private func setupNumberPicker() {
        numberOfImagesTextField.text = "\(numberOfImg) photos"
        numberOfImagesTextField.textAlignment = .center
        numberOfImagesTextField.layer.cornerRadius = 8
        numberOfImagesTextField.layer.borderWidth = 1
        numberOfImagesTextField.layer.borderColor = UIColor.primary1.cgColor
        numberOfImagesTextField.backgroundColor = .neutral5
        numberOfImagesTextField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        numberOfImagesTextField.isUserInteractionEnabled = true
        
        numberPicker.delegate = self
        numberPicker.dataSource = self
        
        if let defaultIndex = availableNumbers.firstIndex(of: numberOfImg) {
            numberPicker.selectRow(defaultIndex, inComponent: 0, animated: false)
        }
        
        numberOfImagesTextField.inputView = numberPicker
        numberOfImagesTextField.inputAccessoryView = makePickerToolbar()
    }
    
    private func makePickerToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelPicker))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(confirmPicker))
        
        toolbar.items = [cancelItem, space, doneItem]
        return toolbar
    }
    
    @objc private func cancelPicker() {
        numberOfImagesTextField.resignFirstResponder()
    }
    
    @objc private func confirmPicker() {
        let selectedRow = numberPicker.selectedRow(inComponent: 0)
        let newNumber = availableNumbers[selectedRow]
        
        if newNumber != numberOfImg {
            updateNumberOfImages(newNumber)
        }
        
        numberOfImagesTextField.resignFirstResponder()
    }
    
    private func updateInputImages() {
        inputImages = Array(repeating: nil, count: numberOfImg)

        for (index, image) in listImage.enumerated() {
            if index < inputImages.count {
                inputImages[index] = image
            }
        }
        inputCollectionView.reloadData()
    }
    
    private func updateNumberOfImages(_ newCount: Int) {
        numberOfImg = newCount
        numberOfImagesTextField.text = "\(numberOfImg) photos"
        
        listImage.removeAll()
        resultImg = nil
        resultImageView.image = nil
        isGenerate = false
        
        inputImages = Array(repeating: nil, count: newCount)
        inputTexts = Array(repeating: "", count: newCount)
        
        inputCollectionView.reloadData()
        
        notificationLabel.text = "Add \(newCount) photos to create poster"
        notificationLabel.textColor = .neutral2
        
        setupImages()
    }
    
    @IBAction func addImg(_ sender: UIButton) {
        if isGenerate {
            listImage.removeAll()
            resultImageView.image = nil
            
            initializeArrays()
            inputCollectionView.reloadData()

            isGenerate = false
            notificationLabel.text = "Add \(numberOfImg) photos to create poster"
            
            resultPlaceholder.isHidden = false
        } else {
            if listImage.count < numberOfImg {
                let alert = UIAlertController(title: "Add Photo", message: nil, preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
                    let vc = CameraVC()
                    vc.delegate = self
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true)
                })
                
                alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
                    var config = PHPickerConfiguration()
                    config.selectionLimit = self.numberOfImg - self.listImage.count
                    config.filter = .images
                    let picker = PHPickerViewController(configuration: config)
                    picker.delegate = self
                    self.present(picker, animated: true)
                })
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                present(alert, animated: true)
            } else {
                notificationLabel.text = "Too many images selected!"
                notificationLabel.textColor = .accentRed
            }
        }
    }
    
    @IBAction func generatePoster(_ sender: UIButton) {
        if isGenerate {
            if let savedImage = resultImg {
                UIImageWriteToSavedPhotosAlbum(savedImage, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        } else {
            guard listImage.count == numberOfImg else {
                notificationLabel.text = "Choose exactly \(numberOfImg) images!!"
                notificationLabel.textColor = .accentRed
                return
            }
            
            let frame = resultImageView.bounds
            let labelHeight: CGFloat = 24
            let posterWidth = frame.width
            let posterHeight = frame.height - labelHeight
            let imgWidth = posterWidth / CGFloat(numberOfImg)
            let declination: CGFloat = 16
            
            let renderer = UIGraphicsImageRenderer(bounds: frame)
            let resultImage = renderer.image { context in
                let ctx = context.cgContext
                
                for i in 0..<numberOfImg {
                    ctx.saveGState()
                    let positionX = CGFloat(i) * imgWidth

                    let clippingPath = UIBezierPath()
                    var leftTopX = positionX
                    var leftBottomX = positionX
                    
                    if i > 0 {
                        let separator = positionX
                        if i % 2 == 1 {
                            leftTopX = separator - declination
                            leftBottomX = separator + declination
                        } else {
                            leftTopX = separator + declination
                            leftBottomX = separator - declination
                        }
                    }
                    
                    var rightTopX = positionX + imgWidth
                    var rightBottomX = positionX + imgWidth
                    
                    if i < numberOfImg - 1 {
                        let separator = positionX + imgWidth
                        if (i + 1) % 2 == 1 {
                            rightTopX = separator - declination
                            rightBottomX = separator + declination
                        } else {
                            rightTopX = separator + declination
                            rightBottomX = separator - declination
                        }
                    }
                    
                    clippingPath.move(to: CGPoint(x: leftTopX, y: 0))
                    clippingPath.addLine(to: CGPoint(x: rightTopX, y: 0))
                    clippingPath.addLine(to: CGPoint(x: rightBottomX, y: posterHeight))
                    clippingPath.addLine(to: CGPoint(x: leftBottomX, y: posterHeight))
                    clippingPath.close()
                    
                    clippingPath.addClip()
                    
                    let image = listImage[i]
                    if i == 0 {
                        let imgFrame = CGRect(x: positionX, y: 0, width: imgWidth + declination, height: posterHeight)
                        image.draw(in: aspectFilledRect(for: image.size, in: imgFrame))
                    } else if i == numberOfImg - 1 {
                        let imgFrame = CGRect(x: positionX - declination, y: 0, width: imgWidth + declination, height: posterHeight)
                        image.draw(in: aspectFilledRect(for: image.size, in: imgFrame))
                    } else {
                        let imgFrame = CGRect(x: positionX - declination, y: 0, width: imgWidth + declination * 2, height: posterHeight)
                        image.draw(in: aspectFilledRect(for: image.size, in: imgFrame))
                    }
                    
                    ctx.restoreGState()
                }
                
                for i in 1..<numberOfImg {
                    let separatorWidth = imgWidth * CGFloat(i)
                    let separator = UIBezierPath()

                    if i % 2 == 1 {
                        separator.move(to: CGPoint(x: separatorWidth - declination, y: 0))
                        separator.addLine(to: CGPoint(x: separatorWidth + declination, y: posterHeight))
                        UIColor.white.setStroke()
                        separator.lineWidth = 4
                        separator.stroke()
                    } else {
                        separator.move(to: CGPoint(x: separatorWidth + declination, y: 0))
                        separator.addLine(to: CGPoint(x: separatorWidth - declination, y: posterHeight))
                        UIColor.white.setStroke()
                        separator.lineWidth = 4
                        separator.stroke()
                    }
                }
                
                UIColor.systemBrown.setFill()
                UIBezierPath(rect: CGRect(origin: CGPoint(x: .zero, y: posterHeight), size: .init(width: posterWidth, height: labelHeight))).fill()
                
                let CGFTotal: CGFloat = CGFloat(numberOfImg)
                let listAttributedText = listLabel
                for i in 0..<listAttributedText.count {
                    listAttributedText[i].draw(in: CGRect(x: posterWidth * CGFloat(i) / CGFTotal , y: posterHeight, width: posterWidth / CGFTotal, height: labelHeight))
                }
            }
            resultImg = resultImage
            resultImageView.image = resultImage
            isGenerate = true
//            resultImageView.subviews.forEach { $0.removeFromSuperview() }
            notificationLabel.text = "Generated successfully!"
            notificationLabel.textColor = .accentGood
            resultPlaceholder.isHidden = true
        }
    }
    
    private func aspectFilledRect(for imageSize: CGSize, in targetRect: CGRect) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let targetAspect = targetRect.width / targetRect.height
        
        var drawRect = targetRect

        if imageAspect > targetAspect {
            let width = targetRect.height * imageAspect
            let x = targetRect.origin.x - (width - targetRect.width) / 2
            drawRect = CGRect(x: x, y: targetRect.origin.y, width: width, height: targetRect.height)
        } else {
            let height = targetRect.width / imageAspect
            let y = targetRect.origin.y - (height - targetRect.height) / 2
            drawRect = CGRect(x: targetRect.origin.x, y: y, width: targetRect.width, height: height)
        }
        return drawRect
    }
    
    @objc private func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            notificationLabel.text = "Error saving image: \(error.localizedDescription)"
            notificationLabel.textColor = .accentRed
        } else {
            notificationLabel.text = "Image saved successfully!"
            notificationLabel.textColor = .accentGood
        }
    }
    
    private func setupBtn() {
        addBtn.setTitle("Add Photos", for: .normal)
        addBtn.layer.cornerRadius = 16
        addBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        addBtn.tintColor = .neutral5
        addBtn.backgroundColor = .primary1
        
        generateBtn.setTitle("Generate Poster", for: .normal)
        generateBtn.layer.cornerRadius = 16
        generateBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        generateBtn.tintColor = .neutral5
        generateBtn.backgroundColor = .primary1
    }
    
    private func setupImages() {
        resultImageView.layer.cornerRadius = 16
        resultImageView.backgroundColor = .neutral3
        resultImageView.subviews.forEach { $0.removeFromSuperview() }
        
        resultPlaceholder.text = "Your poster will show here"
        resultPlaceholder.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        resultPlaceholder.textColor = .neutral5
        resultPlaceholder.textAlignment = .center
        resultPlaceholder.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupCollectionView() {
        inputCollectionView.delegate = self
        inputCollectionView.dataSource = self
        inputCollectionView.showsHorizontalScrollIndicator = false
        inputCollectionView.backgroundColor = .clear
     
        inputCollectionView.register(UINib(nibName: "InputCell", bundle: nil), forCellWithReuseIdentifier: "InputCell")
    }
    
    private func initializeArrays() {
        inputImages = Array(repeating: nil, count: numberOfImg)
        inputTexts = Array(repeating: "", count: numberOfImg)
    }
    
    private func updateUI() {
        let imgCount = listImage.count
        notificationLabel.text = "Added \(imgCount)/\(numberOfImg) images"
        notificationLabel.textColor = imgCount == numberOfImg ? .accentGood : .neutral2
    }
}

extension HomeVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfImg
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InputCell", for: indexPath) as! InputCell
        
        guard indexPath.item < inputImages.count && indexPath.item < inputTexts.count else {
            cell.configure(with: nil, text: "", index: indexPath.item)
            return cell
        }
        
        cell.configure(with: inputImages[indexPath.item], text: inputTexts[indexPath.item], index: indexPath.item + 1)
        cell.onTextChanged = { [weak self] text in
            self?.inputTexts[indexPath.item] = text
            }
        cell.onImageTapped = { [weak self] in
            self?.changePhotoAtIndex(indexPath.item)
        }
        return cell
    }

    private func changePhotoAtIndex(_ index: Int) {
        selectedImg = index
        
        let alert = UIAlertController(title: "Change Photo", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
            let vc = CameraVC()
            vc.delegate = self
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            var config = PHPickerConfiguration()
            config.selectionLimit = 1
            config.filter = .images
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            self.present(picker, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
        if selectedImg != nil && inputImages[index] != nil{
            alert.addAction(UIAlertAction(title: "Remove Photo", style: .destructive) { _ in
                self.listImage.remove(at: index)
                self.selectedImg = nil
            })
        }
    }
}

extension HomeVC: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return availableNumbers.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let number = availableNumbers[row]
        return "\(number) photos"
    }
}

extension HomeVC: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        if let selectedIndex = selectedImg, selectedIndex < listImage.count {
            guard let result = results.first else { return }
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let self = self, let image = image as? UIImage else { return }
                DispatchQueue.main.async {
//                    self.inputImages[selectedIndex] = image
//                    self.inputCollectionView.reloadItems(at: [IndexPath(item: selectedIndex, section: 0)])
                    self.listImage[selectedIndex] = image
                    self.selectedImg = nil
                }
            }
        } else {
            results.forEach { result in
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    guard let self = self, let image = image as? UIImage else { return }
                    DispatchQueue.main.async {
                        self.listImage.append(image)
                    }
                }
            }
        }
    }
}

extension HomeVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            listImage.append(image)
        }
    }
}
extension HomeVC: CameraVCDelegate {
    func cameraVC(_ controller: CameraVC, didCapture image: UIImage) {
        if let selectedIndex = selectedImg, selectedIndex < listImage.count {
            self.listImage[selectedIndex] = image
            
//            inputImages[selectedIndex] = image
//            inputCollectionView.reloadItems(at: [IndexPath(item: selectedIndex, section: 0)])
//            selectedImg = nil
        } else {
            listImage.append(image)
        }
    }
}


