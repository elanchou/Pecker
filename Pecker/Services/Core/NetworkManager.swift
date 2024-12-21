import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(Error)
    case decodingFailed(Error)
    case serverError(Int, String)
    case noData
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "无效的响应"
        case .requestFailed(let error):
            return "请求失败: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "解码失败: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "服务器错误 (\(code)): \(message)"
        case .noData:
            return "没有数据"
        }
    }
}

actor NetworkManager {
    static let shared = NetworkManager()
    private let session: URLSession
    private let logger: Logger
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config)
        logger = Logger(subsystem: "com.elanchou.pecker", category: "network")
    }
    
    func request<T: Decodable>(_ endpoint: String,
                              baseURL: String,
                              method: String = "GET",
                              headers: [String: String]? = nil,
                              queryItems: [URLQueryItem]? = nil,
                              body: Data? = nil) async throws -> T {
        
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            logger.error("Invalid URL: \(baseURL + endpoint)")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        
        // Log request
        logger.info("[\(method)] \(url.absoluteString)")
        if let headers = headers {
            logger.debug("Headers: \(headers)")
        }
        if let body = body, let bodyString = String(data: body, encoding: .utf8) {
            logger.debug("Body: \(bodyString)")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Log response
            if let httpResponse = response as? HTTPURLResponse {
                logger.info("Response [\(httpResponse.statusCode)] \(url.absoluteString)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                    logger.error("Server error: \(responseString)")
                    throw NetworkError.serverError(httpResponse.statusCode, responseString)
                }
            }
            
            logger.debug("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } catch {
                logger.error("Decoding error: \(error)")
                throw NetworkError.decodingFailed(error)
            }
        } catch {
            logger.error("Request failed: \(error)")
            throw NetworkError.requestFailed(error)
        }
    }
    
    func requestData(_ endpoint: String,
                    baseURL: String,
                    method: String = "GET",
                    headers: [String: String]? = nil,
                    queryItems: [URLQueryItem]? = nil,
                    body: Data? = nil) async throws -> Data {
        
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            logger.error("Invalid URL: \(baseURL + endpoint)")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        
        // Log request
        logger.info("[\(method)] \(url.absoluteString)")
        if let headers = headers {
            logger.debug("Headers: \(headers)")
        }
        if let body = body, let bodyString = String(data: body, encoding: .utf8) {
            logger.debug("Body: \(bodyString)")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Log response
            if let httpResponse = response as? HTTPURLResponse {
                logger.info("Response [\(httpResponse.statusCode)] \(url.absoluteString)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                    logger.error("Server error: \(responseString)")
                    throw NetworkError.serverError(httpResponse.statusCode, responseString)
                }
            }
            
            logger.debug("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
            return data
        } catch {
            logger.error("Request failed: \(error)")
            throw NetworkError.requestFailed(error)
        }
    }
} 