import UIKit

class BaseViewController: UIViewController {
    
    // MARK: - Properties
    let contentView = UIView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseUI()
        setupNavigationBar()
        setupGestures()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentInsets()
    }
    
    // MARK: - UI Setup
    private func setupBaseUI() {
        view.backgroundColor = .systemBackground.withAlphaComponent(0.8)
        
        // 设置模糊背景
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    private func setupGestures() {
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        edgePan.edges = .left
        view.addGestureRecognizer(edgePan)
    }
    
    @objc private func handleEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let progress = translation.x / view.bounds.width
        
        switch gesture.state {
        case .began:
            navigationController?.popViewController(animated: true)
        case .changed:
            if let transition = navigationController?.view.layer.presentation() {
                transition.transform = CATransform3DMakeTranslation(translation.x, 0, 0)
            }
        case .ended, .cancelled:
            if progress > 0.3 {
                navigationController?.popViewController(animated: true)
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.navigationController?.view.layer.transform = CATransform3DIdentity
                }
            }
        default:
            break
        }
    }
    
    private func updateContentInsets() {
        // 获取 TabBar 的高度
        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 0
        
        // 为不同类型的滚动视图设置底部内边距
        view.subviews.forEach { subview in
            if let scrollView = subview as? UIScrollView {
                var insets = scrollView.contentInset
                insets.bottom = tabBarHeight
                scrollView.contentInset = insets
                
                // 同时更新滚动指示器的内边距
                scrollView.scrollIndicatorInsets = insets
            } else if let collectionView = subview as? UICollectionView {
                var insets = collectionView.contentInset
                insets.bottom = tabBarHeight
                collectionView.contentInset = insets
                
                collectionView.scrollIndicatorInsets = insets
            } else if let tableView = subview as? UITableView {
                var insets = tableView.contentInset
                insets.bottom = tabBarHeight
                tableView.contentInset = insets
                
                tableView.scrollIndicatorInsets = insets
            }
        }
    }
    
    // 递归查找所有滚动视图
    private func findScrollViews(in view: UIView) -> [UIScrollView] {
        var scrollViews: [UIScrollView] = []
        
        for subview in view.subviews {
            if let scrollView = subview as? UIScrollView {
                scrollViews.append(scrollView)
            }
            scrollViews.append(contentsOf: findScrollViews(in: subview))
        }
        
        return scrollViews
    }
    
    // 提供一个方法让子类可以手动更新内边距
    func updateScrollViewInsets() {
        updateContentInsets()
    }
} 
