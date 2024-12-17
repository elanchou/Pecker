//
//  SettingCell.swift
//  Pecker
//
//  Created by elanchou on 2024/12/12.
//

import UIKit
import SnapKit

struct Setting {
    let icon: String
    let iconBackgroundColor: UIColor
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        iconBackgroundColor: UIColor,
        title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconBackgroundColor = iconBackgroundColor
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
}

class SettingCell: UITableViewCell {
    // MARK: - Properties
    private let tapFeedback = UISelectionFeedbackGenerator()
    
    // MARK: - UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 10
        
        // 添加微妙的内阴影效果
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = .zero
        view.layer.shadowOpacity = 0.05
        view.layer.shadowRadius = 3
        return view
    }()
    
    private let iconContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        
        // 添加内部渐变
        let gradientLayer = CAGradientLayer()
        gradientLayer.cornerRadius = 6
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.addSublayer(gradientLayer)
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private let titleStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()
    
    private let textStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let accessoryStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()
    
    // MARK: - Init & Setup
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(titleStackView)
        
        titleStackView.addArrangedSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        
        titleStackView.addArrangedSubview(textStackView)
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(subtitleLabel)
        
        titleStackView.addArrangedSubview(accessoryStackView)
        
        // 布局约束
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0))
            make.height.equalTo(54) // 降低高度
        }
        
        titleStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        iconContainer.snp.makeConstraints { make in
            make.size.equalTo(28) // 减小图标尺寸
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(16)
        }
    }
    
    // MARK: - Configuration
    func configure(with setting: Setting) {
        iconContainer.backgroundColor = setting.iconBackgroundColor
        
        // 设置渐变色
        if let gradientLayer = iconContainer.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = iconContainer.bounds
            gradientLayer.colors = [
                setting.iconBackgroundColor.withAlphaComponent(1).cgColor,
                setting.iconBackgroundColor.withAlphaComponent(0.8).cgColor
            ]
        }
        
        iconImageView.image = UIImage(systemName: setting.icon)
        titleLabel.text = setting.title
        subtitleLabel.text = setting.subtitle
        subtitleLabel.isHidden = setting.subtitle == nil
        
        // 根据是否有副标题调整布局
        textStackView.spacing = setting.subtitle == nil ? 0 : 2
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        accessoryType = .none
        accessoryView = nil
        accessoryStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 更新渐变层frame
        if let gradientLayer = iconContainer.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = iconContainer.bounds
        }
    }
}
