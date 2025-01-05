import UIKit
import SnapKit

class ReadingSettingsViewController: BaseViewController {
    // MARK: - Properties
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = .systemGroupedBackground
        table.separatorStyle = .none
        return table
    }()
    
    private var sections: [SettingsSection] = [
        SettingsSection(title: "字体", items: [
            SettingsItem(icon: "textformat", iconColor: .systemBlue, title: "字体大小", accessoryType: .disclosureIndicator),
            SettingsItem(icon: "textformat.size", iconColor: .systemGreen, title: "行间距", accessoryType: .disclosureIndicator)
        ]),
        SettingsSection(title: "显示", items: [
            SettingsItem(icon: "text.alignleft", iconColor: .systemOrange, title: "对齐方式", accessoryType: .disclosureIndicator),
            SettingsItem(icon: "rectangle.portrait", iconColor: .systemPurple, title: "阅读宽度", accessoryType: .disclosureIndicator)
        ])
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "阅读设置"
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
extension ReadingSettingsViewController: UITableViewDataSource {
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
}

// MARK: - UITableViewDelegate
extension ReadingSettingsViewController: UITableViewDelegate {
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
extension ReadingSettingsViewController {
    private func handleSettingsTap(_ item: SettingsItem) {
        switch item.title {
        case "字体大小":
            showFontSizeSettings()
        case "行间距":
            showLineSpacingSettings()
        case "对齐方式":
            showAlignmentSettings()
        case "阅读宽度":
            showWidthSettings()
        default:
            break
        }
    }
    
    private func showFontSizeSettings() {
        let alert = UIAlertController(title: "字体大小", message: nil, preferredStyle: .actionSheet)
        
        let sizes = [14, 16, 18, 20, 22]
        let currentSize = Int(SettingsManager.shared.fontSize)
        
        for size in sizes {
            let action = UIAlertAction(title: "\(size)pt" + (size == currentSize ? " ✓" : ""), style: .default) { [weak self] _ in
                SettingsManager.shared.fontSize = CGFloat(size)
                self?.tableView.reloadData()
                NotificationCenter.default.post(name: NSNotification.Name("FontSizeChanged"), object: nil)
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showLineSpacingSettings() {
        // TODO: 实现行间距设置
    }
    
    private func showAlignmentSettings() {
        // TODO: 实现对齐方式设置
    }
    
    private func showWidthSettings() {
        // TODO: 实现阅读宽度设置
    }
} 