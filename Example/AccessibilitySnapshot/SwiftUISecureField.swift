import SwiftUI

struct SwiftUISecureField: View {
    var body: some View {
        VStack {
            SecureField("Password", text: .constant(""))
            SecureField("Password", text: .constant("secret123"))
            TextField("Username", text: .constant(""))
        }
    }
}
