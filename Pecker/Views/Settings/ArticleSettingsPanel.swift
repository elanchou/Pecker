import UIKit

protocol ArticleSettingsPanelDelegate: AnyObject {
    func settingsPanel(_ panel: ArticleSettingsPanel, didChangeFontSize size: CGFloat)
    func settingsPanel(_ panel: ArticleSettingsPanel, didSelectFont font: String)
}

class ArticleSettingsPanel: UIView {
    
    weak var delegate: ArticleSettingsPanelDelegate?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let handleView: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiaryLabel
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 32
        return stack
    }()
    
    private let fontSizePreview: UILabel = {
        let label = UILabel()
        label.text = "Aa"
        label.textAlignment = .center
        label.textColor = .label
        label.font = .systemFont(ofSize: 80, weight: .bold)
        return label
    }()
    
    private let fontSizeSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 14
        slider.maximumValue = 24
        slider.value = 17
        return slider
    }()
    
    private let fontSizeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let fontControl: UISegmentedControl = {
        let fonts = ["系统", "无衬线", "衬线"]
        let control = UISegmentedControl(items: fonts)
        control.selectedSegmentIndex = 0
        return control
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(containerView)
        containerView.addSubview(handleView)
        containerView.addSubview(stackView)
        
        // Font size section
        let fontSizeStack = UIStackView(arrangedSubviews: [fontSizePreview, fontSizeSlider, fontSizeLabel])
        fontSizeStack.axis = .vertical
        fontSizeStack.spacing = 16
        fontSizeStack.alignment = .center
        
        // Font type section
        let fontLabel = UILabel()
        fontLabel.text = "字体"
        fontLabel.font = .systemFont(ofSize: 15, weight: .medium)
        fontLabel.textColor = .secondaryLabel
        
        let fontStack = UIStackView(arrangedSubviews: [fontLabel, fontControl])
        fontStack.axis = .vertical
        fontStack.spacing = 12
        
        [fontSizeStack, fontStack].forEach { stackView.addArrangedSubview($0) }
        
        // Layout
        containerView.translatesAutoresizingMaskIntoConstraints = false
        handleView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        fontSizeSlider.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            
            handleView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            handleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 36),
            handleView.heightAnchor.constraint(equalToConstant: 5),
            
            stackView.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            
            fontSizeSlider.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.8)
        ])
        
        updateFontSizeLabel()
    }
    
    private func setupActions() {
        fontSizeSlider.addTarget(self, action: #selector(fontSizeChanged), for: .valueChanged)
        fontControl.addTarget(self, action: #selector(fontChanged), for: .valueChanged)
    }
    
    @objc private func fontSizeChanged() {
        updateFontSizeLabel()
        delegate?.settingsPanel(self, didChangeFontSize: CGFloat(fontSizeSlider.value))
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    @objc private func fontChanged() {
        let fonts = [
            "-apple-system, system-ui",
            "Helvetica Neue, Arial",
            "Georgia, serif"
        ]
        delegate?.settingsPanel(self, didSelectFont: fonts[fontControl.selectedSegmentIndex])
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    private func updateFontSizeLabel() {
        fontSizeLabel.text = "\(Int(fontSizeSlider.value))pt"
        fontSizePreview.font = .systemFont(ofSize: CGFloat(fontSizeSlider.value) * 3, weight: .bold)
    }
}

//extension UIColor {
//    var hexString: String {
//        var red: CGFloat = 0
//        var green: CGFloat = 0
//        var blue: CGFloat = 0
//        var alpha: CGFloat = 0
//        
//        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
//        
//        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
//        
//        return String(format: "%06x", rgb)
//    }
//} 
