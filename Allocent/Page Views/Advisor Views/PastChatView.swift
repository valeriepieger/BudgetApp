import SwiftUI

struct PastChatView: View {
    let session: ChatSession
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(session.messages) { message in
                            ChatBubble(message: message)
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle(session.formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
