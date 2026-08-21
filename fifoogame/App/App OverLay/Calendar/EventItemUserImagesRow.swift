//
//  EventItemUserImagesRow.swift
//  fifoo
//
//  Created by Daudi Sagala on 5/30/26.
//

import SwiftUI

struct EventItemUserImagesRow: View {
    var imageUrls: [String]
    var tipsCount: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            HStack(alignment: .center, spacing: -20) {
                ForEach(imageUrls.prefix(3), id: \.self) { url in
                    
                    CustomAsyncImage(url: URL(string: url)!)
                        .scaledToFit()
                        .frame(height: 30)
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                    
                } //f/e
            } //hs
            
            Text("You have \(tipsCount) Tips")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black.opacity(0.9))
            
                Text(Image(systemName: "arrow.right.circle.fill"))
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
            Spacer()
            
        }
        .padding(.top, 5)
    }
}


