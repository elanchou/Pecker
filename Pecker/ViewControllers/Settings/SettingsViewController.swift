import UIKit
import CloudKit

class SettingsViewController: BaseViewController {
    // MARK: - Properties
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        return table
    }()
    
    private var sections: [(title: String, rows: [SettingsRow])] = []
    private var iCloudSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "iCloudSync") }
        set { UserDefaults.standard.set(newValue, forKey: "iCloudSync") }
    }
    
    private var syncStatus: String = "正在检查..." {
        didSet {
            if let indexPath = getIndexPath(for: .syncStatus) {
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 添加表格动画
        tableView.alpha = 0
        tableView.transform = CGAffineTransform(translationX: 0, y: 20)
        
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.tableView.alpha = 1
            self.tableView.transform = .identity
        }
        
        setupUI()
        setupSections()
        checkSyncStatus()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "设置"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func setupSections() {
        sections = [
            ("iCloud 同步", [
                .iCloudSync,
                .syncStatus
            ]),
            ("关于", [
                .version,
                .buildVersion
            ]),
            ("每日总结", [
                .todaySummaryEnabled,
                .todaySummaryUpdateTime,
                .todaySummaryFrequency
            ]),
            ("", [
                .copyright
            ])
        ]
    }
    
    // MARK: - Helper Methods
    private func getIndexPath(for row: SettingsRow) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            if let rowIndex = section.rows.firstIndex(of: row) {
                return IndexPath(row: rowIndex, section: sectionIndex)
            }
        }
        return nil
    }
    
    private func checkSyncStatus() {
        CKContainer.default().accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncStatus = "错误: \(error.localizedDescription)"
                    return
                }
                
                switch status {
                case .available:
                    self?.syncStatus = "已连接"
                case .noAccount:
                    self?.syncStatus = "未登录 iCloud"
                case .restricted:
                    self?.syncStatus = "受限"
                case .couldNotDetermine:
                    self?.syncStatus = "无法确定状态"
                case .temporarilyUnavailable:
                    self?.syncStatus = "暂时不可用"
                @unknown default:
                    self?.syncStatus = "未知状态"
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let row = sections[indexPath.section].rows[indexPath.row]
        
        cell.textLabel?.textColor = .label
        cell.detailTextLabel?.textColor = .secondaryLabel
        
        switch row {
        case .iCloudSync:
            cell.textLabel?.text = "启用 iCloud 同步"
            let toggle = UISwitch()
            toggle.isOn = iCloudSyncEnabled
            toggle.addTarget(self, action: #selector(iCloudSyncToggled), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none
            
        case .syncStatus:
            cell.textLabel?.text = "同步状态"
            cell.detailTextLabel?.text = syncStatus
            cell.selectionStyle = .none
            
        case .version:
            cell.textLabel?.text = "版本"
            cell.detailTextLabel?.text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            cell.selectionStyle = .none
            
        case .buildVersion:
            cell.textLabel?.text = "构建版本"
            cell.detailTextLabel?.text = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
            cell.selectionStyle = .none
            
        case .copyright:
            cell.textLabel?.text = "© 2024 Your Name. All rights reserved."
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.font = .systemFont(ofSize: 14)
            cell.selectionStyle = .none
            
        case .todaySummaryEnabled:
            cell.textLabel?.text = "启用每日总结"
            let toggle = UISwitch()
            toggle.isOn = TodaySummaryManager.shared.isEnabled
            toggle.addTarget(self, action: #selector(todaySummaryToggled), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none
            
        case .todaySummaryUpdateTime:
            cell.textLabel?.text = "更新时间"
            cell.detailTextLabel?.text = "\(TodaySummaryManager.shared.updateTime):00"
            cell.accessoryType = .disclosureIndicator
            
        case .todaySummaryFrequency:
            cell.textLabel?.text = "显示频率"
            cell.detailTextLabel?.text = "\(TodaySummaryManager.shared.showFrequency) 小时"
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = sections[indexPath.section].rows[indexPath.row]
        switch row {
        case .todaySummaryUpdateTime:
            showTimePickerAlert()
        case .todaySummaryFrequency:
            showFrequencyPickerAlert()
        default:
            break
        }
    }
    
    private func showTimePickerAlert() {
        let alert = UIAlertController(title: "更新时间", message: "选择每日更新时间", preferredStyle: .actionSheet)
        
        for hour in 0...23 {
            let action = UIAlertAction(title: String(format: "%02d:00", hour), style: .default) { [weak self] _ in
                TodaySummaryManager.shared.updateTime = hour
                self?.tableView.reloadData()
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showFrequencyPickerAlert() {
        let alert = UIAlertController(title: "显示频率", message: "选择显示间隔时间", preferredStyle: .actionSheet)
        
        let frequencies = [6, 12, 24, 48, 72]
        for hours in frequencies {
            let action = UIAlertAction(title: "\(hours) 小时", style: .default) { [weak self] _ in
                TodaySummaryManager.shared.showFrequency = hours
                self?.tableView.reloadData()
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func todaySummaryToggled(_ sender: UISwitch) {
        TodaySummaryManager.shared.isEnabled = sender.isOn
    }
}

// MARK: - Actions
extension SettingsViewController {
    @objc private func iCloudSyncToggled(_ sender: UISwitch) {
        iCloudSyncEnabled = sender.isOn
        checkSyncStatus()
    }
}

// MARK: - Settings Row Enum
enum SettingsRow: Equatable {
    case iCloudSync
    case syncStatus
    case version
    case buildVersion
    case copyright
    case todaySummaryEnabled
    case todaySummaryUpdateTime
    case todaySummaryFrequency
} 
