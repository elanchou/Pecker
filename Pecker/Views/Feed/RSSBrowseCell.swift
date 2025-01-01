import UIKit
import Kingfisher
import SnapKit

class RSSBrowseCell: UITableViewCell {
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 1
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
        label.textColor = .secondaryLabel
        label.backgroundColor = .tertiarySystemGroupedBackground
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }()
    
    private let subscribeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    var onSubscribe: ((RSSDirectoryService.Feed) -> Void)?
    private var currentFeed: RSSDirectoryService.Feed?
    
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
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(categoryLabel)
        containerView.addSubview(subscribeButton)
        
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-6)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(20)
            make.leading.equalTo(containerView).offset(20)
            make.width.height.equalTo(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView)
            make.leading.equalTo(iconImageView.snp.trailing).offset(20)
            make.trailing.equalTo(subscribeButton.snp.leading).offset(-12)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalTo(titleLabel)
        }
        
        categoryLabel.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(descriptionLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleLabel)
            make.bottom.equalTo(containerView).offset(-12)
            make.height.equalTo(20)
        }
        
        subscribeButton.snp.makeConstraints { make in
            make.centerY.equalTo(containerView)
            make.trailing.equalTo(containerView).offset(-12)
            make.width.height.equalTo(32)
        }
        
        // Add shadow to container view
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        containerView.layer.shadowRadius = 6
        containerView.layer.shadowOpacity = 0.05
        containerView.layer.masksToBounds = false
        
        // Add subtle border
        containerView.layer.borderWidth = 0.5
        containerView.layer.borderColor = UIColor.separator.cgColor
        
        // 添加订阅按钮点击事件
        subscribeButton.addTarget(self, action: #selector(handleSubscribe), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func handleSubscribe() {
        guard let feed = currentFeed else { return }
        onSubscribe?(feed)
        
        // 添加点击反馈动画
        UIView.animate(withDuration: 0.2, animations: {
            self.subscribeButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.subscribeButton.transform = .identity
            }
        }
    }
    
    // MARK: - Configuration
    func configure(with feed: RSSDirectoryService.Feed, category: RSSDirectoryService.RSSCategory) {
        currentFeed = feed
        titleLabel.text = feed.title
        
        // 设置描述文本，如果没有描述则隐藏
        if let description = feed.description, !description.isEmpty {
            descriptionLabel.text = description
            descriptionLabel.isHidden = false
        } else {
            descriptionLabel.isHidden = true
            // 如果没有描述，调整分类标签的位置
            categoryLabel.snp.updateConstraints { make in
                make.top.greaterThanOrEqualTo(descriptionLabel.snp.bottom).offset(4)
            }
        }
        
        // 设置分类标签
        categoryLabel.text = "  \(category.name)  "
        categoryLabel.sizeToFit()
        
        // 根据分类类型设置不同的样式
        switch category.type {
        case .country:
            categoryLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            categoryLabel.textColor = .systemBlue
        default:
            categoryLabel.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.1)
            categoryLabel.textColor = .systemIndigo
        }
        
        // 设置图标
        if let feedURL = URL(string: feed.feedURL) {
            // 使用 Google Favicon API 获取高质量图标
            let iconURL = "https://www.google.com/s2/favicons?sz=128&domain=\(feedURL.host ?? "")"
            iconImageView.kf.setImage(
                with: URL(string: iconURL),
                options: [
                    .transition(.fade(0.2)),
                    .processor(DownsamplingImageProcessor(size: CGSize(width: 32, height: 32))),
                    .scaleFactor(UIScreen.main.scale),
                    .cacheOriginalImage
                ]
            )
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction],
            animations: {
                self.containerView.transform = highlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
                self.containerView.layer.shadowOpacity = highlighted ? 0.1 : 0.05
            }
        )
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.beginFromCurrentState, .allowUserInteraction],
            animations: {
                self.containerView.transform = selected ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
                self.containerView.layer.shadowOpacity = selected ? 0.1 : 0.05
            }
        )
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.kf.cancelDownloadTask()
        iconImageView.image = nil
    }
}

// MARK: - UIImage Extension
extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                  y: inputImage.extent.origin.y,
                                  z: inputImage.extent.size.width,
                                  w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage",
                                  parameters: [kCIInputImageKey: inputImage,
                                             kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage,
                      toBitmap: &bitmap,
                      rowBytes: 4,
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                      format: .RGBA8,
                      colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255,
                      green: CGFloat(bitmap[1]) / 255,
                      blue: CGFloat(bitmap[2]) / 255,
                      alpha: CGFloat(bitmap[3]) / 255)
    }
} 
