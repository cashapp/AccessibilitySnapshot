//
//  Copyright 2024 ___ORGANIZATIONNAME___
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

extension View {
  /// Adds a button to a view that will show a sheet with the accessibility snapshot for the view.
  @available(iOS 15.0, *)
  @ViewBuilder
  public func accessibilityPreview() -> some View {
    AccessibilityPreview {
      self
    }
  }

  /// Adds a button to a view that will show a sheet with the accessibility snapshot for the view.
  ///
  /// This modifier allows the client to determine when the accessibility snapshot sheet will be shown. One use case for this is when you want the accessibility snapshot shown on every code change. In that case you could pass in a `.constant(true)` binding, like so:
  /// ```swift
  /// ...
  ///     MyView()
  ///       .accessibilityPreview(isPresented: .constant(true))
  /// ...
  /// ```
  /// - Parameter isPresented: A binding to a bool that controls the presentation of the accessibility snapshot.
  @available(iOS 15.0, *)
  @ViewBuilder
  public func accessibilityPreview(isPresented: Binding<Bool>) -> some View {
    AccessibilityPreview(isPresented: isPresented) {
      self
    }
  }
}

@available(iOS 15.0, *)
struct AccessibilityPreview<Content: View>: View {
  private class ViewModel: ObservableObject {
    @Published var height = 0.0
    @Published var isPresented = false
    @Binding private var boundIsPresented: Bool

    init(isPresented: Binding<Bool>) {
      self.isPresented = isPresented.wrappedValue
      self._boundIsPresented = isPresented
    }

    func setHeight(_ height: CGFloat) {
      self.height = height
    }

    func setIsPresented(_ isPresented: Bool) {
      self.isPresented = isPresented
      self._boundIsPresented.wrappedValue = isPresented
    }
  }

  @ViewBuilder let content: () -> Content
  @StateObject private var viewModel: ViewModel

  init(
    isPresented: Binding<Bool>? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.content = content

    self._viewModel = StateObject(
      wrappedValue: ViewModel(
        isPresented: isPresented ?? .constant(false)
      )
    )
  }

  var body: some View {
    content().sheet(isPresented: $viewModel.isPresented) {
      NavigationView {
        AccessibilityPreviewViewRepresentable(height: viewModel.height) {
          content()
        }
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              viewModel.setIsPresented(false)
            } label: {
              Text("Close")
            }
          }
        }
        .navigationTitle("VoiceOver Accessibility")
        .navigationBarTitleDisplayMode(.inline)
        .navigationViewStyle(.stack)
      }
    }
    .background {
      GeometryReader { proxy in
        Color.clear
          .onAppear {
            viewModel.setHeight(proxy.size.height)
          }
      }
    }
    .overlay(alignment: .bottomTrailing) {
      Button {
        viewModel.setIsPresented(true)
      } label: {
        Text("Show VoiceOver accessibility")
      }
      .padding()
    }
  }
}

struct AccessibilityPreviewViewRepresentable<V: View>: UIViewRepresentable {
  var height: CGFloat
  @ViewBuilder var content: V

  func makeUIView(context: Context) -> UIView {
    let hostingController = UIHostingController(
      rootView: content
    )

    // TODO: Get a more reliable status bar height
    hostingController.view.frame = CGRect(
      x: 0,
      y: 30, // status bar height due to modal
      width: UIScreen.main.bounds.width,
      height: height
    )

    let accessibilitySnapshotView = AccessibilitySnapshotView(
      containedView: hostingController.view,
      viewRenderingMode: .drawHierarchyInRect,
      activationPointDisplayMode: .always,
      showUserInputLabels: false
    )

    // TODO: Should `isPreview` work differently at larger viewport widths?
    accessibilitySnapshotView.isPreview = true

    // TODO: Is `UIScreen.main.bounds` a safe assumption for previews?
    let scrollView = UIScrollView(
      frame: .init(
        x: 0,
        y: 0,
        width: UIScreen.main.bounds.width,
        height: UIScreen.main.bounds.height
      )
    )
    scrollView.addSubview(accessibilitySnapshotView)
    scrollView.alwaysBounceVertical = true

    // Wait a fraction of a second to ensure the view is in the view hierarchy.
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
      try? accessibilitySnapshotView.parseAccessibility(useMonochromeSnapshot: true)
      let size = accessibilitySnapshotView.sizeThatFits(UIScreen.main.bounds.size)

      scrollView.contentSize = size
    }

    return scrollView
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    // no-op
  }

  typealias UIViewType = UIView
}
