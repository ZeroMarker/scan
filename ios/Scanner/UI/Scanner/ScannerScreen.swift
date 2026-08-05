import AVFoundation
import SwiftUI
import UIKit

/// Equivalent of the Android ScannerScreen:
/// permission handling, live preview with a scan frame, result display,
/// copy to clipboard and "scan again".
struct ScannerScreen: View {
    let onBack: () -> Void

    @State private var permissionStatus: AVAuthorizationStatus
    @StateObject private var analyzer = BarcodeAnalyzer()
    @State private var session: AVCaptureSession?
    @State private var showCopied = false
    @State private var isActive = true

    init(onBack: @escaping () -> Void) {
        self.onBack = onBack
        _permissionStatus = State(initialValue: AVCaptureDevice.authorizationStatus(for: .video))
    }

    var body: some View {
        Group {
            switch permissionStatus {
            case .authorized:
                scannerContent
            case .notDetermined:
                Color.black
                    .ignoresSafeArea()
                    .onAppear { requestPermission() }
            default:
                PermissionDeniedView(
                    shouldShowRationale: permissionStatus == .denied,
                    onRequestPermission: requestPermission,
                    onOpenSettings: openSettings,
                    onBack: onBack
                )
            }
        }
    }

    // MARK: - Scanner UI

    private var scannerContent: some View {
        ZStack {
            if let session {
                CameraPreview(session: session)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            } else {
                Color.black.ignoresSafeArea()
            }

            // Scan frame
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 250, height: 250)

            // Back button
            VStack {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.4), in: Circle())
                    }
                    .accessibilityLabel("Back")
                    Spacer()
                }
                Spacer()
            }
            .padding(16)

            // Hint
            VStack {
                Spacer()
                Text("Align barcode within the frame")
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                    .padding(.bottom, 100)
            }

            // Result overlay
            if let result = analyzer.result {
                ScanResultView(
                    result: result,
                    showCopied: showCopied,
                    onCopy: {
                        UIPasteboard.general.string = result.value
                        withAnimation { showCopied = true }
                    },
                    onScanAgain: {
                        showCopied = false
                        analyzer.reset()
                    },
                    onBack: onBack
                )
            }
        }
        .task {
            isActive = true
            startSession()
        }
        .onDisappear {
            isActive = false
            stopSession()
        }
        .onChange(of: analyzer.result) { _, newValue in
            // Release the camera while the result is shown; restart it on "scan again".
            if newValue == nil {
                startSession()
            } else {
                stopSession()
            }
        }
    }

    // MARK: - Session management

    private func startSession() {
        guard session == nil else { return }
        Task {
            let newSession = await Task.detached(priority: .userInitiated) {
                Self.makeSession(analyzer: analyzer)
            }.value
            // Don't start the camera if the screen was left while the session was being created.
            guard isActive, let newSession else { return }
            session = newSession
            await Task.detached(priority: .userInitiated) { newSession.startRunning() }.value
        }
    }

    private func stopSession() {
        let oldSession = session
        session = nil
        if let oldSession {
            Task.detached(priority: .userInitiated) { oldSession.stopRunning() }
        }
    }

    private static func makeSession(analyzer: BarcodeAnalyzer) -> AVCaptureSession? {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else { return nil }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return nil }
        session.addOutput(output)

        output.setMetadataObjectsDelegate(analyzer, queue: .main)
        let available = output.availableMetadataObjectTypes
        output.metadataObjectTypes = analyzer.supportedTypes.filter { available.contains($0) }
        return session
    }

    // MARK: - Permission

    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor in
                permissionStatus = granted ? .authorized : .denied
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Result view (equivalent of the Android ResultContent)

private struct ScanResultView: View {
    let result: ScanResult
    let showCopied: Bool
    let onCopy: () -> Void
    let onScanAgain: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("Scan Result")
                    .font(ScannerTheme.Typography.headline)
                    .foregroundStyle(.white)

                Spacer().frame(height: 24)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Type: \(result.type)")
                        .font(ScannerTheme.Typography.label)
                        .foregroundStyle(.tint)
                    Text(result.value)
                        .font(ScannerTheme.Typography.body)
                        .foregroundStyle(.white)
                        .textSelection(.enabled)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                Spacer().frame(height: 32)

                HStack(spacing: 12) {
                    Button(action: onCopy) {
                        Label(showCopied ? "Copied" : "Copy",
                              systemImage: showCopied ? "checkmark" : "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: onScanAgain) {
                        Text("Scan Again")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer().frame(height: 16)

                Button("Back to Home", action: onBack)
                    .buttonStyle(.plain)

                Spacer()
            }
            .padding(16)
        }
    }
}

// MARK: - Permission denied view (equivalent of the Android PermissionDeniedContent)

private struct PermissionDeniedView: View {
    let shouldShowRationale: Bool
    let onRequestPermission: () -> Void
    let onOpenSettings: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Camera Permission Required")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Spacer().frame(height: 16)

            Text(
                shouldShowRationale
                    ? "This app needs camera access to scan barcodes. Please grant the permission to continue."
                    : "Camera permission has been denied. Enable it in system settings to scan barcodes."
            )
            .font(ScannerTheme.Typography.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Spacer().frame(height: 24)

            Button("Grant Permission", action: onRequestPermission)
                .buttonStyle(.borderedProminent)

            Spacer().frame(height: 12)

            Button("Open Settings", action: onOpenSettings)
                .buttonStyle(.bordered)

            Spacer().frame(height: 12)

            Button("Go Back", action: onBack)
                .buttonStyle(.plain)

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
