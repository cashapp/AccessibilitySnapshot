//
//  ViewRenderingMode.swift
//  AccessibilitySnapshot
//
//  Created by Soroush Khanlou on 7/1/25.
//

/// The preferred strategy for convering a view to an image.
public enum ViewRenderingMode {

    /// Render the view's layer in a `CGContext` using the `render(in:)` method.
    case renderLayerInContext

    /// Draw the view's hierarchy after screen updates using the `drawHierarchy(in:afterScreenUpdates:)` method.
    case drawHierarchyInRect

}
