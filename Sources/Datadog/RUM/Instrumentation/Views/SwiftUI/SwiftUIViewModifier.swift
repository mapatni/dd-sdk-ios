/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

#if canImport(SwiftUI)
import SwiftUI

/// `SwiftUI.ViewModifier` for RUM which invoke `startView` and `stopView` from the
/// global RUM Monitor when the modified view appears and disappears.
@available(iOS 13, *)
internal struct RUMViewModifier: SwiftUI.ViewModifier {
    /// The Content View identifier.
    /// The id will be unique per modified view.
    let identity: String = UUID().uuidString

    /// View Name used for RUM Explorer.
    let name: String

    /// View Path used for RUM Explorer.
    let path: String

    /// Custom attributes to attach to the View.
    let attributes: [AttributeKey: AttributeValue]

    func body(content: Content) -> some View {
        content.onAppear {
            RUMInstrumentation.instance?.viewsInstrumentation
                .notify_onAppear(
                    identity: identity,
                    name: name,
                    path: path,
                    attributes: attributes
                )
        }
        .onDisappear {
            RUMInstrumentation.instance?.viewsInstrumentation
                .notify_onDisappear(identity: identity)
        }
    }
}

@available(iOS 13, *)
public extension SwiftUI.View {
    /// Monitor this view with Datadog RUM. A start and stop events will be logged when this view appears
    /// and disappears.
    ///
    /// - Parameters:
    ///   - name: the View name used for RUM Explorer.
    ///   - attributes: custom attributes to attach to the View.
    /// - Returns: This view after applying a `ViewModifier` for monitoring the view.
    func trackRUMView(
        name: String,
        attributes: [AttributeKey: AttributeValue] = [:]
    ) -> some View {
        let path = "\(name)/\(typeDescription.hashValue)"
        return modifier(RUMViewModifier(name: name, path: path, attributes: attributes))
    }
}

#endif
