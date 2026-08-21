//
//  ImageLoader.swift
//  fifoo
//
//  Created by Daudi Sagala on 5/30/26.
//

import Foundation
import UIKit
import Combine

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var cancellable: AnyCancellable?
    
    func loadImage(from url: URL) {
        let urlString = url.absoluteString
        
        // Check cache first
        if let cachedImage = ImageCache.shared.getImage(forKey: urlString) {
            self.image = cachedImage
            return
        }
        
        // If not in cache, fetch from network
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                guard let self = self else { return }
                if let image = image {
                    ImageCache.shared.setImage(image, forKey: urlString)
                }
                self.image = image
            }
    }
    
    func cancel() {
        cancellable?.cancel()
    }
}
