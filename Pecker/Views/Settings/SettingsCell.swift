import UIKit
import SnapKit

class SettingsCell: UITableViewCell {
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
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 10
        clipsToBounds = true
        
        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        
        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(32)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(18)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        
        detailLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }
    }
    
    // MARK: - Configuration
    func configure(with item: SettingsItem) {
        titleLabel.text = item.title
        detailLabel.text = item.detail
        
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        iconImageView.image = UIImage(systemName: item.icon, withConfiguration: symbolConfig)
        iconContainer.backgroundColor = item.iconColor.withAlphaComponent(0.15)
        iconImageView.tintColor = item.iconColor
        
        switch item.accessoryType {
        case .none:
            accessoryType = .none
            accessoryView = nil
        case .disclosureIndicator:
            accessoryType = .disclosureIndicator
            accessoryView = nil
        case .toggle:
            accessoryType = .none
            accessoryView = settingsSwitch
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        accessoryType = .none
        accessoryView = nil
    }
} 