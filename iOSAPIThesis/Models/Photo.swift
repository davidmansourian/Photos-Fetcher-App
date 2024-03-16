//
//  Photo.swift
//  iOSAPIThesis
//
//  Created by David Mansourian on 2024-03-02.
//

import Foundation

struct Photo: Decodable, Equatable, Identifiable {
    let id: String
    let downloadUrl: String
    let localImageUrl: URL?
    
    enum CodingKeys: String, CodingKey {
        case id
        case downloadUrl = "download_url"
        case localImageUrl
    }
}
