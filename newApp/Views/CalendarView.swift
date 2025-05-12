import SwiftUI

struct CalendarView: View {
    @State private var selectedMonth: Date = Date()
    @State private var focusDataByDate: [String: Double] = [:]
    @State private var dailyDataForCurrentMonth: [String: Double] = [:]

    private let calendar = Calendar.current
    private let dayOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        ZStack {
            Color(hex: "#b99a88").edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .cornerRadius(20)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .padding(.horizontal, 10)

            VStack(spacing: 16) {
                Spacer().frame(height: 16)

                HStack(spacing: 16) {
                    Spacer()
                    Button(action: { changeMonth(by: -1) }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#d5bca6"))
                                .frame(width: 32, height: 32)
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                        }
                    }
                    Text(formattedMonth)
                        .font(.title3)
                        .foregroundColor(Color(hex: "#333333"))
                    Button(action: { changeMonth(by: 1) }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#d5bca6"))
                                .frame(width: 32, height: 32)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)

                HStack(spacing: 0) {
                    ForEach(dayOfWeek, id: \.self) { day in
                        Text(day)
                            .frame(maxWidth: .infinity)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 24)

                GeometryReader { geometry in
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                        ForEach(daysInMonth, id: \.self) { date in
                            if let date = date {
                                let dateString = dateToString(date)
                                let rate = dailyDataForCurrentMonth[dateString] ?? 0.0

                                NavigationLink(destination: GraphView(currentDate: date)) {
                                    VStack {
                                        Text("\(calendar.component(.day, from: date))")
                                            .font(isToday(date) ? .system(size: 16, weight: .bold) : .system(size: 16))
                                            .foregroundColor(isToday(date) ? .blue : Color(hex: "#333333"))
                                            .padding(.top, 4)
                                            .frame(width: 25)
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(getColor(rate: rate))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                Rectangle().fill(Color.clear)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .frame(maxHeight: .infinity)

                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.5)).frame(width: 10, height: 10)
                    Text("Excellent").font(.caption)
                    RoundedRectangle(cornerRadius: 8).fill(Color.yellow.opacity(0.5)).frame(width: 10, height: 10)
                    Text("Good").font(.caption)
                    RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.5)).frame(width: 10, height: 10)
                    Text("Fair").font(.caption)
                    RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.5)).frame(width: 10, height: 10)
                    Text("Poor").font(.caption)
                }
                .padding(.bottom, 30)
            }
            .onAppear { loadAllAchievementRateData() }
            .onChange(of: selectedMonth) { loadAllAchievementRateData() }
        }
    }

    func getColor(rate: Double) -> Color {
        if rate >= 85.0 { return Color.green.opacity(0.5) }
        else if rate >= 75.0 { return Color.yellow.opacity(0.5) }
        else if rate >= 50.0 { return Color.orange.opacity(0.5) }
        else if rate > 0.0 { return Color.red.opacity(0.5) }
        else { return Color(hex: "#f1e7dc") }
    }

    func changeMonth(by months: Int) {
        if let newDate = calendar.date(byAdding: .month, value: months, to: selectedMonth) {
            selectedMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: newDate)) ?? selectedMonth
        }
    }

    var formattedMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func isToday(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: Date())
    }

    var daysInMonth: [Date?] {
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offsetDays = firstWeekday - 1
        let days = calendar.range(of: .day, in: .month, for: firstDay)!.count

        var result: [Date?] = Array(repeating: nil, count: offsetDays)
        for day in 1...days {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                result.append(date)
            }
        }
        while result.count < 42 {
            result.append(nil)
        }
        return result
    }

    func loadAllAchievementRateData() {
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for offset in 0..<range.count {
            if let date = calendar.date(byAdding: .day, value: offset, to: firstDay) {
                let key = formatter.string(from: date)
                dailyDataForCurrentMonth[key] = GraphDataHelper.calculateTotalAchievementRate(dateKey: key)
            }
        }
    }
}

#Preview {
    CalendarView()
}
