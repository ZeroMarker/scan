import Foundation

/// Equivalent of the Android DataRepository interface.
protocol DataRepository {
    func fetchData() async throws -> [String]
}

/// Equivalent of the Android DefaultDataRepository (placeholder data).
struct DefaultDataRepository: DataRepository {
    func fetchData() async throws -> [String] {
        ["Android"]
    }
}
