import UIKit
import SnapKit

class PodcastBrowseViewController: BaseViewController {
    // MARK: - Properties
    private let podcastService = PodcastService.shared
    private var podcasts: [PodcastService.Podcast] = []
    private var genres: [Genre] = []
    private var selectedGenre: Genre?
    
    private let searchController = UISearchController(searchResultsController: nil)
    private let loadingView = LoadingBirdView()
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(PodcastBrowseCell.self, forCellWithReuseIdentifier: "PodcastCell")
        cv.register(
            PodcastHeaderView.self,
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
        title = "发现播客"
        
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
        searchController.searchBar.placeholder = "搜索播客"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    // MARK: - Data Loading
    private func loadData() {
        loadingView.startLoading()
        
        Task {
            do {
                async let podcastsTask = podcastService.getTopPodcasts()
                async let genresTask = podcastService.getPodcastGenres()
                
                let (podcasts, genres) = try await (podcastsTask, genresTask)
                
                await MainActor.run {
                    self.podcasts = podcasts
                    self.genres = genres
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
    
    private func searchPodcasts(_ query: String) {
        guard !query.isEmpty else {
            loadData()
            return
        }
        
        loadingView.startLoading()
        
        Task {
            do {
                let results = try await podcastService.searchPodcasts(query)
                await MainActor.run {
                    self.podcasts = results
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
extension PodcastBrowseViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return podcasts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PodcastCell", for: indexPath) as! PodcastBrowseCell
        let podcast = podcasts[indexPath.item]
        cell.configure(with: podcast)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "HeaderView",
            for: indexPath
        ) as! PodcastHeaderView
        
        header.configure(with: genres) { [weak self] genre in
            self?.selectedGenre = genre
            self?.loadPodcastsByGenre(genre)
        }
        
        return header
    }
}

// MARK: - UICollectionViewDelegate
extension PodcastBrowseViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let podcast = podcasts[indexPath.item]
        guard let feedUrl = podcast.feedUrl else { return }
        
        Task {
            do {
                let feed = Feed(title: podcast.collectionName, url: feedUrl, type: .podcast)
                try await RealmManager.shared.addNewFeed(feed)
                dismiss(animated: true)
            } catch {
                showError(error)
            }
        }
    }
}

// MARK: - UISearchResultsUpdating
extension PodcastBrowseViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text else { return }
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(delayedSearch), with: query, afterDelay: 0.5)
    }
    
    @objc private func delayedSearch(_ query: String) {
        searchPodcasts(query)
    }
}

// MARK: - Genre Loading
extension PodcastBrowseViewController {
    private func loadPodcastsByGenre(_ genre: Genre) {
        loadingView.startLoading()
        
        Task {
            do {
                let podcasts = try await podcastService.getTopPodcasts(genre: genre.id)
                await MainActor.run {
                    self.podcasts = podcasts
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