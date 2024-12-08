import UIKit
import RealmSwift

class ArticleSearchViewController: BaseViewController {
    private let searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "搜索文章"
        bar.searchBarStyle = .minimal
        return bar
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.register(ArticleCell.self, forCellWithReuseIdentifier: "ArticleCell")
        return cv
    }()
    
    private var articles: [Article] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchBar()
    }
    
    private func setupUI() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "取消",
            style: .plain,
            target: self,
            action: #selector(dismissVC)
        )
        
        [searchBar, collectionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // 添加动画效果
        searchBar.transform = CGAffineTransform(translationX: 0, y: -50)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.searchBar.transform = .identity
        }
    }
    
    @objc private func dismissVC() {
        let nav = BaseNavigationController(rootViewController: self)
        // 添加消失动画
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0
            self.searchBar.transform = CGAffineTransform(translationX: 0, y: -50)
        }) { _ in
            self.dismiss(animated: false)
        }
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.becomeFirstResponder() // 自动显示键盘
        
        // 自定义搜索框样式
        searchBar.searchTextField.backgroundColor = .secondarySystemBackground
        searchBar.searchTextField.tintColor = .systemRed
        
        if let glassIcon = searchBar.searchTextField.leftView as? UIImageView {
            glassIcon.tintColor = .systemRed
        }
    }
    
    private func performSearch(with query: String) {
        do {
            let realm = try Realm()
            let results = realm.objects(Article.self)
                .filter("isDeleted == false")
                .filter("title CONTAINS[c] %@ OR content CONTAINS[c] %@", query, query)
                .sorted(byKeyPath: "publishDate", ascending: false)
            
            articles = Array(results)
            
            // 添加动画效果
            let animation = CATransition()
            animation.type = .fade
            animation.duration = 0.3
            collectionView.layer.add(animation, forKey: nil)
            collectionView.reloadData()
            
        } catch {
            showError(error)
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "错误", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension ArticleSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(delayedSearch), with: nil, afterDelay: 0.5)
    }
    
    @objc private func delayedSearch() {
        guard let query = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !query.isEmpty else {
            articles = []
            collectionView.reloadData()
            return
        }
        
        performSearch(with: query)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UICollectionViewDataSource
extension ArticleSearchViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return articles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArticleCell", for: indexPath) as! ArticleCell
        cell.configure(with: articles[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ArticleSearchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 140)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let article = articles[indexPath.item]
        let detailVC = ArticleDetailViewController(articleId: article.id)
        navigationController?.pushViewController(detailVC, animated: true)
    }
} 
