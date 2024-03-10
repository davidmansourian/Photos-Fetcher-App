//
//  APIService.swift
//  iOSAPIThesis
//
//  Created by David Mansourian on 2024-03-02.
//

import Foundation

final class APIService {
    public func fetchPhotosList(from endpoint: String) async throws -> [Photo] {
        return try await fetchData(as: [Photo].self, from: endpoint)
    }
    
    public func fetchPhoto(from endpoint: String) async throws -> Data {
        return try await fetchData(as: Data.self, from: endpoint)
    }
}

extension APIService {
    private func fetchData<T: Decodable>(as type: T.Type, from endpoint: String) async throws -> T {
        guard let url = URL(string: endpoint) else { throw APIError.badURL }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            try validateResponse(response)
            
            guard let validatedData = try validateData(for: type, from: data) else { throw APIError.invalidData }
            
            return validatedData
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
    
    private func validateData<T: Decodable>(for type: T.Type, from data: Data) throws -> T? {
        if type == [Photo].self {
            do {
                return try JSONDecoder().decode(type, from: data)
            } catch {
                throw APIError.invalidData
            }
        } else {
            return data as? T
        }
    }
}

extension APIService {
    enum APIError: Error {
        case badURL, badServerResponse, invalidData
        case invalidStatusCode(Int)
        
        public var customDescription: String {
            switch self {
            case .badURL:
                return "Bad URL."
            case .badServerResponse:
                return "Bad server response."
            case .invalidData:
                return "Couldn't validate data."
            case .invalidStatusCode(let statusCode):
                return "Invalid status code: \(statusCode)."
            }
        }
    }
}
