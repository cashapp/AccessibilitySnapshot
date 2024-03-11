//
//  Copyright 2024 Square Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AccessibilitySnapshotCore
import SwiftUI

struct SwiftUITextEntry: View {
    @State private var textField1 = ""
    @State private var textField2 = "Value in Text Field"
    @State private var textEditor1 = ""

    var body: some View {
        VStack {
            TextField("SwiftUI Text Field", text: $textField1)
            TextField("SwiftUI Text Field", text: $textField2)
            if #available(iOS 14.0, *) {
                TextEditor(text: $textEditor1)
                    .frame(height: 300)
            }
        }
    }
}

struct Preview: View {
    @State private var isPresented = true

    var body: some View {
        if #available(iOS 15.0, *) {
            SwiftUITextEntry()
                .accessibilityPreview(isPresented: $isPresented)
        } else {
            SwiftUITextEntry()
        }
    }
}

struct SwiftUITextEntry_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 15.0, *) {
            SwiftUITextEntry()
                .accessibilityPreview()
//                    Preview()
                .previewLayout(.sizeThatFits)
        } else {
            SwiftUITextEntry()
                .previewLayout(.sizeThatFits)
        }
    }
}
