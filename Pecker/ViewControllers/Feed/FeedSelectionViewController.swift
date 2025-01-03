import UIKit
import RealmSwift
import SnapKit

class FeedSelectionViewController: UIViewController {
    // MARK: - Properties
    private var feeds: Results<Feed>?
    private var notificationToken: NotificationToken?
    
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.delegate = self
        tv.dataSource = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tv.backgroundColor = .systemGroupedBackground
        return tv
    }()
    
    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "搜索订阅源"
        return sc
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Data Loading
    private func loadData() {
        do {
            let realm = try Realm()
            feeds = realm.objects(Feed.self).sorted(byKeyPath: "title")
            
            notificationToken = feeds?.observe { [weak self] changes in
                guard let self = self else { return }
                switch changes {
                case .initial:
                    self.tableView.reloadData()
                case .update:
                    self.tableView.reloadData()
                case .error(let error):
                    print("Error: \(error)")
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }
}

// MARK: - UITableViewDataSource
extension FeedSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feeds?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        if let feed = feeds?[indexPath.row] {
            var config = cell.defaultContentConfiguration()
            config.text = feed.title
            config.secondaryText = feed.url
            cell.contentConfiguration = config
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FeedSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let feed = feeds?[indexPath.row] {
            // 通知首页切换到选中的订阅源
            NotificationCenter.default.post(
                name: NSNotification.Name("SelectedFeedChanged"),
                object: nil,
                userInfo: ["feed": feed]
            )
            dismiss(animated: true)
        }
    }
}

// MARK: - UISearchResultsUpdating
extension FeedSelectionViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else { return }
        
        if searchText.isEmpty {
            loadData()
        } else {
            do {
                let realm = try Realm()
                feeds = realm.objects(Feed.self)
                    .filter("title CONTAINS[c] %@ OR url CONTAINS[c] %@", searchText, searchText)
                    .sorted(byKeyPath: "title")
                tableView.reloadData()
            } catch {
                print("Error: \(error)")
            }
        }
    }
} 