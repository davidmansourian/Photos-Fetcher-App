//
//  Photo.swift
//  iOSAPIThesis
//
//  Created by David Mansourian on 2024-03-02.
//

import Foundation

struct Photo: Decodable {
    let downloadUrl: String
    
    enum CodingKeys: String, CodingKey {
        case downloadUrl = "download_url"
    }
}
