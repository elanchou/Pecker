import UIKit

protocol CustomTabBarDelegate: AnyObject {
    func customTabBar(_ tabBar: CustomTabBar, didSelect item: UITabBarItem)
}

class CustomTabBar: UIView {
    weak var customDelegate: CustomTabBarDelegate?
    private var items: [UITabBarItem] = []
    private var tabBarItems: [CustomTabBarItem] = []
    private var selectedIndex: Int = 0
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        return stack
    }()
    
    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
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
        backgroundColor = .systemBackground
        
        [separatorLine, stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            separatorLine.topAnchor.constraint(equalTo: topAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),
            
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func setItems(_ items: [UITabBarItem]?, animated: Bool) {
        self.items = items ?? []
        setupTabBarItems()
    }
    
    private func setupTabBarItems() {
        // 清除现有的 items
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        tabBarItems.removeAll()
        
        // 创建新的 items
        for (index, item) in items.enumerated() {
            let tabBarItem = CustomTabBarItem(
                normalImage: item.image,
                selectedImage: item.selectedImage
            )
            tabBarItem.tag = index
            tabBarItem.isSelected = index == selectedIndex
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tabBarItemTapped(_:)))
            tabBarItem.addGestureRecognizer(tapGesture)
            
            stackView.addArrangedSubview(tabBarItem)
            tabBarItems.append(tabBarItem)
        }
    }
    
    @objc private func tabBarItemTapped(_ gesture: UITapGestureRecognizer) {
        guard let tabBarItem = gesture.view as? CustomTabBarItem else { return }
        let index = tabBarItem.tag
        
        // 触感反馈
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // 更新选中状态
        tabBarItems[selectedIndex].isSelected = false
        tabBarItems[index].isSelected = true
        selectedIndex = index
        
        // 通知代理
        if let item = items[safe: index] {
            customDelegate?.customTabBar(self, didSelect: item)
        }
    }
    
    var selectedItem: UITabBarItem? {
        get { items[safe: selectedIndex] }
        set {
            guard let newValue = newValue,
                  let index = items.firstIndex(of: newValue) else { return }
            
            tabBarItems[selectedIndex].isSelected = false
            tabBarItems[index].isSelected = true
            selectedIndex = index
        }
    }
    
    func getItems() -> [UITabBarItem] {
        return items
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
