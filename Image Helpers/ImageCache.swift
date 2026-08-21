//
//  ImageCache.swift
//  fifoo
//
//  Created by Daudi Sagala on 5/30/26.
//

import SwiftUI
import Combine

class ImageCache {
    static let shared = ImageCache()
    private init() {}
    private var cache = NSCache<NSString, UIImage>()

    func getImage(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
