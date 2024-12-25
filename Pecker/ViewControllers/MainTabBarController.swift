import UIKit

class MainTabBarController: UITabBarController {
    
    // 定义页面枚举，增强类型安全
    enum TabIndex: Int, CaseIterable {
        case home
        case feedList
//        case podcast
        case rss
        case settings
    }
    
    private let customTabBar = CustomTabBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupCustomTabBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        customTabBar.frame = tabBar.frame
    }
    
    private func setupViewControllers() {
        let viewControllers = TabIndex.allCases.map { index -> UIViewController in
            let viewController: UIViewController
            switch index {
            case .home:
                let homeVC = HomeViewController()
                homeVC.tabBarItem = UITabBarItem(
                    title: nil,
                    image: UIImage(systemName: "house")?
                        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
                        .withRenderingMode(.alwaysTemplate),
                    selectedImage: UIImage(systemName: "house.fill")?
                        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
                        .withRenderingMode(.alwaysTemplate)
                )
                viewController = BaseNavigationController(rootViewController: homeVC)
                
            case .feedList:
                let feedVC = FeedListViewController()
                feedVC.tabBarItem = UITabBarItem(
                    title: nil,
                    image: UIImage(systemName: "list.bullet")?
                        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
                        .withRenderingMode(.alwaysTemplate),
                    selectedImage: UIImage(systemName: "list.bullet.rectangle.fill")?
                        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
                        .withRenderingMode(.alwaysTemplate)
                )
                viewController = BaseNavigationController(rootViewController: feedVC)
                
//            case .podcast:
//                let podcastVC = PodcastBrowseViewController()
//                podcastVC.tabBarItem = UITabBarItem(
//                    title: nil,
//                    image: UIImage(systemName: "mic")?
//                        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
//                        .withRenderingMode(.alwaysTemplate),
//                    selectedImage: UIImage(systemName: "mic.fill")?
//                        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
//                        .withRenderingMode(.alwaysTemplate)
//                )
//                viewController = BaseNavigationController(rootViewController: podcastVC)
//                
            case .rss:
                let rssVC = RSSBrowseViewController()
                rssVC.tabBarItem = UITabBarItem(
                    title: nil,
                    image: UIImage(systemName: "newspaper")?
                        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
                        .withRenderingMode(.alwaysTemplate),
                    selectedImage: UIImage(systemName: "newspaper.fill")?
                        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
                        .withRenderingMode(.alwaysTemplate)
                )
                viewController = BaseNavigationController(rootViewController: rssVC)
                
            case .settings:
                let settingsVC = SettingsViewController()
                settingsVC.tabBarItem = UITabBarItem(
                    title: nil,
                    image: UIImage(systemName: "gear")?
                        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
                        .withRenderingMode(.alwaysTemplate),
                    selectedImage: UIImage(systemName: "gear.circle.fill")?
                        .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
                        .withRenderingMode(.alwaysTemplate)
                )
                viewController = BaseNavigationController(rootViewController: settingsVC)
            }
            return viewController
        }
        
        self.viewControllers = viewControllers
    }
    
    private func setupCustomTabBar() {
        // 隐藏原生 tabBar
        tabBar.isHidden = true
        
        // 设置自定义 tabBar
        customTabBar.customDelegate = self
        customTabBar.setItems(viewControllers?.map { $0.tabBarItem } ?? [], animated: false)
        view.addSubview(customTabBar)
        
        // 设置初始选中项
        customTabBar.selectedItem = viewControllers?.first?.tabBarItem
    }
}

// MARK: - CustomTabBarDelegate
extension MainTabBarController: CustomTabBarDelegate {
    func customTabBar(_ tabBar: CustomTabBar, didSelect item: UITabBarItem) {
        guard let index = tabBar.getItems().firstIndex(of: item),
              index < (viewControllers?.count ?? 0) else {
            return
        }
        
        selectedIndex = index
        
        // 添加动画效果
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: {
            self.selectedViewController?.view.alpha = 1
            self.viewControllers?.forEach { vc in
                if vc != self.selectedViewController {
                    vc.view.alpha = 0
                }
            }
        })
    }
}
