import SwiftUI

struct NavBarView: View {
    @Binding var selectedTab: Tab

    enum Tab {
        case home, task, timer, graph, calendar
    }

    var body: some View {
        HStack {
            Spacer()
            navButton(imageName: "house.fill", tab: .home)
            Spacer()
            navButton(imageName: "list.bullet", tab: .task)
            Spacer()
            navButton(imageName: "clock.fill", tab: .timer)
            Spacer()
            navButton(imageName: "chart.line.uptrend.xyaxis", tab: .graph)
            Spacer()
            navButton(imageName: "calendar", tab: .calendar)
            Spacer()
            
        }
        .padding(.vertical, 10)
        .background(Color.white.shadow(radius: 2))
    }

    func navButton(imageName: String, tab: Tab) -> some View {
        Button(action: {
            selectedTab = tab
        }) {
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .foregroundColor(selectedTab == tab ? .blue : .gray)
        }
    }
}
