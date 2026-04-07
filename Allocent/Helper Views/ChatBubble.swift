import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        if message.role == .system {
            Text(message.content)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .accessibilityLabel("System message: \(message.content)")
        } else {
            HStack(alignment: .bottom, spacing: 8) {
                if isUser { Spacer(minLength: 60) }

                if message.role == .assistant {
                    Circle()
                        .fill(Color("OliveGreen").opacity(0.15))
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color("OliveGreen"))
                        }
                }

                Text(message.content)
                    .font(.body)
                    .foregroundStyle(isUser ? Color("PrimaryButtonText") : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? Color("PrimaryButton") : Color("CardBackground"))
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 18,
                            bottomLeadingRadius: isUser ? 18 : 4,
                            bottomTrailingRadius: isUser ? 4 : 18,
                            topTrailingRadius: 18
                        )
                    )
                    .shadow(
                        color: Color.black.opacity(isUser ? 0.08 : 0.05),
                        radius: 4, x: 0, y: 2
                    )
                    .accessibilityLabel(
                        isUser
                            ? "You said: \(message.content)"
                            : "Advisor said: \(message.content)"
                    )

                if !isUser { Spacer(minLength: 60) }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ChatBubble(message: ChatMessage(role: .assistant, content: "Hi! I'm your budget advisor."))
        ChatBubble(message: ChatMessage(role: .user, content: "How am I doing this month?"))
        ChatBubble(message: ChatMessage(role: .system, content: "Session reset."))
    }
    .padding(.vertical)
    .background(Color("Background"))
}
