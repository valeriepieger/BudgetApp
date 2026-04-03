//
//  ScannerSheet.swift
//  Allocent
//
//  Created by Amber Liu on 4/2/26.
//


import SwiftUI
import VisionKit

// A SwiftUI wrapper around DataScannerViewController.
// Captures live text from the camera and returns it via onTextCaptured.
struct ScannerSheet: UIViewControllerRepresentable {
    let onTextCaptured: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        try? uiViewController.startScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTextCaptured: onTextCaptured, onCancel: onCancel)
    }

    // Coordinator

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onTextCaptured: (String) -> Void
        let onCancel: () -> Void

        init(onTextCaptured: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
            self.onTextCaptured = onTextCaptured
            self.onCancel = onCancel
        }

        // Called when user taps a recognized item in the live view
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            var text = ""
            switch item {
            case .text(let recognizedText):
                text = recognizedText.transcript
            case .barcode(_):
                break 
            @unknown default:
                break
            }
            guard !text.isEmpty else { return }
            dataScanner.stopScanning()
            onTextCaptured(text)
        }
    }
}

// Availability check view — shows ScannerSheet only when DataScanner is supported
struct ScannerAvailabilityView: View {
    let onTextCaptured: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
            ZStack(alignment: .topTrailing) {
                ScannerSheet(onTextCaptured: onTextCaptured, onCancel: onCancel)
                    .ignoresSafeArea()

                // Capture hint overlay
                VStack {
                    Spacer()
                    Text("Point at receipt, then tap any text to capture")
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 40)
                }

                Button("Cancel") {
                    onCancel()
                }
                .foregroundStyle(.white)
                .padding()
            }
        } else {
            ContentUnavailableView(
                "Scanner Not Available",
                systemImage: "camera.slash",
                description: Text("Live text scanning requires iOS 16+ and camera access.")
            )
        }
    }
}
