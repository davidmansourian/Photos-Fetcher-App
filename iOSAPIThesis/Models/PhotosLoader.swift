//
//  LoadingHelper.swift
//  iOSAPIThesis
//
//  Created by David Mansourian on 2024-03-02.
//

import Foundation
import SwiftUI

// The images fetched are always the same (unless the list of url received from the endpoint changes), hence why I am using file manager to store and load from disk.
// Saving images to disk and loading from there before generating thumbnails saves approximately 40 MB of in app-memory. Relatively almost 50%
// The total size of the stored image data on disk is approx 22 MB. User would save approx 22 MB of data everytime they open the app.
// Whether the increased code complexity of the file manager is worth it would be interesting to discuss.

@Observable
final class PhotosLoader {
    private let apiService: APIService
    private let fileDiskManager: FileDiskManager
    private let photoThumbnailHeight: CGFloat = 200
    
    private var photos: [UIImage]?
    
    private(set) var state: State = .idle
    
    init(apiService: APIService, fileDiskManager: FileDiskManager) {
        self.apiService = apiService
        self.fileDiskManager = fileDiskManager
        
        loadContent()
    }
    
    private func loadContent() {
        state = .loading
        
        let urlString = "https://picsum.photos/v2/list"
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let photosList = try await self.apiService.fetchPhotosList(from: urlString)
                await self.createAppPhotosDirectoryIfNeeded()
                await self.loadPhotos(from: photosList)
                await self.updateUserState()
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }
    
    private func createAppPhotosDirectoryIfNeeded() async {
        fileDiskManager.createDirectoryIfNeeded(.appPhotos)
    }
    
    private func loadPhotos(from photosList: [Photo]) async {
        let photos = await withTaskGroup(of: URL?.self, returning: [UIImage]?.self) { [weak self] taskGroup in
            guard let self = self else { return nil }
            
            for photo in photosList {
                taskGroup.addTask {
                    await self.fetchAndSavePhotoIfNeeded(for: photo)
                }
            }
            
            var thumbnails: [UIImage] = []
            
            for await localPhotoUrl in taskGroup {
                if let thumbnail = thumbnailFromLocalPhotoUrl(localPhotoUrl) {
                    thumbnails.append(thumbnail)
                }
            }
            
            return thumbnails
        }
        
        self.photos = photos
    }
    
    private func fetchAndSavePhotoIfNeeded(for photo: Photo) async -> URL? {
        if let localPhotoUrl = fileDiskManager.getFileURL(from: .appPhotos, for: photo.downloadUrl) {
            return localPhotoUrl
        }
        
        guard let imageData = try? await apiService.fetchPhoto(from: photo.downloadUrl),
              let savedPhotoUrl = fileDiskManager.write(imageData, in: .appPhotos, fileName: photo.downloadUrl)
        else {
            print("Error fetching individual photo")
            return nil
        }
        
        return savedPhotoUrl
    }
    
    private func thumbnailFromLocalPhotoUrl(_ localPhotoUrl: URL?) -> UIImage? {
        guard let url = localPhotoUrl,
              let localImage = UIImage(contentsOfFile: url.path()) else {
            return nil
        }
        
        let resizedImage = localImage.aspectFittedToHeight(photoThumbnailHeight)
        resizedImage.jpegData(compressionQuality: 0.1)
        
        return resizedImage
    }
    
    @MainActor
    private func updateUserState() {
        assert(Thread.isMainThread)
        if let photos = self.photos {
            state = .loaded(photos)
        } else {
            state = .error("Couldn't load photos")
        }
    }
}

extension PhotosLoader {
    enum State {
        case idle, loading
        case loaded([UIImage])
        case error(String)
    }
}

extension UIImage {
    func aspectFittedToHeight(_ newHeight: CGFloat) -> UIImage {
        let scale = newHeight / self.size.height
        let newWidth = self.size.width * scale
        let newSize = CGSize(width: newWidth, height: newHeight)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
