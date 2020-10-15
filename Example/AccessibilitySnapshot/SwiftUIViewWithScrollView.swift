//
//  SwiftUIView.swift
//  AccessibilitySnapshotDemo
//
//  Created by Felizia Bernutz on 13.10.20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct SwiftUIViewWithScrollView: View {
    var body: some View {
        ScrollView {
            SwiftUIView()
        }
    }
}

@available(iOS 13.0, *)
struct SwiftUIViewWithScrollView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIViewWithScrollView()
            .previewLayout(.sizeThatFits)
    }
}
