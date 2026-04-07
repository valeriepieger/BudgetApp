//
//  ScannerSheet.swift
//  Allocent
//
//  Created by Amber Liu on 4/2/26.
//

import SwiftUI
import VisionKit
import AVFoundation

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
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = .on
        device.unlockForConfiguration()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTextCaptured: onTextCaptured, onCancel: onCancel)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onTextCaptured: (String) -> Void
        let onCancel: () -> Void
        private var captureTimer: Timer?
        private var latestItems: [RecognizedItem] = []

        init(onTextCaptured: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
            self.onTextCaptured = onTextCaptured
            self.onCancel = onCancel
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            latestItems = allItems
            // Only start timer once — don't reset it on every new item
            if captureTimer == nil {
                captureTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                    self?.captureAll(dataScanner)
                }
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Keep updating latest items so we capture the most complete set
            latestItems = allItems
        }

        private func captureAll(_ dataScanner: DataScannerViewController) {
            var texts: [String] = []
            for item in latestItems {
                if case .text(let recognizedText) = item {
                    texts.append(recognizedText.transcript)
                }
            }
            let allText = texts.joined(separator: "\n")
            guard !allText.isEmpty else { return }
            dataScanner.stopScanning()
            onTextCaptured(allText)
        }
    }
}

// MARK: - Availability View

struct ScannerAvailabilityView: View {
    let onTextCaptured: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
            ZStack(alignment: .bottom) {
                ScannerSheet(
                    onTextCaptured: onTextCaptured,
                    onCancel: onCancel
                )
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    Text("Hold steady over the full receipt")
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())

                    Button {
                        onCancel()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding(.bottom, 40)
                }
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
