//
//  APIService.swift
//  iOSAPIThesis
//
//  Created by David Mansourian on 2024-03-02.
//

import Foundation

struct APIService {
    public func fetchPhotosList(from endpoint: String) async throws -> [Photo] {
        try await fetch(as: [Photo].self, from: endpoint)
    }
    
    public func fetchPhoto(from endpoint: String) async throws -> Data {
        try await fetch(as: Data.self, from: endpoint)
    }
}

extension APIService {
    private func fetch<T: Decodable>(as type: T.Type, from endpoint: String) async throws -> T {
        guard let url = URL(string: endpoint) else { throw APIError.badURL }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            try validateResponse(response)
            
            if type != Data.self {
                return try JSONDecoder().decode(type, from: data)
            }
            
            guard let rawData = data as? T else { throw APIError.invalidData("Unknown data") }
            
            return rawData
        } catch {
            throw error
        }
    }
    
    private func validateResponse(_ response: URLResponse?) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.badServerResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.invalidStatusCode(httpResponse.statusCode)
        }
    }
}

extension APIService {
    enum APIError: LocalizedError {
        case badURL, badServerResponse
        case invalidStatusCode(Int)
        case invalidData(String)
        
        public var errorDescription: String? {
            switch self {
            case .badURL:
                return "Bad URL."
            case .badServerResponse:
                return "Bad server response."
            case .invalidData(let error):
                return "Couldn't validate data: \(error)"
            case .invalidStatusCode(let statusCode):
                return "Invalid status code: \(statusCode)."
            }
        }
    }
}
