//
//  GameNodePlaceholderImage.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/24/26.
//

import UIKit


enum GameNodePlaceholderImage {

    /// Optional asset names you can add to Assets.xcassets later.
    /// If an asset is present it wins; otherwise a generated raster
    /// placeholder is used. No SF Symbols are used for map markers.
    static func assetName(
        for kind: GameNodeKind
    ) -> String {

        "node-placeholder-\(kind.rawValue)"
    }


    static func image(
        for kind: GameNodeKind,
        size: CGFloat = 160
    ) -> UIImage {

        if let asset = UIImage(
            named: assetName(for: kind)
        ) {
            return asset
        }

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(
                width: size,
                height: size
            )
        )

        return renderer.image { context in

            let rect = CGRect(
                x: 0,
                y: 0,
                width: size,
                height: size
            )

            let cgContext = context.cgContext

            let colors = palette(for: kind)

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: [
                    colors.top.cgColor,
                    colors.bottom.cgColor
                ] as CFArray,
                locations: [0, 1]
            )

            if let gradient {
                cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(
                        x: rect.minX,
                        y: rect.minY
                    ),
                    end: CGPoint(
                        x: rect.maxX,
                        y: rect.maxY
                    ),
                    options: []
                )
            } else {
                colors.top.setFill()
                cgContext.fill(rect)
            }

            // A subtle photographic-style highlight so the placeholder
            // reads as an image tile instead of an icon glyph.
            cgContext.setFillColor(
                UIColor.white
                    .withAlphaComponent(0.10)
                    .cgColor
            )

            cgContext.fillEllipse(
                in: CGRect(
                    x: -size * 0.12,
                    y: -size * 0.20,
                    width: size * 0.90,
                    height: size * 0.90
                )
            )

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(
                    ofSize: size * 0.26,
                    weight: .bold
                ),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph,
                .kern: size * 0.008
            ]

            let text = monogram(for: kind) as NSString
            let textHeight = size * 0.34

            text.draw(
                in: CGRect(
                    x: 0,
                    y: (size - textHeight) * 0.52,
                    width: size,
                    height: textHeight
                ),
                withAttributes: attributes
            )
        }
    }
}


private extension GameNodePlaceholderImage {

    struct Palette {
        let top: UIColor
        let bottom: UIColor
    }


    static func monogram(
        for kind: GameNodeKind
    ) -> String {

        switch kind {

        case .play:
            return "PL"

        case .user:
            return "US"

        case .activity:
            return "AC"

        case .post:
            return "PO"

        case .media:
            return "ME"

        case .hyperlink:
            return "LK"
        }
    }


    static func palette(
        for kind: GameNodeKind
    ) -> Palette {

        switch kind {

        case .play:
            return Palette(
                top: UIColor(
                    red: 0.18,
                    green: 0.58,
                    blue: 0.82,
                    alpha: 1
                ),
                bottom: UIColor(
                    red: 0.10,
                    green: 0.34,
                    blue: 0.58,
                    alpha: 1
                )
            )

        case .user:
            return Palette(
                top: UIColor(
                    red: 0.32,
                    green: 0.58,
                    blue: 0.70,
                    alpha: 1
                ),
                bottom: UIColor(
                    red: 0.19,
                    green: 0.37,
                    blue: 0.50,
                    alpha: 1
                )
            )

        case .activity:
            return Palette(
                top: UIColor(
                    red: 0.30,
                    green: 0.62,
                    blue: 0.48,
                    alpha: 1
                ),
                bottom: UIColor(
                    red: 0.18,
                    green: 0.40,
                    blue: 0.31,
                    alpha: 1
                )
            )

        case .post:
            return Palette(
                top: UIColor(
                    red: 0.57,
                    green: 0.46,
                    blue: 0.72,
                    alpha: 1
                ),
                bottom: UIColor(
                    red: 0.36,
                    green: 0.27,
                    blue: 0.52,
                    alpha: 1
                )
            )

        case .media:
            return Palette(
                top: UIColor(
                    red: 0.66,
                    green: 0.43,
                    blue: 0.50,
                    alpha: 1
                ),
                bottom: UIColor(
                    red: 0.43,
                    green: 0.24,
                    blue: 0.31,
                    alpha: 1
                )
            )

        case .hyperlink:
            return Palette(
                top: UIColor(
                    red: 0.49,
                    green: 0.53,
                    blue: 0.66,
                    alpha: 1
                ),
                bottom: UIColor(
                    red: 0.29,
                    green: 0.32,
                    blue: 0.45,
                    alpha: 1
                )
            )
        }
    }
}
