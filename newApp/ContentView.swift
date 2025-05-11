import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MainView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            TaskView()
                .tabItem {
                    Label("Task", systemImage: "checkmark.circle.fill")
                }

            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "clock.fill")
                }

            GraphView()
                .tabItem {
                    Label("Graph", systemImage: "chart.bar.fill")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
        }
    }
}

#Preview {
    ContentView()
}
