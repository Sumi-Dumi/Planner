import SwiftUI

struct FocusPopupView: View {
    @Binding var rating: Int
    var onRate: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("How was your focus level?")
                .font(.headline)
                .padding(.top, 12)

            StarRatingView(rating: $rating)
                .frame(height: 40)

            Button("Rate") {
                onRate()
            }
            .font(.headline)
            .padding(.vertical, 10)
            .padding(.horizontal, 40)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(10)

            Spacer().frame(height: 12)
        }
        .padding()
    }
}
