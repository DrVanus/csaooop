import Foundation
import CryptoKit

class ThreeCommasService {
    static let shared = ThreeCommasService()
    
    private let baseURL = "https://api.3commas.io/public/api"
    
    /// Creates a URLRequest for a given endpoint and query items, using either the read-only or trading keys.
    private func createRequest(endpoint: String, queryItems: [URLQueryItem], useTradingKey: Bool) -> URLRequest? {
        guard var components = URLComponents(string: baseURL + endpoint) else { return nil }
        components.queryItems = queryItems
        guard let url = components.url else { return nil }
        
        // Choose keys based on whether this action requires write access.
        let apiKey = useTradingKey ? ThreeCommasConfig.tradingAPIKey : ThreeCommasConfig.readOnlyAPIKey
        let secret = useTradingKey ? ThreeCommasConfig.tradingSecret : ThreeCommasConfig.readOnlySecret
        
        // Generate HMAC signature based on the query string.
        let queryString = components.percentEncodedQuery ?? ""
        let signature = hmacSignature(for: queryString, secret: secret)
        
        // Configure the request.
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "APIKEY")
        request.setValue(signature, forHTTPHeaderField: "Signature")
        return request
    }
    
    /// Lists all connected accounts.
    func listAccounts(completion: @escaping (Result<Any, Error>) -> Void) {
        let endpoint = "/ver1/accounts"
        let queryItems: [URLQueryItem] = []
        
        guard let request = createRequest(endpoint: endpoint, queryItems: queryItems, useTradingKey: false) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        performRequest(request: request, completion: completion)
    }
    
    /// Loads balances for a given account.
    func loadAccountBalances(accountId: Int, completion: @escaping (Result<Any, Error>) -> Void) {
        let endpoint = "/ver1/accounts/\(accountId)/load_balances"
        let queryItems: [URLQueryItem] = []
        
        guard let request = createRequest(endpoint: endpoint, queryItems: queryItems, useTradingKey: false) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        performRequest(request: request, completion: completion)
    }
    
    /// Example: Start a bot (requires trading key for write access).
    func startBot(botId: Int, completion: @escaping (Result<Any, Error>) -> Void) {
        let endpoint = "/ver1/bots/\(botId)/start"
        let queryItems: [URLQueryItem] = []
        
        guard let request = createRequest(endpoint: endpoint, queryItems: queryItems, useTradingKey: true) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        performRequest(request: request, completion: completion)
    }
    
    /// Generic network request performer.
    private func performRequest(request: URLRequest, completion: @escaping (Result<Any, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data returned", code: -1, userInfo: nil)))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                completion(.success(json))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    /// Helper: Generate an HMAC SHA-256 signature.
    private func hmacSignature(for queryString: String, secret: String) -> String {
        let key = SymmetricKey(data: secret.data(using: .utf8)!)
        let data = queryString.data(using: .utf8)!
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: key)
        return signature.map { String(format: "%02x", $0) }.joined()
    }
}
