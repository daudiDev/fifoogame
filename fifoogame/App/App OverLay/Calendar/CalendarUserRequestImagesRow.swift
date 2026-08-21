//
//  CalendarUserRequestImagesRow.swift
//  fifoo
//
//  Created by Daudi Sagala on 5/30/26.
//

import SwiftUI

// MARK: Add Action calls to:
// MARK: 1. Open unread messages
// MARK: 2. Manage follow requests
// MARK: 3. Manage level
// MARK: 4. Manage "schedule-swap"

struct CalendarUserRequestImagesRow: View {
    var imageUrls: [String]
    var requestsCount: Int
    
    var body: some View {
        
        HStack(alignment: .center, spacing: 5) {
            Text(Image(systemName: "circle"))
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.gray)
            
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
                
                Text("\(requestsCount) Requests are Expiring this Hour")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.8))
                
                Text(Image(systemName: "arrow.right.circle.fill"))
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
            }
            .padding(5)
            .background(RoundedRectangle(cornerRadius: 20).fill(.white).shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1))

            Spacer()
            
        }
        .padding()
      
        
    }
}
