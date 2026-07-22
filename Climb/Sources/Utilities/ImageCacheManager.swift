import SwiftUI
import Combine

/// Disk and memory image caching manager for high-performance photo loading
final class ImageCacheManager {
    static let shared = ImageCacheManager()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let diskCacheURL: URL

    private init() {
        memoryCache.countLimit = 150
        memoryCache.totalCostLimit = 100 * 1024 * 1024 // 100 MB memory limit

        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = cachesDirectory.appendingPathComponent("ClimbImageCache", isDirectory: true)

        if !fileManager.fileExists(atPath: diskCacheURL.path) {
            try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        }
    }

    /// Retrieve image from memory cache, disk cache, or download remotely
    func loadImage(from urlString: String) async -> UIImage? {
        guard !urlString.isEmpty, let url = URL(string: urlString) else { return nil }
        let cacheKey = cacheKey(for: urlString)

        // 1. Memory cache check
        if let memoryImage = memoryCache.object(forKey: cacheKey as NSString) {
            return memoryImage
        }

        // 2. Disk cache check
        let filePath = diskCacheURL.appendingPathComponent(cacheKey)
        if fileManager.fileExists(atPath: filePath.path),
           let diskData = try? Data(contentsOf: filePath),
           let diskImage = UIImage(data: diskData) {
            memoryCache.setObject(diskImage, forKey: cacheKey as NSString, cost: diskData.count)
            return diskImage
        }

        // 3. Remote download
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let image = UIImage(data: data) else { return nil }

            memoryCache.setObject(image, forKey: cacheKey as NSString, cost: data.count)
            try? data.write(to: filePath, options: .atomic)
            return image
        } catch {
            return nil
        }
    }

    /// Prefetch image in background for instant display later
    func prefetch(urlString: String) {
        guard !urlString.isEmpty, URL(string: urlString) != nil else { return }
        let key = cacheKey(for: urlString)
        let filePath = diskCacheURL.appendingPathComponent(key)

        if memoryCache.object(forKey: key as NSString) != nil || fileManager.fileExists(atPath: filePath.path) {
            return
        }

        Task(priority: .background) {
            _ = await loadImage(from: urlString)
        }
    }

    private func cacheKey(for urlString: String) -> String {
        let allowed = CharacterSet.alphanumerics
        return urlString.components(separatedBy: allowed.inverted).joined()
    }
}

/// SwiftUI View that renders images from ImageCacheManager instantly
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let urlString: String
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var uiImage: UIImage? = nil
    @State private var isLoading = false

    var body: some View {
        Group {
            if let uiImage = uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .task(id: urlString) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard !urlString.isEmpty else { return }
        if let cached = await ImageCacheManager.shared.loadImage(from: urlString) {
            self.uiImage = cached
        }
    }
}
