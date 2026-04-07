import SwiftUI

struct ChatHistoryView: View {
    @Bindable var viewModel: AdvisorViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()

                if viewModel.isLoadingHistory {
                    ProgressView()
                } else if viewModel.pastSessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No previous chats")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Your advisor conversations will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.pastSessions) { session in
                                ChatSessionRow(session: session)
                                    .onTapGesture {
                                        Task {
                                            await viewModel.loadSession(id: session.id)
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $viewModel.selectedSession) { session in
                PastChatView(session: session)
            }
        }
    }
}

struct ChatSessionRow: View {
    let session: ChatSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(session.messageCount) messages")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(session.preview)
                .font(.body)
                .lineLimit(2)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
    }
}
