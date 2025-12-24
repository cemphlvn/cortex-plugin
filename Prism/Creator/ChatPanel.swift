import SwiftUI

// MARK: - Chat Panel

struct ChatPanel: View {
    let messages: [CreatorMessage]
    @Binding var input: String
    let onSend: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if messages.isEmpty {
                            emptyState
                        } else {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()
                .background(PrismTheme.border)

            // Input bar
            inputBar
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("What would you like to automate?")
                .font(.headline)
                .foregroundStyle(PrismTheme.textPrimary)

            Text("Describe a task and I'll help you create a Prism for it.")
                .font(.subheadline)
                .foregroundStyle(PrismTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Describe your task...", text: $input, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(PrismTheme.textPrimary)
                .lineLimit(1...5)
                .focused($isFocused)
                .onSubmit {
                    if !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                    }
                }

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? PrismTheme.textTertiary
                            : Color.blue
                    )
            }
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(PrismTheme.surface)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: CreatorMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(message.role == .user ? .white : PrismTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user
                            ? AnyShapeStyle(Color.blue)
                            : AnyShapeStyle(PrismTheme.glass)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if message.role == .golden { Spacer(minLength: 40) }
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9, anchor: message.role == .user ? .trailing : .leading)
                .combined(with: .opacity),
            removal: .opacity
        ))
    }
}

// MARK: - Preview

#Preview("Chat Panel - Empty") {
    ChatPanel(
        messages: [],
        input: .constant(""),
        onSend: {}
    )
    .background(PrismTheme.background)
}

#Preview("Chat Panel - With Messages") {
    ChatPanel(
        messages: [
            CreatorMessage(role: .user, text: "I want to summarize meeting notes"),
            CreatorMessage(role: .golden, text: "Can you show me an example of meeting notes you'd paste in?"),
            CreatorMessage(role: .user, text: "Something like: Team sync on Monday. Discussed Q1 goals, budget allocation. John to follow up on vendor contracts."),
            CreatorMessage(role: .golden, text: "What makes a great summary for you? Bullet points, key decisions, or action items?")
        ],
        input: .constant(""),
        onSend: {}
    )
    .background(PrismTheme.background)
}
