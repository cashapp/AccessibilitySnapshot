import SwiftUI

private struct Circle: View {
    var body: some View {
        Rectangle()
            .foregroundColor(Color(UIColor.lightGray))
            .frame(width: 30, height: 30)
            .cornerRadius(15)
    }
}

struct SwiftUIView: View {
    var body: some View {
        VStack(spacing: 30) {
            Group {
                // View with nothing.
                Circle()
                    .accessibility(label: Text(""))
                    .accessibility(value: Text(""))
                    .accessibility(hint: Text(""))

                // View with label.
                Circle()
                    .accessibility(label: Text("Label"))
                    .accessibility(value: Text(""))
                    .accessibility(hint: Text(""))

                // View with value.
                Circle()
                    .accessibility(label: Text(""))
                    .accessibility(value: Text("Value"))
                    .accessibility(hint: Text(""))

                // View with hint.
                Circle()
                    .accessibility(label: Text(""))
                    .accessibility(value: Text(""))
                    .accessibility(hint: Text("Hint"))

                // View with label and value.
                Circle()
                    .accessibility(label: Text("Label"))
                    .accessibility(value: Text("Value"))
                    .accessibility(hint: Text(""))

                // View with label and hint.
                Circle()
                    .accessibility(label: Text("Label"))
                    .accessibility(value: Text(""))
                    .accessibility(hint: Text("Hint"))

                // View with value and hint.
                Circle()
                    .accessibility(label: Text(""))
                    .accessibility(value: Text("Value"))
                    .accessibility(hint: Text("Hint"))

                // View with label, value, and hint.
                Circle()
                    .accessibility(label: Text("Label"))
                    .accessibility(value: Text("Value"))
                    .accessibility(hint: Text("Hint"))

                if #available(iOS 14.0, *) {
                    // View with label, value, hint, and Custom Actions.
                    Circle()
                        .accessibility(label: Text("Label"))
                        .accessibility(value: Text("Value"))
                        .accessibility(hint: Text("Hint"))
                        .accessibilityAction(named: "Custom") {}
                }

                if #available(iOS 15.0, *) {
                    // View with label, value, hint, and Custom Content.
                    Circle()
                        .accessibility(label: Text("Label"))
                        .accessibility(value: Text("Value"))
                        .accessibility(hint: Text("Hint"))
                        .accessibilityCustomContent("Key", "Value")
                        .accessibilityCustomContent("Important Key", "Important Value", importance: .high)
                }
            }

            Spacer()
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
            .previewLayout(.sizeThatFits)
    }
}
