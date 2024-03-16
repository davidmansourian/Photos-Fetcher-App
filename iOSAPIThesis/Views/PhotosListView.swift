//
//  ContentView.swift
//  iOSAPIThesis
//
//  Created by David Mansourian on 2024-03-02.
//

import SwiftUI

struct PhotosListView: View {
    private let imageHeightInGrid: CGFloat = 200
    
    let loadingHelper = LoadingHelper(apiService: APIService(), fileDiskManager: FileDiskManager())
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        switch loadingHelper.viewState {
        case .idle:
            Text("Waiting for loader")
        case .loading:
            VStack(spacing: 10) {
                Text("Loading photos")
                ProgressView()
            }
        case .loaded(let photos):
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(photos) { photo in
                        if let localImageUrl = photo.localImageUrl,
                           let image = compressedImage(uiImage: UIImage(contentsOfFile: localImageUrl.path()),
                                                         imageHeight: imageHeightInGrid)
                        {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 175, height: imageHeightInGrid)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                    }
                }
            }
        case .error(let errorString):
            ContentUnavailableView("Couldn't load photos", 
                                   systemImage: "exclamationmark.bubble.fill",
                                   description: Text(errorString)
            )
        }
    }
}

extension PhotosListView {
    func compressedImage(uiImage: UIImage?, imageHeight: CGFloat) -> UIImage? {
        guard let image = uiImage else { return nil }
        let resizedImage = image.aspectFittedToHeight(imageHeight)
        resizedImage.jpegData(compressionQuality: 0.1)
        
        return resizedImage
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

#Preview {
    PhotosListView()
}
