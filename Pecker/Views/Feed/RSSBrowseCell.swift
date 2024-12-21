import UIKit
import SnapKit
import Kingfisher

class RSSBrowseCell: UICollectionViewCell {
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .tertiarySystemBackground
        return iv
    }()
    
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = .systemBackground
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
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
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemBlue
        label.numberOfLines = 1
        return label
    }()
    
    private let subscribersLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    private let topicsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 4
        sv.distribution = .fillProportionally
        return sv
    }()
    
    private let recommendedBadge: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 2
        view.isHidden = true
        return view
    }()
    
    private let recommendedLabel: UILabel = {
        let label = UILabel()
        label.text = "推荐"
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .white
        label.isHidden = true
        return label
    }()
    
    // MARK: - PaddingLabel
    private class PaddingLabel: UILabel {
        var padding: UIEdgeInsets
        
        init(padding: UIEdgeInsets = .zero) {
            self.padding = padding
            super.init(frame: .zero)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func drawText(in rect: CGRect) {
            super.drawText(in: rect.inset(by: padding))
        }
        
        override var intrinsicContentSize: CGSize {
            let size = super.intrinsicContentSize
            return CGSize(
                width: size.width + padding.left + padding.right,
                height: size.height + padding.top + padding.bottom
            )
        }
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(containerView)
        
        [imageView, iconView, titleLabel, descriptionLabel, categoryLabel, 
         subscribersLabel, topicsStackView, recommendedBadge, recommendedLabel].forEach {
            containerView.addSubview($0)
        }
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(120)
        }
        
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.leading.equalToSuperview().offset(12)
            make.top.equalTo(imageView.snp.bottom).offset(-12)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView)
            make.leading.equalTo(iconView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-12)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-12)
        }
        
        topicsStackView.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(20)
        }
        
        categoryLabel.snp.makeConstraints { make in
            make.top.equalTo(topicsStackView.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-12)
        }
        
        subscribersLabel.snp.makeConstraints { make in
            make.centerY.equalTo(categoryLabel)
            make.trailing.equalToSuperview().offset(-12)
        }
        
        recommendedBadge.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
            make.width.equalTo(40)
            make.height.equalTo(20)
        }
        
        recommendedLabel.snp.makeConstraints { make in
            make.center.equalTo(recommendedBadge)
        }
    }
    
    // MARK: - Configuration
    func configure(with feed: RSSDirectoryService.RSSFeed) {
        titleLabel.text = feed.title
        descriptionLabel.text = feed.description
        categoryLabel.text = feed.category
        
        if let subscribers = feed.subscribers {
            subscribersLabel.text = formatSubscriberCount(subscribers)
        } else {
            subscribersLabel.text = nil
        }
        
        // 设置图片
        if let imageUrl = feed.imageUrl {
            imageView.kf.setImage(
                with: URL(string: imageUrl),
                placeholder: UIImage(systemName: "photo"),
                options: [
                    .transition(.fade(0.3)),
                    .processor(DownsamplingImageProcessor(size: CGSize(width: 300, height: 300)))
                ]
            )
        }
        
        // 设置图标
        if let iconUrl = feed.iconUrl {
            iconView.kf.setImage(
                with: URL(string: iconUrl),
                placeholder: UIImage(systemName: "globe"),
                options: [
                    .transition(.fade(0.3)),
                    .processor(DownsamplingImageProcessor(size: CGSize(width: 48, height: 48)))
                ]
            )
        }
        
        // 设置话题标签
        topicsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        feed.topics?.prefix(3).forEach { topic in
            let label = createTopicLabel(text: topic)
            topicsStackView.addArrangedSubview(label)
        }
        
        // 设置推荐标记
        recommendedBadge.isHidden = !(feed.isRecommended ?? false)
        recommendedLabel.isHidden = !(feed.isRecommended ?? false)
    }
    
    private func createTopicLabel(text: String) -> UILabel {
        let label = PaddingLabel(padding: UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6))
        label.text = text
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .secondaryLabel
        label.backgroundColor = .tertiarySystemBackground
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.textAlignment = .center
        return label
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        iconView.kf.cancelDownloadTask()
        imageView.image = nil
        iconView.image = nil
        titleLabel.text = nil
        descriptionLabel.text = nil
        categoryLabel.text = nil
        subscribersLabel.text = nil
        topicsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        recommendedBadge.isHidden = true
        recommendedLabel.isHidden = true
    }
    
    private func formatSubscriberCount(_ count: Int) -> String {
        if count >= 10000 {
            let k = Double(count) / 1000.0
            return String(format: "%.1fk 订阅", k)
        } else {
            return "\(count) 订阅"
        }
    }
} 
