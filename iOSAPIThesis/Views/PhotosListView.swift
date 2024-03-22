//
//  ContentView.swift
//  iOSAPIThesis
//
//  Created by David Mansourian on 2024-03-02.
//

import SwiftUI

struct PhotosListView: View {
    private let imageHeightInGrid: CGFloat = 200
    private let imageWidthInGrid: CGFloat = 175
    
    let loadingHelper = PhotosLoader(apiService: APIService(), fileDiskManager: FileDiskManager())
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        switch loadingHelper.state {
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
                    ForEach(photos, id: \.self) { photo in
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: imageWidthInGrid, height: imageHeightInGrid)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
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

#Preview {
    PhotosListView()
}
