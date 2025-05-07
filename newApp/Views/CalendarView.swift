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

    private let calendar = Calendar.current
    private let dayOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
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
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(daysInMonth, id: \.self) { date in
                    // Each date cell
                    if let date = date {
                        let dateString = dateToString(date)
                        let averageFocus = focusDataByDate[dateString] ?? 0

                        NavigationLink(destination: GraphView()) {
                            VStack {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.system(size: 16))
                                    .padding(.top, 4)

                                if averageFocus > 0 {
                                    StarRatingIndicator(rating: averageFocus)
                                        .frame(height: 24)
                                }

                                Spacer()
                            }
                            .frame(height: 65)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isToday(date) ? Color.blue.opacity(0.1) : Color.white)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // Empty cell
                        Rectangle().fill(Color.clear).frame(height: 65)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .onAppear {
            loadAllFocusData()
        }
    }

    // Change month
    func changeMonth(by months: Int) {
        if let newDate = calendar.date(byAdding: .month, value: months, to: selectedMonth) {
            selectedMonth = newDate
            loadAllFocusData()
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
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!.count

        var result: [Date?] = Array(repeating: nil, count: offsetDays)

        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
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
        guard let data = UserDefaults.standard.data(forKey: "SavedTimerSessions"),
              let sessions = try? JSONDecoder().decode([TimerSession].self, from: data) else {
            return
        }

        // Filter by month
        let yearMonth = calendar.dateComponents([.year, .month], from: selectedMonth)
        let filteredSessions = sessions.filter { session in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            guard let sessionDate = dateFormatter.date(from: session.date) else { return false }
            let sessionComponents = calendar.dateComponents([.year, .month], from: sessionDate)
            return sessionComponents.year == yearMonth.year && sessionComponents.month == yearMonth.month
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
