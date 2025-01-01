import UIKit
import SnapKit
import Kingfisher

class RSSBannerCell: UICollectionViewCell {
    // MARK: - UI Components
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        return imageView
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.7).cgColor
        ]
        layer.locations = [0.5, 1.0]
        layer.cornerRadius = 12
        return layer
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white.withAlphaComponent(0.8)
        label.numberOfLines = 2
        return label
    }()
    
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
        contentView.addSubview(imageView)
        imageView.layer.addSublayer(gradientLayer)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(subtitleLabel.snp.top).offset(-4)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    // MARK: - Configuration
    func configure(with banner: RSSBanner) {
        titleLabel.text = banner.title
        subtitleLabel.text = banner.subtitle
        
        if let url = URL(string: banner.imageURL) {
            imageView.kf.setImage(
                with: url,
                options: [
                    .transition(.fade(0.3)),
                    .processor(DownsamplingImageProcessor(size: bounds.size)),
                    .scaleFactor(UIScreen.main.scale),
                    .cacheOriginalImage
                ]
            )
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
    }
}

// MARK: - RSSBanner Model
struct RSSBanner {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: String
    let targetURL: String
} 