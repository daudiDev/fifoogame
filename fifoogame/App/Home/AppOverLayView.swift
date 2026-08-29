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
    
    
    let onPlayTapped: () -> Void
    let onPathTapped: () -> Void
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
                            onPlayTapped: onPlayTapped,
                            onAddNodeTapped: onAddNodeTapped
                        )
                        
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(.clear)

                    // MARK: - Day Path
                    // A persistent path affordance sits above the bottom app
                    // controls. It opens the same inspector used when the
                    // chosen route itself is tapped on the map: completed
                    // stops first, chosen/future stops second.
                    VStack {
                        Spacer()

                        HStack {
                            Spacer()

                            Button {
                                onPathTapped()
                            } label: {
                                Label(
                                    "Path",
                                    systemImage: "point.topleft.down.to.point.bottomright.curvepath"
                                )
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 11)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay {
                                    Capsule()
                                        .stroke(.white.opacity(0.35), lineWidth: 0.5)
                                }
                                .shadow(radius: 6, y: 3)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 96)
                    }
                    .allowsHitTesting(!isShowingHomeMenuView && !isShowingProgressDataView)

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











