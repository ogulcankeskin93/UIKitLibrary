import Foundation

@propertyWrapper
struct FileManagerWrapper<T: Codable> {
    
    struct Wrapper<T> : Codable where T: Codable {
        let wrapped: T
    }
    
    private let key: String
    private let defaultValue: T
    private let directory: FileManager.SearchPathDirectory
    private let excludeiCloudCache: Bool
    
    init(
        key: String,
        defaultValue: T,
        directory: FileManager.SearchPathDirectory = .documentDirectory,
        isHidden: Bool = true,
        excludeiCloudCache: Bool = true
    ) {
        self.key = isHidden ? ".\(key)" : key
        self.defaultValue = defaultValue
        self.directory = directory
        self.excludeiCloudCache = excludeiCloudCache
    }
    
    var wrappedValue: T {
        get {
            do {
                let folderURL = try FileManager.default.url(
                    for: directory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false
                )
                var fileURL = folderURL.appendingPathComponent(key)
                try? fileURL.setExcludeFromiCloudBackup(isExcluded: excludeiCloudCache)
                let data = try Data(contentsOf: fileURL)
                let value = try? JSONDecoder().decode(Wrapper<T>.self, from: data)
                return value?.wrapped ?? defaultValue
            } catch {
                return defaultValue
            }
        }
        set {
            do {
                let folderURL = try FileManager.default.url(
                    for: directory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false
                )
                let fileURL = folderURL.appendingPathComponent(key)
                let data = try JSONEncoder().encode(Wrapper(wrapped:newValue))
                try data.write(to: fileURL)
            } catch { }
        }
    }
}


private extension URL {
    
    mutating func setExcludeFromiCloudBackup(isExcluded: Bool) throws {
       var values = URLResourceValues()
       values.isExcludedFromBackup = isExcluded
       try? self.setResourceValues(values)
    }
    
    func getExcludeFromiCloudBackup() throws -> Bool {
       let keySet: Set<URLResourceKey> = [.isExcludedFromBackupKey]
       
       return try
          self.resourceValues(forKeys: keySet).isExcludedFromBackup ?? false
    }
}
