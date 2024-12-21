import Foundation

struct Genre: Codable {
    let id: Int
    let name: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case id = "genreId"
        case name
        case url
    }
} 