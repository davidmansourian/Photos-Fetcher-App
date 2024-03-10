//
//  ContentView.swift
//  iOSAPIThesis
//
//  Created by David Mansourian on 2024-03-02.
//

import SwiftUI

struct PhotosListView: View {
    let loadingHelper = LoadingHelper(apiService: APIService())
    
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
                        if let imageData = photo.imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 175, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                    }
                }
            }
        case .error(let errorString):
            ContentUnavailableView("Couldn't load photos", systemImage: "exclamationmark.bubble.fill", description: Text(errorString))
        }
    }
}

#Preview {
    PhotosListView()
}
