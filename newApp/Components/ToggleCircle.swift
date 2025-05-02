import SwiftUI

struct ToggleCircle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            HStack {
                ZStack {
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isOn {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 12, height: 12)
                    }
                }
                Text(label)
                    .foregroundColor(.black)
            }
        }
    }
}
