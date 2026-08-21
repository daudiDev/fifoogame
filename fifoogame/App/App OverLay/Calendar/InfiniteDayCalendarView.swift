//
//  InfiniteCalendarView.swift
//  fifoo
//
//  Created by Daudi Sagala on 5/29/26.
//

import SwiftUI

struct InfiniteDayCalendarView: View {
    
    @State private var isScrolling = false
    @State private var isShowingFullCalendar: Bool = false
    
    private let calendar = Calendar.current
    
    @State private var selectedDate: Date = Date()
    @StateObject private var appManager = AppManager.shared
    @State private var scrollHour: Int = Calendar.current.component(.hour, from: Date())
    
    private var days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let startDate = calendar.date(byAdding: .month, value: -1, to: today)!
        let endDate = calendar.date(byAdding: .month, value: 1, to: today)!
        
        var dates: [Date] = []
        var current = startDate
        
        while current <= endDate {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        return dates
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Week Header
            weekHeader
            
            Divider()
            
            // MARK: - Timeline
            
            GeometryReader { geo in
                ScrollViewReader { proxy in
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        
//                        LazyVStack(spacing: 0, pinnedViews: []) {
                        LazyVStack(spacing: 0) {
                            
                            let selectedDay =
                            calendar.startOfDay(for: appManager.selectedDate)
                            
                            ForEach(0..<24, id: \.self) { hour in
                                
                                HourRow(
                                    geo: geo,
                                    date: selectedDay,
                                    hour: hour,
                                    isCurrentHour: isCurrentHour(
                                        date: selectedDay,
                                        hour: hour
                                    )
                                )
                                .id(idFor(date: selectedDay, hour: hour))
                            } //f/e
                        } //lz stack
                        .padding(.top, 8)
                    } //sv
                    .onAppear {
                        
                        let today = calendar.startOfDay(for: Date())
                        let currentHour = calendar.component(.hour, from: Date())
                        
                        DispatchQueue.main.async {
                            proxy.scrollTo(
                                idFor(date: today, hour: currentHour),
                                anchor: UnitPoint(x: 0.5, y: 0.35)
                            )
                        }
                    }
                    .onScrollPhaseChange { oldPhase, newPhase in

                        print("Phase changed: \(newPhase)")

                        switch newPhase {
                        case .idle:
                            print("🔴 Scroll Ended")
                            isScrolling = false

                        case .tracking, .interacting, .decelerating, .animating:
                            if !isScrolling {
                                print("🟢 Scroll Started")
                                isScrolling = true
                            }

                        @unknown default:
                            break
                        }
                    }
                    
                } //sr
            } //gr
        } //vs
        .background(.ultraThinMaterial)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                
                Button(action: {
                    //MARK: add action
                    isShowingFullCalendar = true
                }) {
                    HStack(spacing: 8) {
                        
                        Text(monthString(from: appManager.selectedDate) + ", " + yearString(from: appManager.selectedDate))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.9))
                        Text(Image(systemName: "calendar"))
                            .font(.system(size: 20, weight: .regular, design: .serif))
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingFullCalendar) {
            CalendarView(isShowingFullCalendar: $isShowingFullCalendar)
        }
        
    }
    
    // MARK: - Week Header
    
    private var weekHeader: some View {
        ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    
                    LazyHStack(alignment: .center, spacing: 12) {
                        
                        ForEach(days, id: \.self) { date in
                            
                            Button {
                                
                                appManager.selectedDate =
                                calendar.startOfDay(for: date)
                                
                            } label: {
                                
                                VStack(spacing: 3) {
                                    
                                    Text(weekdayString(from: date))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                    
                                        .foregroundStyle(
                                            isSameDay(date, appManager.selectedDate)
                                            ? .blue
                                            : .black
                                        )
                                    
                                    Text(dayNumber(from: date))
                                        .font(.headline)
                                        .fontWeight(
                                            isSameDay(date, appManager.selectedDate)
                                            ? .bold
                                            : .semibold
                                        )
                                        .foregroundStyle(
                                            isSameDay(date, appManager.selectedDate)
                                            ? .white
                                            : .primary
                                        )
                                        .frame(width: 36, height: 36)
                                        .background(
                                            Circle()
                                                .fill(
                                                    isSameDay(date, appManager.selectedDate)
                                                    ? .blue
                                                    : .clear
                                                )
                                        )
                                }
                                .frame(width: 50)
                            }
                            .id(date)
                        }
                    }
                    .padding(.horizontal)

            }
            .frame(height: 60)
//            .padding(.bottom)
            .onAppear {
                
                DispatchQueue.main.async {
                    proxy.scrollTo(
                        calendar.startOfDay(for: Date()),
                        anchor: .center
                    )
                }
            }
            .onChange(of: appManager.selectedDate) { _, newDate in
                
                let targetHour: Int
                
                if calendar.isDateInToday(newDate) {
                    targetHour = calendar.component(.hour, from: Date())
                } else {
                    targetHour = 8
                }
                
                withAnimation {
                    proxy.scrollTo(
                        idFor(
                            date: calendar.startOfDay(for: newDate),
                            hour: targetHour
                        ),
                        anchor: UnitPoint(x: 0.5, y: 0.35)
                    )
                }
            } //o/c
        }
        .background(.white)
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
        return formatter.string(from: date)
    }
    
    private func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }
    
    private func isCurrentHour(date: Date, hour: Int) -> Bool {
        let now = Date()
        
        return calendar.isDate(date, inSameDayAs: now)
        && calendar.component(.hour, from: now) == hour
    }
    
    private func idFor(date: Date, hour: Int) -> String {
        "\(date.timeIntervalSince1970)-\(hour)"
    }
    
    // MARK: - Hour Row
    
    struct HourRow: View {
        
        var geo: GeometryProxy
        let date: Date
        let hour: Int
        let isCurrentHour: Bool
        
        var body: some View {
            VStack {
                HStack(alignment: .center, spacing: 8) {
                    
                    Text(hourString(hour))
                        .font(.custom("Chalkduster", size: 16))
                        .foregroundStyle(.gray)
                        .frame(width: 60, alignment: .center)
                    
                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(Color.gray.opacity(0.25))
                            .frame(height: 2)
                        Spacer()
                    }
                    
                } //hs
                .frame(height: 18)
                .padding(.trailing)
                
                //MARK: add event here
                TempEventView(geo: geo, hour: hour)
                
                Spacer()
                
                if (hour % 3 == 0) {
                    
                    //MARK: add params
                    NavigationLink{ PostsView()} label: {
                        CalendarUserRequestImagesRow(imageUrls: ["https://res.cloudinary.com/dgowl1p3x/image/upload/v1720756835/avatars_collection/fka5g58kqmtymugm6jyi.png", "https://res.cloudinary.com/dgowl1p3x/image/upload/v1720756235/avatars_collection/k0y44amiztqdalrue3mz.png", "https://res.cloudinary.com/dgowl1p3x/image/upload/v1720756226/avatars_collection/pgdwr7unpbal3m6wgibs.png",
                                                                 "https://res.cloudinary.com/dgowl1p3x/image/upload/v1720756699/avatars_collection/ijnw73tj9rmfhgsvovch.png"], requestsCount: hour + 1)
                    }
                }
                
                if ( ["Mon", "Wed", "Fri"].contains(weekdayString(date)) ) {
                    Text(weekdayString(date))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.gray)
                        .padding()
                    
                }
                
            } //vs
            .frame(minHeight: 100)
            .background(
                isCurrentHour
                ? Color.green.opacity(0.05)
                : Color.clear
            )
            
        }
        
        private func hourString(_ hour: Int) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "ha"
            
            let calendar = Calendar.current
            let date = calendar.date(
                bySettingHour: hour,
                minute: 0,
                second: 0,
                of: Date()
            )!
            
            return formatter.string(from: date).lowercased()
        }
        
        private func weekdayString(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
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
        
    }
    
    struct TempEventView: View {
        var geo: GeometryProxy
        var hour: Int
        let darkGreen = Color.green.mix(with: .black, by: 0.2)
        var body: some View {
            
            if (hour == 5) {
                
                VStack {
                    HStack {
                        VStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.purple)
                                .frame(width: 4)
                                .frame(maxHeight: .infinity)
                        } //vs
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Morning Run")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                Spacer()
                                Text("5:05am - 5:45am")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.gray)
                            }
                            HStack {
                                Text(Image(systemName: "mappin.and.ellipse"))
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Lake Mount Track - 2mi away")
                                    .font(.system(size: 14, weight: .semibold))
                                
                            }
                            HStack {
                                Text(Image(systemName: "checkmark.circle"))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.gray)
                                Text("Confirmed")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.gray)
                            }
                            
                            //MARK: tips/requests/comments
                            //MARK: add params
                            NavigationLink{ ActivityItemPostsView()} label: {
                                EventItemUserImagesRow(imageUrls: ["https://res.cloudinary.com/dgowl1p3x/image/upload/v1720757054/avatars_collection/jfqtztusv1abheoh4niq.png",
                                                                   "https://res.cloudinary.com/dgowl1p3x/image/upload/v1720757026/avatars_collection/ngjrfplm1dtgxotrezxy.png", "https://res.cloudinary.com/dgowl1p3x/image/upload/v1720756835/avatars_collection/fka5g58kqmtymugm6jyi.png"], tipsCount: 7)
                            }
                        } //vs
                        
                    } //hs
                    
                    HStack(alignment: .center) {
                        Spacer()
                        //MARK: add params
                        NavigationLink{ ActivityDetailsView()} label: {
                            HStack {
                                Text("Open")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 20).fill(.blue.opacity(0.05)))
                        }
                        Spacer()
                        Button(action: {
                            //MARK: add action
                            
                        }) {
                            HStack {
                                Text("Done")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.blue)
                            }
//                            .frame(width: geo.size.width * 0.2)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 20).fill(.blue.opacity(0.05)))
                        }
                        Spacer()
                        Button(action: {
                            //MARK: add action
                            
                        }) {
                            HStack {
                                Text("Skip")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.blue)
                            }
//                            .frame(width: geo.size.width * 0.2)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 20).fill(.blue.opacity(0.05)))
                        }
                        Spacer()
                    } //hs
                    .padding(5)
                    
                } //vs
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(.white).shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1))
                .padding(.horizontal)
                
                
                VStack {
                    HStack {
                        
                        VStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.green)
                                .frame(width: 4)
                                .frame(maxHeight: .infinity)
                        } //vs
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Post-workout Snack")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                Spacer()
                                Text("5:45am - 6:00am")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.gray)
                            }
                            HStack {
                                Text(Image(systemName: "checkmark.circle.fill"))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.green)
                                Text("Scheduled")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.green)
                            }
                            
                        } //vs
                        
                    } //hs
                    
                    HStack(alignment: .center) {
                        Spacer()
                        //MARK: add params
                        NavigationLink{ ActivityDetailsView()} label: {
                            HStack {
                                Text("Open")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.blue)
                            }
//                            .frame(width: geo.size.width * 0.2)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 20).fill(.blue.opacity(0.05)))
                        }
                        Spacer()
                        Button(action: {
                            //MARK: add action
                            
                        }) {
                            HStack {
                                Text("Done")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.blue)
                            }
//                            .frame(width: geo.size.width * 0.2)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 320).fill(.blue.opacity(0.05)))
                        }
                        Spacer()
                        Button(action: {
                            //MARK: add action
                            
                        }) {
                            HStack {
                                Text("Skip")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.blue)
                            }
//                            .frame(width: geo.size.width * 0.2)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 20).fill(.blue.opacity(0.05)))
                        }
                        Spacer()
                    } //hs
                    .padding(5)
                    
                } //vs
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(.white).shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1))
                .padding(.horizontal)
                
            } else if (hour == 13) {
                VStack {
                    HStack {
                        VStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.purple)
                                .frame(width: 4)
                                .frame(maxHeight: .infinity)
                        } //vs
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Lunch")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                Spacer()
                                Text("12:00am - 1:00apm")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.gray)
                            }
                            HStack {
                                
                                Text("🌯 Burrito. Extra chicken. White rice. Sour cream, hot salsa, cheese")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(darkGreen)
                                Spacer()
                            }
                            HStack {
                                Text(Image(systemName: "mappin.and.ellipse"))
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Chipotle - 1.5mi away")
                                    .font(.system(size: 14, weight: .semibold))
                                
                            }
                            HStack {
                                Text(Image(systemName: "checkmark.circle"))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.gray)
                                Text("Confirmed")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.gray)
                            }
                            
                            //MARK: tips/requests/comments
                            //MARK: add params
                            NavigationLink{ ActivityItemPostsView()} label: {
                                EventItemUserImagesRow(imageUrls:
                                                        ["https://res.cloudinary.com/dgowl1p3x/image/upload/v1720756835/avatars_collection/fka5g58kqmtymugm6jyi.png","https://res.cloudinary.com/dgowl1p3x/image/upload/v1720757054/avatars_collection/jfqtztusv1abheoh4niq.png","https://res.cloudinary.com/dgowl1p3x/image/upload/v1720757026/avatars_collection/ngjrfplm1dtgxotrezxy.png"], tipsCount: 13)
                            }
                        } //vs
                        
                    } //hs
                    
                    HStack(alignment: .center) {
                        Spacer()
                        //MARK: add params
                        NavigationLink{ ActivityDetailsView()} label: {
                            HStack {
                                Text("Open")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 20).fill(.blue.opacity(0.05)))
                        }
                        Spacer()
                        Button(action: {
                            //MARK: add action
                            
                        }) {
                            HStack {
                                Text("Done")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.blue)
                            }
//                            .frame(width: geo.size.width * 0.2)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 20).fill(.blue.opacity(0.05)))
                        }
                        Spacer()
                        Button(action: {
                            //MARK: add action
                            
                        }) {
                            HStack {
                                Text("Skip")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.blue)
                            }
//                            .frame(width: geo.size.width * 0.2)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 20).fill(.blue.opacity(0.05)))
                        }
                        Spacer()
                    } //hs
                    .padding(5)
                    
                } //vs
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(.white).shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1))
                .padding(.horizontal)
            }
            
        }
        
    }
    
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
