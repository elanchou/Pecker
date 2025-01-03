import UIKit
import SnapKit

class SectionHeaderView: UICollectionReusableView {
    // MARK: - Properties
    private var contents: [Content] = []
    weak var delegate: SectionHeaderViewDelegate?
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = AppTheme.secondary
        return label
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .lastBaseline
        return stack
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(containerView)
        containerView.addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(countLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
            make.bottom.equalToSuperview()
        }
    }
    
    private func setupGestures() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        addGestureRecognizer(longPress)
    }
    
    // MARK: - Configuration
    func configure(title: String, count: Int, contents: [Content]) {
        titleLabel.text = title
        countLabel.text = "\(count)篇"
        self.contents = contents
        
        // 根据是否有标题调整布局
        if title.isEmpty {
            stackView.isHidden = true
        } else {
            stackView.isHidden = false
        }
    }
    
    // MARK: - Actions
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            // 添加触感反馈
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // 添加动画效果
            UIView.animate(withDuration: 0.2, animations: {
                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                self.alpha = 0.8
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    self.transform = .identity
                    self.alpha = 1.0
                }
            }
            
            delegate?.sectionHeader(self, didLongPressWithContents: contents)
        }
    }
}

protocol SectionHeaderViewDelegate: AnyObject {
    func sectionHeader(_ header: SectionHeaderView, didLongPressWithContents contents: [Content])
}
