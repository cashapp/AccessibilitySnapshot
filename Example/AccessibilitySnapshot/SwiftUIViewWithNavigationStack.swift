//
//  Copyright 2023 Square Inc.
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


#if swift(>=5.1) && canImport(SwiftUI)

import SwiftUI

@available(iOS 16.0, *)
struct SwiftUIViewWithNavigationStack: View {
    var body: some View {
        NavigationStack {
            Text("Text inside a NavigationStack")
                .navigationTitle("Navigation Stack")
                .toolbar {
                    ToolbarItem {
                        Button {
                            // no-op
                        } label: {
                            Text("Add")
                        }
                    }
                }
        }
    }
}

@available(iOS 16.0, *)
struct SwiftUIViewWithNavigationStack_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIViewWithNavigationStack()
            .previewLayout(.sizeThatFits)
    }
}

#endif
