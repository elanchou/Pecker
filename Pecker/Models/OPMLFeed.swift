import Foundation

struct OPMLFeed: Codable {
    let title: String?
    let xmlUrl: String?
    let htmlUrl: String?
    let description: String?
    let category: String?
    let language: String?
    
    enum CodingKeys: String, CodingKey {
        case title = "text"
        case xmlUrl
        case htmlUrl
        case description
        case category
        case language
    }
}

struct OPMLOutline: Codable {
    var title: String
    var feeds: [OPMLFeed]
    
    enum CodingKeys: String, CodingKey {
        case title = "text"
        case feeds = "outline"
    }
}

struct OPMLDocument: Codable {
    let head: OPMLHead
    let body: OPMLBody
    
    enum CodingKeys: String, CodingKey {
        case head
        case body
    }
}

struct OPMLHead: Codable {
    let title: String
    let dateCreated: String?
    let dateModified: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case dateCreated
        case dateModified
    }
}

struct OPMLBody: Codable {
    let outlines: [OPMLOutline]
    
    enum CodingKeys: String, CodingKey {
        case outlines = "outline"
    }
} 
