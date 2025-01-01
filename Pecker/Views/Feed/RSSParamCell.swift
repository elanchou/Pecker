import UIKit
import SnapKit

class RSSParamCell: UITableViewCell {
    // MARK: - Properties
    var onTextChanged: ((String) -> Void)?
    
    // MARK: - UI Components
    let textField: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 16)
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        return textField
    }()
    
    private let requiredLabel: UILabel = {
        let label = UILabel()
        label.text = "*"
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 14)
        label.isHidden = true
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        selectionStyle = .none
        
        contentView.addSubview(textField)
        contentView.addSubview(requiredLabel)
        
        textField.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
            make.height.equalTo(32)
        }
        
        requiredLabel.snp.makeConstraints { make in
            make.centerY.equalTo(textField)
            make.trailing.equalTo(textField).offset(-8)
        }
        
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.delegate = self
    }
    
    // MARK: - Configuration
    func configure(with param: RSSDirectoryService.RSSParam) {
        textField.placeholder = param.description
        requiredLabel.isHidden = !param.required
        
        if let example = param.example {
            textField.placeholder = "\(param.description) (例如: \(example))"
        }
    }
    
    // MARK: - Actions
    @objc private func textFieldDidChange(_ textField: UITextField) {
        onTextChanged?(textField.text ?? "")
    }
}

// MARK: - UITextFieldDelegate
extension RSSParamCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
} 