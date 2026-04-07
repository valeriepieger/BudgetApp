//
//  AdvisorView.swift
//  Allocent
//
//  Created by Valerie on 3/28/26.
//

import SwiftUI

struct AdvisorView: View {
    @State private var viewModel = AdvisorViewModel()
    @State private var isFirstAppear = true

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {
                AdvisorHeader(viewModel: viewModel)
                ChatContentView(viewModel: viewModel)
            }
        }
        .onAppear {
            Task {
                if isFirstAppear {
                    isFirstAppear = false
                    await viewModel.setup()
                } else {
                    await viewModel.startNewSession()
                }
            }
        }
        .sheet(isPresented: $viewModel.showHistory) {
            ChatHistoryView(viewModel: viewModel)
        }
    }
}

struct AdvisorHeader: View {
    @Bindable var viewModel: AdvisorViewModel

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color("OliveGreen"), Color("OliveGreen").opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 42, height: 42)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("Advisor")
                    .font(.title3)
                    .bold()
                Text("Budget Assistant")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task { await viewModel.loadHistory() }
                viewModel.showHistory = true
            } label: {
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.title3)
                    .foregroundStyle(Color("OliveGreen"))
            }
            .accessibilityLabel("Chat history")
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color("CardBackground"))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}


struct ChatContentView: View {
    @Bindable var viewModel: AdvisorViewModel
    @FocusState private var isTextFieldFocused: Bool
    
    //user won't be able to send a message they typed if view model still loading (AI still crafting response)
    private var canSend: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isLoading
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isLoading {
                            //if AI coming up with response (loading), typing indicator on left side
                            HStack {
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal)
                            .id("loading")
                        }
                    }
                    .padding(.vertical, 12)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.isLoading) { _, isLoading in
                    if isLoading {
                        withAnimation {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                TextField("Ask about your budget...", text: $viewModel.inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color("CardBackground"))
                    .clipShape(.rect(cornerRadius: 22))
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                    .onSubmit { sendMessage() }
                    .focused($isTextFieldFocused)

                Button("Send message", systemImage: "arrow.up.circle.fill", action: sendMessage)
                    .labelStyle(.iconOnly)
                    .font(.system(size: 34))
                    .foregroundStyle(canSend ? Color("OliveGreen") : Color("OliveGreen").opacity(0.3))
                    .disabled(!canSend)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color("Background"))

        }
        .onTapGesture { //to get keyboard out of the way on tap outside of keyboard
            isTextFieldFocused = false
        }
    }

    private func sendMessage() {
        guard canSend else { return }
        Task { await viewModel.sendMessage() }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = viewModel.messages.last?.id {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color("OliveGreen"))
                    .frame(width: 8, height: 8)
                    .scaleEffect(phase == index ? 1.3 : 0.7)
                    .opacity(phase == index ? 1.0 : 0.4)
                    .animation(.easeInOut(duration: 0.4), value: phase)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("CardBackground"))
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .accessibilityLabel("Advisor is thinking")
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(400))
                phase = (phase + 1) % 3
            }
        }
    }
}

#Preview {
    AdvisorView()
}
