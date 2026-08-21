//
//  HomeView.swift
//  fifoo
//
//  Created by Daudi Sagala on 7/14/26.
//

import SwiftUI

struct AppOverLayView: View {
    
    @State private var isTopRowVisible = true
    
    @State private var isShowingHomeMenuView = false
    @State private var isShowingUserActionsProgressView: Bool = false
    @State private var isShowingGroupView = false
    @State private var isShowingSearchView = false
    @State private var isShowingGroupChatView = true
    @State private var isShowingAskHelp: Bool = false
    @State private var isShowingPlay: Bool = false
    
    @State private var commentsExpanded = true
    @State private var commentsDragOffset: CGFloat = 0
    
    @Binding var isShowingAddNode: Bool
    
    var body: some View {
        GeometryReader { geo in
                ZStack {
                    
                    //MARK: main home view
                    
                    
                    VStack {
                        
                        AppOverLayTopRow(isShowingHomeMenuView: $isShowingHomeMenuView, isShowingUserActionsProgressView: $isShowingUserActionsProgressView)
                        Spacer()
                        
                        AppOverLayBottomRow(geo: geo, isShowingSearchView: $isShowingSearchView, isShowingAskHelp: $isShowingAskHelp, isShowingPlay: $isShowingPlay, isShowingAddNode: $isShowingAddNode)
                        
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(.clear)
                    
                    // Custom Full Screen Cover
                    if isShowingHomeMenuView {
                        
                        AppOverlayMenu(isShowingHomeMenuView: $isShowingHomeMenuView)
                            .transition(.move(edge: .trailing))
                            .zIndex(1)
                    }
                } //zs
                .background(.clear)
                .sheet(isPresented: $isShowingSearchView) {
                    SearchView(isShowingSearchView: $isShowingSearchView)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                        .presentationBackground(.ultraThinMaterial)
                }
                .sheet(isPresented: $isShowingAskHelp) {
                    SeekHelpView(isShowingAskHelp: $isShowingAskHelp)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                        .presentationBackground(.ultraThinMaterial)
                }
            
            
        } //gr
     
    }

    
}











