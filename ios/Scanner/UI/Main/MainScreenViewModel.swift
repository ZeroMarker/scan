import Foundation

/// UI states mirroring the Android MainScreenUiState sealed interface.
enum MainScreenUiState: Equatable {
    case loading
    case error(String)
    case success([String])
}

/// Equivalent of the Android MainScreenViewModel (ViewModel + StateFlow).
@MainActor
final class MainScreenViewModel: ObservableObject {
    @Published private(set) var uiState: MainScreenUiState = .loading

    private let repository: DataRepository

    init(repository: DataRepository) {
        self.repository = repository
        Task { await load() }
    }

    func load() async {
        uiState = .loading
        do {
            uiState = .success(try await repository.fetchData())
        } catch {
            uiState = .error(error.localizedDescription)
        }
    }
}
