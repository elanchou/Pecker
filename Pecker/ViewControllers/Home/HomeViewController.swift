import UIKit
import RealmSwift
import JXSegmentedView
import SnapKit

class HomeViewController: BaseViewController {
    // MARK: - Properties
    private var articles: Results<Article>?
    private var notificationToken: NotificationToken?
    private var currentGrouping: ArticleGrouping = .byDate {
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
        
        // 配置分段控制器背景
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
            articles = realm.objects(Article.self).filter("isDeleted == false")
            
            notificationToken = articles?.observe { [weak self] changes in
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
        guard let baseArticles = articles else { return }
        var filteredArticles = baseArticles.filter("isDeleted == false")
        
        // 应用分组过滤
        switch currentGrouping {
        case .favorites:
            filteredArticles = filteredArticles.filter("isFavorite == true")
        case .unread:
            filteredArticles = filteredArticles.filter("isRead == false")
        default:
            break
        }
        
        // 根据分组方式组织数据
        switch currentGrouping {
        case .byDate:
            sections = groupArticlesByDate(Array(filteredArticles))
        case .byFeed:
            sections = groupArticlesByFeed(Array(filteredArticles))
        case .favorites, .unread:
            sections = [("", Array(filteredArticles))]
        }
        
        // 更新 UI
        collectionView.reloadData()
    }
    
    // 添加一个属性来储组后的数据
    // 添加一个属性来储组后的数据
    private var sections: [(String, [Article])] = []
    
    private func groupArticlesByDate(_ articles: [Article]) -> [(String, [Article])] {
        let grouped = Dictionary(grouping: articles) { article in
            Calendar.current.startOfDay(for: article.publishDate)
        }
        return grouped.map { (date, articles) in
            (formatDate(date), articles.sorted { $0.publishDate > $1.publishDate })
        }.sorted { $0.0 > $1.0 }
    }
    
    private func groupArticlesByFeed(_ articles: [Article]) -> [(String, [Article])] {
        var feedGroups: [Feed: [Article]] = [:]
        
        for article in articles {
            if let feed = article.feed.first {
                feedGroups[feed, default: []].append(article)
            }
        }
        
        return feedGroups.map { (feed, articles) in
            (feed.title, articles.sorted { $0.publishDate > $1.publishDate })
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
//        guard let articles = articles else { return }
//        let aiVC = AIConversationViewController(type: .feedSummary(Array(articles)))
//        let navController = UINavigationController(rootViewController: aiVC)
//        present(navController, animated: true)
    }
    
    @objc private func showSearch() {
        let searchVC = ArticleSearchViewController()
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArticleCell", for: indexPath) as! ArticleCell
        let article = sections[indexPath.section].1[indexPath.item]
        
        cell.delegate = self
        cell.configure(
            with: article,
            isExpanded: expandedCells.contains(article.id)
        )
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                   withReuseIdentifier: "HeaderView",
                                                                   for: indexPath) as! SectionHeaderView
        
        let (title, articles) = sections[indexPath.section]
        header.configure(title: title, count: articles.count)
        return header
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Task {
            // 获取文章 ID
            let articleId = sections[indexPath.section].1[indexPath.item].id
            
            // 在主线程获取文对象
            await MainActor.run {
                do {
                    let realm = try Realm()
                    if let article = realm.object(ofType: Article.self, forPrimaryKey: articleId) {
                        let detailVC = ArticleDetailViewController(articleId: article.id)
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
        }
    }
}

// MARK: - ArticleGrouping
private enum ArticleGrouping: Int {
    case byDate = 0
    case byFeed = 1
    case favorites = 2
    case unread = 3
}

// MARK: - Layout
private extension HomeViewController {
    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] section, env -> NSCollectionLayoutSection? in
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
    func articleCell(_ cell: ArticleCell, didTapAIButton article: Article) {
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
                let summary = try await aiService.generateSummary(for: .singleArticle(article))
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

// MARK: - JXSegmentedViewDelegate
extension HomeViewController: JXSegmentedViewDelegate {
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        currentGrouping = ArticleGrouping(rawValue: index) ?? .byDate
    }
} 
