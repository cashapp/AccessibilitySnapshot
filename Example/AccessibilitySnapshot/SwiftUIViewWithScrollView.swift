//
//  Copyright 2020 Square Inc.
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
