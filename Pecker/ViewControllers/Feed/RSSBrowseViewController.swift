import UIKit
import SnapKit

class RSSBrowseViewController: BaseViewController {
    // MARK: - Properties
    private let rssService = RSSDirectoryService.shared
    private var feeds: [RSSDirectoryService.RSSFeed] = []
    private var categories: [RSSDirectoryService.RSSCategory] = []
    private var selectedCategory: RSSDirectoryService.RSSCategory?
    
    private let searchController = UISearchController(searchResultsController: nil)
    private let loadingView = LoadingBirdView()
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(RSSBrowseCell.self, forCellWithReuseIdentifier: "RSSCell")
        cv.register(
            RSSHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "HeaderView"
        )
        return cv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchController()
        loadData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "发现订阅源"
        
        view.addSubview(collectionView)
        view.addSubview(loadingView)
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(150)
        }
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "搜索订阅源"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    // MARK: - Data Loading
    private func loadData() {
        loadingView.startLoading()
        
        Task {
            do {
                async let feedsTask = rssService.getPopularFeeds()
                async let categoriesTask = rssService.getCategories()
                
                let (feeds, categories) = try await (feedsTask, categoriesTask)
                
                await MainActor.run {
                    self.feeds = feeds
                    self.categories = categories
                    self.collectionView.reloadData()
                    self.loadingView.stopLoading()
                }
            } catch {
                await MainActor.run {
                    self.loadingView.stopLoading()
                    self.showError(error)
                }
            }
        }
    }
    
    private func searchFeeds(_ query: String) {
        guard !query.isEmpty else {
            loadData()
            return
        }
        
        loadingView.startLoading()
        
        Task {
            do {
                let results = try await rssService.searchFeeds(query)
                await MainActor.run {
                    self.feeds = results
                    self.collectionView.reloadData()
                    self.loadingView.stopLoading()
                }
            } catch {
                await MainActor.run {
                    self.loadingView.stopLoading()
                    self.showError(error)
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
    
    // MARK: - Layout
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { section, env -> NSCollectionLayoutSection? in
            // Item
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
            
            // Group
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(200)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 8)
            
            // Header
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(50)
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

// MARK: - UICollectionViewDataSource
extension RSSBrowseViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return feeds.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RSSCell", for: indexPath) as! RSSBrowseCell
        let feed = feeds[indexPath.item]
        cell.configure(with: feed)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "HeaderView",
            for: indexPath
        ) as! RSSHeaderView
        
        header.configure(with: categories) { [weak self] category in
            self?.selectedCategory = category
            self?.loadFeedsByCategory(category)
        }
        
        return header
    }
}

// MARK: - UICollectionViewDelegate
extension RSSBrowseViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let feed = feeds[indexPath.item]
        
        Task {
            do {
                let newFeed = Feed(title: feed.title, url: feed.url, type: .article)
                try await RealmManager.shared.addNewFeed(newFeed)
                dismiss(animated: true)
            } catch {
                showError(error)
            }
        }
    }
}

// MARK: - UISearchResultsUpdating
extension RSSBrowseViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text else { return }
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(delayedSearch), with: query, afterDelay: 0.5)
    }
    
    @objc private func delayedSearch(_ query: String) {
        searchFeeds(query)
    }
}

// MARK: - Category Loading
extension RSSBrowseViewController {
    private func loadFeedsByCategory(_ category: RSSDirectoryService.RSSCategory) {
        loadingView.startLoading()
        
        Task {
            do {
                let feeds = try await rssService.getFeedsByCategory(category)
                await MainActor.run {
                    self.feeds = feeds
                    self.collectionView.reloadData()
                    self.loadingView.stopLoading()
                }
            } catch {
                await MainActor.run {
                    self.loadingView.stopLoading()
                    self.showError(error)
                }
            }
        }
    }
} 
