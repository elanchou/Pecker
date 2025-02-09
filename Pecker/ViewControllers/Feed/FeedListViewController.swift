import UIKit
import RealmSwift

class FeedListViewController: BaseViewController {
    // MARK: - Properties
    private var notificationToken: NotificationToken?
    private var feeds: Results<Feed>?
    private let rssService = RSSService()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let loadingView = LoadingBirdView()
    private let refreshLoadingView = LoadingBirdView()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        refresh.tintColor = .clear
        refresh.backgroundColor = .clear
        return refresh
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.register(FeedCell.self, forCellReuseIdentifier: "FeedCell")
        table.delegate = self
        table.dataSource = self
        table.refreshControl = refreshControl
        table.separatorStyle = .none
        return table
    }()
    
    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    
    private let emptyImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "square.stack.3d.up.fill")
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emptyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "没有订阅源"
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let emptyDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "添加你喜欢的网站和博客，获取最新内容"
        label.font = .systemFont(ofSize: 15)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let addFeedButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("添加订阅源", for: .normal)
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 20
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        observeFeeds()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = L("Feeds")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addFeed)
        )
        
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(loadingView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(150)
        }
        
        refreshLoadingView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        refreshControl.addSubview(refreshLoadingView)
        
        refreshLoadingView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(10)
            make.size.equalTo(60)
        }
        
        setupEmptyState()
    }
    
    // MARK: - Data Loading
    private func observeFeeds() {
        do {
            let realm = try Realm()
            feeds = realm.objects(Feed.self).filter("isDeleted == false").sorted(byKeyPath: "title")
            
            notificationToken = feeds?.observe { [weak self] changes in
                guard let self = self else { return }
                switch changes {
                case .initial:
                    self.tableView.reloadData()
                case .update(_, let deletions, let insertions, let modifications):
                    self.tableView.performBatchUpdates {
                        self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                        self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                        self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    }
                case .error(let error):
                    print("Error observing feeds: \(error)")
                }
            }
        } catch {
            print("Error setting up feed observation: \(error)")
        }
    }
    
    @objc private func addFeed() {
        let vc = AddFeedViewController()
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    @objc private func refreshData() {
        refreshLoadingView.startLoading()
        
        Task {
            do {
                let realm = try await Realm()
                // 将 Results 转换为数组，并确保每个 feed 都是有效的
                guard let feeds = feeds else { return }
                let feedArray = Array(feeds)
                
                for feed in feedArray {
                    // 在每次循环中重新获取最新的 feed 对象
                    if let currentFeed = realm.object(ofType: Feed.self, forPrimaryKey: feed.id) {
                        try await rssService.updateFeed(currentFeed)
                    }
                }
                
                await MainActor.run {
                    refreshLoadingView.stopLoading { [weak self] in
                        self?.refreshControl.endRefreshing()
                    }
                }
            } catch {
                await MainActor.run {
                    refreshLoadingView.stopLoading { [weak self] in
                        self?.refreshControl.endRefreshing()
                        self?.showError(error)
                    }
                }
            }
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
    
    // 添加长按手势支持
    private func setupGestures() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPress)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: point),
               let feed = feeds?[indexPath.row] {
                showFeedActions(for: feed, at: point)
            }
        }
    }
    
    private func showFeedActions(for feed: Feed, at point: CGPoint) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // 标记所有已读
        alert.addAction(UIAlertAction(title: "标记所有已读", style: .default) { [weak self] _ in
            self?.markAllAsRead(feed: feed)
        })
        
        // 复制订阅链接
        alert.addAction(UIAlertAction(title: "复制订阅链接", style: .default) { _ in
            UIPasteboard.general.string = feed.url
            // 复制成功的反馈
            ToastView.success("已复制订阅链接")
        })
        
        // 删除订阅
        alert.addAction(UIAlertAction(title: "删除订阅", style: .destructive) { [weak self] _ in
            self?.deleteFeed(feed)
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = CGRect(origin: point, size: .zero)
        }
        
        present(alert, animated: true)
    }
    
    private func markAllAsRead(feed: Feed) {
        Task {
            do {
                try await RealmManager.shared.markAllContentsAsRead(in: feed)
                ToastView.success("已将所有文章标记为已读")
            } catch {
                ToastView.failure(error.localizedDescription)
            }
        }
    }
    
    private func deleteFeed(_ feed: Feed) {
        Task {
            do {
                try await RealmManager.shared.deleteFeed(feed)
                ToastView.success("已删除订阅源")
            } catch {
                ToastView.failure(error.localizedDescription)
            }
        }
    }
    
    deinit {
        notificationToken?.invalidate()
    }
    
    // 处理滚动时的动画
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        
        if offsetY < 0 {
            // 计算下拉进度
            let progress = min(abs(offsetY) / 100, 1.0)
            
            // 如果还没有开始刷新，根据下拉进度调整动画
            if !refreshControl.isRefreshing {
                refreshLoadingView.alpha = progress
            }
        }
    }
    
    private func setupEmptyState() {
        view.addSubview(emptyStateView)
        emptyStateView.addSubview(emptyImageView)
        emptyStateView.addSubview(emptyTitleLabel)
        emptyStateView.addSubview(emptyDescriptionLabel)
        emptyStateView.addSubview(addFeedButton)
        
        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
        }
        
        emptyImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(100)
        }
        
        emptyTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyImageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
        
        emptyDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
        }
        
        addFeedButton.snp.makeConstraints { make in
            make.top.equalTo(emptyDescriptionLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.equalTo(140)
            make.height.equalTo(40)
            make.bottom.equalToSuperview()
        }
        
        addFeedButton.addTarget(self, action: #selector(addFeedTapped), for: .touchUpInside)
    }
    
    @objc private func addFeedTapped() {
        let addFeedVC = AddFeedViewController()
        let nav = UINavigationController(rootViewController: addFeedVC)
        present(nav, animated: true)
    }
    
    private func updateEmptyState() {
        let isEmpty = feeds?.isEmpty ?? true
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
}

// MARK: - UITableViewDataSource
extension FeedListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feeds?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath) as! FeedCell
        if let feed = feeds?[indexPath.row] {
            cell.configure(with: feed)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FeedListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return getSwipeActions(for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
}

// MARK: - Swipe Actions Configuration
extension FeedListViewController {
    func onSwipeAction(_ action: FeedAction, feed: Feed) {
        switch action {
        case .delete:
            // 显示删除确认对话框
            let alert = UIAlertController(
                title: "确认删除",
                message: "确定要删除这个订阅源吗？这将同时删除所有相关的文章。",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "删除", style: .destructive) { _ in
                Task {
                    do {
                        try await RealmManager.shared.deleteFeed(feed)
                        ToastView.success("已删除订阅源")
                    } catch {
                        ToastView.failure(error.localizedDescription)
                    }
                }
            })
            
            present(alert, animated: true)
            
        case .share:
            let activityVC = UIActivityViewController(
                activityItems: [feed.url],
                applicationActivities: nil
            )
            
            // 在 iPad 上需要设置弹出位置
            if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = view
                popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            present(activityVC, animated: true)
            
        case .markAllRead:
            Task {
                do {
                    try await RealmManager.shared.markAllContentsAsRead(in: feed)
                    ToastView.success("已将所有文章标记为已读")
                } catch {
                    ToastView.failure(error.localizedDescription)
                }
            }
        }
    }
    
    func getSwipeActions(for indexPath: IndexPath) -> UISwipeActionsConfiguration {
        // 标记已读操作
        let markReadAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            guard let feed = self?.feeds?[indexPath.row] else {
                completion(false)
                return
            }
            self?.onSwipeAction(.markAllRead, feed: feed)
            completion(true)
        }
        customizeAction(markReadAction,
                       icon: "checkmark",
                       backgroundColor: .systemGreen,
                       text: "已读")
        
        // 分享操作
        let shareAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            guard let feed = self?.feeds?[indexPath.row] else {
                completion(false)
                return
            }
            self?.onSwipeAction(.share, feed: feed)
            completion(true)
        }
        customizeAction(shareAction,
                       icon: "square.and.arrow.up",
                       backgroundColor: .systemBlue,
                       text: "分享")
        
        // 删除操作
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            guard let feed = self?.feeds?[indexPath.row] else {
                completion(false)
                return
            }
            self?.onSwipeAction(.delete, feed: feed)
            completion(true)
        }
        customizeAction(deleteAction,
                       icon: "trash",
                       backgroundColor: .systemRed,
                       text: "删除")
        
        // 配置滑动操作
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, shareAction, markReadAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    private func customizeAction(_ action: UIContextualAction, icon: String, backgroundColor: UIColor, text: String) {
        // 创建容器视图
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 72, height: 72))
        container.backgroundColor = .clear
        
        // 创建圆形按钮背景
        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        circleView.center = container.center
        circleView.backgroundColor = backgroundColor.withAlphaComponent(0.1)
        circleView.layer.cornerRadius = 18
        container.addSubview(circleView)
        
        // 创建图标
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        let imageView = UIImageView(image: UIImage(systemName: icon, withConfiguration: symbolConfig))
        imageView.tintColor = backgroundColor
        imageView.contentMode = .scaleAspectFit
        circleView.addSubview(imageView)
        
        // 设置图标约束
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 16),
            imageView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        // 将自定义视图转换为图片
        let renderer = UIGraphicsImageRenderer(size: container.bounds.size)
        let image = renderer.image { _ in
            container.drawHierarchy(in: container.bounds, afterScreenUpdates: true)
        }
        
        // 设置操作的背景色和图标
        action.backgroundColor = .systemBackground
        action.image = image
    }
    
    // MARK: - Feed Actions
    enum FeedAction {
        case markAllRead
        case share
        case delete
    }
}
