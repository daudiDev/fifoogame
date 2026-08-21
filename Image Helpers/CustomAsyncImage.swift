//
//  Untitled.swift
//  fifoo
//
//  Created by Daudi Sagala on 5/30/26.
//


import SwiftUI

struct CustomAsyncImage: View {
    @StateObject private var loader = ImageLoader()
    let url: URL

    init(url: URL) {
        self.url = url
    }
 
    var body: some View {
        image
            .onAppear {
                loader.loadImage(from: url)
            }
            .onDisappear { loader.cancel() }
    }

    private var image: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
            } else {
                
                Image("placeholder")
                    .resizable()
                
            }
        }
    }
}

