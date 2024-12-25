import UIKit
import CloudKit

class SettingsViewController: BaseViewController {
    // MARK: - Properties
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = .systemGroupedBackground
        table.separatorStyle = .none
        return table
    }()
    
    private var sections: [(title: String, rows: [SettingsRow])] = []
    private var iCloudSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "iCloudSync") }
        set { UserDefaults.standard.set(newValue, forKey: "iCloudSync") }
    }
    
    private var syncStatus: String = LocalizedString("loading") {
        didSet {
            if let indexPath = getIndexPath(for: .syncStatus) {
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSections()
        checkSyncStatus()
        
        // 监听语言变化
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(languageDidChange),
                                            name: Notification.Name("LanguageDidChange"),
                                            object: nil)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = LocalizedString("tab.settings")
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SettingCell.self, forCellReuseIdentifier: "SettingCell")
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
            (LocalizedString("settings.icloud"), [
                .iCloudSync,
                .syncStatus
            ]),
            (LocalizedString("settings.today_summary"), [
                .todaySummaryEnabled,
                .todaySummaryUpdateTime,
                .todaySummaryFrequency
            ]),
            (LocalizedString("settings.about"), [
                .version,
            ]),
            ("", [
                .copyright
            ]),
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
                    self?.syncStatus = LocalizedString("settings.icloud.connected")
                case .noAccount:
                    self?.syncStatus = LocalizedString("settings.icloud.no_account")
                case .restricted:
                    self?.syncStatus = LocalizedString("settings.icloud.restricted")
                case .couldNotDetermine:
                    self?.syncStatus = LocalizedString("settings.icloud.unknown")
                case .temporarilyUnavailable:
                    self?.syncStatus = LocalizedString("settings.icloud.unavailable")
                @unknown default:
                    self?.syncStatus = LocalizedString("settings.icloud.unknown")
                }
            }
        }
    }
    
    @objc private func languageDidChange() {
        title = LocalizedString("tab.settings")
        setupSections()
        tableView.reloadData()
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
        return sections[section].title.isEmpty ? nil : sections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
        let row = sections[indexPath.section].rows[indexPath.row]
        
        switch row {
        case .iCloudSync:
            cell.configure(with: Setting(
                icon: "icloud",
                iconBackgroundColor: .systemBlue,
                title: LocalizedString("settings.icloud.enable"),
                subtitle: nil,
                action: nil
            ))
            let toggle = UISwitch()
            toggle.isOn = iCloudSyncEnabled
            toggle.addTarget(self, action: #selector(iCloudSyncToggled), for: .valueChanged)
            cell.accessoryView = toggle
            
        case .syncStatus:
            cell.configure(with: Setting(
                icon: "arrow.triangle.2.circlepath",
                iconBackgroundColor: .systemGreen,
                title: LocalizedString("settings.icloud.status"),
                subtitle: syncStatus,
                action: nil
            ))
            
        case .todaySummaryEnabled:
            cell.configure(with: Setting(
                icon: "newspaper",
                iconBackgroundColor: .systemIndigo,
                title: LocalizedString("settings.today_summary.enabled"),
                subtitle: nil,
                action: nil
            ))
            let toggle = UISwitch()
            toggle.isOn = TodaySummaryManager.shared.isEnabled
            toggle.addTarget(self, action: #selector(todaySummaryToggled), for: .valueChanged)
            cell.accessoryView = toggle
            
        case .todaySummaryUpdateTime:
            cell.configure(with: Setting(
                icon: "clock",
                iconBackgroundColor: .systemOrange,
                title: LocalizedString("settings.today_summary.update_time"),
                subtitle: String(format: "%02d:00", TodaySummaryManager.shared.updateTime),
                action: nil
            ))
            
        case .todaySummaryFrequency:
            cell.configure(with: Setting(
                icon: "timer",
                iconBackgroundColor: .systemPurple,
                title: LocalizedString("settings.today_summary.frequency"),
                subtitle: "\(TodaySummaryManager.shared.showFrequency) " + LocalizedString("settings.today_summary.hours"),
                action: nil
            ))
            
        case .version:
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            cell.configure(with: Setting(
                icon: "info.circle",
                iconBackgroundColor: .systemGray,
                title: LocalizedString("settings.version"),
                subtitle: version,
                action: nil
            ))
            
        case .copyright:
            cell.configure(with: Setting(
                icon: "c.circle",
                iconBackgroundColor: .systemGray2,
                title: "© 2024 Pecker",
                subtitle: nil,
                action: nil
            ))
        case .buildVersion:
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            cell.configure(with: Setting(
                icon: "info.circle",
                iconBackgroundColor: .systemGray,
                title: LocalizedString("settings.version"),
                subtitle: version,
                action: nil
            ))
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sections[section].title.isEmpty ? 0 : 40
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !sections[section].title.isEmpty else { return nil }
        
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.text = sections[section].title
        
        headerView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        
        return headerView
    }
    
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
        let alert = UIAlertController(
            title: LocalizedString("settings.today_summary.update_time"),
            message: LocalizedString("settings.today_summary.update_time.message"),
            preferredStyle: .actionSheet
        )
        
        for hour in 0...23 {
            let action = UIAlertAction(title: String(format: "%02d:00", hour), style: .default) { [weak self] _ in
                TodaySummaryManager.shared.updateTime = hour
                self?.tableView.reloadData()
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: LocalizedString("cancel"), style: .cancel))
        present(alert, animated: true)
    }
    
    private func showFrequencyPickerAlert() {
        let alert = UIAlertController(
            title: LocalizedString("settings.today_summary.frequency"),
            message: LocalizedString("settings.today_summary.frequency.message"),
            preferredStyle: .actionSheet
        )
        
        let frequencies = [6, 12, 24, 48, 72]
        for hours in frequencies {
            let action = UIAlertAction(
                title: "\(hours) " + LocalizedString("settings.today_summary.hours"),
                style: .default
            ) { [weak self] _ in
                TodaySummaryManager.shared.showFrequency = hours
                self?.tableView.reloadData()
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: LocalizedString("cancel"), style: .cancel))
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
