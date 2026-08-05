import AVFoundation
import Foundation

/// A detected barcode (value + human readable type name).
struct ScanResult: Equatable {
    let value: String
    let type: String
}

/// Detects barcodes from the camera feed via AVCaptureMetadataOutput,
/// equivalent of the Android ML Kit BarcodeAnalyzer.
final class BarcodeAnalyzer: NSObject, AVCaptureMetadataOutputObjectsDelegate, ObservableObject {

    @Published private(set) var result: ScanResult?

    /// Formats we accept, mirroring the Android supported set.
    /// (UPC-A is reported by iOS as EAN-13, so there is no separate entry.)
    let supportedTypes: [AVMetadataObject.ObjectType] = [
        .qr,
        .code128,
        .code39,
        .code93,
        .codabar,
        .dataMatrix,
        .ean13,
        .ean8,
        .itf14,
        .upce,
        .pdf417,
        .aztec,
    ]

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        // Ignore further detections once a result is captured (mirrors the isScanning flag).
        guard result == nil,
              let first = metadataObjects
                  .compactMap { $0 as? AVMetadataMachineReadableCodeObject }
                  .first(where: { $0.stringValue != nil }),
              let value = first.stringValue
        else { return }

        result = ScanResult(value: value, type: name(for: first.type))
    }

    /// Equivalent of the Android analyzer.resumeScanning().
    func reset() {
        result = nil
    }

    private func name(for type: AVMetadataObject.ObjectType) -> String {
        switch type {
        case .qr: return "QR Code"
        case .code128: return "Code 128"
        case .code39: return "Code 39"
        case .code93: return "Code 93"
        case .codabar: return "Codabar"
        case .dataMatrix: return "Data Matrix"
        case .ean13: return "EAN-13"
        case .ean8: return "EAN-8"
        case .itf14: return "ITF"
        case .upce: return "UPC-E"
        case .pdf417: return "PDF417"
        case .aztec: return "Aztec"
        default: return "Unknown"
        }
    }
}
