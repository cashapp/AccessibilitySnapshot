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

@available(iOS 15.0, *)
struct SwiftUIViewWithListWithSections: View {
    @State var groupedItems: [(String, [String])] = [
        ("Section 1", ["Item 1", "Item 2", "Item 3"]),
        ("Section 2", ["Item 1", "Item 2", "Item 3"]),
        ("Section 3", ["Item 1", "Item 2", "Item 3"]),
    ]

    var body: some View {
        List {
            ForEach(groupedItems, id: \.0) { groupedItem in
                Section(groupedItem.0) {
                    ForEach(groupedItem.1, id: \.self) { item in
                        Text(item)
                    }
                }
            }
        }
    }
}

@available(iOS 15.0, *)
struct SwiftUIViewWithListWithSections_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIViewWithListWithSections()
            .previewLayout(.sizeThatFits)
    }
}

#endif
