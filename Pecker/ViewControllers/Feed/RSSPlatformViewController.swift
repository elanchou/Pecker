import UIKit
import SnapKit

class RSSPlatformViewController: BaseViewController {
    // MARK: - Properties
    private let platform: RSSDirectoryService.RSSPlatform
    private var selectedPath: RSSDirectoryService.RSSPath?
    private var params: [String: String] = [:]
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemGroupedBackground
        return tableView
    }()
    
    private let subscribeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(L("rss.subscribe"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.isEnabled = false
        return button
    }()
    
    // MARK: - Initialization
    init(platform: RSSDirectoryService.RSSPlatform) {
        self.platform = platform
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = platform.name
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(tableView)
        view.addSubview(subscribeButton)
        
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(subscribeButton.snp.top).offset(-16)
        }
        
        subscribeButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            make.height.equalTo(50)
        }
        
        subscribeButton.addTarget(self, action: #selector(handleSubscribe), for: .touchUpInside)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(RSSParamCell.self, forCellReuseIdentifier: "ParamCell")
    }
    
    // MARK: - Actions
    @objc private func handleSubscribe() {
        guard let path = selectedPath else { return }
        
        // 检查是否所有必需参数都已填写
        let missingParams = path.params.filter { param in
            param.required && (params[param.name] == nil || params[param.name]?.isEmpty == true)
        }
        
        if !missingParams.isEmpty {
            let alert = UIAlertController(
                title: L("error"),
                message: L("rss.params.required"),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: L("ok"), style: .default))
            present(alert, animated: true)
            return
        }
        
        // 生成订阅 URL
        let feedURL = RSSDirectoryService.shared.generateFeedURL(
            platform: platform,
            path: path,
            params: params
        )
        
        // 验证并添加订阅
        Task {
            do {
                let feed = try await RSSDirectoryService.shared.validateFeed(feedURL)
                try await RSSDirectoryService.shared.subscribe(feed)
                
                // 显示成功提示并返回
                let alert = UIAlertController(
                    title: L("success"),
                    message: L("rss.add.success"),
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: L("ok"), style: .default) { [weak self] _ in
                    self?.navigationController?.popViewController(animated: true)
                })
                present(alert, animated: true)
                
            } catch {
                let alert = UIAlertController(
                    title: L("error"),
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: L("ok"), style: .default))
                present(alert, animated: true)
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension RSSPlatformViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return selectedPath == nil ? 1 : 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return platform.paths.count
        } else {
            return selectedPath?.params.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            let path = platform.paths[indexPath.row]
            
            var content = cell.defaultContentConfiguration()
            content.text = path.name
            content.secondaryText = path.description
            cell.contentConfiguration = content
            
            cell.accessoryType = path.path == selectedPath?.path ? .checkmark : .none
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ParamCell", for: indexPath) as! RSSParamCell
            let param = selectedPath!.params[indexPath.row]
            cell.configure(with: param)
            cell.textField.text = params[param.name]
            cell.onTextChanged = { [weak self] text in
                self?.params[param.name] = text
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return L("rss.feed.type")
        } else {
            return L("rss.params")
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return selectedPath?.example
        }
        return nil
    }
}

// MARK: - UITableViewDelegate
extension RSSPlatformViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            selectedPath = platform.paths[indexPath.row]
            params.removeAll()
            subscribeButton.isEnabled = true
            tableView.reloadData()
        }
    }
} 
