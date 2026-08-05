import XCTest
@testable import Scanner

/// Equivalent of the Android MainScreenViewModelTest.
final class MainScreenViewModelTests: XCTestCase {

    @MainActor
    func testInitialStateIsLoading() {
        let viewModel = MainScreenViewModel(repository: SuspendedRepository())
        XCTAssertEqual(viewModel.uiState, .loading)
    }

    @MainActor
    func testRepositoryEmitsData_isSuccess() async {
        let viewModel = MainScreenViewModel(repository: FakeRepository(items: ["Android", "Kotlin"]))
        await waitUntilLoaded(viewModel)
        XCTAssertEqual(viewModel.uiState, .success(["Android", "Kotlin"]))
    }

    @MainActor
    func testRepositoryThrows_isError() async {
        let viewModel = MainScreenViewModel(repository: FailingRepository())
        await waitUntilLoaded(viewModel)
        guard case .error = viewModel.uiState else {
            return XCTFail("Expected error state, got \(viewModel.uiState)")
        }
    }
}

/// Repository that never completes; keeps the UI state at `.loading`.
private struct SuspendedRepository: DataRepository {
    func fetchData() async throws -> [String] {
        try await withUnsafeThrowingContinuation { _ in }
    }
}

private struct FakeRepository: DataRepository {
    let items: [String]
    func fetchData() async throws -> [String] { items }
}

private struct FailingRepository: DataRepository {
    func fetchData() async throws -> [String] {
        throw URLError(.badServerResponse)
    }
}

@MainActor
private func waitUntilLoaded(_ viewModel: MainScreenViewModel) async {
    while viewModel.uiState == .loading {
        await Task.yield()
    }
}
