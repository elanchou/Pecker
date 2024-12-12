import UIKit
import SnapKit
import Lottie

class AIConversationViewController: UIViewController {
    // MARK: - Properties
    private var messages: [AIMessage] = []
    private let aiService = AIService()
    private var isProcessing = false
    
    // MARK: - UI Elements
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.keyboardDismissMode = .interactive
        cv.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        cv.register(AIMessageCell.self, forCellWithReuseIdentifier: "MessageCell")
        return cv
    }()
    
    private let inputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 10
        return view
    }()
    
    private let inputTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.textColor = .label
        tv.backgroundColor = .secondarySystemBackground
        tv.layer.cornerRadius = 20
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 40)
        tv.isScrollEnabled = false
        tv.returnKeyType = .send
        return tv
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        button.tintColor = .systemPurple
        button.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        return button
    }()
    
    private let loadingView: LottieAnimationView = {
        let animation = LottieAnimationView(name: "ai_loading")
        animation.loopMode = .loop
        animation.contentMode = .scaleAspectFit
        animation.isHidden = true
        return animation
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
        
        // 添加点击手势来关闭键盘
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        collectionView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "AI 助手"
        
        // 设置导航栏
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.down"),
            style: .plain,
            target: self,
            action: #selector(dismissVC)
        )
        
        // 添加子视图
        view.addSubview(collectionView)
        view.addSubview(inputContainerView)
        inputContainerView.addSubview(inputTextView)
        inputContainerView.addSubview(sendButton)
        view.addSubview(loadingView)
        
        // 设置约束
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputContainerView.snp.top)
        }
        
        inputContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.greaterThanOrEqualTo(60)
        }
        
        inputTextView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.height.lessThanOrEqualTo(100)
        }
        
        sendButton.snp.makeConstraints { make in
            make.trailing.equalTo(inputTextView).offset(-8)
            make.centerY.equalTo(inputTextView)
            make.width.height.equalTo(30)
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(120)
        }
        
        // 添加事件处理
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        inputTextView.delegate = self
    }
    
    // MARK: - Layout
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 0
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        return layout
    }
    
    // MARK: - Actions
    @objc private func dismissVC() {
        dismiss(animated: true)
    }
    
    @objc private func sendMessage() {
        guard let text = inputTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }
        
        // 清空输入框
        inputTextView.text = ""
        updateInputTextViewHeight()
        
        // 发送触感反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 添加用户消息
        let userMessage = AIMessage(text: text, isFromUser: true)
        addMessage(userMessage)
        
        // 添加 AI 思考中的加载消息
        let loadingMessage = AIMessage(text: "思考中...", isFromUser: false)
        let loadingIndex = messages.count
        addMessage(loadingMessage)
        
        // 发送到 AI 服务
        Task {
            do {
                let response = try await aiService.chat(text)
                
                await MainActor.run {
                    // 移除加载消息
                    messages.remove(at: loadingIndex)
                    collectionView.deleteItems(at: [IndexPath(item: loadingIndex, section: 0)])
                    
                    // 添加 AI 回答
                    let aiMessage = AIMessage(text: response, isFromUser: false)
                    addMessage(aiMessage)
                    
                    // 回答完成的触感反馈
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    // 移除加载消息
                    messages.remove(at: loadingIndex)
                    collectionView.deleteItems(at: [IndexPath(item: loadingIndex, section: 0)])
                    
                    showError(error)
                    
                    // 错误触感反馈
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
    
    func sendSummary(_ messages: [OpenAIService.ChatMessage]) async {
        do {
            isProcessing = true
            showLoading(true)
            
            let response = try await aiService.chat(messages)
            
            await MainActor.run {
                isProcessing = false
                showLoading(false)
                
                // 添加回答消息
                let message = AIMessage(text: response, isFromUser: false)
                self.addMessage(message)
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                showLoading(false)
                showError(error)
            }
        }
    }
    
    func sendMessage(_ text: String) async {
        do {
            isProcessing = true
            showLoading(true)
            
            let response = try await aiService.chat(text)
            
            await MainActor.run {
                isProcessing = false
                showLoading(false)
                
                // 添加回答消息
                let message = AIMessage(text: response, isFromUser: false)
                self.addMessage(message)
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                showLoading(false)
                showError(error)
            }
        }
    }
    
    private func showLoading(_ show: Bool) {
        loadingView.isHidden = !show
        if show {
            loadingView.play()
        } else {
            loadingView.stop()
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "错误",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                             name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                             name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        inputContainerView.snp.updateConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-keyboardFrame.height)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        inputContainerView.snp.updateConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func addMessage(_ message: AIMessage, animate: Bool = false) {
        messages.append(message)
        
        collectionView.performBatchUpdates {
            collectionView.insertItems(at: [IndexPath(item: messages.count - 1, section: 0)])
        } completion: { [weak self] _ in
            guard let self = self else { return }
            
            // 滚动到底部
            self.scrollToBottom(animated: true)
            
            // 如果是用户消息，触发触感反馈
            if message.isFromUser {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
    }
    
    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }
}

// MARK: - UICollectionViewDataSource
extension AIConversationViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageCell", for: indexPath) as! AIMessageCell
        let message = messages[indexPath.item]
        
        // 如果是加载消息，显示加载动画
        if !message.isFromUser && message.text == "思考中..." {
            cell.showLoading()
        } else {
            cell.configure(with: message)
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension AIConversationViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let message = messages[indexPath.item]
        return AIMessageCell.size(for: message, maxWidth: collectionView.bounds.width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
    }
}

// MARK: - UITextViewDelegate
extension AIConversationViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateInputTextViewHeight()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            sendMessage()
            return false
        }
        return true
    }
    
    private func updateInputTextViewHeight() {
        let size = inputTextView.sizeThatFits(CGSize(width: inputTextView.bounds.width, height: .infinity))
        let height = min(max(size.height, 40), 100)
        
        inputTextView.snp.updateConstraints { make in
            make.height.lessThanOrEqualTo(height)
        }
        
        UIView.animate(withDuration: 0.1) {
            self.view.layoutIfNeeded()
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        scrollToBottom(animated: true)
    }
}
