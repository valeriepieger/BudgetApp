//
//  ScanReceiptView.swift
//  Allocent
//
//  Created by Amber Liu on 4/2/26.
//

import SwiftUI
import SwiftData
import PhotosUI
import Vision
import FoundationModels

enum ScanState {
    case idle
    case processing
    case confirming(Transaction)
    case error(String)
}

struct ScanReceiptView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var scanState: ScanState = .idle
    @State private var showScanner = false
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Group {
                switch scanState {
                case .idle:
                    idleView
                case .processing:
                    processingView
                case .confirming(let transaction):
                    ConfirmTransactionView(transaction: transaction) {
                        dismiss()
                    } onRetry: {
                        scanState = .idle
                    }
                case .error(let message):
                    errorView(message: message)
                }
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showScanner) {
                ScannerAvailabilityView { capturedText in
                    showScanner = false
                    Task { await parseText(capturedText) }
                } onCancel: {
                    showScanner = false
                    scanState = .idle
                }
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { _, newItem in
                guard let newItem else { return }
                Task { await processPhotoPickerItem(newItem) }
            }
        }
    }

    // Subviews

    private var idleView: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "receipt")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)
            Text("Add a receipt")
                .font(.title2.bold())
            Text("Use your camera to scan a physical receipt, or upload a screenshot from your photos.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            VStack(spacing: 12) {
                Button {
                    showScanner = true
                } label: {
                    Label("Scan with Camera", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    showPhotoPicker = true
                } label: {
                    Label("Choose from Photos", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private var processingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Reading receipt...")
                .font(.headline)
            Text("Apple Intelligence is parsing your receipt on-device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Something went wrong")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again") {
                scanState = .idle
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }

    // OCR

    private func recognizeText(from image: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let text = request.results?
                    .compactMap { ($0 as? VNRecognizedTextObservation)?.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // Parsing

    private func parseText(_ rawText: String) async {
        scanState = .processing
        do {
            let availability = SystemLanguageModel.default.availability
            guard case .available = availability else {
                scanState = .error("Apple Intelligence is not available. Please enable it in Settings > Apple Intelligence & Siri.")
                return
            }

            let session = LanguageModelSession(instructions: """
                You are a receipt parser. Extract transaction details from raw OCR receipt text.
                Use the TOTAL line for amount, never subtotal.
                Clean up merchant names (remove store numbers, LLC, etc).
            """)

            let response = try await session.respond(
                to: "Parse this receipt: \(rawText)",
                generating: ParsedReceipt.self
            )

            let transaction = response.content.toTransaction()
            modelContext.insert(transaction)
            try modelContext.save()
            scanState = .confirming(transaction)
        } catch {
            scanState = .error(error.localizedDescription)
        }
    }

    private func processPhotoPickerItem(_ item: PhotosPickerItem) async {
        scanState = .processing
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let cgImage = uiImage.cgImage else {
                scanState = .error("Could not load the selected image.")
                return
            }
            let rawText = try await recognizeText(from: cgImage)
            guard !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                scanState = .error("No text found in this image. Try a clearer photo.")
                return
            }
            await parseText(rawText)
        } catch {
            scanState = .error(error.localizedDescription)
        }
    }
}

// Confirm Transaction View

struct ConfirmTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var transaction: Transaction
    let onConfirm: () -> Void
    let onRetry: () -> Void

    var body: some View {
        Form {
            Section("Parsed Details") {
                LabeledContent("Merchant") {
                    TextField("Merchant", text: $transaction.merchant)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("Amount") {
                    TextField("Amount", value: $transaction.amount, format: .currency(code: "USD"))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
                DatePicker("Date", selection: $transaction.date, displayedComponents: .date)
                Picker("Category", selection: $transaction.category) {
                    ForEach(TransactionCategory.allCases, id: \.self) { cat in
                        Text("\(cat.emoji) \(cat.rawValue)").tag(cat)
                    }
                }
            }
            Section {
                Button("Confirm & Save") {
                    try? modelContext.save()
                    onConfirm()
                }
                .frame(maxWidth: .infinity)
                .bold()

                Button("Scan Again", role: .destructive) {
                    modelContext.delete(transaction)
                    onRetry()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Confirm Receipt")
        .navigationBarTitleDisplayMode(.inline)
    }
}
