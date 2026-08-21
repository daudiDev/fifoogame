//
//  AppOverLayTopRow.swift
//  fifoo
//
//  Created by Daudi Sagala on 7/15/26.
//

import SwiftUI

struct AppOverLayTopRow: View {
    @Binding var isShowingHomeMenuView: Bool
    @Binding var isShowingUserActionsProgressView: Bool
    @StateObject private var appManager = AppManager.shared
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
         
            Text("fifoo")
                .font(Font.custom("chewy", size: 28))
                .foregroundStyle(.black)
            
            Spacer()
            
            //MARK: add action data??
           
                HStack(alignment: .center, spacing: 3) {
                    Text(weekdayString(from: appManager.selectedDate))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                    Text(monthString(from: appManager.selectedDate))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                    Text(dayNumber(from: appManager.selectedDate))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                    Text(yearString(from: appManager.selectedDate))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.9))
                    Text(Image(systemName: "arrow.right"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                    
                } //hs
        
              
            Spacer()
            
            //MARK: this will open the app menu with links to: profile, chat, reminders, posts etc
            Button(action: {
                withAnimation(.spring()) {
                    isShowingHomeMenuView.toggle()
                }
            }) {
                
                ZStack {
                    //MARK: add user profile image
                    HStack(alignment: .center) {
                        Image("placeholder")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .background(
                                Color.blue.opacity(0.1),
                                in: Circle()
                            )
                    }
                    
                    //MARK: add data on the actions count?? or something else
                    HStack {
                        Spacer()
                        VStack {
                            Text("8")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(5)
                                .background(Circle().fill(Color.red))
                            Spacer()
                        }
                        
                    }
                    .frame(width: 40, height: 40)
                    .background(.clear)
                    
                } //zs
                
            } //btn
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 25).fill(.ultraThinMaterial))
        .padding(.horizontal)
        
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
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func dayNumber(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date) + ", "
    }
}


