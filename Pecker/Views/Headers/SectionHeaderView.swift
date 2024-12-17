import UIKit
import SnapKit

class SectionHeaderView: UICollectionReusableView {
    // MARK: - Properties
    weak var delegate: SectionHeaderViewDelegate?
    private var contents: [Content] = []
    
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
    
    private let aiButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "sparkles"), for: .normal)
        button.tintColor = AppTheme.dark
        return button
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
        addSubview(aiButton)
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.bottom.equalToSuperview().offset(-18)
            make.width.lessThanOrEqualToSuperview().offset(-80)
        }
        
        countLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(12)
            make.centerY.equalTo(titleLabel)
        }
        
        aiButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(28)
        }
        
        aiButton.addTarget(self, action: #selector(aiButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    func configure(title: String, count: Int, contents: [Content] = []) {
        titleLabel.text = title
        countLabel.text = "\(count) 篇文章"
        self.contents = contents
        
        // 如果没有内容，隐藏 AI 按钮
        aiButton.isHidden = contents.isEmpty
    }
    
    // MARK: - Actions
    @objc private func aiButtonTapped() {
        delegate?.sectionHeader(self, didTapAIButtonWith: contents)
    }
}

// MARK: - Delegate
protocol SectionHeaderViewDelegate: AnyObject {
    func sectionHeader(_ header: SectionHeaderView, didTapAIButtonWith contents: [Content])
}
