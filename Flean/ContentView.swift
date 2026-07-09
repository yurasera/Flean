//
//  ContentView.swift
//  Flean
//
//  Created by Yuhaya Lissera on 07/07/26.
//

import SwiftUI
import PhotosUI
import Photos

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    
    func loadLatestImage() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        guard let latestAsset = fetchResult.firstObject else { return }
        
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        
        imageManager.requestImage(for: latestAsset, targetSize: CGSize(width: 400, height: 400), contentMode: .aspectFit, options: requestOptions) { image, _ in
            selectedImage = image
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(12)
            } else {
                Image(systemName: "photo")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .frame(height: 200)
            }
            
            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                Label("Select from Gallery", systemImage: "photo.badge.plus")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadLatestImage()
        }
        .onChange(of: photosPickerItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
