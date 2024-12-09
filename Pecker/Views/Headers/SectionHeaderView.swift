import UIKit
import SnapKit

class SectionHeaderView: UICollectionReusableView {
    // MARK: - UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = AppTheme.secondary
        return label
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(titleLabel)
        addSubview(countLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.bottom.equalToSuperview().offset(-18)
        }
        
        countLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(12)
            make.centerY.equalTo(titleLabel)
        }
    }
    
    // MARK: - Configuration
    func configure(title: String, count: Int) {
        titleLabel.text = title
        countLabel.text = "\(count) 篇"
    }
} 
