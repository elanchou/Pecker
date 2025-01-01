import UIKit

class RSSBrowseViewController: BaseViewController {
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
        control.backgroundColor = .white
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
        title = LocalizedString("rss.discover")
        view.backgroundColor = .systemGroupedBackground
        
        // 设置 segmentControl 背景
        let segmentBackground = UIView()
        segmentBackground.backgroundColor = .systemBackground
        
        // 添加底部阴影
        segmentBackground.layer.shadowColor = UIColor.black.cgColor
        segmentBackground.layer.shadowOffset = CGSize(width: 0, height: 1)
        segmentBackground.layer.shadowRadius = 4
        segmentBackground.layer.shadowOpacity = 0.05
        
        // 添加视图顺序很重要，先添加背景
        view.addSubview(segmentBackground)
        view.addSubview(segmentedControl)
        view.addSubview(headerView)
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        
        // SegmentControl 背景
        segmentBackground.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(segmentedControl).offset(8)
        }
        
        // SegmentControl
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(32)
        }
        
        // Header View
        headerView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        
        // Table View
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        // Loading Indicator
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // 设置 TableView
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(RSSBrowseCell.self, forCellReuseIdentifier: "RSSBrowseCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        // 添加下拉刷新
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc private func refreshData() {
        
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
        
        
        // 添加订阅回调
        cell.onSubscribe = { [weak self] feed in
            self?.handleSubscribe(feed)
        }
        
        return cell
    }
    
    private func handleSubscribe(_ feed: RSSDirectoryService.Feed) {
        Task {
            do {
//                try await RSSDirectoryService.shared.subscribe(feed)
                // 显示成功提示
                showSuccessToast(message: LocalizedString("rss.add.success"))
            } catch {
                // 显示错误提示
                showErrorToast(message: LocalizedString("feed.add.error"))
            }
        }
    }
    
    private func showSuccessToast(message: String) {
        let toast = UILabel()
        toast.text = message
        toast.textColor = .white
        toast.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
        toast.textAlignment = .center
        toast.font = .systemFont(ofSize: 14, weight: .medium)
        toast.layer.cornerRadius = 20
        toast.clipsToBounds = true
        
        view.addSubview(toast)
        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(40)
            make.width.greaterThanOrEqualTo(120)
        }
        
        toast.alpha = 0
        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                UIView.animate(withDuration: 0.3, animations: {
                    toast.alpha = 0
                }) { _ in
                    toast.removeFromSuperview()
                }
            }
        }
    }
    
    private func showErrorToast(message: String) {
        let toast = UILabel()
        toast.text = message
        toast.textColor = .white
        toast.backgroundColor = UIColor.systemRed.withAlphaComponent(0.9)
        toast.textAlignment = .center
        toast.font = .systemFont(ofSize: 14, weight: .medium)
        toast.layer.cornerRadius = 20
        toast.clipsToBounds = true
        
        view.addSubview(toast)
        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(40)
            make.width.greaterThanOrEqualTo(120)
        }
        
        toast.alpha = 0
        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                UIView.animate(withDuration: 0.3, animations: {
                    toast.alpha = 0
                }) { _ in
                    toast.removeFromSuperview()
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension RSSBrowseViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // TODO: Handle feed selection
    }
} 
