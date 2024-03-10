//
//  Photo.swift
//  iOSAPIThesis
//
//  Created by David Mansourian on 2024-03-02.
//

import Foundation

struct Photo: Decodable, Equatable, Identifiable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let downloadUrl: String
    let imageData: Data?
    
    enum CodingKeys: String, CodingKey {
        case id, author
        case width, height
        case imageData
        case downloadUrl = "download_url"
    }
}
