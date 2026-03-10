import Foundation

@Observable
final class FileTrayModel {
    private(set) var files: [URL] = []

    func add(_ url: URL) {
        guard !files.contains(url) else { return }
        files.append(url)
    }

    func remove(_ url: URL) {
        files.removeAll { $0 == url }
    }

    func clear() {
        files.removeAll()
    }
}
