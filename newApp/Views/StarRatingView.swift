import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 4) {
                ForEach(1...10, id: \.self) { i in
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.yellow)
                        .onTapGesture {
                            rating = i
                        }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let starWidth: CGFloat = 28 // 24 + spacing
                        let newRating = Int((value.location.x) / starWidth) + 1
                        if (1...10).contains(newRating) {
                            rating = newRating
                        }
                    }
            )
        }
    }
}
