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
    private let fileDiskManager: FileDiskManager
    
    private var photos: [Photo]?
    
    private(set) var viewState: ViewState = .idle
    
    init(apiService: APIService, fileDiskManager: FileDiskManager) {
        self.apiService = apiService
        self.fileDiskManager = fileDiskManager
        
        loadPhotosList()
    }
    
    private func loadPhotosList() {
        viewState = .loading
        
        let urlString = "https://picsum.photos/v2/list"
        
        Task {
            do {
                let photosList = try await apiService.fetchPhotosList(from: urlString)
                await createAppPhotosDirectoryIfNeeded()
                await loadPhotos(from: photosList)
                await updateUserState()
            } catch {
                let errorMessage = (error as? APIService.APIError)?.customDescription ?? error.localizedDescription
                self.viewState = .error(errorMessage)
            }
        }
    }
        
    private func loadPhotos(from photosList: [Photo]) async {
        let photos = await withTaskGroup(of: (Photo?, URL?).self, returning: [Photo].self) { [weak self] taskGroup in
            guard let self = self else { return [] }
            
            for photo in photosList {
                taskGroup.addTask {
                    if let localImageUrl = self.fileDiskManager.getFileURL(from: .appPhotos, for: photo.downloadUrl) {
                        return (photo, localImageUrl)
                    }

                    guard let imageData = try? await self.apiService.fetchPhoto(from: photo.downloadUrl),
                          let savedImageUrl = self.fileDiskManager.writeData(imageData, in: .appPhotos, fileName: photo.downloadUrl)
                    else {
                        print("Error fetching individual image")
                        return (nil, nil)
                    }

                    return (photo, savedImageUrl)
                }
            }
            
            var newPhotos: [Photo] = []
            
            for await (photoObject, localUrl) in taskGroup {
                if let photo = photoObject,
                   let url = localUrl {
                    let newPhoto = Photo(id: photo.id, downloadUrl: photo.downloadUrl, localImageUrl: url)
                    newPhotos.append(newPhoto)
                }
            }
            
            return newPhotos
        }
        
        self.photos = photos
    }
    
    private func createAppPhotosDirectoryIfNeeded() async {
        fileDiskManager.createDirectoryIfNeeded(.appPhotos)
    }
    
    @MainActor
    private func updateUserState() {
        if let photos = self.photos, !photos.isEmpty {
            print(Thread.current)
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
