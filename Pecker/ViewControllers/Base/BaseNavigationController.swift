import UIKit

class BaseNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
    }
    
    private func setupAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // 创建纯色背景图片
        let backgroundImage = { () -> UIImage in
            let lightColor = UIColor.white
            let darkColor = UIColor.black
            
            let size = CGSize(width: 1, height: 1)
            let renderer = UIGraphicsImageRenderer(size: size)
            
            return renderer.image { context in
                if #available(iOS 13.0, *) {
                    UITraitCollection.current.performAsDark {
                        darkColor.setFill()
                        context.fill(CGRect(origin: .zero, size: size))
                    }
                    UITraitCollection.current.performAsLight {
                        lightColor.setFill()
                        context.fill(CGRect(origin: .zero, size: size))
                    }
                } else {
                    lightColor.setFill()
                    context.fill(CGRect(origin: .zero, size: size))
                }
            }
        }()
        
        // 设置背景图片
        appearance.backgroundImage = backgroundImage
        appearance.shadowImage = nil
        appearance.shadowColor = .clear
        
        // 设置文字属性
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        
        // 应用外观
        navigationBar.standardAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        
        // 设置按钮颜色
        navigationBar.tintColor = .systemRed
        
        // 禁用大标题
        navigationBar.prefersLargeTitles = false
    }
}

// MARK: - UITraitCollection Extension
private extension UITraitCollection {
    func performAsDark(_ closure: () -> Void) {
        _ = self.userInterfaceStyle
        self.performAsCurrent {
            if #available(iOS 13.0, *) {
                let darkTraitCollection = UITraitCollection(userInterfaceStyle: .dark)
                darkTraitCollection.performAsCurrent(closure)
            }
        }
    }
    
    func performAsLight(_ closure: () -> Void) {
        _ = self.userInterfaceStyle
        self.performAsCurrent {
            if #available(iOS 13.0, *) {
                let lightTraitCollection = UITraitCollection(userInterfaceStyle: .light)
                lightTraitCollection.performAsCurrent(closure)
            }
        }
    }
} 
