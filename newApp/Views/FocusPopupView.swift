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

            Button("RATE") {
                onRate()
            }
            .font(.headline.bold())
            .padding(.vertical, 10)
            .padding(.horizontal, 40)
            .background(Color(hex: "#7b5e57")) 
            .cornerRadius(10)
            .foregroundColor(.white)

            Spacer().frame(height: 12)
        }
        .padding()
    }
}
