import UIKit
import Kingfisher
import RealmSwift
import JXSegmentedView
import SnapKit
import Lottie

class HomeViewController: BaseViewController, UIPopoverPresentationControllerDelegate {
    // MARK: - Properties
    private var contents: Results<Content>?
    private var notificationToken: NotificationToken?
    private var currentGrouping: ContentGrouping = .byDate {
        didSet {
            if oldValue != currentGrouping {
                updateUI(animated: true)
            }
        }
    }
    private var currentFeed: Feed?
    
    // 缓存相关
    private var sectionCache: [ContentGrouping: [(String, [Content])]] = [:]
    private var heightCache: [IndexPath: CGFloat] = [:]
    private var imageCache = NSCache<NSString, UIImage>()
    private var prefetchDataSource: UICollectionViewDataSourcePrefetching?
    private var isUpdating = false
    
    // 分页相关
    private let pageSize = 20
    private var currentPage = 0
    private var hasMoreData = true
    private var isLoadingMore = false
    
    private let segmentedDataSource = JXSegmentedTitleDataSource()
    private let segmentedView = JXSegmentedView()
    private let indicatorLineView = JXSegmentedIndicatorLineView()
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.delegate = self
        cv.dataSource = self
        cv.register(ArticleCell.self, forCellWithReuseIdentifier: "ArticleCell")
        cv.register(PodcastCell.self, forCellWithReuseIdentifier: "PodcastCell")
        cv.register(SectionHeaderView.self,
                   forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                   withReuseIdentifier: "HeaderView")
        return cv
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        refresh.tintColor = .clear
        refresh.backgroundColor = .clear
        return refresh
    }()
    
    private lazy var searchButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(showSearch)
        )
        button.tintColor = .systemRed
        return button
    }()
    
    private var expandedCells = Set<String>()
    private let aiService = AIService()
    
    private let loadingView = LoadingBirdView()
    private let refreshLoadingView = LoadingBirdView()
    
    private var currentPlayingPodcast: Content?
    private var miniPlayerView: MiniPlayerView?
    
    // 添加空状态视图
    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = .clear
        return view
    }()
    
    private let emptyImageView: LottieAnimationView = {
        let animation = LottieAnimationView(name: "bird")
        animation.loopMode = .loop
        animation.contentMode = .scaleAspectFit
        return animation
    }()
    
    private let emptyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "还没有任何内容"
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let emptyDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "点击下方按钮添加订阅源，开始阅读之旅"
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
        button.backgroundColor = AppTheme.primary
        button.tintColor = .white
        button.layer.cornerRadius = 20
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupFeedSelection()
        setupPrefetching()
        loadData()
        
        // 监听订阅源选择
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFeedSelection(_:)),
            name: NSNotification.Name("SelectedFeedChanged"),
            object: nil
        )
        
        // 监听内存警告
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        notificationToken?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "文章"
        
        // 配置分段控制器景
        let segmentBackground = UIView()
        segmentBackground.backgroundColor = .systemBackground
        
        view.addSubview(segmentBackground)
        view.addSubview(segmentedView)
        view.addSubview(collectionView)
        view.addSubview(loadingView)
        
        segmentBackground.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(segmentedView)
        }
        
        segmentedView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(segmentedView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        // 设置 collectionView 的内容边距
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        collectionView.contentInsetAdjustmentBehavior = .never
        
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
        
        setupSegmentedView()
        setupCollectionView()
        setupMiniPlayer()
        setupEmptyState()
    }
    
    private func setupSegmentedView() {
        segmentedDataSource.titles = ["按时间", "按订阅源", "收藏", "未读"]
        segmentedDataSource.titleNormalColor = .secondaryLabel
        segmentedDataSource.titleSelectedColor = .label
        segmentedDataSource.titleNormalFont = .systemFont(ofSize: 15)
        segmentedDataSource.titleSelectedFont = .systemFont(ofSize: 15, weight: .medium)
        segmentedDataSource.isTitleColorGradientEnabled = true
        
        segmentedView.dataSource = segmentedDataSource
        
        // 配置指示器
        indicatorLineView.indicatorWidth = JXSegmentedViewAutomaticDimension
        indicatorLineView.indicatorHeight = 3
        indicatorLineView.indicatorColor = .systemRed
        indicatorLineView.indicatorCornerRadius = 1.5
        
        segmentedView.indicators = [indicatorLineView]
        segmentedView.delegate = self
    }
    
    private func setupCollectionView() {
        collectionView.refreshControl = refreshControl
    }
    
    private func setupMiniPlayer() {
        miniPlayerView = MiniPlayerView()
        guard let miniPlayerView = miniPlayerView else { return }
        
        view.addSubview(miniPlayerView)
        
        miniPlayerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.snp.bottom)
            make.height.equalTo(60).priority(.required)
        }
        miniPlayerView.isHidden = true
    }
    
    private func setupEmptyState() {
        // 先将 emptyStateView 添加到父视图
        view.addSubview(emptyStateView)
        
        // 设置 emptyStateView 的约束
        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
        }
        
        // 播放动画并添加子视图
        emptyImageView.play()
        emptyStateView.addSubview(emptyImageView)
        emptyStateView.addSubview(emptyTitleLabel)
        emptyStateView.addSubview(emptyDescriptionLabel)
        emptyStateView.addSubview(addFeedButton)
        
        emptyImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(120)
        }
        
        emptyTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyImageView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }
        
        emptyDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
        }
        
        addFeedButton.snp.makeConstraints { make in
            make.top.equalTo(emptyDescriptionLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.equalTo(160)
            make.height.equalTo(44)
            make.bottom.equalToSuperview()
        }
        
        addFeedButton.addTarget(self, action: #selector(addFeedTapped), for: .touchUpInside)
        
        // 默认隐藏空状态视图
        emptyStateView.isHidden = true
    }
    
    private func updateEmptyState() {
        let isEmpty = sections.isEmpty
        
        // 如果状态没有改变，不执行动画
        guard emptyStateView.isHidden == isEmpty else { return }
        
        UIView.animate(withDuration: 0.2) {
            self.emptyStateView.alpha = isEmpty ? 1 : 0
            self.collectionView.alpha = isEmpty ? 0 : 1
        } completion: { _ in
            self.emptyStateView.isHidden = !isEmpty
            self.collectionView.isHidden = isEmpty
            
            if isEmpty {
                self.emptyImageView.play()
            } else {
                self.emptyImageView.stop()
            }
        }
    }
    
    // MARK: - Data Loading
    @MainActor
    private func loadData(forceRefresh: Bool = false) {
        guard !isUpdating else { return }
        isUpdating = true
        
        // 如果有缓存且不是强制刷新，直接使用缓存
        if !forceRefresh, let cachedSections = sectionCache[currentGrouping] {
            sections = cachedSections
            updateUI(animated: false)
            isUpdating = false
            return
        }
        
        contents = RealmManager.shared.getContents(filter: "isDeleted == false")
        
        notificationToken = contents?.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial:
                self.updateUI(animated: false)
            case .update:
                self.updateUI(animated: true)
            case .error(let error):
                print("Error: \(error)")
            }
            self.isUpdating = false
        }
        
        updateUI(animated: false)
    }
    
    private func updateUI(animated: Bool) {
        guard let baseContents = contents else { return }
        
        // 在后台线程处理数据前，先将 Realm 结果转换为普通数组
        let frozenContents = Array(baseContents.freeze())
        
        // 在后台线程处理数据
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            // 根据条件过滤数据
            var filteredContents = frozenContents.filter { !$0.isDeleted }
            
            // 应用分组过滤
            switch await self.currentGrouping {
            case .favorites:
                filteredContents = filteredContents.filter { $0.isFavorite }
            case .unread:
                filteredContents = filteredContents.filter { !$0.isRead }
            default:
                break
            }
            
            // 根据分组方式组织数据
            let newSections: [(String, [Content])]
            switch await self.currentGrouping {
            case .byDate:
                newSections = await self.groupContentsByDate(filteredContents)
            case .byFeed:
                newSections = await self.groupContentsByFeed(filteredContents)
            case .favorites, .unread:
                newSections = [("", filteredContents)]
            }
            
            
            
            // 在主线程更新 UI
            await MainActor.run {
                self.sectionCache[self.currentGrouping] = newSections
                self.sections = newSections
                
                if animated {
                    UIView.transition(with: self.collectionView,
                                    duration: 0.2,
                                    options: .transitionCrossDissolve) {
                        self.collectionView.reloadData()
                    }
                } else {
                    UIView.performWithoutAnimation {
                        self.collectionView.reloadData()
                    }
                }
                
                self.updateEmptyState()
            }
        }
    }
    
    // 添加一个属性来储组后的数据
    private var sections: [(String, [Content])] = []
    
    private func groupContentsByDate(_ contents: [Content]) -> [(String, [Content])] {
        let calendar = Calendar.current
        
        // 先按日期分组内容
        var dateGroups: [Date: [Content]] = [:]
        for content in contents {
            let startOfDay = calendar.startOfDay(for: content.publishDate)
            dateGroups[startOfDay, default: []].append(content)
        }
        
        // 对每个组内的内容按时间排序
        for (date, items) in dateGroups {
            dateGroups[date] = items.sorted { $0.publishDate > $1.publishDate }
        }
        
        // 对日期进行排序并生成最终结果
        return dateGroups.keys
            .sorted(by: >)  // 日期倒序排列
            .map { date in
                let title = formatDate(date, needTime: false)
                return (title, dateGroups[date]!)
            }
    }
    
    private func groupContentsByFeed(_ contents: [Content]) -> [(String, [Content])] {
        var feedGroups: [String: [Content]] = [:]
        
        for content in contents {
            if let feed = content.feed.first {
                feedGroups[feed.title, default: []].append(content)
            }
        }
        
        return feedGroups.map { (title, contents) in
            (title, contents.sorted { $0.publishDate > $1.publishDate })
        }.sorted { $0.0 < $1.0 }
    }
    
    // MARK: - Actions
    @objc private func refreshData() {
        // 触感反馈
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        if #available(iOS 17.5, *) {
            generator.impactOccurred(at: .init(x: 0, y: UIScreen.main.bounds.size.width / 2))
        } else {
            generator.impactOccurred()
        }
        
        // 开始加载动画
        refreshLoadingView.startLoading()
        
        Task { @MainActor in
            do {
                let feeds = RealmManager.shared.getFeeds()?.toArray() ?? []
                let rssService = RSSService()
                
                // 使用 withThrowingTaskGroup 并行更新所有订阅源
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for feed in feeds {
                        group.addTask {
                            if let feedsResults = await RealmManager.shared.getFeeds(priorityId: feed.id) {
                                if let currentFeed = feedsResults.first {
                                    try await rssService.updateFeed(currentFeed)
                                }
                            }
                        }
                    }
                    try await group.waitForAll()
                }
                
                // 停止刷新动画
                refreshLoadingView.stopLoading { [weak self] in
                    self?.refreshControl.endRefreshing()
                }
                
            } catch {
                // 停止刷新动画并显示错误
                refreshLoadingView.stopLoading { [weak self] in
                    self?.refreshControl.endRefreshing()
                    self?.showError(error)
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "错误",
                                    message: error.localizedDescription,
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func showSearch() {
        let searchVC = ContentSearchViewController()
        let nav = UINavigationController(rootViewController: searchVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    @MainActor
    @objc private func showAIConversation() {
        let aiVC = AIConversationViewController()
        let nav = UINavigationController(rootViewController: aiVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
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
        
        // 检查是否需要加载更多
        let threshold: CGFloat = 100.0
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.bounds.height
        let currentOffset = scrollView.contentOffset.y
        
        if currentOffset > contentHeight - scrollViewHeight - threshold {
            loadMoreIfNeeded()
        }
    }
    
    @objc private func addFeedTapped() {
        let addFeedVC = AddFeedViewController()
        let nav = UINavigationController(rootViewController: addFeedVC)
        present(nav, animated: true)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: point),
               let cell = collectionView.cellForItem(at: indexPath) {
                
                // 添加触感反馈
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                // 添加弹出动画
                UIView.animate(withDuration: 0.2, animations: {
                    cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                }) { _ in
                    UIView.animate(withDuration: 0.2) {
                        cell.transform = .identity
                    }
                }
                
                // 处理长按事件
                let content = sections[indexPath.section].1[indexPath.item]
                if let articleCell = cell as? ArticleCell {
                    articleCell.onLongPress?(content)
                }
            }
        }
    }
    
    @objc private func handleFeedSelection(_ notification: Notification) {
        guard let feed = notification.userInfo?["feed"] as? Feed else { return }
        
        // 更新当前选中的订阅源
        currentFeed = feed
        
        // 更新数据
        guard let baseContents = contents else { return }
        let filteredContents = baseContents.filter("feed.id == %@ AND isDeleted == false", feed.id)
        sections = [("", Array(filteredContents))]
        
        // 更新 UI
        collectionView.reloadData()
        updateEmptyState()
        
        // 滚动到顶部
        if !sections.isEmpty {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        }
    }
    
    // MARK: - Memory Management
    @objc private func handleMemoryWarning() {
        // 清理缓存
        heightCache.removeAll()
        imageCache.removeAllObjects()
        
        // 只保留当前分组的缓存
        let currentSections = sectionCache[currentGrouping]
        sectionCache.removeAll()
        if let sections = currentSections {
            sectionCache[currentGrouping] = sections
        }
    }
    
    // MARK: - Prefetching
    private func setupPrefetching() {
        prefetchDataSource = self
        collectionView.prefetchDataSource = prefetchDataSource
    }
    
    // MARK: - Pagination
    private func loadMoreIfNeeded() {
        guard hasMoreData && !isLoadingMore else { return }
        isLoadingMore = true
        
        // 模拟加载更多数据
        currentPage += 1
        
        // TODO: 实现实际的分页加载逻辑
        
        isLoadingMore = false
    }
}

// MARK: - Helpers
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Results {
    func toArray() -> [Element] {
        return compactMap { $0 }
    }
}

extension HomeViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        // 预加载图片
        for indexPath in indexPaths {
            if let content = sections[indexPath.section].1[safe: indexPath.item],
               let imageURL = content.imageURLs.first,
               let url = URL(string: imageURL) {
                ImagePrefetcher(urls: [url]).start()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        // 取消预加载
        for indexPath in indexPaths {
            if let content = sections[indexPath.section].1[safe: indexPath.item],
               let imageURL = content.imageURLs.first,
               let url = URL(string: imageURL) {
                ImagePrefetcher(urls: [url]).stop()
            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].1.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let content = sections[indexPath.section].1[indexPath.item]
        if content.type == .article {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArticleCell", for: indexPath) as! ArticleCell
            cell.configure(with: content)
            // 设置长按回调
            cell.onLongPress = { [weak self] content in
                // 自动发送总结请求
                Task {
                    let message = self?.aiService.generateSummary(for: .singleContent(content))
                    AIAssistantManager.shared.startThinking()
                    if let message = message {
                        let text = try await self?.aiService.chat(message)
                        AIAssistantManager.shared.addInsight(.init(
                            type: .summary,
                            title: content.title,
                            description: text ?? "",
                            action: { [weak self] in
                                // 点击总结后的操作，可以跳转到详情页
                                let detailVC = ArticleDetailViewController(articleId: content.id)
                                self?.navigationController?.pushViewController(detailVC, animated: true)
                            }
                        ))
                    }
                    AIAssistantManager.shared.stopThinking()
                }
            }
            
            return cell
        } else if content.type == .podcast {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PodcastCell", for: indexPath) as! PodcastCell
            cell.configure(with: content)
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                   withReuseIdentifier: "HeaderView",
                                                                   for: indexPath) as! SectionHeaderView
        
        let (title, contents) = sections[indexPath.section]
        header.configure(title: title, count: contents.count, contents: contents)
        header.delegate = self
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 120)
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Task {
            // 获取文章 ID
            let contentId = sections[indexPath.section].1[indexPath.item].id
            
            // 在主线程获取文对象
            await MainActor.run {
                do {
                    let realm = try Realm()
                    if let content = realm.object(ofType: Content.self, forPrimaryKey: contentId) {
                        let detailVC = ArticleDetailViewController(articleId: content.id)
                        navigationController?.pushViewController(detailVC, animated: true)
                    }
                } catch {
                    showError(error)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // 当 cell 显示时，更新其布局
        if let articleCell = cell as? ArticleCell {
            articleCell.setNeedsLayout()
            articleCell.layoutIfNeeded()
        } else if let podcastCell = cell as? PodcastCell {
            podcastCell.setNeedsLayout()
            podcastCell.layoutIfNeeded()
        }
    }
}

// MARK: - ContentGrouping
private enum ContentGrouping: Int {
    case byDate = 0
    case byFeed = 1
    case favorites = 2
    case unread = 3
}

// MARK: - Layout
private extension HomeViewController {
    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, env -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(130)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(130)
            )
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 16
            
            // 根据是否是第一个 section 调整间距
            if sectionIndex == 0 {
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 64,
                    leading: 20,
                    bottom: 24,
                    trailing: 20
                )
            } else {
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 32,
                    leading: 20,
                    bottom: 24,
                    trailing: 20
                )
            }
            
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(44)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            
            // 根据是否是第一个 section 调整 header 的内边距
            if sectionIndex == 0 {
                header.contentInsets = NSDirectionalEdgeInsets(
                    top: 0,
                    leading: 0,
                    bottom: 12,
                    trailing: 0
                )
            } else {
                header.contentInsets = NSDirectionalEdgeInsets(
                    top: 0,
                    leading: 0,
                    bottom: 12,
                    trailing: 0
                )
            }
            
            section.boundarySupplementaryItems = [header]
            return section
        }
        return layout
    }
    
    // MARK: - Quick Navigation
    private func setupQuickNavigation() {
        // 添加右侧快速定位视图
        let quickNavView = QuickNavigationView()
        view.addSubview(quickNavView)
        
        quickNavView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(30)
            make.height.equalTo(300)
        }
        
        // 更新快速定位数据
        quickNavView.dates = sections.map { $0.0 }
        quickNavView.onDateSelected = { [weak self] index in
            guard let self = self else { return }
            let indexPath = IndexPath(item: 0, section: index)
            self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    // MARK: - Feed Selection
    private func setupFeedSelection() {
        // 添加订阅源选择按钮
        let feedSelectionButton = UIButton(type: .system)
        feedSelectionButton.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        feedSelectionButton.addTarget(self, action: #selector(showFeedSelection), for: .touchUpInside)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: feedSelectionButton)
    }
    
    @objc private func showFeedSelection() {
        let feedSelectionVC = FeedSelectionViewController()
        feedSelectionVC.modalPresentationStyle = .popover
        feedSelectionVC.preferredContentSize = CGSize(width: 250, height: 400)
        
        if let popover = feedSelectionVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
            popover.permittedArrowDirections = .up
            popover.delegate = self
        }
        
        present(feedSelectionVC, animated: true)
    }
    
    // MARK: - Cell Interaction
    private func setupCellInteraction() {
        // 添加长按手势
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.2 // 减少长按时间以提高响应速度
        collectionView.addGestureRecognizer(longPress)
    }
}

// MARK: - ArticleCellDelegate
extension HomeViewController: ArticleCellDelegate {
    func articleCell(_ cell: ArticleCell, didTapAIButton article: Content) {
        let aiVC = AIConversationViewController()
        let nav = UINavigationController(rootViewController: aiVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
        
        // 自动发送总结请求
        Task {
            let message = aiService.generateSummary(for: .singleContent(article))
            await aiVC.sendSummary(message)
        }
    }
}

extension HomeViewController: PodcastCellDelegate {
    func podcastCell(_ cell: PodcastCell, didChangePlayingState isPlaying: Bool) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let content = sections[indexPath.section].1[indexPath.item]
        
        if isPlaying {
            // 停止其他正在播放的内容
            if let currentPlaying = currentPlayingPodcast,
               currentPlaying.id != content.id {
                stopAllPlayingPodcasts(except: content)
            }
            
            currentPlayingPodcast = content
            showMiniPlayer(for: content)
        } else {
            if content.id == currentPlayingPodcast?.id {
                currentPlayingPodcast = nil
                hideMiniPlayer()
            }
        }
    }
    
    private func stopAllPlayingPodcasts(except: Content? = nil) {
        for section in sections {
            for content in section.1 where content.type == .podcast && content.isPlaying {
                if let exceptId = except?.id, content.id == exceptId { continue }
                
                content.isPlaying = false
                
                // 更新 UI
                if let cell = collectionView.visibleCells.first(where: { cell in
                    guard let podcastCell = cell as? PodcastCell,
                          let cellContent = podcastCell.content else { return false }
                    return cellContent.id == content.id
                }) as? PodcastCell {
                    cell.stopPlaying()
                }
            }
        }
    }
    
    private func showMiniPlayer(for content: Content) {
        guard let miniPlayerView = miniPlayerView else { return }
        miniPlayerView.configure(with: content)
        
        // 计算偏移量，包含 TabBar 高度
        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 0
        let offset = 60 + tabBarHeight // MiniPlayer 高度 + TabBar 高度
        
        if miniPlayerView.isHidden {
            miniPlayerView.isHidden = false
            miniPlayerView.transform = CGAffineTransform(translationX: 0, y: offset)
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                miniPlayerView.transform = .identity
            }
        }
    }

    private func hideMiniPlayer() {
        guard let miniPlayerView = miniPlayerView else { return }
        
        // 计算偏移量，包含 TabBar 高度
        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 0
        let offset = 60 + tabBarHeight // MiniPlayer 高度 + TabBar 高度
        
        UIView.animate(withDuration: 0.3) {
            miniPlayerView.transform = CGAffineTransform(translationX: 0, y: offset)
        } completion: { _ in
            miniPlayerView.isHidden = true
            miniPlayerView.transform = .identity
        }
    }
}

// MARK: - JXSegmentedViewDelegate
extension HomeViewController: JXSegmentedViewDelegate {
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        currentGrouping = ContentGrouping(rawValue: index) ?? .byDate
    }
}

// MARK: - SectionHeaderViewDelegate
extension HomeViewController: SectionHeaderViewDelegate {
    func sectionHeader(_ header: SectionHeaderView, didLongPressWithContents contents: [Content]) {
        // 自动发送总结请求
        Task {
            let message = aiService.generateSummary(for: .multipleContents(contents))
            AIAssistantManager.shared.startThinking()
            let text = try await aiService.chat(message)
            AIAssistantManager.shared.addInsight(.init(type: .summary, title: "总结", description: text, action: {
                
            }))
        }
    }
}
