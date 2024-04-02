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
    
    // MARK: Line-per-line description
    /// - Set state to loading
    /// - declare urlString
    /// - Create Task to perform asynchronous operation
    /// - Make sure that 'self' is available (that instance should exist)
    /// - Creat do-catch block
    /// - call fetchPhotosList from the apiService using the urlString and store it in the property 'photosList'
    /// - Create internal storage directory if needed
    /// - Load all photos from the photosList
    /// - Update user state
    /// - Go in to catch if needed
    /// - Set state to error if error is caught
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
    
    // MARK: Line-per-line description
    /// - Calls fileDiskManager to create the 'appPhotos' directory in the internal storage if needed
    private func createAppPhotosDirectoryIfNeeded() async {
        fileDiskManager.createDirectoryIfNeeded(.appPhotos)
    }
    
    // MARK: Line-per-line description
    /// - Create a task group
    /// - Make sure that 'self' is available (that instance should exist)
    /// - Loop through 'photosList' from argument in function
    /// - addTask in the task group for each photo by calling 'fetchAndSavePhotosIfNeeded'
    /// - Declare thumbnails array that should store images
    /// - Loop through the results from the task group
    /// - Create thumbnail (smaller representation of original photo)
    /// - Append the thumbnail into the thumbnails array created
    /// - Make the task group return the thumbnails array to the "photos" property
    /// - Set class variable 'photos' to the finished photos array returned from the task group
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
    
    
    // MARK: Line-per-line description
    /// - Check if the photo is saved in internal storage
    /// - If the photo is saved in internal storage, return the internal storage URL
    /// - If the photo is not saved in internal storage, try to fetch it by using the apiService
    /// - If the fetch from apiService is successful, save the image data to internal storage
    /// - If the apiService fails fetching the photo, print a custom error description and return nil
    /// - If apiService was succesful, return the savedPhotoUrl
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
    
    // MARK: Line-per-line description
    /// - Check so that inserted URL in the function is an URL
    /// - and check so that the image exists locally using the local URL, otherwise return nil
    /// - Resize the image by calling 'aspectFittedToHeight'. The height is determined by the class variable 'photoThumbnailHeight'
    /// - Compress the jpegData
    /// - Return the resized image
    private func thumbnailFromLocalPhotoUrl(_ localPhotoUrl: URL?) -> UIImage? {
        guard let url = localPhotoUrl,
              let localImage = UIImage(contentsOfFile: url.path()) else {
            return nil
        }
        
        let resizedImage = localImage.aspectFittedToHeight(photoThumbnailHeight)
        resizedImage.jpegData(compressionQuality: 0.1)
        
        return resizedImage
    }
    
    // MARK: Line-per-line description
    /// - Make sure that the function is executed on the main thread
    /// - If the class variable 'photos' is not nil, set the state to .loaded with an associated value of the photos
    /// - Otherwise, set the state to .error with an associated value of the error description
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
