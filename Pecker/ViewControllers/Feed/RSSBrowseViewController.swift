import UIKit
import SnapKit

class RSSBrowseViewController: BaseViewController {
    // MARK: - Properties
    private let rssService = RSSDirectoryService.shared
    private var categories: [RSSDirectoryService.RSSCategory] = []
    private var selectedCategory: RSSDirectoryService.RSSCategory?
    private var isLoading = false
    private var error: Error?
    
    private var banners: [RSSBanner] = []
    private var currentBannerIndex = 0
    private var bannerTimer: Timer?
    
    // MARK: - UI Components
    private let searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchBar.placeholder = LocalizedString("rss.search.placeholder")
        controller.obscuresBackgroundDuringPresentation = false
        return controller
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = createCollectionViewLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        return collectionView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupBindings()
        loadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startBannerTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopBannerTimer()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = LocalizedString("rss.discover")
        view.backgroundColor = .systemBackground
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func createCollectionViewLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }
            
            switch Section(rawValue: sectionIndex) {
            case .banner:
                // Banner 布局
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9), heightDimension: .absolute(200))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPagingCentered
                section.interGroupSpacing = 10
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 20, trailing: 10)
                
                // 添加自动滚动
                section.visibleItemsInvalidationHandler = { [weak self] items, offset, environment in
                    guard let self = self else { return }
                    let page = round(offset.x / environment.container.contentSize.width)
                    self.currentBannerIndex = Int(page)
                }
                
                return section
                
            case .featured:
                // 精选内容布局
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9), heightDimension: .absolute(150))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 20, trailing: 10)
                
                let header = self.createSectionHeader()
                section.boundarySupplementaryItems = [header]
                
                return section
                
            case .categories:
                // 分类网格布局
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(120))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(250))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 20, trailing: 10)
                
                let header = self.createSectionHeader()
                section.boundarySupplementaryItems = [header]
                
                return section
                
            case .articles, .podcasts, .videos, .social:
                // 水平滚动列表布局
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.8), heightDimension: .absolute(180))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 20, trailing: 10)
                
                let header = self.createSectionHeader()
                section.boundarySupplementaryItems = [header]
                
                return section
                
            default:
                return nil
            }
        }
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // 注册 Cell 和 Header
        collectionView.register(RSSBannerCell.self, forCellWithReuseIdentifier: "RSSBannerCell")
        collectionView.register(RSSFeaturedCell.self, forCellWithReuseIdentifier: "RSSFeaturedCell")
        collectionView.register(RSSCategoryCell.self, forCellWithReuseIdentifier: "RSSCategoryCell")
        collectionView.register(RSSArticleCell.self, forCellWithReuseIdentifier: "RSSArticleCell")
        collectionView.register(RSSPodcastCell.self, forCellWithReuseIdentifier: "RSSPodcastCell")
        collectionView.register(RSSVideoCell.self, forCellWithReuseIdentifier: "RSSVideoCell")
        collectionView.register(RSSSocialCell.self, forCellWithReuseIdentifier: "RSSSocialCell")
        collectionView.register(
            RSSHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "RSSHeaderView"
        )
    }
    
    private func setupBindings() {
        searchController.searchResultsUpdater = self
    }
    
    private func createSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(44))
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }
    
    // MARK: - Banner Auto Scroll
    private func startBannerTimer() {
        stopBannerTimer()
        bannerTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.scrollToNextBanner()
        }
    }
    
    private func stopBannerTimer() {
        bannerTimer?.invalidate()
        bannerTimer = nil
    }
    
    private func scrollToNextBanner() {
        guard !banners.isEmpty else { return }
        
        let nextIndex = (currentBannerIndex + 1) % banners.count
        let indexPath = IndexPath(item: nextIndex, section: Section.banner.rawValue)
        
        collectionView.scrollToItem(
            at: indexPath,
            at: .centeredHorizontally,
            animated: true
        )
    }
    
    // MARK: - Data Loading
    private func loadData() {
        Task {
            do {
                isLoading = true
                loadingIndicator.startAnimating()
                
                // 加载分类
                categories = await rssService.getCategories()
                
                // 加载 Banner 数据（示例数据）
                banners = [
                    RSSBanner(
                        id: "1",
                        title: "探索 RSS 的无限可能",
                        subtitle: "发现更多优质内容",
                        imageURL: "https://picsum.photos/800/400",
                        targetURL: "https://example.com/1"
                    ),
                    RSSBanner(
                        id: "2",
                        title: "热门播客推荐",
                        subtitle: "聆听知识的声音",
                        imageURL: "https://picsum.photos/800/400",
                        targetURL: "https://example.com/2"
                    ),
                    RSSBanner(
                        id: "3",
                        title: "精选视频内容",
                        subtitle: "视觉盛宴等你来看",
                        imageURL: "https://picsum.photos/800/400",
                        targetURL: "https://example.com/3"
                    ),
                    RSSBanner(
                        id: "4",
                        title: "社交媒体精选",
                        subtitle: "不错过每一个精彩瞬间",
                        imageURL: "https://picsum.photos/800/400",
                        targetURL: "https://example.com/4"
                    ),
                    RSSBanner(
                        id: "5",
                        title: "新闻资讯聚合",
                        subtitle: "实时掌握全球动态",
                        imageURL: "https://picsum.photos/800/400",
                        targetURL: "https://example.com/5"
                    )
                ]
                
                collectionView.reloadData()
                isLoading = false
                loadingIndicator.stopAnimating()
                
                // 开始 Banner 自动滚动
                startBannerTimer()
                
            } catch {
                self.error = error
                showError(error)
                isLoading = false
                loadingIndicator.stopAnimating()
            }
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: LocalizedString("error"),
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: LocalizedString("ok"), style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Section Enum
extension RSSBrowseViewController {
    enum Section: Int, CaseIterable {
        case banner
        case featured
        case categories
        case articles
        case podcasts
        case videos
        case social
        
        var title: String {
            switch self {
            case .banner: return ""
            case .featured: return LocalizedString("rss.featured")
            case .categories: return LocalizedString("rss.categories")
            case .articles: return LocalizedString("rss.articles")
            case .podcasts: return LocalizedString("rss.podcasts")
            case .videos: return LocalizedString("rss.videos")
            case .social: return LocalizedString("rss.social")
            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension RSSBrowseViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Section.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .banner: return banners.count
        case .featured: return 3 // 精选内容数量
        case .categories: return categories.count
        case .articles: return 5 // 文章数量
        case .podcasts: return 5 // 播客数量
        case .videos: return 5 // 视频数量
        case .social: return 5 // 社交媒体数量
        default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch Section(rawValue: indexPath.section) {
        case .banner:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RSSBannerCell", for: indexPath) as! RSSBannerCell
            let banner = banners[indexPath.item]
            cell.configure(with: banner)
            return cell
            
        case .featured:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RSSFeaturedCell", for: indexPath) as! RSSFeaturedCell
            // 配置精选内容 Cell（示例数据）
            let featured = RSSFeatured(
                id: "\(indexPath.item + 1)",
                title: "精选内容 \(indexPath.item + 1)",
                description: "这是一个精选内容的描述",
                category: "分类",
                iconURL: "https://picsum.photos/40",
                targetURL: "https://example.com/featured/\(indexPath.item + 1)"
            )
            cell.configure(with: featured)
            return cell
            
        case .categories:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RSSCategoryCell", for: indexPath) as! RSSCategoryCell
            let category = categories[indexPath.item]
            cell.configure(with: category)
            return cell
            
        case .articles:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RSSArticleCell", for: indexPath) as! RSSArticleCell
            // 配置文章 Cell（示例数据）
            let article = RSSArticle(
                id: "\(indexPath.item + 1)",
                title: "文章标题 \(indexPath.item + 1)",
                source: "来源网站",
                date: "2024-01-\(indexPath.item + 1)",
                imageURL: "https://picsum.photos/400/200",
                articleURL: "https://example.com/article/\(indexPath.item + 1)"
            )
            cell.configure(with: article)
            return cell
            
        case .podcasts:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RSSPodcastCell", for: indexPath) as! RSSPodcastCell
            // 配置播客 Cell（示例数据）
            let podcast = RSSPodcast(
                id: "\(indexPath.item + 1)",
                title: "播客节目 \(indexPath.item + 1)",
                author: "主播名称",
                duration: "45:00",
                imageURL: "https://picsum.photos/400/400",
                audioURL: "https://example.com/podcast/\(indexPath.item + 1)"
            )
            cell.configure(with: podcast)
            return cell
            
        case .videos:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RSSVideoCell", for: indexPath) as! RSSVideoCell
            // 配置视频 Cell（示例数据）
            let video = RSSVideo(
                id: "\(indexPath.item + 1)",
                title: "视频标题 \(indexPath.item + 1)",
                channel: "频道名称",
                viewCount: "\(Int.random(in: 1000...100000)) 次观看",
                duration: "\(Int.random(in: 1...10)):00",
                thumbnailURL: "https://picsum.photos/400/225",
                videoURL: "https://example.com/video/\(indexPath.item + 1)"
            )
            cell.configure(with: video)
            return cell
            
        case .social:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RSSSocialCell", for: indexPath) as! RSSSocialCell
            // 配置社交媒体 Cell（示例数据）
            let social = RSSSocial(
                id: "\(indexPath.item + 1)",
                platform: [.weibo, .twitter, .instagram][indexPath.item % 3],
                name: "用户名称",
                username: "@username",
                content: "这是一条社交媒体动态内容，可能包含文字、图片等",
                avatarURL: "https://picsum.photos/100/100",
                mediaURL: indexPath.item % 2 == 0 ? "https://picsum.photos/400/300" : nil,
                stats: "\(Int.random(in: 10...1000)) 点赞 · \(Int.random(in: 5...100)) 评论"
            )
            cell.configure(with: social)
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "RSSHeaderView",
                for: indexPath
            ) as! RSSHeaderView
            
            if let section = Section(rawValue: indexPath.section) {
                header.configure(with: section.title)
            }
            
            return header
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate
extension RSSBrowseViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section) {
        case .banner:
            let banner = banners[indexPath.item]
            if let url = URL(string: banner.targetURL) {
                UIApplication.shared.open(url)
            }
            
        case .categories:
            let category = categories[indexPath.item]
            let vc = RSSPlatformListViewController(category: category)
            navigationController?.pushViewController(vc, animated: true)
            
        default:
            break
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopBannerTimer()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        startBannerTimer()
    }
}

// MARK: - UISearchResultsUpdating
extension RSSBrowseViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        // 实现搜索功能
    }
} 
