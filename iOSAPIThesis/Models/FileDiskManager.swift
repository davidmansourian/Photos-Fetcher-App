//
//  FileDiskManager.swift
//  iOSAPIThesis
//
//  Created by David Mansourian on 2024-03-16.
//

import Foundation

struct FileDiskManager {
    private let manager = FileManager.default

    public func writeData(_ data: Data, in directory: Directory, fileName: String) -> URL? {
        let documentsURL = URL.documentsDirectory
        let customFolderURL = documentsURL.appending(path: directory.name)
        
        let fileURL = customFolderURL.appending(path: sanitzedFileName(fileName))
        
        do {
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
            return fileURL
        } catch {
            print("Failed writing to directory \(directory.name): \(error.localizedDescription)")
            return nil
        }
    }
    
    public func getFileURL(from path: Directory, for fileName: String) -> URL? {
        let documentsURL = URL.documentsDirectory
        let customFolderURL = documentsURL.appending(path: path.name)
        let fileURL = customFolderURL.appending(path: sanitzedFileName(fileName))
        
        return manager.fileExists(atPath: fileURL.path()) ? fileURL : nil
    }
    
    public func createDirectoryIfNeeded(_ directory: Directory) {
        let documentsURL = URL.documentsDirectory
        let customFolderURL = documentsURL.appending(path: directory.name)
        
        if !manager.fileExists(atPath: customFolderURL.path()) {
            do {
                try manager.createDirectory(at: customFolderURL, withIntermediateDirectories: false)
            } catch {
                print("Error when creating directory: \(error.localizedDescription)")
            }
        } else {
            print("Directory \(directory.name) already exists. Skipping creation.")
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
