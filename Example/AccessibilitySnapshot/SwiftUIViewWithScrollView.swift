import SwiftUI

/// A SwiftUI View inside a ScrollView will produce no accessibility elements for iOS 14.0 and 14.1, for more
/// information see cashapp/AccessibilitySnapshot#33. This seems to be a SwiftUI bug which was resolved in iOS 14.2.
struct SwiftUIViewWithScrollView: View {
    var body: some View {
        ScrollView {
            SwiftUIView()
        }
    }
}

struct SwiftUIViewWithScrollView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIViewWithScrollView()
            .previewLayout(.sizeThatFits)
    }
}
