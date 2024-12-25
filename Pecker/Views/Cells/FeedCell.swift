import UIKit
import Kingfisher
import SnapKit

class FeedCell: UITableViewCell {
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let iconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()
    
    private let websiteLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    private let defaultIconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
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
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        iconContainer.addSubview(defaultIconLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(websiteLabel)
        
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-6)
        }
        
        iconContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        defaultIconLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalTo(iconContainer.snp.right).offset(12)
            make.right.equalToSuperview().offset(-12)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.right.equalTo(titleLabel)
        }
        
        websiteLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(4)
            make.left.right.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-12)
        }
    }
    
    // MARK: - Configuration
    func configure(with feed: Feed) {
        titleLabel.text = feed.title
        descriptionLabel.text = feed.category
        websiteLabel.text = URL(string: feed.url)?.host
        
        // 设置图标
        if let iconURL = feed.iconURL {
            iconImageView.isHidden = false
            defaultIconLabel.isHidden = true
            iconImageView.kf.setImage(
                with: URL(string: iconURL),
                placeholder: nil,
                options: [
                    .transition(.fade(0.2)),
                    .processor(DownsamplingImageProcessor(size: CGSize(width: 40, height: 40))),
                    .scaleFactor(UIScreen.main.scale),
                    .cacheOriginalImage
                ]
            ) { [weak self] result in
                switch result {
                case .failure:
                    // 如果图片加载失败，显示默认文字图标
                    self?.showDefaultIcon(for: feed.title)
                default:
                    break
                }
            }
        } else {
            showDefaultIcon(for: feed.title)
        }
        
        // 添加点击时的动画效果
        let interaction = UIContextMenuInteraction(delegate: self)
        containerView.addInteraction(interaction)
    }
    
    private func showDefaultIcon(for title: String) {
        iconImageView.isHidden = true
        defaultIconLabel.isHidden = false
        defaultIconLabel.text = String(title.prefix(1)).uppercased()
        
        // 根据标题生成随机颜色
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemIndigo, .systemOrange, .systemPurple, .systemPink]
        let index = abs(title.hashValue) % colors.count
        iconContainer.backgroundColor = colors[index].withAlphaComponent(0.2)
        defaultIconLabel.textColor = colors[index]
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.kf.cancelDownloadTask()
        iconImageView.image = nil
        defaultIconLabel.text = nil
        websiteLabel.text = nil
    }
}

// MARK: - UIContextMenuInteractionDelegate
extension FeedCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let subscribeAction = UIAction(
                title: LocalizedString("feed.add"),
                image: UIImage(systemName: "plus.circle.fill"),
                attributes: []
            ) { [weak self] _ in
                // TODO: Handle subscribe action
            }
            
            let shareAction = UIAction(
                title: LocalizedString("share"),
                image: UIImage(systemName: "square.and.arrow.up"),
                attributes: []
            ) { [weak self] _ in
                // TODO: Handle share action
            }
            
            return UIMenu(title: "", children: [subscribeAction, shareAction])
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion { [weak self] in
            // TODO: Handle preview action
        }
    }
} 
