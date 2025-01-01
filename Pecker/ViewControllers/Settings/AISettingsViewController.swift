import UIKit

class AISettingsViewController: BaseViewController {
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(SettingCell.self, forCellReuseIdentifier: "SettingCell")
        tableView.backgroundColor = .systemGroupedBackground
        return tableView
    }()
    
    private enum Section: Int, CaseIterable {
        case provider
        case apiKeys
        
        var title: String {
            switch self {
            case .provider: return LocalizedString("settings.ai.provider")
            case .apiKeys: return LocalizedString("settings.ai.api_key")
            }
        }
    }
    
    private enum Row {
        case provider
        case openAIKey
        case deepSeekKey
    }
    
    private let sections: [(Section, [Row])] = [
        (.provider, [.provider]),
        (.apiKeys, [.openAIKey, .deepSeekKey])
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = LocalizedString("settings.ai")
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func showProviderPicker() {
        let alert = UIAlertController(
            title: LocalizedString("settings.ai.provider"),
            message: nil,
            preferredStyle: .actionSheet
        )
        
        AIService.AIProvider.allCases.forEach { provider in
            alert.addAction(UIAlertAction(title: LocalizedString("settings.ai.\(provider.rawValue.lowercased())"), style: .default) { [weak self] _ in
                UserDefaults.standard.set(provider.rawValue, forKey: "DefaultAIProvider")
                self?.tableView.reloadData()
            })
        }
        
        alert.addAction(UIAlertAction(title: LocalizedString("cancel"), style: .cancel))
        present(alert, animated: true)
    }
    
    private func showAPIKeyInput(for provider: AIService.AIProvider) {
        let alert = UIAlertController(
            title: "\(LocalizedString("settings.ai.\(provider.rawValue.lowercased())")) \(LocalizedString("settings.ai.api_key"))",
            message: LocalizedString("settings.ai.api_key.message"),
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "API Key"
            textField.isSecureTextEntry = true
            if let key = UserDefaults.standard.string(forKey: "\(provider.rawValue)Key") {
                textField.text = key
            }
        }
        
        alert.addAction(UIAlertAction(title: LocalizedString("ok"), style: .default) { [weak self] _ in
            if let key = alert.textFields?.first?.text {
                UserDefaults.standard.set(key, forKey: "\(provider.rawValue)Key")
                self?.tableView.reloadData()
            }
        })
        
        alert.addAction(UIAlertAction(title: LocalizedString("cancel"), style: .cancel))
        present(alert, animated: true)
    }
}

extension AISettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].1.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].0.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
        let row = sections[indexPath.section].1[indexPath.row]
        
        switch row {
        case .provider:
            cell.textLabel?.text = LocalizedString("settings.ai.provider")
            if let provider = UserDefaults.standard.string(forKey: "DefaultAIProvider") {
                cell.detailTextLabel?.text = LocalizedString("settings.ai.\(provider.lowercased())")
            } else {
                cell.detailTextLabel?.text = LocalizedString("settings.ai.\(AIService.AIProvider.default.rawValue.lowercased())")
            }
            cell.accessoryType = .disclosureIndicator
            
        case .openAIKey:
            cell.textLabel?.text = "\(LocalizedString("settings.ai.openai")) \(LocalizedString("settings.ai.api_key"))"
            if UserDefaults.standard.string(forKey: "OpenAIKey") != nil {
                cell.detailTextLabel?.text = LocalizedString("settings.ai.api_key.set")
            } else {
                cell.detailTextLabel?.text = LocalizedString("settings.ai.api_key.not_set")
            }
            cell.accessoryType = .disclosureIndicator
            
        case .deepSeekKey:
            cell.textLabel?.text = "\(LocalizedString("settings.ai.deepseek")) \(LocalizedString("settings.ai.api_key"))"
            if UserDefaults.standard.string(forKey: "DeepSeekKey") != nil {
                cell.detailTextLabel?.text = LocalizedString("settings.ai.api_key.set")
            } else {
                cell.detailTextLabel?.text = LocalizedString("settings.ai.api_key.not_set")
            }
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = sections[indexPath.section].1[indexPath.row]
        switch row {
        case .provider:
            showProviderPicker()
        case .openAIKey:
            showAPIKeyInput(for: .openAI)
        case .deepSeekKey:
            showAPIKeyInput(for: .deepSeek)
        }
    }
} 