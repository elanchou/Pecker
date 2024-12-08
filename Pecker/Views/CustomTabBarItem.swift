import UIKit
import SnapKit

class CustomTabBarItem: UIView {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondaryLabel
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let badgeView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()
    
    var isSelected: Bool = false {
        didSet {
            iconImageView.tintColor = isSelected ? .systemRed : .secondaryLabel
            iconImageView.image = isSelected ? selectedImage : normalImage
            titleLabel.textColor = isSelected ? .systemRed : .secondaryLabel
        }
    }
    
    private var normalImage: UIImage?
    private var selectedImage: UIImage?
    
    init(normalImage: UIImage?, selectedImage: UIImage?) {
        super.init(frame: .zero)
        self.normalImage = normalImage
        self.selectedImage = selectedImage
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(badgeView)
        
        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconImageView.snp.bottom).offset(4)
        }
        
        badgeView.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.top).offset(-4)
            make.left.equalTo(iconImageView.snp.right).offset(-4)
            make.size.equalTo(16)
        }
        
        iconImageView.image = normalImage
    }
    
    func setBadge(visible: Bool) {
        badgeView.isHidden = !visible
    }
} 