import UIKit
import Lottie

class LoadingBirdView: UIView {
    private let animationView: LottieAnimationView = {
        let animation = LottieAnimationView(name: "bird")
        animation.loopMode = .loop
        animation.contentMode = .scaleAspectFit
        animation.isHidden = true
        animation.alpha = 0
        return animation
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(animationView)
        animationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func startLoading() {
        animationView.isHidden = false
        animationView.play()
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.animationView.alpha = 1
        }
    }
    
    func stopLoading(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.animationView.alpha = 0
        } completion: { _ in
            self.animationView.stop()
            self.animationView.isHidden = true
            completion?()
        }
    }
    
    deinit {
        animationView.stop()
    }
} 