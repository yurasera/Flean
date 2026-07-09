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
    @State private var currentAsset: PHAsset?
    @State private var allAssets: PHFetchResult<PHAsset>?
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    
    func loadAllImages() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        loadImageAtIndex(0)
    }
    
    func loadImageAtIndex(_ index: Int) {
        guard let allAssets = allAssets, index < allAssets.count else { return }
        
        currentIndex = index
        let asset = allAssets.object(at: index)
        currentAsset = asset
        
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.deliveryMode = .highQualityFormat
        
        imageManager.requestImage(for: asset, targetSize: CGSize(width: 800, height: 800), contentMode: .aspectFit, options: requestOptions) { image, _ in
            selectedImage = image
        }
    }
    
    func deleteCurrentImage() {
        guard let asset = currentAsset else { return }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }) { success, error in
            if success {
                DispatchQueue.main.async {
                    // Reload assets after deletion
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                    allAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                    
                    // Show next image (or previous if at end)
                    if currentIndex < (allAssets?.count ?? 0) {
                        loadImageAtIndex(currentIndex)
                    } else if (allAssets?.count ?? 0) > 0 {
                        // If at the end, show the last image
                        loadImageAtIndex((allAssets?.count ?? 0) - 1)
                    }
                }
            }
        }
    }
    
    func keepAndShowNext() {
        let nextIndex = currentIndex + 1
        if let allAssets = allAssets, nextIndex < allAssets.count {
            loadImageAtIndex(nextIndex)
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
                    .offset(x: dragOffset)
                    .rotationEffect(.degrees(dragOffset / 20))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                if value.translation.width < -100 {
                                    // Swipe left - delete
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        dragOffset = -500
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        deleteCurrentImage()
                                        dragOffset = 0
                                    }
                                } else if value.translation.width > 100 {
                                    // Swipe right - keep and next
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        dragOffset = 500
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        keepAndShowNext()
                                        dragOffset = 0
                                    }
                                } else {
                                    // Return to center
                                    withAnimation(.spring()) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                    .overlay(
                        HStack {
                            if dragOffset < -50 {
                                VStack {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.red)
                                    Text("Delete")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                }
                                .opacity(min(abs(dragOffset) / 100, 1))
                                Spacer()
                            } else if dragOffset > 50 {
                                Spacer()
                                VStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.green)
                                    Text("Keep")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                                .opacity(min(abs(dragOffset) / 100, 1))
                            }
                        }
                        .padding(.horizontal, 40)
                    )
            } else {
                Image(systemName: "photo")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .frame(height: 200)
            }
            
            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "arrow.left")
                    Text("Delete")
                        .font(.caption)
                }
                .foregroundColor(.red)
                
                Spacer()
                
                Text("Swipe to sort")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack {
                    Image(systemName: "arrow.right")
                    Text("Keep")
                        .font(.caption)
                }
                .foregroundColor(.green)
            }
            .padding(.horizontal)
            
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
            loadAllImages()
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
