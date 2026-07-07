import SwiftUI

@available(iOS 15.0, *)
struct SwiftUILazyScrollView: View {
    enum ScrollPosition {
        case top, middle, bottom
    }

    let scrollPosition: ScrollPosition
    let rowCount = 30

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(0 ..< rowCount, id: \.self) { index in
                        Text("Lazy \(index)")
                            .accessibilityLabel("Lazy \(index)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .id(index)
                    }
                }
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
