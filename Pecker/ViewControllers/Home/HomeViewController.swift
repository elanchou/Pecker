import UIKit
import RealmSwift
import JXSegmentedView
import SnapKit

class HomeViewController: BaseViewController {
    // MARK: - Properties
    private var contents: Results<Content>?
    private var notificationToken: NotificationToken?
    private var currentGrouping: ContentGrouping = .byDate {
        didSet {
            updateUI()
        }
    }
    
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
    
    private let refreshControl = UIRefreshControl()
    
    private let aiButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "sparkles"),
            style: .plain,
            target: HomeViewController.self,
            action: #selector(aiButtonTapped)
        )
        button.tintColor = .systemPurple
        return button
    }()
    
    private let searchButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: HomeViewController.self,
            action: #selector(showSearch)
        )
        button.tintColor = .systemRed
        return button
    }()
    
    private var expandedCells = Set<String>()
    private let aiService = AISummaryService()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItems = [aiButton, searchButton]
        setupUI()
        loadData()
        
        // 设置 collectionView 背景色
        collectionView.backgroundColor = .systemBackground
    }
    
    deinit {
        notificationToken?.invalidate()
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
        
        setupSegmentedView()
        setupCollectionView()
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
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    // MARK: - Data Loading
    private func loadData() {
        do {
            let realm = try Realm()
            contents = realm.objects(Content.self).filter("isDeleted == false")
            
            notificationToken = contents?.observe { [weak self] changes in
                guard let self = self else { return }
                switch changes {
                case .initial:
                    self.updateUI()
                case .update:
                    self.updateUI()
                case .error(let error):
                    print("Error: \(error)")
                }
            }
            
            updateUI()
        } catch {
            showError(error)
        }
    }
    
    private func updateUI() {
        // 获取基础数据
        guard let baseContents = contents else { return }
        var filteredContents = baseContents.filter("isDeleted == false")
        
        // 应用分组过滤
        switch currentGrouping {
        case .favorites:
            filteredContents = filteredContents.filter("isFavorite == true")
        case .unread:
            filteredContents = filteredContents.filter("isRead == false")
        default:
            break
        }
        
        // 根据分组方式组织数据
        switch currentGrouping {
        case .byDate:
            sections = groupContentsByDate(Array(filteredContents))
        case .byFeed:
            sections = groupContentsByFeed(Array(filteredContents))
        case .favorites, .unread:
            sections = [("", Array(filteredContents))]
        }
        
        // 更新 UI
        collectionView.reloadData()
    }
    
    // 添加一个属性来储组后的数据
    private var sections: [(String, [Content])] = []
    
    private func groupContentsByDate(_ contents: [Content]) -> [(String, [Content])] {
        let grouped = Dictionary(grouping: contents) { content in
            Calendar.current.startOfDay(for: content.publishDate)
        }
        return grouped.map { (date, contents) in
            (formatDate(date), contents.sorted { $0.publishDate > $1.publishDate })
        }.sorted { $0.0 > $1.0 }
    }
    
    private func groupContentsByFeed(_ contents: [Content]) -> [(String, [Content])] {
        var feedGroups: [Feed: [Content]] = [:]
        
        for content in contents {
            if let feed = content.feed.first {
                feedGroups[feed, default: []].append(content)
            }
        }
        
        return feedGroups.map { (feed, contents) in
            (feed.title, contents.sorted { $0.publishDate > $1.publishDate })
        }.sorted { $0.0 < $1.0 }
    }
    
    // MARK: - Actions
    @objc private func refreshData() {
        // 刷新所有订阅源
        Task { @MainActor in
            do {
                let realm = try await Realm()
                let feeds = realm.objects(Feed.self).filter("isDeleted == false")
                let rssService = RSSService()
                
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
        let alert = UIAlertController(title: "错误",
                                    message: error.localizedDescription,
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func aiButtonTapped() {
//        guard let contents = contents else { return }
//        let aiVC = AIConversationViewController(type: .feedSummary(Array(contents)))
//        let navController = UINavigationController(rootViewController: aiVC)
//        present(navController, animated: true)
    }
    
    @objc private func showSearch() {
        let searchVC = ContentSearchViewController()
        let nav = UINavigationController(rootViewController: searchVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
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
        
        if content.type == .podcast {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PodcastCell", for: indexPath) as! PodcastCell
            cell.configure(with: content)
            cell.delegate = self
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArticleCell", for: indexPath) as! ArticleCell
            cell.configure(with: content)
            cell.delegate = self
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                   withReuseIdentifier: "HeaderView",
                                                                   for: indexPath) as! SectionHeaderView
        
        let (title, contents) = sections[indexPath.section]
        header.configure(title: title, count: contents.count)
        return header
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
        let layout = UICollectionViewCompositionalLayout { section, env -> NSCollectionLayoutSection? in
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
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
            
            // 添加 header
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(44)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [header]
            
            return section
        }
        return layout
    }
}

// MARK: - ArticleCellDelegate
extension HomeViewController: ArticleCellDelegate {
    func articleCell(_ cell: ArticleCell, didTapAIButton article: Content) {
        if article.aiSummary != nil {
            if expandedCells.contains(article.id) {
                expandedCells.remove(article.id)
                cell.hideSummary()
            } else {
                expandedCells.insert(article.id)
                cell.configure(with: article, isExpanded: true)
            }
            
            // 使用 performBatchUpdates 来确保布局更新
            collectionView.performBatchUpdates(nil) { _ in
                // 强制重新计算布局
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
            return
        }
        
        Task {
            do {
                let summary = try await aiService.generateSummary(for: .singleContent(article))
                await MainActor.run {
                    article.updateAISummary(summary)
                    self.expandedCells.insert(article.id)
                    cell.configure(with: article, isExpanded: true)
                    
                    // 使用 performBatchUpdates 来确保布局更新
                    self.collectionView.performBatchUpdates(nil) { _ in
                        // 强制重新计算布局
                        self.collectionView.collectionViewLayout.invalidateLayout()
                    }
                }
            } catch {
                showError(error)
            }
        }
    }
}

extension HomeViewController: PodcastCellDelegate {
    func podcastCell(_ cell: PodcastCell, didTapPlayPauseFor content: Content) {
        // 更新 UI 和播放状态
        if let indexPath = collectionView.indexPath(for: cell) {
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    func podcastCell(_ cell: PodcastCell, didUpdateProgress progress: Float, for content: Content) {
        // 可以在这里更新其他 UI 元素，比如迷你播放器
        // 目前暂时不需要实现
    }
    
    func podcastCell(_ cell: PodcastCell, didChangePlayingState isPlaying: Bool) {
        // 获取当前播放的内容
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        
        let content = sections[indexPath.section].1[indexPath.item]
        
        // 如果开始播放，暂停其他正在播放的内容
        if isPlaying {
            for (sectionIndex, section) in sections.enumerated() {
                for (itemIndex, otherContent) in section.1.enumerated() {
                    if otherContent.type == .podcast &&
                       otherContent.id != content.id &&
                       otherContent.isPlaying {
                        // 更新数据库中的播放状态
                        guard let realm = try? Realm() else { return }
                        try? realm.write {
                            otherContent.isPlaying = false
                        }
                        
                        let otherIndexPath = IndexPath(item: itemIndex, section: sectionIndex)
                        if let otherCell = collectionView.cellForItem(at: otherIndexPath) as? PodcastCell {
                            otherCell.stopPlaying()
                        }
                    }
                }
            }
        }
        
        // 更新数据库中的播放状态
        guard let realm = try? Realm() else { return }
        try? realm.write {
            content.isPlaying = isPlaying
        }
        
        // 触感反馈
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // 更新 UI
        if let indexPath = collectionView.indexPath(for: cell) {
            collectionView.reloadItems(at: [indexPath])
        }
    }
}

// MARK: - JXSegmentedViewDelegate
extension HomeViewController: JXSegmentedViewDelegate {
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        currentGrouping = ContentGrouping(rawValue: index) ?? .byDate
    }
} 
