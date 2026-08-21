//
//  FullScreenImageView.swift
//  Fifoo Play
//
//  Created by Daudi Sagala on 8/10/26.
//
//

import SwiftUI
import UIKit


// MARK: - Image Cache

@MainActor
final class ExerciseImageCache {

    static let shared = ExerciseImageCache()

    private let cache =
        NSCache<NSURL, UIImage>()

    private init() {}


    func image(
        for url: URL
    ) -> UIImage? {

        cache.object(
            forKey: url as NSURL
        )
    }


    func insert(
        _ image: UIImage,
        for url: URL
    ) {

        cache.setObject(
            image,
            forKey: url as NSURL
        )
    }
}


// MARK: - Full Screen Image

struct FullScreenImageView: View {

    var geometry: GeometryProxy

    let url: URL


    @State private var loadedImage: UIImage?

    @State private var isLoading = false


    var body: some View {

        ZStack {

            // MARK: Background

            Color.black


            // MARK: Loaded Image

            if let loadedImage {

                Image(
                    uiImage: loadedImage
                )
                .resizable()
                .scaledToFill()
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .clipped()


            } else {

                // Don't put a large ProgressView here.
                //
                // During TikTok-style page transitions,
                // a plain black background produces a much
                // smoother result than flashing a spinner.
                Color.black
            }
        }
        .frame(
            width: geometry.size.width,
            height: geometry.size.height
        )
        .clipped()

        .task(id: url) {

            await loadImage()
        }
    }


    // MARK: - Load Image

    @MainActor
    private func loadImage() async {

        // MARK: Already Loaded In This View

        if loadedImage != nil {
            return
        }


        // MARK: Cache Hit

        if let cachedImage =
            ExerciseImageCache.shared.image(
                for: url
            ) {

            loadedImage = cachedImage

            return
        }


        // MARK: Prevent Duplicate Request

        guard !isLoading else {
            return
        }

        isLoading = true

        defer {

            isLoading = false
        }


        // MARK: Download

        do {

            let (
                data,
                response
            ) = try await URLSession.shared.data(
                from: url
            )


            // MARK: Verify HTTP Response

            if let httpResponse =
                response as? HTTPURLResponse {

                guard
                    200...299 ~=
                        httpResponse.statusCode
                else {

                    return
                }
            }


            // MARK: Create UIImage

            guard let image =
                    UIImage(data: data)
            else {

                return
            }


            // MARK: Save To Cache

            ExerciseImageCache.shared.insert(
                image,
                for: url
            )


            // MARK: Display

            loadedImage = image


        } catch {

            guard !Task.isCancelled else {
                return
            }

            print(
                "Exercise image loading failed:",
                error.localizedDescription
            )
        }
    }
}
