import UIKit
import RealmSwift
import SnapKit
import Lottie

class TodaySummaryViewController: UIViewController {
    private let todayLabel: UILabel = {
        let label = UILabel()
        label.text = "Today"
        label.font = .systemFont(ofSize: 65, weight: .bold)
        label.textColor = .label
        label.alpha = 0
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .secondaryLabel
        label.alpha = 0
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        label.text = formatter.string(from: Date())
        return label
    }()
    
    private let summaryTextView: AITextView = {
        let textView = AITextView()
        textView.alpha = 0
        return textView
    }()
    
    private let loadingView: LoadingBirdView = {
        let view = LoadingBirdView()
        return view
    }()
    
    private lazy var dismissPanGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        return gesture
    }()
    
    private var initialTouchPoint: CGPoint = .zero
    private var initialTransform: CGAffineTransform?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
        startAnimation()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(todayLabel)
        view.addSubview(dateLabel)
        view.addSubview(summaryTextView)
        view.addSubview(loadingView)
        
        todayLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        dateLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(todayLabel.snp.bottom).offset(8)
        }
        
        summaryTextView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(180)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(200)
        }
    }
    
    private func setupGestures() {
        // 添加下滑手势
        view.addGestureRecognizer(dismissPanGesture)
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            initialTransform = view.transform
            
        case .changed:
            if translation.y < 0 {
                let progress = min(abs(translation.y) / view.bounds.height, 1.0)
                view.transform = CGAffineTransform(translationX: 0, y: translation.y)
                view.alpha = 1 - progress * 0.3
            }
            
        case .ended, .cancelled:
            let shouldDismiss = velocity.y < -500 || translation.y < -200
            
            if shouldDismiss {
                performDismissAnimation()
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
                    self.view.transform = self.initialTransform ?? .identity
                    self.view.alpha = 1
                }
            }
            
        default:
            break
        }
    }
    
    private func performDismissAnimation() {
        // 创建一个缩小并向上移动的动画
        let scaleTransform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        let moveTransform = CGAffineTransform(translationX: 0, y: -view.bounds.height)
        let combinedTransform = scaleTransform.concatenating(moveTransform)
        
        UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [.curveEaseOut]) {
            self.view.transform = combinedTransform
            self.view.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }
    
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !summaryTextView.frame.contains(location) {
            performDismissAnimation()
        }
    }
    
    private func startAnimation() {
        UIView.animate(withDuration: 0.8, delay: 0.5, options: .curveEaseOut) {
            self.todayLabel.alpha = 1
            self.dateLabel.alpha = 1
        } completion: { _ in
            
            self.todayLabel.snp.remakeConstraints { make in
                make.top.equalTo(self.view.safeAreaLayoutGuide).offset(60)
                make.leading.equalToSuperview().offset(20)
                make.width.equalTo(self.view.bounds.width * 0.6)
            }
            
            self.dateLabel.snp.remakeConstraints { make in
                make.top.equalTo(self.todayLabel.snp.bottom).offset(8)
                make.leading.equalTo(self.todayLabel)
            }
            
            UIView.animate(withDuration: 0.6, delay: 1.0, options: .curveEaseInOut) {
                self.view.layoutIfNeeded()
            } completion: { _ in
                self.generateSummary()
            }
        }
    }
    
    private func generateSummary() {
        loadingView.startLoading()
        
        Task {
            do {
                if TodaySummaryManager.shared.shouldUpdateSummary() {
                    let realm = try await Realm()
                    let contents = realm.objects(Content.self)
                        .filter("isDeleted == false")
                        .sorted(byKeyPath: "publishDate", ascending: false)
                    
                    let summary = try await generateDailySummary(for: Array(contents))
                    TodaySummaryManager.shared.saveSummary(summary)
                    
                    await MainActor.run {
                        showSummary(summary)
                    }
                } else if let savedSummary = TodaySummaryManager.shared.getSavedSummary() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        Task {
                            self.showSummary(savedSummary)
                        }
                    }
                }
            } catch {
                print("Error generating summary: \(error)")
                await MainActor.run {
                    loadingView.stopLoading()
                }
            }
        }
    }
    
    private func showSummary(_ summary: String) {
        loadingView.stopLoading { [weak self] in
            self?.summaryTextView.startTyping(summary)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.summaryTextView.alpha = 1
        }
        
        TodaySummaryManager.shared.updateLastShowTime()
    }
    
    private func generateDailySummary(for contents: [Content]) async throws -> String {
        let aiService = AIService()
        let prompt = aiService.generateSummary(for: .multipleContents(contents))
        let summary = try await aiService.chat(prompt)
        return summary
    }
    
    deinit {
        loadingView.stopLoading()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension TodaySummaryViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 如果点击在 summaryTextView 上，不响应点击手势
        let location = touch.location(in: view)
        return !summaryTextView.frame.contains(location)
    }
} 
