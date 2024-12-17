import UIKit
import RealmSwift
import SnapKit

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
        
        // 添加表格动画
        tableView.alpha = 0
        tableView.transform = CGAffineTransform(translationX: 0, y: 20)
        
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.tableView.alpha = 1
            self.tableView.transform = .identity
        }
        
        setupUI()
        observeFeeds()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "订阅源"
        
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
    
    // MARK: - Actions
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
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
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
                // 成功的反馈
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } catch {
                showError(error)
            }
        }
    }
    
    private func deleteFeed(_ feed: Feed) {
        Task {
            do {
                try await RealmManager.shared.deleteFeed(feed)
                // 成功的反馈
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } catch {
                showError(error)
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
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            if let feed = self?.feeds?[indexPath.row] {
                feed.markAsDeleted()
                completion(true)
            } else {
                completion(false)
            }
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        let refreshAction = UIContextualAction(style: .normal, title: "刷新") { [weak self] _, _, completion in
            guard let feed = self?.feeds?[indexPath.row] else {
                completion(false)
                return
            }
            
            Task {
                do {
                    try await self?.rssService.updateFeed(feed)
                    completion(true)
                } catch {
                    await MainActor.run {
                        self?.showError(error)
                    }
                    completion(false)
                }
            }
        }
        refreshAction.backgroundColor = .systemBlue
        refreshAction.image = UIImage(systemName: "arrow.clockwise")
        
        return UISwipeActionsConfiguration(actions: [deleteAction, refreshAction])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
} 
