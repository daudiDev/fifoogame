//
//  HomeBottomRow.swift
//  fifoo
//
//  Created by Daudi Sagala on 7/15/26.
//

import SwiftUI

struct AppOverLayBottomRow: View {
    var geo: GeometryProxy
    @Binding var isShowingSearchView: Bool
    @Binding var isShowingAskHelp: Bool
    @Binding var isShowingPlay: Bool
    @Binding var isShowingAddNode: Bool
    
    var body: some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: 35) {
                Button {
                    
                    withAnimation(.spring()) {
                        isShowingSearchView.toggle()
                    }
                    
                } label: {
                    Text(Image(systemName: "magnifyingglass.circle.fill"))
                        .font(.system(size: 28, weight: .regular, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.9))
                }
                .buttonStyle(
                    .plain
                )
                
                Button {
                    
                    isShowingPlay = true
                    
                } label: {
                    Text(Image(systemName: "play.square.stack.fill"))
                        .font(.system(size: 28))
                        .foregroundStyle(.black.opacity(0.9))
                }
                .buttonStyle(
                    .plain
                )
                

                Button {
                    
                    isShowingAddNode =
                    true
                    
                } label: {
                    
                    Text(Image(systemName: "plus.circle.fill"))
                        .font(.system(size: 28))
                        .foregroundStyle(.black.opacity(0.9))
                }
                .buttonStyle(
                    .plain
                )
                
                Button {
                    
                    isShowingAskHelp = true
                    
                } label: {
                    Text(Image(systemName: "questionmark.circle.fill"))
                        .font(.system(size: 28))
                        .foregroundStyle(.black.opacity(0.9))
                }
                .buttonStyle(
                    .plain
                )
                
                
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 30).fill(.ultraThinMaterial))
            .padding(.horizontal)
        }

    }
}


