import SwiftUI

struct ConversationMessagesView: View {
    enum Source {
        case conversation(SocialConversationSummary)
        case friend(SocialFriend)
        case support
    }

    let source: Source

    @State private var socketManager = SocketManager.shared
    @State private var auth = AuthManager.shared
    @State private var draft = ""

    init(conversation: SocialConversationSummary) {
        source = .conversation(conversation)
    }

    init(friend: SocialFriend) {
        source = .friend(friend)
    }

    init(support: Bool) {
        source = .support
    }

    private var title: String {
        switch source {
        case .conversation(let conversation): conversation.title
        case .friend(let friend): friend.displayName
        case .support: "Fifoo Support"
        }
    }

    private var partnerImageURL: String? {
        switch source {
        case .conversation(let conversation):
            let currentID = auth.currentUser.flatMap { UUID(uuidString: $0.userID) }
            return conversation.participants.first(where: { $0.userID != currentID })?.imageURL
        case .friend(let friend):
            return friend.imageURL
        case .support:
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if socketManager.isConversationLoading && socketManager.activeConversationMessages.isEmpty {
                Spacer()
                ProgressView("Loading conversation…")
                Spacer()
            } else if socketManager.activeConversationMessages.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No messages yet",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Send the first message below.")
                )
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(socketManager.activeConversationMessages) { message in
                                messageRow(message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: socketManager.activeConversationMessages.count) { _, _ in
                        if let id = socketManager.activeConversationMessages.last?.id {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(id, anchor: .bottom)
                            }
                        }
                    }
                    .task {
                        if let id = socketManager.activeConversationMessages.last?.id {
                            proxy.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
            }

            composer
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            switch source {
            case .conversation(let conversation):
                socketManager.openConversation(conversation)
            case .friend(let friend):
                socketManager.openConversation(with: friend)
            case .support:
                socketManager.openSupportConversation()
            }
        }
    }

    @ViewBuilder
    private func messageRow(_ message: SocialMessage) -> some View {
        let myID = auth.currentUser.flatMap { UUID(uuidString: $0.userID) }
        let mine = message.senderID == myID

        HStack(alignment: .bottom, spacing: 8) {
            if mine { Spacer(minLength: 55) }

            if !mine {
                SocialAvatarView(
                    imageURL: message.senderImageURL ?? partnerImageURL,
                    name: message.senderName,
                    size: 30
                )
            }

            VStack(alignment: mine ? .trailing : .leading, spacing: 4) {
                Text(message.body)
                    .font(.body)
                    .foregroundStyle(mine ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        mine ? Color.purple : Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 18)
                    )

                if let date = message.createdAt {
                    Text(date.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
            }

            if !mine { Spacer(minLength: 55) }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))

            Button {
                let text = draft
                draft = ""
                socketManager.sendConversationMessage(text)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.purple)
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || socketManager.activeConversationID == nil)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
