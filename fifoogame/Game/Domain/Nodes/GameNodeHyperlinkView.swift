//
//  GameNodeHyperlinkView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//



import SwiftUI
import WebKit


enum HyperlinkNodeViewAction:
    Equatable,
    Sendable {

    case upvote
    case downvote
}


private enum HyperlinkLocalVote:
    Equatable {

    case upvote
    case downvote
}


struct GameNodeHyperlinkView: View {

    let node:
        GameMapNode


    let onAction:
        ((HyperlinkNodeViewAction, GameMapNode) -> Void)?


    @Environment(\.dismiss)
    private var dismiss


    @State
    private var selectedVote:
        HyperlinkLocalVote?


    init(
        node: GameMapNode,
        onAction: ((HyperlinkNodeViewAction, GameMapNode) -> Void)? = nil
    ) {

        self.node = node
        self.onAction = onAction
    }


    var body: some View {

        ZStack {

            Color(.systemBackground)
                .ignoresSafeArea()


            webContent
                .ignoresSafeArea(
                    edges: .bottom
                )


            VStack(
                spacing: 0
            ) {

                header

                Spacer()

                voteControls
            }
        }
        .statusBarHidden(
            false
        )
    }
}


// =====================================================
// MARK: - Content
// =====================================================

private extension GameNodeHyperlinkView {

    @ViewBuilder
    var webContent: some View {

        if let url = resolvedURL {

            HyperlinkWebView(
                url: url
            )

        } else {

            ContentUnavailableView(
                "Unable to Open Link",
                systemImage:
                    "link.badge.plus",
                description:
                    Text(
                        "This hyperlink does not contain a valid web address."
                    )
            )
        }
    }


    var resolvedURL: URL? {

        guard case let .hyperlink(
            content
        ) = node.content
        else {

            return nil
        }


        let cleaned =
            content.urlString
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        guard
            !cleaned.isEmpty,
            cleaned.lowercased() != "none"
        else {

            return nil
        }


        if let url = URL(
            string: cleaned
        ),
           url.scheme != nil
        {

            return url
        }


        return URL(
            string:
                "https://\(cleaned)"
        )
    }


    var title: String {

        guard case let .hyperlink(
            content
        ) = node.content
        else {

            return "Link"
        }


        let cleaned =
            content.title
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        return cleaned.isEmpty
            ? "Link"
            : cleaned
    }
}


// =====================================================
// MARK: - Header
// =====================================================

private extension GameNodeHyperlinkView {

    var header: some View {

        HStack(
            spacing: 12
        ) {

            Button {

                dismiss()

            } label: {

                Image(
                    systemName:
                        "xmark"
                )
                .font(
                    .system(
                        size: 15,
                        weight: .bold
                    )
                )
                .frame(
                    width: 42,
                    height: 42
                )
                .background(
                    .ultraThinMaterial,
                    in:
                        Circle()
                )
            }
            .accessibilityLabel(
                "Cancel"
            )


            Text(
                title
            )
            .font(
                .headline
            )
            .lineLimit(
                1
            )
            .truncationMode(
                .tail
            )


            Spacer(
                minLength: 0
            )
        }
        .padding(
            .horizontal,
            14
        )
        .padding(
            .vertical,
            8
        )
        .background(
            .regularMaterial
        )
    }
}


// =====================================================
// MARK: - Vote Controls
// =====================================================

private extension GameNodeHyperlinkView {

    var voteControls: some View {

        HStack(
            spacing: 12
        ) {

            voteButton(
                title: "Upvote",
                systemImage: "hand.thumbsup.fill",
                isSelected:
                    selectedVote == .upvote
            ) {

                selectedVote =
                    .upvote

                onAction?(
                    .upvote,
                    node
                )
            }


            voteButton(
                title: "Downvote",
                systemImage: "hand.thumbsdown.fill",
                isSelected:
                    selectedVote == .downvote
            ) {

                selectedVote =
                    .downvote

                onAction?(
                    .downvote,
                    node
                )
            }
        }
        .padding(
            .horizontal,
            16
        )
        .padding(
            .top,
            10
        )
        .padding(
            .bottom,
            14
        )
        .background(
            .regularMaterial
        )
    }


    func voteButton(
        title: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {

        Button(
            action:
                action
        ) {

            Label(
                title,
                systemImage:
                    systemImage
            )
            .font(
                .system(
                    size: 15,
                    weight: .semibold
                )
            )
            .frame(
                maxWidth:
                    .infinity
            )
            .padding(
                .vertical,
                12
            )
            .foregroundStyle(
                isSelected
                    ? Color.white
                    : Color.primary
            )
            .background {

                RoundedRectangle(
                    cornerRadius:
                        14,
                    style:
                        .continuous
                )
                .fill(
                    isSelected
                        ? Color.accentColor
                        : Color.primary.opacity(0.08)
                )
            }
        }
        .buttonStyle(
            .plain
        )
    }
}


// =====================================================
// MARK: - WKWebView
// =====================================================

private struct HyperlinkWebView:
    UIViewRepresentable {

    let url: URL


    func makeCoordinator() -> Coordinator {

        Coordinator()
    }


    func makeUIView(
        context: Context
    ) -> WKWebView {

        let configuration =
            WKWebViewConfiguration()


        let webView =
            WKWebView(
                frame:
                    .zero,
                configuration:
                    configuration
            )


        webView.navigationDelegate =
            context.coordinator

        webView.uiDelegate =
            context.coordinator

        webView.allowsBackForwardNavigationGestures =
            false

        webView.allowsLinkPreview =
            false

        webView.scrollView.contentInsetAdjustmentBehavior =
            .automatic


        webView.load(
            URLRequest(
                url:
                    url
            )
        )


        return webView
    }


    func updateUIView(
        _ webView: WKWebView,
        context: Context
    ) {

        guard
            webView.url != url
        else {

            return
        }


        webView.load(
            URLRequest(
                url:
                    url
            )
        )
    }


    final class Coordinator:
        NSObject,
        WKNavigationDelegate,
        WKUIDelegate {

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {

            if navigationAction.targetFrame == nil,
               let url = navigationAction.request.url
            {

                webView.load(
                    URLRequest(
                        url:
                            url
                    )
                )
            }


            return nil
        }
    }
}
