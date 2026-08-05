import SwiftUI

/// Navigation destinations, mirroring the Android NavigationKeys (Main / Scanner).
enum Route: Hashable {
    case scanner
}

/// Equivalent of the Android MainNavigation (Navigation3 NavDisplay).
struct MainRouter: View {
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            MainScreen(onScan: { path.append(.scanner) })
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .scanner:
                        ScannerScreen(onBack: { path.removeLast() })
                    }
                }
        }
    }
}
