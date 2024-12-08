//import CloudKit
//import RealmSwift
//
//actor CloudKitService {
//    static let shared = CloudKitService()
//    
//    private let container = CKContainer.default()
//    private let database: CKDatabase
//    private let zoneID = CKRecordZone.ID(zoneName: "PeckerZone")
//    
//    private enum RecordType {
//        static let feed = "Feed"
//    }
//    
//    private init() {
//        database = container.privateCloudDatabase
//    }
//    
//    // MARK: - Zone Management
//    private func setupZone() async throws {
//        let zone = CKRecordZone(zoneID: zoneID)
//        let configuration = CKOperation.Configuration()
//        configuration.timeoutIntervalForRequest = 10
//        
//        let modifyOperation = CKModifyRecordZonesOperation(
//            recordZonesToSave: [zone],
//            recordZoneIDsToDelete: nil
//        )
//        modifyOperation.configuration = configuration
//        modifyOperation.modifyRecordZonesResultBlock = { result in
//            switch result {
//            case .success:
//                print("Zone created successfully")
//            case .failure(let error):
//                print("Failed to create zone: \(error)")
//            }
//        }
//        
//        database.add(modifyOperation)
//    }
//    
//    // MARK: - Sync Management
//    func startSync() async throws {
//        try await setupZone()
//        try await syncFeeds()
//    }
//    
//    // MARK: - Feed Sync
//    private func syncFeeds() async throws {
//        let realm = try await Realm()
//        let localFeeds = realm.objects(Feed.self).filter("isDeleted == false")
//        
//        // 获取云端 Feed URLs
//        let query = CKQuery(recordType: RecordType.feed, predicate: NSPredicate(value: true))
//        let result = try await database.records(matching: query, inZoneWith: zoneID, desiredKeys: ["url"])
//        
//        // 上传本地新增的 Feed URLs
//        for feed in localFeeds {
//            let exists = try await result.matchResults.contains { matchResult in
//                if case .success(let record) = try matchResult.1.get() {
//                    return record.recordID.recordName == feed.id
//                }
//                return false
//            }
//            
//            if !exists {
//                try await uploadFeed(feed)
//            }
//        }
//        
//        // 导入云端新增的 Feed URLs
//        for matchResult in result.matchResults {
//            do {
//                if case .success(let record) = try matchResult.1.get(),
//                   let url = record["url"] as? String {
//                    // 检查本地是否已存在该 URL
//                    if realm.objects(Feed.self).filter("url == %@", url).first == nil {
//                        // 使用 RSSService 导入新的 Feed
//                        try await RSSService.shared.addNewFeed(url: url)
//                    }
//                }
//            } catch {
//                print("Error processing cloud record: \(error)")
//                continue
//            }
//        }
//    }
//    
//    private func uploadFeed(_ feed: Feed) async throws {
//        let record = CKRecord(recordType: RecordType.feed, recordID: CKRecord.ID(recordName: feed.id, zoneID: zoneID))
//        record["url"] = feed.url
//        
//        let configuration = CKOperation.Configuration()
//        configuration.timeoutIntervalForRequest = 10
//        
//        let modifyOperation = CKModifyRecordsOperation(
//            recordsToSave: [record],
//            recordIDsToDelete: nil
//        )
//        modifyOperation.configuration = configuration
//        modifyOperation.modifyRecordsResultBlock = { result in
//            switch result {
//            case .success:
//                print("Feed uploaded successfully")
//            case .failure(let error):
//                print("Failed to upload feed: \(error)")
//            }
//        }
//        
//        database.add(modifyOperation)
//    }
//    
//    // MARK: - Subscription Management
//    func setupSubscriptions() async throws {
//        let subscription = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: "feed-changes")
//        let notificationInfo = CKSubscription.NotificationInfo()
//        notificationInfo.shouldSendContentAvailable = true
//        subscription.notificationInfo = notificationInfo
//        
//        let operation = CKModifySubscriptionsOperation(
//            subscriptionsToSave: [subscription],
//            subscriptionIDsToDelete: nil
//        )
//        operation.modifySubscriptionsResultBlock = { result in
//            switch result {
//            case .success:
//                print("Subscription setup successfully")
//            case .failure(let error):
//                print("Failed to setup subscription: \(error)")
//            }
//        }
//        
//        database.add(operation)
//    }
//    
//    // MARK: - Error Handling
//    private func handleCloudKitError(_ error: Error) async throws {
//        if let cloudError = error as? CKError {
//            switch cloudError.code {
//            case .zoneNotFound, .userDeletedZone:
//                try await setupZone()
//            case .quotaExceeded:
//                throw CloudKitError.quotaExceeded
//            case .networkFailure, .networkUnavailable:
//                throw CloudKitError.networkError
//            case .serverResponseLost, .serviceUnavailable:
//                throw CloudKitError.serverError
//            default:
//                throw error
//            }
//        }
//    }
//}
//
//// MARK: - Custom Errors
//enum CloudKitError: LocalizedError {
//    case quotaExceeded
//    case networkError
//    case serverError
//    
//    var errorDescription: String? {
//        switch self {
//        case .quotaExceeded:
//            return "iCloud 存储空间已满"
//        case .networkError:
//            return "网络连接失败"
//        case .serverError:
//            return "服务器暂时不可用"
//        }
//    }
//}
