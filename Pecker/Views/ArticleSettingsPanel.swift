import UIKit

protocol ArticleSettingsPanelDelegate: AnyObject {
    func settingsPanel(_ panel: ArticleSettingsPanel, didChangeFontSize size: CGFloat)
    func settingsPanel(_ panel: ArticleSettingsPanel, didSelectFont font: String)
}

class ArticleSettingsPanel: UIView {
    enum FontSize: Int, CaseIterable {
        case small = 0
        case normal = 1
        case large = 2
        case extraLarge = 3
        
        var size: CGFloat {
            switch self {
            case .small: return 14
            case .normal: return 16
            case .large: return 18
            case .extraLarge: return 20
            }
        }
    }
    
    weak var delegate: ArticleSettingsPanelDelegate?
    
    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["小", "标准", "大", "特大"])
        control.selectedSegmentIndex = 1 // 默认标准大小
        return control
    }()
    
    private let fontPickerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("选择字体", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        return button
    }()
    
    private let blurView: UIVisualEffectView = {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blur.clipsToBounds = true
        return blur
    }()
    
    private let handleView: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiaryLabel
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.1
        
        // 添加圆角
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.cornerRadius = 16
        
        addSubview(blurView)
        blurView.contentView.addSubview(handleView)
        blurView.contentView.addSubview(segmentedControl)
        blurView.contentView.addSubview(fontPickerButton)
        
        [blurView, handleView, segmentedControl, fontPickerButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            handleView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 8),
            handleView.centerXAnchor.constraint(equalTo: blurView.contentView.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 36),
            handleView.heightAnchor.constraint(equalToConstant: 5),
            
            segmentedControl.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -16),
            
            fontPickerButton.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            fontPickerButton.leadingAnchor.constraint(equalTo: segmentedControl.leadingAnchor),
            fontPickerButton.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -16)
        ])
        
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        fontPickerButton.addTarget(self, action: #selector(showFontPicker), for: .touchUpInside)
    }
    
    @objc private func segmentedControlValueChanged() {
        let fontSize = FontSize.allCases[segmentedControl.selectedSegmentIndex]
        delegate?.settingsPanel(self, didChangeFontSize: fontSize.size)
    }
    
    @objc private func showFontPicker() {
        let fontPicker = UIFontPickerViewController()
        fontPicker.delegate = self
        if let viewController = delegate as? UIViewController {
            viewController.present(fontPicker, animated: true)
        }
    }
}

extension ArticleSettingsPanel: UIFontPickerViewControllerDelegate {
    func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
        if let descriptor = viewController.selectedFontDescriptor {
            delegate?.settingsPanel(self, didSelectFont: descriptor.postscriptName)
        }
    }
} 