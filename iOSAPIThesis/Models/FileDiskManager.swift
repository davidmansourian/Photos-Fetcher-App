//
//  FileDiskManager.swift
//  iOSAPIThesis
//
//  Created by David Mansourian on 2024-03-16.
//

import Foundation

struct FileDiskManager {
    private let manager = FileManager.default
    
    public func write(_ data: Data, in directory: Directory, fileName: String) -> URL? {
        let documentsUrl = URL.documentsDirectory
        let customFolderUrl = documentsUrl.appending(path: directory.name)
        
        let fileUrl = customFolderUrl.appending(path: sanitzedFileName(fileName))
        
        do {
            try data.write(to: fileUrl, options: [.atomic, .completeFileProtection])
            return fileUrl
        } catch {
            print("Failed writing to directory '\(directory.name)': \(error.localizedDescription)")
            return nil
        }
    }
    
    public func getFileURL(from directory: Directory, for fileName: String) -> URL? {
        let documentsUrl = URL.documentsDirectory
        let customFolderUrl = documentsUrl.appending(path: directory.name)
        let fileUrl = customFolderUrl.appending(path: sanitzedFileName(fileName))
        
        return manager.fileExists(atPath: fileUrl.path()) ? fileUrl : nil
    }
    
    public func createDirectoryIfNeeded(_ directory: Directory) {
        let documentsUrl = URL.documentsDirectory
        let customFolderUrl = documentsUrl.appending(path: directory.name)
        
        if !manager.fileExists(atPath: customFolderUrl.path()) {
            do {
                try manager.createDirectory(at: customFolderUrl, withIntermediateDirectories: false)
            } catch {
                print("Error when creating directory '\(directory.name)': \(error.localizedDescription)")
            }
        } else {
            print("Directory '\(directory.name)' already exists. Skipping creation.")
        }
    }
    
    private func sanitzedFileName(_ fileName: String) -> String {
        fileName
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "/", with: "_")
    }
}

extension FileDiskManager {
    enum Directory {
        case appPhotos
        
        var name: String {
            switch self {
            case .appPhotos:
                "AppPhotos"
            }
        }
    }
}
