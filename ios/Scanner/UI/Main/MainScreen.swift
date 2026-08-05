import SwiftUI

/// Equivalent of the Android MainScreen.
struct MainScreen: View {
    let onScan: () -> Void

    @StateObject private var viewModel: MainScreenViewModel

    init(
        onScan: @escaping () -> Void,
        viewModel: MainScreenViewModel = MainScreenViewModel(repository: DefaultDataRepository())
    ) {
        self.onScan = onScan
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Barcode Scanner")
                .font(ScannerTheme.Typography.headline)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 16)

            Text("Scan barcodes and QR codes instantly")
                .font(ScannerTheme.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 48)

            Button(action: onScan) {
                Label("Start Scanning", systemImage: "qrcode.viewfinder")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer().frame(height: 24)

            switch viewModel.uiState {
            case .loading:
                EmptyView()
            case .error(let message):
                Text("Error loading data: \(message)")
                    .foregroundStyle(.red)
            case .success(let data):
                ForEach(data, id: \.self) { item in
                    Text("Hello \(item)!")
                }
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MainScreen(onScan: {})
}
