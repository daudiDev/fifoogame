//
//  AppOverLayView.swift
//  fifoogame
//
//  Created by Daudi Sagala on 8/25/26.
//


import SwiftUI

struct AppOverLayView: View {
    private let socketManager = SocketManager.shared
    @State private var isTopRowVisible = true
    @State private var isShowingHomeMenuView = false
    @State private var isShowingUserActionsProgressView: Bool = false
    @State private var isShowingGroupView = false
    @State private var isShowingSearchView = false
    @State private var isShowingDayMapDatePicker = false
    @State private var isShowingGroupChatView = true
    @State private var isShowingAskHelp: Bool = false
    
    @State private var commentsExpanded = true
    @State private var commentsDragOffset: CGFloat = 0
    
    @State private var isShowingProgressDataView = false
    
    
    let onAddNodeTapped: () -> Void
    
    var body: some View {
        GeometryReader { geo in
                ZStack {
                    
                    //MARK: main home view
                    
                    
                    VStack {
                        
                        AppOverLayTopRow(
                            isShowingUserActionsProgressView:
                                $isShowingUserActionsProgressView,
                            isShowingProgressDataView:
                                $isShowingProgressDataView,
                            onCalendarTapped: {

                                socketManager
                                    .dayMapDatePickerOpened()

                                isShowingDayMapDatePicker =
                                    true
                            }
                        )
                        Spacer()
                        
                        AppOverLayBottomRow(
                            geo: geo,
                            isShowingSearchView: $isShowingSearchView,
                            isShowingHomeMenuView: $isShowingHomeMenuView,
                            onAddNodeTapped: onAddNodeTapped
                        )
                        
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
                    
                    // Custom Full Screen Cover
                    if isShowingProgressDataView {
                        
                        UserProgressDataView(isShowingProgressDataView: $isShowingProgressDataView)
                            .transition(.move(edge: .trailing))
                            .zIndex(2)
                        
                    }
                    
                } //zs
                .background(.clear)
                .sheet(
                    isPresented: $isShowingSearchView,
                    onDismiss: {

                        socketManager.activatePendingSearchResult()
                    }
                ) {
                    SearchView(
                        isShowingSearchView:
                            $isShowingSearchView
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.ultraThinMaterial)
                }
                .sheet(
                    isPresented:
                        $isShowingDayMapDatePicker
                ) {

                    DayMapDatePickerView()
                        .presentationDetents([
                            .large
                        ])
                        .presentationDragIndicator(
                            .visible
                        )
                        .presentationBackground(
                            .ultraThinMaterial
                        )
                }
                
        } //gr
     
    }

    
}











