import SwiftUI

struct SwiftUITextEntry: View {
    var body: some View {
        VStack {
            TextField("SwiftUI Text Field", text: .constant(""))
            TextField("SwiftUI Text Field", text: .constant("Value in Text Field"))
            SecureField("Password", text: .constant(""))
            SecureField("Password", text: .constant("secret123"))
            if #available(iOS 14.0, *) {
                TextEditor(text: .constant(""))
            }
        }
    }
}

struct SwiftUITextEntry_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUITextEntry()
            .previewLayout(.sizeThatFits)
    }
}
