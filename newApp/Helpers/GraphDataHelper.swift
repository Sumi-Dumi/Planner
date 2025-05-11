//
//  GraphDataHelper.swift
//  newApp
//
//  Created by Shirley Yi on 11/5/2025.
//

import Foundation


class GraphDataHelper {
    static func loadFocusEntries(dateKey: String) -> [FocusEntry] {
        guard
            let data = UserDefaults.standard.data(forKey: "SavedTimerSessions"),
            let sessions = try? JSONDecoder().decode(
                [TimerSession].self,
                from: data
            )
        else {
            return []
        }

        let calendar = Calendar.current
        var hourly: [Int: [Int]] = [:]

        for session in sessions where session.date == dateKey {
            guard let rating = session.focusRating else { continue }

            var start = session.startTime
            let end = session.endTime

            while start < end {
                let hour = calendar.component(.hour, from: start)
                hourly[hour, default: []].append(rating)

                if let next = calendar.date(
                    byAdding: .minute,
                    value: 10,
                    to: start
                ) {
                    start = next
                } else {
                    break
                }
            }
        }

        return hourly.map { hour, ratings in
            let avg = Double(ratings.reduce(0, +)) / Double(ratings.count)
            return FocusEntry(id: UUID(), hour: hour, focus: avg)
        }.sorted { $0.hour < $1.hour }
    }
    
    static func calculateAchievementRatesByTask(dateKey: String) -> [(task: TaskItem, achievedTime: TimeInterval, plannedTime: TimeInterval,rate: Double)] {
        guard
            let plannedData = UserDefaults.standard.data(
                forKey: "SavedGridData"
            ),
            let planned = try? JSONDecoder().decode(
                [String: [CellCoord: TaskItem]].self,
                from: plannedData
            ),
            let achievedData = UserDefaults.standard.data(
                forKey: "SavedTimerSessions"
            ),
            let sessions = try? JSONDecoder().decode(
                [TimerSession].self,
                from: achievedData
            )
        else {
            return []
        }

        var plannedTimes: [UUID: TimeInterval] = [:]
        if let dayPlan = planned[dateKey] {
            for task in dayPlan.values {
                plannedTimes[task.id, default: 0] += 600
            }

        }

        var actualTimes: [UUID: TimeInterval] = [:]
        for session in sessions where session.date == dateKey {
            let duration =
                session.endTime.timeIntervalSince(session.startTime)
            actualTimes[session.task.id, default: 0] += duration
        }

        var result: [(task: TaskItem, achievedTime: TimeInterval, plannedTime: TimeInterval,rate: Double)] = []
        let allTasks = Dictionary(
            grouping: planned[dateKey]?.values.map { $0 } ?? [],
            by: { $0.id }
        ).compactMapValues { $0.first }

        for (id, plannedTime) in plannedTimes {
            if let task = allTasks[id] {
                let actual = actualTimes[id, default: 0]
                let rate =
                plannedTime > 0 ? actual / plannedTime : 0
                result.append((task, actual, plannedTime, rate))
            }
        }

        return result
    }
    
    static func calculateTotalAchievedTime(dateKey: String) -> TimeInterval {
        guard
            let achievedData = UserDefaults.standard.data(
                forKey: "SavedTimerSessions"
            ),
            let sessions = try? JSONDecoder().decode(
                [TimerSession].self,
                from: achievedData
            )
        else {
            return 0
        }

        var totalTime: TimeInterval = 0
        for session in sessions where session.date == dateKey {
            totalTime += session.endTime.timeIntervalSince(session.startTime)
        }
        return totalTime
    }

    static func calculateTotalPlannedTime(dateKey: String) -> TimeInterval {
        guard
            let plannedData = UserDefaults.standard.data(
                forKey: "SavedGridData"
            ),
            let planned = try? JSONDecoder().decode(
                [String: [CellCoord: TaskItem]].self,
                from: plannedData
            )
        else {
            return 0
        }

        var totalTime: TimeInterval = 0
        if let dayPlan = planned[dateKey] {
            for _ in dayPlan.values {
                totalTime += 600

            }

        }
        return totalTime
    }
    
    static func calculateTotalAchievementRate(dateKey: String) -> Double {
        let totalPlannedTime = calculateTotalPlannedTime(dateKey: dateKey)
        let totalAchievedTime = calculateTotalAchievedTime(dateKey: dateKey)
        
        guard totalPlannedTime > 0 else {
            return 0
        }
        
        return Double(totalAchievedTime) / totalPlannedTime * 100
    }
    
}
