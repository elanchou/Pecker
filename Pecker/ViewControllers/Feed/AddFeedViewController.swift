import UIKit
import RealmSwift
import SnapKit

class AddFeedViewController: BaseViewController {
    // MARK: - Properties
    private let rssService = RSSService()
    
    private let urlTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "输入 RSS 订阅源地址"
        textField.font = .systemFont(ofSize: 17)
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .URL
        textField.returnKeyType = .done
        return textField
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("添加", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.isEnabled = false
        return button
    }()
    
    private let loadingView = LoadingBirdView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "添加订阅源"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "取消",
            style: .plain,
            target: self,
            action: #selector(dismissVC)
        )
        
        view.addSubview(urlTextField)
        view.addSubview(addButton)
        view.addSubview(loadingView)
        
        urlTextField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        addButton.snp.makeConstraints { make in
            make.top.equalTo(urlTextField.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(150)
        }
        
        urlTextField.delegate = self
        urlTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }
    
    @objc private func dismissVC() {
        dismiss(animated: true)
    }
    
    // MARK: - Actions
    @objc private func addButtonTapped() {
        guard let urlString = urlTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !urlString.isEmpty else { return }
        
        // 规范化 URL
        var normalizedURL = urlString
        if !normalizedURL.hasPrefix("http://") && !normalizedURL.hasPrefix("https://") {
            normalizedURL = "https://" + normalizedURL
        }
        
        guard let url = URL(string: normalizedURL) else {
            showError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的 URL"]))
            return
        }
        
        addFeed()
    }
    
    private func addFeed() {
        loadingView.startLoading()
        
        Task {
            do {
                // Add Feed
                let feed = try await rssService.fetchFeedInfo(url: urlTextField.text ?? "")
                try await RealmManager.shared.addNewFeed(feed)
                
                // Add Articles
                try await rssService.updateFeed(feed)
                
                await MainActor.run {
                    loadingView.stopLoading { [weak self] in
                        self?.dismiss(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    loadingView.stopLoading { [weak self] in
                        self?.showError(error)
                    }
                }
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
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if addButton.isEnabled {
            addButtonTapped()
        }
        return true
    }
} 
