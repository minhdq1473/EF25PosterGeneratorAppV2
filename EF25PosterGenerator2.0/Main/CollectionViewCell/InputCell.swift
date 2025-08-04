//
//  InputCell.swift
//  EF25PosterGenerator2.0
//
//  Created by iKame Elite Fresher 2025 on 4/8/25.
//

import UIKit

class InputCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var placeholderLabel: UILabel!
    var onTextChanged: ((String) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUIImageView()
        setupTextField()
        // Initialization code
    }

//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupUIImageView()
//        setupTextField()
//    }
    
    private func setupUIImageView() {
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .systemGray4
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        placeholderLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        placeholderLabel.textColor = .white
        placeholderLabel.textAlignment = .center
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupTextField() {
        textField.layer.cornerRadius = 12
        textField.backgroundColor = .systemGray6
        textField.textAlignment = .center
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [space, doneItem]
        textField.inputAccessoryView = toolbar
    }
    
    @objc private func textChanged() {
        onTextChanged?(textField.text ?? "")
    }
    
    @objc private func dismissKeyboard() {
        textField.resignFirstResponder()
    }
    
    func configure(with image: UIImage?, text: String, index: Int) {
        imageView.image = image
        
        placeholderLabel.text = "Image \(index)"
        placeholderLabel.isHidden = image != nil
        
        textField.text = text
        textField.placeholder = "Label \(index)"
    }
}
