//
//  SeekHelpView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/20/26.
//

import SwiftUI

struct SeekHelpView: View {
    
    @Binding var isShowingAskHelp: Bool
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
            Text("Seek Help Page")
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
