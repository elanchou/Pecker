import UIKit
import SnapKit

class QuickNavigationView: UIView {
    // MARK: - Properties
    var dates: [String] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var onDateSelected: ((Int) -> Void)?
    
    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: 30, height: 30)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.register(DateCell.self, forCellWithReuseIdentifier: "DateCell")
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - UICollectionViewDataSource
extension QuickNavigationView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dates.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DateCell", for: indexPath) as! DateCell
        cell.configure(with: dates[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension QuickNavigationView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onDateSelected?(indexPath.item)
    }
}

// MARK: - DateCell
private class DateCell: UICollectionViewCell {
    // MARK: - UI Components
    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Configuration
    func configure(with date: String) {
        label.text = date
    }
    
    override var isSelected: Bool {
        didSet {
            label.textColor = isSelected ? .systemBlue : .secondaryLabel
            label.font = isSelected ? .systemFont(ofSize: 12, weight: .medium) : .systemFont(ofSize: 12)
        }
    }
} 