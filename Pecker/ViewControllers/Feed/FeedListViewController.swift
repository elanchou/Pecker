import UIKit
import RealmSwift
import SnapKit

class FeedListViewController: BaseViewController {
    // MARK: - Properties
    private var notificationToken: NotificationToken?
    private var feeds: Results<Feed>?
    private let rssService = RSSService()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.register(FeedCell.self, forCellReuseIdentifier: "FeedCell")
        table.delegate = self
        table.dataSource = self
        table.refreshControl = UIRefreshControl()
        table.refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return table
    }()
    
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        
        let imageView = UIImageView(image: UIImage(systemName: "newspaper"))
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let label = UILabel()
        label.text = "还没有订阅源\n点击右上角添加"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
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
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
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
        Task {
            do {
                guard let feeds = feeds else { return }
                for feed in feeds {
                    try await rssService.updateFeed(feed)
                }
                await MainActor.run {
                    refreshControl.endRefreshing()
                }
            } catch {
                await MainActor.run {
                    refreshControl.endRefreshing()
                    showError(error)
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
                try await RealmManager.shared.markAllArticlesAsRead(in: feed)
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