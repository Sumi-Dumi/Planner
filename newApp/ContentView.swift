import SwiftUI

struct ContentView: View {
    @State private var selectedTab: NavBarView.Tab = .home

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case .home:
                    MainView()
                case .task:
                    TaskView()
                case .timer:
                    TimerView()
                case .graph:
                    GraphView()
                case .calendar:
                    CalendarView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            NavBarView(selectedTab: $selectedTab)
                .frame(height: 80)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    ContentView()
}
