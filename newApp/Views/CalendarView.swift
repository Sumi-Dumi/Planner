//
//  CalendarView.swift
//  newApp
//
//  Created by yuki on 7/5/2025.
//
//
//  CalendarView.swift
//  newApp
//
//  Created by yuki on 7/5/2025.
//
import SwiftUI

struct CalendarView: View {
    @State private var selectedMonth: Date = Date()
    @State private var focusDataByDate: [String: Double] = [:]

    @State private var dailyDataForCurrentMonth: [String: Double] = [:]

    private let calendar = Calendar.current
    private let dayOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Month display and navigation buttons
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left").font(.title2)
                    }
                    Spacer()
                    Text(formattedMonth)
                        .font(.title3)
                        .foregroundColor(.blue)
                    Spacer()
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right").font(.title2)
                    }
                }
                .padding(.horizontal)

                // Day of week header
                HStack(spacing: 0) {
                    ForEach(dayOfWeek, id: \.self) { day in
                        Text(day)
                            .frame(maxWidth: .infinity)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                // Calendar grid
                GeometryReader { geometry in
                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible()),
                            count: 7
                        ),
                        spacing: 10
                    ) {
                        ForEach(daysInMonth, id: \.self) { date in
                            // Each date cell
                            if let date = date {
                                let dateString = dateToString(date)
                                let achievementRate =
                                    dailyDataForCurrentMonth[
                                        dateString
                                    ] ?? 0.0

                                NavigationLink(
                                    destination: GraphView(currentDate: date)
                                ) {

                                    VStack {
                                        Text(
                                            "\(calendar.component(.day, from: date))"
                                        )
                                        .font(
                                            isToday(date)
                                                ? .system(
                                                    size: 16,
                                                    weight: .bold
                                                ) : .system(size: 16)
                                        )
                                        .foregroundColor(
                                            isToday(date) ? .blue : .black
                                        )
                                        .padding(.top, 4)
                                        .frame(width: 25, alignment: .center)

                                        Spacer()
                                    }
                                    .padding(10)

                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                getColor(rate: achievementRate)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                // Empty cell
                                Rectangle().fill(Color.clear)

                            }
                        }
                    }
                    .padding(.horizontal)
                }.frame(maxHeight: .infinity)
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.5))
                        .frame(width: 10, height: 10)
                    Text("Excellent")
                        .font(.caption)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.yellow.opacity(0.5))
                        .frame(width: 10, height: 10)
                    Text("Good")
                        .font(.caption)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.5))
                        .frame(width: 10, height: 10)
                    Text("Fair")
                        .font(.caption)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.5))
                        .frame(width: 10, height: 10)
                    Text("Poor")
                        .font(.caption)
                }
                Spacer()
            }
            .onAppear {
                // populateDummyAchievement()
                loadAllAchievementRateData()

            }
            .onChange(of: selectedMonth) {
                // populateDummyAchievement()
                loadAllAchievementRateData()
            }
        }
    }

    func getColor(rate: Double) -> Color {
        if rate >= 85.0 {
            return Color.green.opacity(0.5)
        } else if rate >= 75.0 {
            return Color.yellow.opacity(0.5)
        } else if rate >= 50.0 {
            return Color.orange.opacity(0.5)
        } else if rate > 0.0 {
            return Color.red.opacity(0.5)
        } else {
            return Color.blue.opacity(
                0.1
            )

        }
    }

    func populateDummyAchievement() {
        var firstDayComponents = DateComponents()
        firstDayComponents.month = calendar.component(
            .month,
            from: selectedMonth
        )
        firstDayComponents.year = calendar.component(.year, from: selectedMonth)
        firstDayComponents.day = 1

        guard let firstDayOfMonth = calendar.date(from: firstDayComponents)
        else {
            fatalError("Couldn't create date from components")
        }
        guard
            let rangeOfDays = calendar.range(
                of: .day,
                in: .month,
                for: firstDayOfMonth
            )
        else {
            fatalError("Couldn't get range of days in month")
        }
        let daysInMonth = rangeOfDays.count

        let formatter = DateFormatter()
        var dayStrings: [String] = []
        formatter.dateFormat = "yyyy-MM-dd"
        for dayOffset in 0..<daysInMonth {
            let dayComponents = DateComponents(day: dayOffset)
            guard
                let dayDate = calendar.date(
                    byAdding: dayComponents,
                    to: firstDayOfMonth
                )
            else {
                fatalError("Couldn't create date from components")
            }
            let dayString = formatter.string(from: dayDate)
            dayStrings.append(dayString)

        }

        for dateKey in dayStrings {
            print(dateKey)
            dailyDataForCurrentMonth[dateKey] = Double.random(in: 0...100)
        }
    }

    // Change month
    func changeMonth(by months: Int) {
        if let newDateBeforeAdjustment = calendar.date(
            byAdding: .month,
            value: months,
            to: selectedMonth
        ) {
            var components = calendar.dateComponents(
                [.year, .month],
                from: newDateBeforeAdjustment
            )
            components.day = 1
            if let newDate = calendar.date(
                from: components
            ) {
                selectedMonth = newDate
            }

        }
    }

    // Format for month display
    var formattedMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    // Convert date to string
    func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // Check if date is today
    func isToday(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: Date())
    }

    // Get array of dates for the month
    var daysInMonth: [Date?] {
        let firstDayOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: selectedMonth)
        )!

        // First day of month
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        // Calculate empty spaces for the first week (Sunday start)
        let offsetDays = firstWeekday - 1

        // Days in month
        let daysInMonth = calendar.range(
            of: .day,
            in: .month,
            for: firstDayOfMonth
        )!.count

        var result: [Date?] = Array(repeating: nil, count: offsetDays)

        for day in 1...daysInMonth {
            if let date = calendar.date(
                byAdding: .day,
                value: day - 1,
                to: firstDayOfMonth
            ) {
                result.append(date)
            }
        }

        // Fill remaining cells to complete 6 weeks
        while result.count < 42 {
            result.append(nil)
        }

        return result
    }

    // Load focus data for all days
    func loadAllFocusData() {
        guard
            let data = UserDefaults.standard.data(forKey: "SavedTimerSessions"),
            let sessions = try? JSONDecoder().decode(
                [TimerSession].self,
                from: data
            )
        else {
            return
        }

        // Filter by month
        let yearMonth = calendar.dateComponents(
            [.year, .month],
            from: selectedMonth
        )
        let filteredSessions = sessions.filter { session in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            guard let sessionDate = dateFormatter.date(from: session.date)
            else { return false }
            let sessionComponents = calendar.dateComponents(
                [.year, .month],
                from: sessionDate
            )
            return sessionComponents.year == yearMonth.year
                && sessionComponents.month == yearMonth.month
        }

        // Aggregate focus ratings by date
        var dateRatings: [String: [Int]] = [:]

        for session in filteredSessions {
            if let rating = session.focusRating {
                dateRatings[session.date, default: []].append(rating)
            }
        }

        // Calculate averages
        var averageByDate: [String: Double] = [:]

        for (date, ratings) in dateRatings {
            let sum = ratings.reduce(0, +)
            let average = Double(sum) / Double(ratings.count)
            averageByDate[date] = average
        }

        focusDataByDate = averageByDate
    }

    func loadAllAchievementRateData() {
        //get a list of string containing datekey for the whole month
        var firstDayComponents = DateComponents()
        firstDayComponents.month = calendar.component(
            .month,
            from: selectedMonth
        )
        firstDayComponents.year = calendar.component(.year, from: selectedMonth)
        firstDayComponents.day = 1

        guard let firstDayOfMonth = calendar.date(from: firstDayComponents)
        else {
            print("Error: Couldn't create date from components")
            return
        }
        guard
            let rangeOfDays = calendar.range(
                of: .day,
                in: .month,
                for: firstDayOfMonth
            )
        else {
            print("Error: Couldn't get range of days in month")
            return
        }
        let daysInMonth = rangeOfDays.count

        let formatter = DateFormatter()
        var dayStrings: [String] = []
        formatter.dateFormat = "yyyy-MM-dd"
        for dayOffset in 0..<daysInMonth {
            let dayComponents = DateComponents(day: dayOffset)
            guard
                let dayDate = calendar.date(
                    byAdding: dayComponents,
                    to: firstDayOfMonth
                )
            else {
                fatalError("Couldn't create date from components")
            }
            let dayString = formatter.string(from: dayDate)
            dayStrings.append(dayString)

        }

        //get achievement rate for each day of the month displayed
        for dateKey in dayStrings {

            dailyDataForCurrentMonth[dateKey] =
                GraphDataHelper.calculateTotalAchievementRate(dateKey: dateKey)
        }

    }
}

// Star rating indicator (display only)
struct StarRatingIndicator: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 1) {
            Image(systemName: "star.fill")
                .resizable()
                .frame(width: 12, height: 12)
                .foregroundColor(.yellow)

            Text(String(format: "%.1f", rating))
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    CalendarView()
}
