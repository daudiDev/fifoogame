//
//  GameNodeMediaView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//



import SwiftUI
import UIKit
import AVFoundation
import WebKit


/// Full-screen, read-only presentation for a Media map node.
///
/// Media nodes intentionally do not open `GameNodeEditorView` when tapped.
/// The content fills the screen like a short-form media experience:
/// - images aspect-fill the screen,
/// - videos autoplay and loop,
/// - GIFs animate automatically,
/// - the title is drawn in the upper overlay,
/// - the only control is the exit / Cancel button.
struct GameNodeMediaView: View {

    let node:
        GameMapNode


    @Environment(\.dismiss)
    private var dismiss


    var body: some View {

        GeometryReader { geometry in

            ZStack(
                alignment:
                    .top
            ) {

                Color.black
                    .ignoresSafeArea()


                if case let .media(
                    content
                ) = node.content {

                    mediaContent(
                        content,
                        size:
                            geometry.size
                    )
                    .frame(
                        width:
                            geometry.size.width,
                        height:
                            geometry.size.height
                    )
                    .clipped()
                    .ignoresSafeArea()


                    topOverlay(
                        content:
                            content,
                        safeAreaTop:
                            geometry.safeAreaInsets.top
                    )

                } else {

                    mediaPlaceholder(
                        size:
                            geometry.size
                    )
                    .ignoresSafeArea()


                    topOverlay(
                        title:
                            node.content.title,
                        safeAreaTop:
                            geometry.safeAreaInsets.top
                    )
                }
            }
            .frame(
                width:
                    geometry.size.width,
                height:
                    geometry.size.height
            )
        }
        .background(
            Color.black
        )
        .statusBarHidden(
            true
        )
    }
}


// =====================================================
// MARK: - Media Content
// =====================================================

private extension GameNodeMediaView {

    @ViewBuilder
    func mediaContent(
        _ content:
            MediaNodeContent,
        size:
            CGSize
    ) -> some View {

        switch content.mediaType {

        case .image:

            imageMedia(
                content,
                size:
                    size
            )


        case .video:

            if let url =
                resolvedMediaURL(
                    from:
                        content.urlString
                ) {

                FullScreenLoopingVideoView(
                    url:
                        url
                )

            } else {

                fallbackMediaImage(
                    content,
                    size:
                        size
                )
            }


        case .gif:

            if let url =
                resolvedMediaURL(
                    from:
                        content.urlString
                ) {

                FullScreenGIFView(
                    url:
                        url
                )

            } else {

                fallbackMediaImage(
                    content,
                    size:
                        size
                )
            }
        }
    }


    @ViewBuilder
    func imageMedia(
        _ content:
            MediaNodeContent,
        size:
            CGSize
    ) -> some View {

        if let url =
            resolvedMediaURL(
                from:
                    content.urlString
            ) {

            AsyncImage(
                url:
                    url
            ) { phase in

                switch phase {

                case .empty:

                    ZStack {

                        fallbackMediaImage(
                            content,
                            size:
                                size
                        )


                        ProgressView()
                            .tint(
                                .white
                            )
                    }


                case let .success(
                    image
                ):

                    image
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width:
                                size.width,
                            height:
                                size.height
                        )
                        .clipped()


                case .failure:

                    fallbackMediaImage(
                        content,
                        size:
                            size
                    )


                @unknown default:

                    fallbackMediaImage(
                        content,
                        size:
                            size
                    )
                }
            }

        } else {

            fallbackMediaImage(
                content,
                size:
                    size
            )
        }
    }


    @ViewBuilder
    func fallbackMediaImage(
        _ content:
            MediaNodeContent,
        size:
            CGSize
    ) -> some View {

        switch content.image {

        case let .asset(
            name
        ):

            if let image =
                UIImage(
                    named:
                        name
                ) {

                Image(
                    uiImage:
                        image
                )
                .resizable()
                .scaledToFill()
                .frame(
                    width:
                        size.width,
                    height:
                        size.height
                )
                .clipped()

            } else {

                mediaPlaceholder(
                    size:
                        size
                )
            }


        case let .remote(
            urlString
        ):

            if let url =
                resolvedMediaURL(
                    from:
                        urlString
                ) {

                AsyncImage(
                    url:
                        url
                ) { phase in

                    if case let .success(
                        image
                    ) = phase {

                        image
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width:
                                    size.width,
                                height:
                                    size.height
                            )
                            .clipped()

                    } else {

                        mediaPlaceholder(
                            size:
                                size
                        )
                    }
                }

            } else {

                mediaPlaceholder(
                    size:
                        size
                )
            }


        case .systemSymbol,
             nil:

            mediaPlaceholder(
                size:
                    size
            )
        }
    }


    func mediaPlaceholder(
        size:
            CGSize
    ) -> some View {

        Image(
            uiImage:
                GameNodePlaceholderImage.image(
                    for:
                        .media
                )
        )
        .resizable()
        .scaledToFill()
        .frame(
            width:
                size.width,
            height:
                size.height
        )
        .clipped()
        .overlay {

            Color.black
                .opacity(
                    0.28
                )
        }
    }


    func resolvedMediaURL(
        from value:
            String?
    ) -> URL? {

        guard let value
        else {

            return nil
        }


        let cleaned =
            value
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        guard !cleaned.isEmpty
        else {

            return nil
        }


        return URL(
            string:
                cleaned
        )
    }
}


// =====================================================
// MARK: - Upper Overlay
// =====================================================

private extension GameNodeMediaView {

    func topOverlay(
        content:
            MediaNodeContent,
        safeAreaTop:
            CGFloat
    ) -> some View {

        topOverlay(
            title:
                content.title,
            safeAreaTop:
                safeAreaTop
        )
    }


    func topOverlay(
        title:
            String,
        safeAreaTop:
            CGFloat
    ) -> some View {

        ZStack(
            alignment:
                .top
        ) {

            LinearGradient(
                colors: [
                    .black.opacity(
                        0.88
                    ),
                    .black.opacity(
                        0.48
                    ),
                    .clear
                ],
                startPoint:
                    .top,
                endPoint:
                    .bottom
            )
            .frame(
                height:
                    safeAreaTop
                    + 150
            )
            .allowsHitTesting(
                false
            )


            HStack(
                alignment:
                    .top,
                spacing:
                    16
            ) {

                Text(
                    title
                )
                .font(
                    .title2
                        .weight(
                            .bold
                        )
                )
                .foregroundStyle(
                    .white
                )
                .lineLimit(
                    2
                )
                .multilineTextAlignment(
                    .leading
                )
                .shadow(
                    color:
                        .black.opacity(
                            0.55
                        ),
                    radius:
                        3,
                    x:
                        0,
                    y:
                        1
                )


                Spacer(
                    minLength:
                        12
                )


                Button {

                    dismiss()

                } label: {

                    Image(
                        systemName:
                            "xmark"
                    )
                    .font(
                        .system(
                            size:
                                17,
                            weight:
                                .bold
                        )
                    )
                    .foregroundStyle(
                        .white
                    )
                    .frame(
                        width:
                            44,
                        height:
                            44
                    )
                    .background {

                        Circle()
                            .fill(
                                .black.opacity(
                                    0.48
                                )
                            )
                    }
                    .overlay {

                        Circle()
                            .stroke(
                                .white.opacity(
                                    0.16
                                ),
                                lineWidth:
                                    1
                            )
                    }
                }
                .accessibilityLabel(
                    "Cancel"
                )
            }
            .padding(
                .horizontal,
                18
            )
            .padding(
                .top,
                safeAreaTop
                + 10
            )
        }
    }
}


// =====================================================
// MARK: - Full-Screen Looping Video
// =====================================================

/// Uses an AVPlayerLayer rather than SwiftUI's `VideoPlayer` so no playback
/// controls are introduced. The Media screen therefore keeps exactly one
/// visible button: Cancel / exit.
private struct FullScreenLoopingVideoView:
    UIViewRepresentable {

    let url:
        URL


    func makeCoordinator() -> Coordinator {

        Coordinator()
    }


    func makeUIView(
        context:
            Context
    ) -> PlayerContainerView {

        let view =
            PlayerContainerView()


        context.coordinator.configure(
            url:
                url,
            in:
                view
        )


        return view
    }


    func updateUIView(
        _ uiView:
            PlayerContainerView,
        context:
            Context
    ) {

        if context.coordinator.currentURL != url {

            context.coordinator.configure(
                url:
                    url,
                in:
                    uiView
            )
        }


        context.coordinator.player?
            .play()
    }


    static func dismantleUIView(
        _ uiView:
            PlayerContainerView,
        coordinator:
            Coordinator
    ) {

        coordinator.stop()

        uiView.playerLayer.player =
            nil
    }


    final class Coordinator {

        var player:
            AVQueuePlayer?

        var looper:
            AVPlayerLooper?

        var currentURL:
            URL?


        func configure(
            url:
                URL,
            in view:
                PlayerContainerView
        ) {

            stop()


            let item =
                AVPlayerItem(
                    url:
                        url
                )


            let player =
                AVQueuePlayer()


            player.actionAtItemEnd =
                .none


            let looper =
                AVPlayerLooper(
                    player:
                        player,
                    templateItem:
                        item
                )


            self.player =
                player

            self.looper =
                looper

            self.currentURL =
                url


            view.playerLayer.player =
                player

            view.playerLayer.videoGravity =
                .resizeAspectFill


            player.play()
        }


        func stop() {

            player?
                .pause()

            looper?
                .disableLooping()

            looper =
                nil

            player?
                .removeAllItems()

            player =
                nil

            currentURL =
                nil
        }
    }


    final class PlayerContainerView:
        UIView {

        override class var layerClass:
            AnyClass {

            AVPlayerLayer.self
        }


        var playerLayer:
            AVPlayerLayer {

            layer as! AVPlayerLayer
        }
    }
}


// =====================================================
// MARK: - Full-Screen GIF
// =====================================================

/// WKWebView is used only as a lightweight GIF renderer so animated GIFs play
/// without adding another image-loading dependency. Scrolling, selection and
/// user interaction are disabled, keeping the presentation media-only.
private struct FullScreenGIFView:
    UIViewRepresentable {

    let url:
        URL


    func makeCoordinator() -> Coordinator {

        Coordinator()
    }


    func makeUIView(
        context:
            Context
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


        webView.isOpaque =
            false

        webView.backgroundColor =
            .black

        webView.scrollView.backgroundColor =
            .black

        webView.scrollView.isScrollEnabled =
            false

        webView.scrollView.bounces =
            false

        webView.isUserInteractionEnabled =
            false


        load(
            url:
                url,
            in:
                webView,
            coordinator:
                context.coordinator
        )


        return webView
    }


    func updateUIView(
        _ webView:
            WKWebView,
        context:
            Context
    ) {

        guard context.coordinator.currentURL != url
        else {

            return
        }


        load(
            url:
                url,
            in:
                webView,
            coordinator:
                context.coordinator
        )
    }


    private func load(
        url:
            URL,
        in webView:
            WKWebView,
        coordinator:
            Coordinator
    ) {

        coordinator.currentURL =
            url


        let escapedURL =
            htmlEscaped(
                url.absoluteString
            )


        let html =
            """
            <!doctype html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
                <style>
                    html, body {
                        margin: 0;
                        padding: 0;
                        width: 100%;
                        height: 100%;
                        overflow: hidden;
                        background: #000;
                    }

                    img {
                        display: block;
                        width: 100%;
                        height: 100%;
                        object-fit: cover;
                    }
                </style>
            </head>
            <body>
                <img src="\(escapedURL)" alt="">
            </body>
            </html>
            """


        webView.loadHTMLString(
            html,
            baseURL:
                nil
        )
    }


    private func htmlEscaped(
        _ value:
            String
    ) -> String {

        value
            .replacingOccurrences(
                of:
                    "&",
                with:
                    "&amp;"
            )
            .replacingOccurrences(
                of:
                    "\"",
                with:
                    "&quot;"
            )
            .replacingOccurrences(
                of:
                    "<",
                with:
                    "&lt;"
            )
            .replacingOccurrences(
                of:
                    ">",
                with:
                    "&gt;"
            )
    }


    final class Coordinator {

        var currentURL:
            URL?
    }
}
