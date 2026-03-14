import SwiftUI
import ImageIO

// MARK: - Platform Image Alias
// Abstracts UIImage (iOS) vs NSImage (macOS) for cross-platform image handling.

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

// MARK: - ImageStorageService
// Manages image file I/O in Documents/TrelloClone/attachments/.
// Images are JPEG-compressed and stored outside UserDefaults to avoid bloat.
// Provides thumbnail generation via CGImageSource for efficient list display.

@Observable
final class ImageStorageService {

    /// Base directory: {Documents}/TrelloClone/attachments/
    private let attachmentsDirectory: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        attachmentsDirectory = docs.appendingPathComponent("TrelloClone/attachments", isDirectory: true)

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: attachmentsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Save

    /// Saves image data as JPEG to disk. Returns the filename on success.
    @discardableResult
    func saveImage(_ data: Data, filename: String) -> Bool {
        let url = attachmentsDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    /// Saves a PlatformImage as JPEG with specified compression quality.
    @discardableResult
    func saveImage(_ image: PlatformImage, filename: String, compressionQuality: CGFloat = 0.8) -> Bool {
        guard let data = jpegData(from: image, quality: compressionQuality) else { return false }
        return saveImage(data, filename: filename)
    }

    // MARK: - Load

    /// Loads a full-resolution image from disk. Returns nil if file doesn't exist.
    func loadImage(filename: String) -> PlatformImage? {
        let url = attachmentsDirectory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        #if canImport(UIKit)
        return UIImage(contentsOfFile: url.path)
        #elseif canImport(AppKit)
        return NSImage(contentsOf: url)
        #endif
    }

    /// Loads a downsampled thumbnail using CGImageSource for memory efficiency.
    /// maxDimension controls the longest edge of the thumbnail (default 200pt).
    func loadThumbnail(filename: String, maxDimension: CGFloat = 200) -> PlatformImage? {
        let url = attachmentsDirectory.appendingPathComponent(filename)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        #if canImport(UIKit)
        return UIImage(cgImage: cgImage)
        #elseif canImport(AppKit)
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #endif
    }

    // MARK: - Delete

    /// Deletes an image file from disk.
    func deleteImage(filename: String) {
        let url = attachmentsDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Helpers

    private func jpegData(from image: PlatformImage, quality: CGFloat) -> Data? {
        #if canImport(UIKit)
        return image.jpegData(compressionQuality: quality)
        #elseif canImport(AppKit)
        guard let tiffData = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiffData) else { return nil }
        return rep.representation(using: .jpeg, properties: [.compressionFactor: quality])
        #endif
    }
}
