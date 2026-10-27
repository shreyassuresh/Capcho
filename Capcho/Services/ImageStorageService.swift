//
//  ImageStorageService.swift
//  Capcho
//
//  Created by Capcho on 27/10/26.
//

import UIKit

final class ImageStorageService {
    static let shared = ImageStorageService()
    
    private let fileManager = FileManager.default
    private let cache = NSCache<NSString, UIImage>()
    
    private var imagesDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let capchoDir = appSupport.appendingPathComponent("Capcho", isDirectory: true)
        let imagesDir = capchoDir.appendingPathComponent("Images", isDirectory: true)
        
        if !fileManager.fileExists(atPath: imagesDir.path) {
            try? fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true, attributes: nil)
        }
        return imagesDir
    }
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB thumbnail cache
    }
    
    // MARK: - Save Image
    /// Saves UIImage as JPEG to local Application Support directory and returns the unique filename
    func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.82) else { return nil }
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL, options: .completeFileProtection)
            // Cache thumbnail
            if let thumb = createThumbnail(from: data, targetSize: CGSize(width: 300, height: 300)) {
                cache.setObject(thumb, forKey: filename as NSString)
            }
            return filename
        } catch {
            print("ImageStorageService: Failed to save image: \(error)")
            return nil
        }
    }
    
    // MARK: - Load Image
    /// Loads the full-resolution image from disk
    func loadImage(named filename: String) -> UIImage? {
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    // MARK: - Load Thumbnail
    /// Returns cached thumbnail or generates one asynchronously
    func loadThumbnail(named filename: String, targetSize: CGSize = CGSize(width: 240, height: 240)) -> UIImage? {
        if let cached = cache.object(forKey: filename as NSString) {
            return cached
        }
        
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        
        if let thumb = createThumbnail(from: data, targetSize: targetSize) {
            cache.setObject(thumb, forKey: filename as NSString)
            return thumb
        }
        
        return nil
    }
    
    // MARK: - Delete Image
    /// Deletes the local image file from disk and clears cache
    func deleteImage(named filename: String?) {
        guard let filename = filename, !filename.isEmpty else { return }
        cache.removeObject(forKey: filename as NSString)
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    // MARK: - Raw Data Export / Import Helpers
    func imageData(for filename: String) -> Data? {
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        return try? Data(contentsOf: fileURL)
    }
    
    func saveRawData(_ data: Data, filename: String) {
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        try? data.write(to: fileURL, options: .completeFileProtection)
    }
    
    // MARK: - Internal Thumbnail Generation
    private func createThumbnail(from data: Data, targetSize: CGSize) -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        
        let maxPixelDimension = max(targetSize.width, targetSize.height) * UIScreen.main.scale
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelDimension
        ]
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return UIImage(data: data)
        }
        
        return UIImage(cgImage: cgImage)
    }
}
