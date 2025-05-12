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

            CalendarView()
                .tabItem {
                    Label("Graph", systemImage: "chart.bar.fill")
                }
        }
        .tint(.white) 

    }
}

#Preview {
    ContentView()
}
