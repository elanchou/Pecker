import UIKit
import SnapKit

class RSSPlatformListViewController: BaseViewController {
    // MARK: - Properties
    private let category: RSSDirectoryService.RSSCategory
    private let rssService = RSSDirectoryService.shared
    private var platforms: [RSSDirectoryService.RSSPlatform] = []
    private var isLoading = false
    private var error: Error?
    
    // MARK: - UI Components
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        return collectionView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Initialization
    init(category: RSSDirectoryService.RSSCategory) {
        self.category = category
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        loadData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = category.name
        view.backgroundColor = .systemBackground
        
        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(RSSPlatformCell.self, forCellWithReuseIdentifier: "RSSPlatformCell")
    }
    
    // MARK: - Data Loading
    private func loadData() {
        Task {
            do {
                isLoading = true
                loadingIndicator.startAnimating()
                platforms = await rssService.getPlatforms(for: category)
                collectionView.reloadData()
                isLoading = false
                loadingIndicator.stopAnimating()
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

// MARK: - UICollectionViewDataSource
extension RSSPlatformListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return platforms.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RSSPlatformCell", for: indexPath) as! RSSPlatformCell
        let platform = platforms[indexPath.item]
        cell.configure(with: platform)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension RSSPlatformListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 44) / 2 // 44 = 16 * 2 + 12
        return CGSize(width: width, height: 120)
    }
}

// MARK: - UICollectionViewDelegate
extension RSSPlatformListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let platform = platforms[indexPath.item]
        let vc = RSSPlatformViewController(platform: platform)
        navigationController?.pushViewController(vc, animated: true)
    }
} 