import UIKit

class RSSBrowseViewController: UIViewController {
    // MARK: - Properties
    private let rssService = RSSDirectoryService.shared
    private var feeds: [RSSDirectoryService.Feed] = []
    private var categories: [RSSDirectoryService.RSSCategory] = []
    private var selectedCategory: RSSDirectoryService.RSSCategory?
    private var isLoading = false
    private var error: Error?
    
    // MARK: - UI Components
    private let segmentedControl: UISegmentedControl = {
        let items = ["Categories", "Countries"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.backgroundColor = .secondarySystemBackground
        return control
    }()
    
    private let headerView: RSSBrowseHeaderView = {
        let view = RSSBrowseHeaderView()
        return view
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        return tableView
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
        setupBindings()
        loadData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "RSS Feeds"
        
        view.addSubview(segmentedControl)
        view.addSubview(headerView)
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            headerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        tableView.register(RSSBrowseCell.self, forCellReuseIdentifier: "RSSBrowseCell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupBindings() {
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        headerView.onCategorySelected = { [weak self] category in
            self?.selectedCategory = category
            Task {
                await self?.loadFeeds()
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadData() {
        Task {
            do {
                isLoading = true
                loadingIndicator.startAnimating()
                
                if segmentedControl.selectedSegmentIndex == 0 {
                    categories = try await rssService.getCategories()
                } else {
                    categories = try await rssService.getCountries()
                }
                
                headerView.configure(with: categories)
                
                if let firstCategory = categories.first {
                    selectedCategory = firstCategory
                    await loadFeeds()
                }
                
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
    
    private func loadFeeds() async {
        guard let category = selectedCategory else { return }
        
        do {
            isLoading = true
            loadingIndicator.startAnimating()
            
            feeds = try await rssService.getFeedsByCategory(category)
            tableView.reloadData()
            
            isLoading = false
            loadingIndicator.stopAnimating()
        } catch {
            self.error = error
            showError(error)
            isLoading = false
            loadingIndicator.stopAnimating()
        }
    }
    
    // MARK: - Actions
    @objc private func segmentedControlValueChanged() {
        loadData()
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension RSSBrowseViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feeds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RSSBrowseCell", for: indexPath) as! RSSBrowseCell
        let feed = feeds[indexPath.row]
        if let category = selectedCategory {
            cell.configure(with: feed, category: category)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension RSSBrowseViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 280
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // TODO: Handle feed selection
    }
} 
