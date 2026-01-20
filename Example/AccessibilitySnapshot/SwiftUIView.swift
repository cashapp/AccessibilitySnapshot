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

fileprivate struct Circle: View {
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

                if #available(iOS 15.0, *) {
                    Circle()
                        .accessibility(label: Text(getAccessibilityAttributedLabel()))
                }

                if #available(iOS 15.0, *) {
                    Circle()
                        .accessibility(label: Text(getAccessibilityAttributedLabel()))
                        .accessibility(value: Text(getAccessibilityAttributedValue()))
                        .accessibility(hint: Text(getAccessibilityAttributedHint()))
                }
                
                // View with IPA notation for pronunciation
                if #available(iOS 15.0, *) {
                    Circle()
                        .accessibility(label: Text(getAccessibilityIPALabel()))
                }

                if #available(iOS 15.0, *) {
                    Text("Section Title")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h1)
                }

                if #available(iOS 15.0, *) {
                    Text("Section Subtitle")
                        .font(.subheadline)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                }
            }
            
            Spacer()
        }
    }

    @available(iOS 15, *)
    func getAccessibilityAttributedLabel() -> AttributedString {
        var attributedString = AttributedString("Hello Bonjour")

        // Unfortunately, SwiftUI does not appear to respect this attribute, so VoiceOver will not read
        // "Bonjour" in French. This is not an issue on UIKit. A feedback item has been filed with Apple.
        // The .languageIdentifier key works in place of this. However, we do not intend to show it in the
        // legend as its scope goes beyond accessibility.
        let languageAttribute = AttributeContainer([.accessibilitySpeechLanguage: "fr-CA"])
        if let range = attributedString.range(of: "Bonjour") {
            attributedString[range].setAttributes(languageAttribute)
        }
        let headingAttribute = AttributeContainer([.accessibilityTextHeadingLevel: 1])
        attributedString.setAttributes(headingAttribute)
        return attributedString
    }

    @available(iOS 15, *)
    func getAccessibilityAttributedValue() -> AttributedString {
        let spellOutAttribute = AttributeContainer([.accessibilitySpeechSpellOut: true])
        let attributedString = AttributedString("50%", attributes: spellOutAttribute)
        return attributedString
    }

    @available(iOS 15, *)
    func getAccessibilityAttributedHint() -> AttributedString {
        let attributes = AttributeContainer([
            .accessibilitySpeechPitch: 1.5,
            .accessibilitySpeechPunctuation: true
        ])
        let attributedString = AttributedString("This is a high-pitched hint.", attributes: attributes)
        return attributedString
    }
    
    @available(iOS 15, *)
    func getAccessibilityIPALabel() -> AttributedString {
        let ipaAttribute = AttributeContainer([.accessibilitySpeechIPANotation: "ˈkiːnwɑː"])
        let attributedString = AttributedString("Quinoa", attributes: ipaAttribute)
        return attributedString
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
            .previewLayout(.sizeThatFits)
    }
}
