import UIKit
import CloudKit

class SettingsViewController: BaseViewController {
    // MARK: - Properties
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = .systemGroupedBackground
        table.separatorStyle = .none
        return table
    }()
    
    private var sections: [SettingsSection] = [
        SettingsSection(title: "通用", items: [
            SettingsItem(icon: "paintbrush", iconColor: .systemIndigo, title: "主题", accessoryType: .disclosureIndicator),
            SettingsItem(icon: "bell", iconColor: .systemRed, title: "通知", accessoryType: .disclosureIndicator),
            SettingsItem(icon: "arrow.clockwise", iconColor: .systemBlue, title: "自动刷新", accessoryType: .toggle)
        ]),
        SettingsSection(title: "内容", items: [
            SettingsItem(icon: "text.justify", iconColor: .systemGreen, title: "阅读设置", accessoryType: .disclosureIndicator),
            SettingsItem(icon: "square.stack.3d.up", iconColor: .systemOrange, title: "订阅源管理", accessoryType: .disclosureIndicator),
            SettingsItem(icon: "arrow.up.arrow.down", iconColor: .systemPurple, title: "排序方式", accessoryType: .disclosureIndicator)
        ]),
        SettingsSection(title: "数据", items: [
            SettingsItem(icon: "icloud", iconColor: .systemBlue, title: "iCloud 同步", accessoryType: .toggle),
            SettingsItem(icon: "arrow.triangle.2.circlepath", iconColor: .systemGreen, title: "导入/导出", accessoryType: .disclosureIndicator),
            SettingsItem(icon: "trash", iconColor: .systemRed, title: "清除缓存", accessoryType: .none)
        ]),
        SettingsSection(title: "关于", items: [
            SettingsItem(icon: "star", iconColor: .systemYellow, title: "评分", accessoryType: .disclosureIndicator),
            SettingsItem(icon: "envelope", iconColor: .systemBlue, title: "反馈", accessoryType: .disclosureIndicator),
            SettingsItem(icon: "info.circle", iconColor: .systemGray, title: "版本", detail: "1.0.0", accessoryType: .none)
        ])
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "设置"
        view.backgroundColor = .systemGroupedBackground
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SettingsCell.self, forCellReuseIdentifier: "SettingsCell")
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
        let item = sections[indexPath.section].items[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].items[indexPath.row]
        handleSettingsTap(item)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = SettingsHeaderView()
        header.configure(with: sections[section].title)
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }
}

// MARK: - Settings Models
struct SettingsSection {
    let title: String
    let items: [SettingsItem]
}

struct SettingsItem {
    let icon: String
    let iconColor: UIColor
    let title: String
    var detail: String?
    let accessoryType: SettingsAccessoryType
}

enum SettingsAccessoryType {
    case none
    case disclosureIndicator
    case toggle
}

// MARK: - Actions
extension SettingsViewController {
    private func handleSettingsTap(_ item: SettingsItem) {
        switch item.title {
        case "主题":
            // 处理主题设置
            break
        case "通知":
            // 处理通知设置
            break
        case "订阅源管理":
            let feedListVC = FeedListViewController()
            navigationController?.pushViewController(feedListVC, animated: true)
        case "清除缓存":
            showClearCacheAlert()
        case "反馈":
            openFeedbackMail()
        case "评分":
            openAppStore()
        default:
            break
        }
    }
    
    private func showClearCacheAlert() {
        let alert = UIAlertController(
            title: "清除缓存",
            message: "确定要清除所有缓存数据吗？这不会删除你的订阅源。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清除", style: .destructive) { _ in
            // 执行清除缓存操作
            Task {
                do {
                    try await RealmManager.shared.clearCache()
                    ToastView.success("缓存已清除")
                } catch {
                    ToastView.failure(error.localizedDescription)
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func openFeedbackMail() {
        // 实现邮件反馈功能
    }
    
    private func openAppStore() {
        // 实现跳转 App Store 功能
    }
} 
