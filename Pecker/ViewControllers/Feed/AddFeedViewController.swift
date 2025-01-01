import UIKit
import RealmSwift
import SnapKit

class AddFeedViewController: BaseViewController {
    // MARK: - Properties
    private let rssService = RSSService()
    private var isLoading = false
    
    // MARK: - UI Components
    private let headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "square.stack.3d.up.fill")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "添加新的订阅源"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "输入网站的 RSS 订阅地址，或者从推荐列表中选择"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let inputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let urlTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "输入 RSS 订阅源地址"
        textField.font = .systemFont(ofSize: 17)
        textField.borderStyle = .none
        textField.clearButtonMode = .whileEditing
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .URL
        textField.returnKeyType = .done
        textField.backgroundColor = .clear
        return textField
    }()
    
    private let pasteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "doc.on.clipboard"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("添加订阅", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.isEnabled = false
        
        // 添加渐变背景
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBlue.cgColor,
            UIColor.systemIndigo.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 12
        button.layer.insertSublayer(gradientLayer, at: 0)
        
        return button
    }()
    
    private let orLabel: UILabel = {
        let label = UILabel()
        label.text = "或者"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let browseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("浏览推荐订阅源", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        return button
    }()
    
    private let loadingView = LoadingBirdView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        checkClipboard()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradientLayer = addButton.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = addButton.bounds
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "添加订阅源"
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "取消",
            style: .plain,
            target: self,
            action: #selector(dismissVC)
        )
        
        view.addSubview(headerImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(inputContainerView)
        inputContainerView.addSubview(urlTextField)
        inputContainerView.addSubview(pasteButton)
        view.addSubview(addButton)
        view.addSubview(orLabel)
        view.addSubview(browseButton)
        view.addSubview(loadingView)
        
        headerImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(32)
            make.centerX.equalToSuperview()
            make.size.equalTo(60)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(headerImageView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(32)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(32)
        }
        
        inputContainerView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(56)
        }
        
        urlTextField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(pasteButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        
        pasteButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(28)
        }
        
        addButton.snp.makeConstraints { make in
            make.top.equalTo(inputContainerView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        orLabel.snp.makeConstraints { make in
            make.top.equalTo(addButton.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }
        
        browseButton.snp.makeConstraints { make in
            make.top.equalTo(orLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(150)
        }
    }
    
    private func setupActions() {
        urlTextField.delegate = self
        urlTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        pasteButton.addTarget(self, action: #selector(pasteButtonTapped), for: .touchUpInside)
        browseButton.addTarget(self, action: #selector(browseButtonTapped), for: .touchUpInside)
    }
    
    private func checkClipboard() {
        if let clipboardString = UIPasteboard.general.string,
           URL(string: clipboardString) != nil {
            pasteButton.isEnabled = true
            pasteButton.tintColor = .systemBlue
        } else {
            pasteButton.isEnabled = false
            pasteButton.tintColor = .tertiaryLabel
        }
    }
    
    // MARK: - Actions
    @objc private func dismissVC() {
        dismiss(animated: true)
    }
    
    @objc private func pasteButtonTapped() {
        if let clipboardString = UIPasteboard.general.string {
            urlTextField.text = clipboardString
            textFieldDidChange()
        }
    }
    
    @objc private func browseButtonTapped() {
        let vc = RSSBrowseViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func addButtonTapped() {
        guard let urlString = urlTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !urlString.isEmpty else { return }
        
        // 规范化 URL
        var normalizedURL = urlString
        if !normalizedURL.hasPrefix("http://") && !normalizedURL.hasPrefix("https://") {
            normalizedURL = "https://" + normalizedURL
        }
        
        guard URL(string: normalizedURL) != nil else {
            showError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的 URL"]))
            return
        }
        
        addFeed()
    }
    
    private func addFeed() {
        guard !isLoading else { return }
        isLoading = true
        
        // 禁用界面
        urlTextField.isEnabled = false
        addButton.isEnabled = false
        pasteButton.isEnabled = false
        browseButton.isEnabled = false
        
        // 显示加载动画
        loadingView.startLoading()
        
        Task {
            do {
                // Add Feed
                let feed = try await rssService.fetchFeedInfo(url: urlTextField.text ?? "")
                try await RealmManager.shared.addNewFeed(feed)
                
                // Add Contents
                try await rssService.updateFeed(feed)
                
                await MainActor.run {
                    loadingView.stopLoading { [weak self] in
                        // 显示成功动画
                        self?.showSuccessAnimation {
                            self?.dismiss(animated: true)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    loadingView.stopLoading { [weak self] in
                        self?.showError(error)
                        // 恢复界面
                        self?.urlTextField.isEnabled = true
                        self?.addButton.isEnabled = true
                        self?.pasteButton.isEnabled = true
                        self?.browseButton.isEnabled = true
                        self?.isLoading = false
                    }
                }
            }
        }
    }
    
    private func showSuccessAnimation(completion: @escaping () -> Void) {
        // 创建成功动画视图
        let successView = UIView(frame: view.bounds)
        successView.backgroundColor = .systemBackground
        successView.alpha = 0
        
        let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmarkImageView.tintColor = .systemGreen
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        successView.addSubview(checkmarkImageView)
        checkmarkImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(100)
        }
        
        view.addSubview(successView)
        
        // 执行动画
        UIView.animate(withDuration: 0.3, animations: {
            successView.alpha = 1
            checkmarkImageView.transform = .identity
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0.5, options: [], animations: {
                successView.alpha = 0
            }) { _ in
                successView.removeFromSuperview()
                completion()
            }
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "添加失败",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension AddFeedViewController: UITextFieldDelegate {
    @objc private func textFieldDidChange() {
        addButton.isEnabled = !(urlTextField.text?.isEmpty ?? true)
        
        // 更新按钮状态
        UIView.animate(withDuration: 0.2) {
            self.addButton.alpha = self.addButton.isEnabled ? 1.0 : 0.6
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if addButton.isEnabled {
            addButtonTapped()
        }
        return true
    }
} 
