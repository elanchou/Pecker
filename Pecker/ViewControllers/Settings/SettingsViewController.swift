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
            SettingsItem(icon: "bell", iconColor: .systemRed, title: "通知", accessoryType: .toggle, isOn: SettingsManager.shared.areNotificationsEnabled),
            SettingsItem(icon: "arrow.clockwise", iconColor: .systemBlue, title: "自动刷新", accessoryType: .toggle, isOn: SettingsManager.shared.isAutoRefreshEnabled)
        ]),
        SettingsSection(title: "内容", items: [
            SettingsItem(icon: "text.justify", iconColor: .systemGreen, title: "阅读设置", accessoryType: .disclosureIndicator),
            SettingsItem(icon: "square.stack.3d.up", iconColor: .systemOrange, title: "订阅源管理", accessoryType: .disclosureIndicator),
            SettingsItem(icon: "arrow.up.arrow.down", iconColor: .systemPurple, title: "排序方式", accessoryType: .disclosureIndicator)
        ]),
        SettingsSection(title: "数据", items: [
            SettingsItem(icon: "icloud", iconColor: .systemBlue, title: "iCloud 同步", accessoryType: .toggle, isOn: SettingsManager.shared.isICloudSyncEnabled),
            SettingsItem(icon: "arrow.triangle.2.circlepath", iconColor: .systemGreen, title: "导入/导出", accessoryType: .disclosureIndicator),
            SettingsItem(icon: "trash", iconColor: .systemRed, title: "清除缓存", accessoryType: .none)
        ]),
        SettingsSection(title: "关于", items: [
            SettingsItem(icon: "star", iconColor: .systemYellow, title: "评分", accessoryType: .disclosureIndicator),
            SettingsItem(icon: "envelope", iconColor: .systemBlue, title: "反馈", accessoryType: .disclosureIndicator),
            SettingsItem(icon: "info.circle", iconColor: .systemGray, title: "版本", detail: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0", accessoryType: .none)
        ])
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateToggleStates()
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
    
    private func updateToggleStates() {
        // 更新开关状态
        let settings = SettingsManager.shared
        
        if let notificationIndex = sections[0].items.firstIndex(where: { $0.title == "通知" }) {
            sections[0].items[notificationIndex].isOn = settings.areNotificationsEnabled
        }
        
        if let autoRefreshIndex = sections[0].items.firstIndex(where: { $0.title == "自动刷新" }) {
            sections[0].items[autoRefreshIndex].isOn = settings.isAutoRefreshEnabled
        }
        
        if let iCloudIndex = sections[2].items.firstIndex(where: { $0.title == "iCloud 同步" }) {
            sections[2].items[iCloudIndex].isOn = settings.isICloudSyncEnabled
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
        
        if item.accessoryType == .toggle {
            cell.switchValueChanged = { [weak self] isOn in
                self?.handleToggleChange(for: item, isOn: isOn)
            }
        }
        
        return cell
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

// MARK: - Actions
extension SettingsViewController {
    private func handleSettingsTap(_ item: SettingsItem) {
        switch item.title {
        case "主题":
            showThemeSettings()
        case "阅读设置":
            showReadingSettings()
        case "订阅源管理":
            let feedListVC = FeedListViewController()
            navigationController?.pushViewController(feedListVC, animated: true)
        case "排序方式":
            showSortOptions()
        case "导入/导出":
            showImportExportOptions()
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
    
    private func handleToggleChange(for item: SettingsItem, isOn: Bool) {
        let settings = SettingsManager.shared
        
        switch item.title {
        case "通知":
            settings.areNotificationsEnabled = isOn
        case "自动刷新":
            settings.isAutoRefreshEnabled = isOn
        case "iCloud 同步":
            settings.isICloudSyncEnabled = isOn
        default:
            break
        }
    }
    
    private func showThemeSettings() {
        let alert = UIAlertController(title: "选择主题", message: nil, preferredStyle: .actionSheet)
        
        let themes: [(String, SettingsManager.Theme)] = [
            ("跟随系统", .system),
            ("浅色", .light),
            ("深色", .dark)
        ]
        
        for (title, theme) in themes {
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                SettingsManager.shared.currentTheme = theme
                self?.tableView.reloadData()
            })
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showReadingSettings() {
        let readingVC = ReadingSettingsViewController()
        navigationController?.pushViewController(readingVC, animated: true)
    }
    
    private func showSortOptions() {
        let alert = UIAlertController(title: "排序方式", message: nil, preferredStyle: .actionSheet)
        
        let sortOptions: [(String, SettingsManager.SortOrder)] = [
            ("最新在前", .dateDesc),
            ("最早在前", .dateAsc),
            ("按标题", .titleAsc),
            ("未读优先", .unreadFirst)
        ]
        
        for (title, order) in sortOptions {
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                SettingsManager.shared.sortOrder = order
                self?.tableView.reloadData()
                NotificationCenter.default.post(name: NSNotification.Name("SortOrderChanged"), object: nil)
            })
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showImportExportOptions() {
        let alert = UIAlertController(title: "导入/导出", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "导出数据", style: .default) { [weak self] _ in
            self?.exportData()
        })
        
        alert.addAction(UIAlertAction(title: "导入数据", style: .default) { [weak self] _ in
            self?.importData()
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showClearCacheAlert() {
        let alert = UIAlertController(
            title: "清除缓存",
            message: "确定要清除所有缓存数据吗？这不会删除你的订阅源。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清除", style: .destructive) { [weak self] _ in
            Task { [weak self] in
                do {
                    try await SettingsManager.shared.clearCache()
                    ToastView.success("缓存已清除")
                } catch {
                    ToastView.failure(error.localizedDescription)
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func exportData() {
        Task {
            do {
                let url = try await SettingsManager.shared.exportData()
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                present(activityVC, animated: true)
            } catch {
                ToastView.failure("导出失败：\(error.localizedDescription)")
            }
        }
    }
    
    private func importData() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    private func openFeedbackMail() {
        if let url = URL(string: "mailto:feedback@example.com") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openAppStore() {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/idYOUR_APP_ID") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension SettingsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        Task {
            do {
                try await SettingsManager.shared.importData(from: url)
                ToastView.success("导入成功")
            } catch {
                ToastView.failure("导入失败：\(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Settings Models
struct SettingsSection {
    let title: String
    var items: [SettingsItem]
}

struct SettingsItem {
    let icon: String
    let iconColor: UIColor
    let title: String
    var detail: String?
    let accessoryType: SettingsAccessoryType
    var isOn: Bool = false
    
    init(icon: String, iconColor: UIColor, title: String, detail: String? = nil, accessoryType: SettingsAccessoryType, isOn: Bool = false) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.detail = detail
        self.accessoryType = accessoryType
        self.isOn = isOn
    }
}

enum SettingsAccessoryType {
    case none
    case disclosureIndicator
    case toggle
}
