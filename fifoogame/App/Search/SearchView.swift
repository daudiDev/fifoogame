//
//  SearchView.swift
//  fifoo
//
//  Created by Daudi Sagala on 5/25/26.
//

import SwiftUI
import UIKit


// MARK: - Search View

struct SearchView: View {

    @Binding
    var isShowingSearchView: Bool

    private let socketManager =
        SocketManager.shared

    @Environment(\.dismiss)
    private var dismiss


    var body: some View {

        VStack(
            spacing: 0
        ) {

            titleSection

            Divider()

            searchField

            Divider()

            searchContent
        }
        .background(
            Color(uiColor: .systemBackground)
        )
    }
}


// =====================================================
// MARK: - Title
// =====================================================

private extension SearchView {

    var titleSection: some View {

        HStack(
            spacing: 12
        ) {

            Text(
                "Search"
            )
            .font(
                .headline
            )
            .foregroundStyle(
                .primary
            )


            Spacer()


            Button {

                closeSearch()

            } label: {

                Image(
                    systemName:
                        "xmark"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    .secondary
                )
                .frame(
                    width: 32,
                    height: 32
                )
                .background(
                    Circle()
                        .fill(
                            Color(
                                uiColor:
                                    .secondarySystemBackground
                            )
                        )
                )
            }
            .buttonStyle(
                .plain
            )
            .accessibilityLabel(
                "Close search"
            )
        }
        .padding(
            .horizontal,
            16
        )
        .padding(
            .vertical,
            12
        )
    }
}


// =====================================================
// MARK: - Search Field
// =====================================================

private extension SearchView {

    var searchField: some View {

        HStack(
            spacing: 10
        ) {

            Image(
                systemName:
                    "magnifyingglass"
            )
            .foregroundStyle(
                .secondary
            )


            TextField(
                "Search today's map",
                text:
                    searchTextBinding
            )
            .textInputAutocapitalization(
                .never
            )
            .autocorrectionDisabled()
            .submitLabel(
                .search
            )
            .onSubmit {

                socketManager.submitSearch()
            }


            if !socketManager.searchQuery.isEmpty {

                Button {

                    socketManager.clearSearch()

                } label: {

                    Image(
                        systemName:
                            "xmark.circle.fill"
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
                .buttonStyle(
                    .plain
                )
                .accessibilityLabel(
                    "Clear search"
                )
            }
        }
        .padding(
            .horizontal,
            14
        )
        .frame(
            minHeight: 48
        )
        .background(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .fill(
                Color(
                    uiColor:
                        .secondarySystemBackground
                )
            )
        )
        .padding(
            .horizontal,
            16
        )
        .padding(
            .vertical,
            12
        )
    }


    var searchTextBinding:
        Binding<String> {

        Binding(
            get: {

                socketManager.searchQuery
            },
            set: { newValue in

                socketManager.updateSearchQuery(
                    newValue
                )
            }
        )
    }
}


// =====================================================
// MARK: - Results
// =====================================================

private extension SearchView {

    @ViewBuilder
    var searchContent: some View {

        let cleanedQuery =
            socketManager.searchQuery
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        if cleanedQuery.isEmpty {

            ContentUnavailableView(
                "Search Fifoo",
                systemImage:
                    "magnifyingglass",
                description:
                    Text(
                        "Search today's map by title, activity type, post type, person, tag, time, or other stop text."
                    )
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )

        } else if socketManager.searchResults.isEmpty {

            ContentUnavailableView.search(
                text:
                    cleanedQuery
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )

        } else {

            List(
                socketManager.searchResults
            ) { result in

                Button {

                    selectSearchResult(
                        result
                    )

                } label: {

                    SearchResultRow(
                        result:
                            result
                    )
                }
                .buttonStyle(
                    .plain
                )
            }
            .listStyle(
                .plain
            )
        }
    }


    func selectSearchResult(
        _ result: SocketManager.SearchResult
    ) {

        // Store the intent first. AppOverlayView activates it from the
        // Search sheet's onDismiss callback so the destination node view is
        // never presented on top of this sheet.
        socketManager.selectSearchResult(
            result
        )

        isShowingSearchView =
            false
    }


    func closeSearch() {

        socketManager.clearSearch()

        isShowingSearchView =
            false

        dismiss()
    }
}


// =====================================================
// MARK: - Search Result Row
// =====================================================

private struct SearchResultRow: View {

    let result:
        SocketManager.SearchResult


    var body: some View {

        HStack(
            spacing: 12
        ) {

            nodeImage


            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    result.title
                )
                .font(
                    .headline
                )
                .foregroundStyle(
                    .primary
                )
                .lineLimit(
                    2
                )


                Text(
                    result.subtitle
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    .secondary
                )
                .lineLimit(
                    1
                )
            }


            Spacer(
                minLength: 8
            )


            VStack(
                alignment: .trailing,
                spacing: 4
            ) {

                Text(
                    result.time.displayClockString
                )
                .font(
                    .subheadline
                )
                .fontWeight(
                    .semibold
                )
                .monospacedDigit()


                Text(
                    result.kind.displayName
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .padding(
            .vertical,
            6
        )
        .contentShape(
            Rectangle()
        )
    }


    @ViewBuilder
    var nodeImage: some View {

        Group {

            switch result.image {

            case let .asset(name):

                if let uiImage =
                    UIImage(
                        named:
                            name
                    )
                {

                    Image(
                        uiImage:
                            uiImage
                    )
                    .resizable()
                    .scaledToFill()

                } else {

                    placeholderImage
                }


            case let .remote(urlString):

                if let url =
                    URL(
                        string:
                            urlString
                    )
                {

                    AsyncImage(
                        url:
                            url
                    ) { phase in

                        switch phase {

                        case let .success(image):

                            image
                                .resizable()
                                .scaledToFill()

                        case .empty:

                            ZStack {

                                placeholderImage

                                ProgressView()
                            }

                        case .failure:

                            placeholderImage

                        @unknown default:

                            placeholderImage
                        }
                    }

                } else {

                    placeholderImage
                }


            case .systemSymbol,
                 .none:

                placeholderImage
            }
        }
        .frame(
            width: 48,
            height: 48
        )
        .clipShape(
            Circle()
        )
        .overlay {

            Circle()
                .stroke(
                    .secondary.opacity(0.25),
                    lineWidth: 1
                )
        }
    }


    var placeholderImage: some View {

        Image(
            uiImage:
                GameNodePlaceholderImage.image(
                    for:
                        result.kind
                )
        )
        .resizable()
        .scaledToFill()
    }
}
