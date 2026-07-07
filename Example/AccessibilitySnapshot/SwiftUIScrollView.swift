import SwiftUI

@available(iOS 15.0, *)
struct SwiftUIScrollView: View {
    enum ScrollPosition {
        case top, middle, bottom
    }

    let scrollPosition: ScrollPosition
    let rowCount = 30

    var body: some View {
        ScrollViewReader { proxy in
            List(0 ..< rowCount, id: \.self) { index in
                Text("Item \(index)")
                    .accessibilityLabel("Item \(index)")
                    .id(index)
            }
            .onAppear {
                switch scrollPosition {
                case .top:
                    proxy.scrollTo(0, anchor: .top)
                case .middle:
                    proxy.scrollTo(rowCount / 2, anchor: .center)
                case .bottom:
                    proxy.scrollTo(rowCount - 1, anchor: .bottom)
                }
            }
        }
    }
}
