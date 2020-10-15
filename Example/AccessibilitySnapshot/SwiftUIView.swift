//
//  SwiftUIView.swift
//  AccessibilitySnapshotDemo
//
//  Created by Felizia Bernutz on 13.10.20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
fileprivate struct Circle: View {
    var body: some View {
        Rectangle()
            .foregroundColor(Color(UIColor.lightGray))
            .frame(width: 30, height: 30)
            .cornerRadius(15)
    }
}

@available(iOS 13.0, *)
struct SwiftUIView: View {
    var body: some View {
//        ScrollView {
            VStack(spacing: 30) {
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

                Spacer()
            }
//        }
    }
}

@available(iOS 13.0, *)
struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
            .previewLayout(.sizeThatFits)
    }
}
