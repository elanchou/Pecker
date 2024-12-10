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
    
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        refresh.tintColor = .clear
        refresh.backgroundColor = .clear
        return refresh
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
    
    private let loadingView = LoadingBirdView()
    private let refreshLoadingView = LoadingBirdView()
    
    private var currentPlayingPodcast: Content?
    private var miniPlayerView: MiniPlayerView?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItems = [searchButton]
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
        refreshLoadingView.startLoading()
        
        Task { @MainActor in
            do {
                let realm = try await Realm()
                let feeds = Array(realm.objects(Feed.self).filter("isDeleted == false"))
                let rssService = RSSService()
                
                for feed in feeds {
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
                heightDimension: .absolute(88)
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
    func sectionHeader(_ header: SectionHeaderView, didTapAIButtonWith contents: [Content]) {
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
