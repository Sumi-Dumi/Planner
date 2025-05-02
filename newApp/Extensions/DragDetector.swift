import SwiftUI

struct DragDetector: UIViewRepresentable {
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let labelWidth: CGFloat
    let rowCount: Int
    let colCount: Int

    @Binding var selectedTask: TaskItem?
    @Binding var filledCells: [CellCoord: TaskItem]

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        view.addGestureRecognizer(pan)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        let parent: DragDetector
        var lastCoord: CellCoord?

        init(_ parent: DragDetector) {
            self.parent = parent
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view, let task = parent.selectedTask else { return }
            let point = gesture.location(in: view)

            let col = Int((point.x - parent.labelWidth) / parent.cellWidth)
            let row = Int(point.y / parent.cellHeight)

            guard col >= 0, col < parent.colCount, row >= 0, row < parent.rowCount else { return }

            let coord = CellCoord(row: row, col: col)

            if coord != lastCoord {
                if parent.filledCells[coord] == task {
                    parent.filledCells[coord] = nil
                } else {
                    parent.filledCells[coord] = task
                }
                lastCoord = coord
            }

            if gesture.state == .ended || gesture.state == .cancelled {
                lastCoord = nil
            }
        }
    }
}
