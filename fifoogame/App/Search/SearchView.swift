//
//  SearchView.swift
//  fifoo
//
//  Created by Daudi Sagala on 5/25/26.
//

import SwiftUI


// MARK: - Search View

struct SearchView: View {
    
    @Binding var isShowingSearchView: Bool
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 0) {
            titleSection
            
            Divider()
            
            Spacer()
            
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        HStack(spacing: 12) {
            Text("Search Page")
                .font(.headline)
                .foregroundStyle(.primary)
            
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close conversation")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(uiColor: .systemBackground))
    }
    

}
