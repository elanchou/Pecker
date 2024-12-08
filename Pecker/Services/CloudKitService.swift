//import CloudKit
//import Foundation
//import RealmSwift
//
//actor CloudKitService {
//    private let container: CKContainer
//    private let database: CKDatabase
//    
//    init(container: CKContainer = .default()) {
//        self.container = container
//        self.database = container.privateCloudDatabase
//    }
//    
//    // MARK: - Feed Sync
//    
//    func syncFeeds(_ feeds: [Feed]) async throws {
//        let operation = CKModifyRecordsOperation()
//        
//        let records = feeds.compactMap { feed -> CKRecord? in
//            guard let cloudID = feed.cloudID else {
//                let record = CKRecord(recordType: "Feed")
//                record["id"] = feed.id
//                record["title"] = feed.title
//                record["url"] = feed.url
//                record["iconURL"] = feed.iconURL
//                record["category"] = feed.category
//                record["unreadCount"] = feed.unreadCount
//                record["lastUpdated"] = feed.lastUpdated
//                return record
//            }
//            
//            guard let record = try? await database.record(for: CKRecord.ID(recordName: cloudID)) else {
//                return nil
//            }
//            
//            record["title"] = feed.title
//            record["url"] = feed.url
//            record["iconURL"] = feed.iconURL
//            record["category"] = feed.category
//            record["unreadCount"] = feed.unreadCount
//            record["lastUpdated"] = feed.lastUpdated
//            
//            return record
//        }
//        
//        operation.recordsToSave = records
//        operation.savePolicy = .changedKeys
//        
//        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
//            operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
//                if let error = error {
//                    continuation.resume(throwing: error)
//                    return
//                }
//                
//                // 更新本地 Feed 的 cloudID
//                if let savedRecords = savedRecords {
//                    Task {
//                        let realm = try await Realm()
//                        try await MainActor.run {
//                            try realm.write {
//                                for record in savedRecords {
//                                    if let feedId = record["id"] as? String,
//                                       let feed = realm.object(ofType: Feed.self, forPrimaryKey: feedId) {
//                                        feed.cloudID = record.recordID.recordName
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//                
//                continuation.resume()
//            }
//            
//            database.add(operation)
//        }
//    }
//    
//    // MARK: - Article Sync
//    
//    func syncArticles(_ articles: [Article]) async throws {
//        let operation = CKModifyRecordsOperation()
//        
//        let records = try await withThrowingTaskGroup(of: CKRecord?.self) { group in
//            for article in articles {
//                group.addTask {
//                    await self.createOrUpdateArticleRecord(article)
//                }
//            }
//            
//            var results: [CKRecord] = []
//            for try await record in group {
//                if let record = record {
//                    results.append(record)
//                }
//            }
//            return results
//        }
//        
//        operation.recordsToSave = records
//        operation.savePolicy = .changedKeys
//        
//        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
//            operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
//                if let error = error {
//                    continuation.resume(throwing: error)
//                    return
//                }
//                continuation.resume()
//            }
//            
//            database.add(operation)
//        }
//    }
//    
//    private func createOrUpdateArticleRecord(_ article: Article) async -> CKRecord? {
//        guard let feed = article.feed.first,
//              let feedCloudID = feed.cloudID else {
//            return nil
//        }
//        
//        let record: CKRecord
//        if let cloudID = article.cloudID,
//           let existingRecord = try? await database.record(for: CKRecord.ID(recordName: cloudID)) {
//            record = existingRecord
//        } else {
//            record = CKRecord(recordType: "Article")
//            record["id"] = article.id
//        }
//        
//        record["title"] = article.title
//        record["content"] = article.content
//        record["url"] = article.url
//        record["publishDate"] = article.publishDate
//        record["summary"] = article.summary
//        record["aiSummary"] = article.aiSummary
//        record["isRead"] = article.isRead
//        record["isFavorite"] = article.isFavorite
//        record["imageURLs"] = article.imageURLs.map { $0 }
//        
//        let feedReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: feedCloudID),
//                                             action: .deleteSelf)
//        record["feed"] = feedReference
//        
//        return record
//    }
//    
//    // MARK: - Fetch Data
//    
//    func fetchFeeds() async throws -> [Feed] {
//        let query = CKQuery(recordType: "Feed", predicate: NSPredicate(value: true))
//        query.sortDescriptors = [NSSortDescriptor(key: "lastUpdated", ascending: false)]
//        
//        let (matchResults, _) = try await database.records(matching: query)
//        let records = try matchResults.compactMap { try $0.1.get() }
//        
//        return try await withThrowingTaskGroup(of: Feed?.self) { group in
//            for record in records {
//                group.addTask {
//                    await self.createOrUpdateFeed(from: record)
//                }
//            }
//            
//            var feeds: [Feed] = []
//            for try await feed in group {
//                if let feed = feed {
//                    feeds.append(feed)
//                }
//            }
//            return feeds
//        }
//    }
//    
//    private func createOrUpdateFeed(from record: CKRecord) async -> Feed? {
//        guard let id = record["id"] as? String else { return nil }
//        
//        let realm = try? await Realm()
//        let feed = realm?.object(ofType: Feed.self, forPrimaryKey: id) ?? Feed()
//        
//        await MainActor.run {
//            try? realm?.write {
//                feed.id = id
//                feed.title = record["title"] as? String ?? ""
//                feed.url = record["url"] as? String ?? ""
//                feed.iconURL = record["iconURL"] as? String
//                feed.category = record["category"] as? String
//                feed.unreadCount = record["unreadCount"] as? Int ?? 0
//                feed.lastUpdated = record["lastUpdated"] as? Date ?? Date()
//                feed.cloudID = record.recordID.recordName
//                
//                if let realm = realm, realm.object(ofType: Feed.self, forPrimaryKey: id) == nil {
//                    realm.add(feed)
//                }
//            }
//        }
//        
//        return feed
//    }
//}
