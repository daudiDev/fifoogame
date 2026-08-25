//
//  AppOverLayTopRow.swift
//  fifoo
//
//  Created by Daudi Sagala on 7/15/26.
//

import SwiftUI

struct AppOverLayTopRow: View {
    private let socketManager = SocketManager.shared
    @Binding var isShowingUserActionsProgressView: Bool
    @StateObject private var appManager = AppManager.shared
    @Binding var isShowingProgressDataView: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            
            //MARK: add action data??
            NavigationLink{InfiniteDayCalendarView()} label: {
                HStack(alignment: .center, spacing: 3) {
                    Image("calendar_color")
                        .resizable()
                        .frame(width: 25, height: 25)
                    Text(weekdayString(from: appManager.selectedDate))
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black)
                        .textCase(.uppercase)
                    Text(monthString(from: appManager.selectedDate))
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black)
                        .textCase(.uppercase)
                    Text(dayNumber(from: appManager.selectedDate))
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black)
                    Text(yearString(from: appManager.selectedDate))
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black.opacity(0.9))
                    
                } //hs
            }
            
            Spacer()
            
            //MARK: todo add link to progress percentage data
            Button(action: {
                withAnimation(.spring()) {
                    isShowingProgressDataView.toggle()
                }
            }) {
                UserCircularProgressBar(progress: socketManager.userDailyProgress)
            }
            
         
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 25).fill(.ultraThinMaterial))
//        .padding(.horizontal)
        
    }
    
    // MARK: - Helpers
    private func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
    
    private func yearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY"
        return formatter.string(from: date)
    }
    
    private func weekdayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private func dayNumber(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date) + ", "
    }
}


