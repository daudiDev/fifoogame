import SwiftUI

struct SocialAvatarView: View {
    let imageURL: String?
    let name: String
    var size: CGFloat = 48

    private var initials: String {
        let pieces = name.split(separator: " ").prefix(2)
        let value = pieces.compactMap(\.first).map(String.init).joined()
        return value.isEmpty ? "F" : value.uppercased()
    }

    var body: some View {
        Group {
            if let imageURL,
               let url = URL(string: imageURL),
               !imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
        .accessibilityLabel("\(name) profile image")
    }

    private var placeholder: some View {
        Circle()
            .fill(.purple.opacity(0.16))
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                    .foregroundStyle(.purple)
            }
    }
}

struct SocialRelativeTimeText: View {
    let date: Date?
    var prefix: String = ""

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var text: String {
        guard let date else { return prefix + "Not recently active" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let relative = formatter.localizedString(for: date, relativeTo: Date())
        return prefix + relative
    }
}
