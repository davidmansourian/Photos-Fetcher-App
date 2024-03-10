//
//  LoadingHelper.swift
//  iOSAPIThesis
//
//  Created by David Mansourian on 2024-03-02.
//

import Foundation

@Observable
final class LoadingHelper {
    private let apiService: APIService
    
    private var photos: [Photo]?
    
    private(set) var viewState: ViewState = .idle
    
    init(apiService: APIService) {
        self.apiService = apiService
        
        loadPhotosList()
    }
    
    
    private func loadPhotosList() {
        viewState = .loading
        
        let urlString = "https://picsum.photos/v2/list"
        Task {
            do {
                let photosList = try await apiService.fetchPhotosList(from: urlString)
                await loadPhotos(from: photosList)
                updateUserResults()
            } catch {
                let errorMessage = (error as? APIService.APIError)?.customDescription ?? error.localizedDescription
                self.viewState = .error(errorMessage)
            }
        }
    }
    
    private func loadPhotos(from photosList: [Photo]) async {
        let photos = await withTaskGroup(of: (Photo, Data?).self, returning: [Photo].self) { [weak self] taskGroup in
            guard let self = self else { return [] }
            
            for photo in photosList {
                taskGroup.addTask {
                    let imageData = try? await self.apiService.fetchPhoto(from: photo.downloadUrl)
                    return (photo, imageData)
                }
            }
            
            var photosWithImageData: [Photo] = []
            
            for await (photo, imageData) in taskGroup {
                let photo = Photo(id: photo.id, author: photo.author, width: photo.width, height: photo.height, downloadUrl: photo.downloadUrl, imageData: imageData)
                photosWithImageData.append(photo)
            }
            
            return photosWithImageData
        }
        
        self.photos = photos
    }
    
    private func updateUserResults() {
        if let photos = self.photos, !photos.isEmpty {
            viewState = .loaded(photos)
        } else {
            viewState = .error("Couldn't load photos")
        }
    }
}

extension LoadingHelper {
    enum ViewState: Equatable {
        case idle, loading
        case loaded([Photo])
        case error(String)
    }
}
