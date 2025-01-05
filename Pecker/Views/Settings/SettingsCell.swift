import UIKit
import SnapKit

class SettingsCell: UITableViewCell {
    // MARK: - Properties
    var switchValueChanged: ((Bool) -> Void)?
    
    // MARK: - UI Components
    private let iconContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()
    
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    
    private let settingsSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = .systemBlue
        return toggle
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
        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(settingsSwitch)
        
        iconContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(32)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconContainer.snp.right).offset(12)
            make.centerY.equalToSuperview()
        }
        
        detailLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        settingsSwitch.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        settingsSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }
    
    // MARK: - Configuration
    func configure(with item: SettingsItem) {
        iconImageView.image = UIImage(systemName: item.icon)
        iconContainer.backgroundColor = item.iconColor.withAlphaComponent(0.2)
        iconImageView.tintColor = item.iconColor
        titleLabel.text = item.title
        detailLabel.text = item.detail
        
        switch item.accessoryType {
        case .none:
            accessoryType = .none
            settingsSwitch.isHidden = true
            detailLabel.isHidden = item.detail == nil
        case .disclosureIndicator:
            accessoryType = .disclosureIndicator
            settingsSwitch.isHidden = true
            detailLabel.isHidden = item.detail == nil
        case .toggle:
            accessoryType = .none
            settingsSwitch.isHidden = false
            detailLabel.isHidden = true
            settingsSwitch.isOn = item.isOn
        }
    }
    
    // MARK: - Actions
    @objc private func switchChanged(_ sender: UISwitch) {
        switchValueChanged?(sender.isOn)
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        switchValueChanged = nil
        accessoryType = .none
        settingsSwitch.isHidden = true
        detailLabel.isHidden = true
    }
} 