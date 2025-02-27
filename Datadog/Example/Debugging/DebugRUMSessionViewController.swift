/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import SwiftUI
import Datadog

@available(iOS 13, *)
internal class DebugRUMSessionViewController: UIHostingController<DebugRUMSessionView> {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: DebugRUMSessionView())
    }
}

private enum SessionItemType {
    case view
    case resource
    case action
    case error
}

@available(iOS 13.0, *)
private class DebugRUMSessionViewModel: ObservableObject {
    struct SessionItem: Identifiable {
        let label: String
        let type: SessionItemType
        var isPending: Bool
        var stopAction: (() -> Void)?

        var id: UUID = UUID()
    }

    @Published var sessionItems: [SessionItem] = []

    @Published var viewKey: String = ""
    @Published var actionName: String = ""
    @Published var errorMessage: String = ""
    @Published var resourceKey: String = ""

    func startView() {
        guard !viewKey.isEmpty else {
            return
        }

        let key = viewKey
        sessionItems.append(
            SessionItem(
                label: key,
                type: .view,
                isPending: true,
                stopAction: { [weak self] in
                    self?.modifySessionItem(type: .view, label: key) { mutableSessionItem in
                        mutableSessionItem.isPending = false
                        mutableSessionItem.stopAction = nil
                        Global.rum.stopView(key: key)
                    }
                }
            )
        )

        Global.rum.startView(key: key)
        self.viewKey = ""
    }

    func addAction() {
        guard !actionName.isEmpty else {
            return
        }

        sessionItems.append(
            SessionItem(label: actionName, type: .action, isPending: false, stopAction: nil)
        )

        Global.rum.addUserAction(type: .custom, name: actionName)
        self.actionName = ""
    }

    func addError() {
        guard !errorMessage.isEmpty else {
            return
        }

        sessionItems.append(
            SessionItem(label: errorMessage, type: .error, isPending: false, stopAction: nil)
        )

        Global.rum.addError(message: errorMessage)
        self.errorMessage = ""
    }

    func startResource() {
        guard !resourceKey.isEmpty else {
            return
        }

        let key = self.resourceKey
        sessionItems.append(
            SessionItem(
                label: key,
                type: .resource,
                isPending: true,
                stopAction: { [weak self] in
                    self?.modifySessionItem(type: .resource, label: key) { mutableSessionItem in
                        mutableSessionItem.isPending = false
                        mutableSessionItem.stopAction = nil
                        Global.rum.stopResourceLoading(resourceKey: key, statusCode: nil, kind: .other)
                    }
                }
            )
        )

        Global.rum.startResourceLoading(resourceKey: key, url: mockURL())
        self.resourceKey = ""
    }

    // MARK: - Private

    private func modifySessionItem(type: SessionItemType, label: String, change: (inout SessionItem) -> Void) {
        sessionItems = sessionItems.map { item in
            var item = item
            if item.type == type, item.label == label {
                change(&item)
            }
            return item
        }
    }

    private func mockURL() -> URL {
        return URL(string: "https://foo.com/\(UUID().uuidString)")!
    }
}

@available(iOS 13.0, *)
internal struct DebugRUMSessionView: View {
    @ObservedObject private var viewModel = DebugRUMSessionViewModel()

    var body: some View {
        VStack() {
            HStack {
                FormItemView(
                    title: "RUM View", placeholder: "view key", accent: .rumViewColor, value: $viewModel.viewKey
                )
                Button("START") { viewModel.startView() }
            }
            HStack {
                FormItemView(
                    title: "RUM Action", placeholder: "name", accent: .rumActionColor, value: $viewModel.actionName
                )
                Button("ADD") { viewModel.addAction() }
            }
            HStack {
                FormItemView(
                    title: "RUM Error", placeholder: "message", accent: .rumErrorColor, value: $viewModel.errorMessage
                )
                Button("ADD") { viewModel.addError() }
            }
            HStack {
                FormItemView(
                    title: "RUM Resource", placeholder: "key", accent: .rumResourceColor, value: $viewModel.resourceKey
                )
                Button("START") { viewModel.startResource() }
            }
            Divider()
            Text("RUM Session:")
                .bold()
                .font(.footnote)
            List(viewModel.sessionItems) { sessionItem in
                SessionItemView(item: sessionItem)
                    .listRowInsets(EdgeInsets())
                    .padding(4)
            }
            .listStyle(PlainListStyle())
        }
        .buttonStyle(DatadogButtonStyle())
        .padding()
    }
}

@available(iOS 13.0, *)
private struct FormItemView: View {
    let title: String
    let placeholder: String
    let accent: Color

    @Binding var value: String

    var body: some View {
        HStack {
            Text(title)
                .bold()
                .font(.system(size: 10))
                .padding(8)
                .background(accent)
                .foregroundColor(Color.white)
                .cornerRadius(8)
            TextField(placeholder, text: $value)
                .font(.system(size: 12))
                .padding(8)
                .background(Color(UIColor.secondarySystemFill))
                .cornerRadius(8)
        }
        .padding(8)
        .background(Color(UIColor.systemFill))
        .foregroundColor(Color.secondary)
        .cornerRadius(8)
    }
}

@available(iOS 13.0, *)
private struct SessionItemView: View {
    let item: DebugRUMSessionViewModel.SessionItem

    var body: some View {
        HStack() {
            HStack() {
                Text(label(for: item.type))
                    .bold()
                    .font(.system(size: 10))
                    .padding(8)
                    .background(color(for: item.type))
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
                Text(item.label)
                    .bold()
                    .font(.system(size: 14))
                Spacer()
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemFill))
            .foregroundColor(Color.secondary)
            .cornerRadius(8)

            if item.isPending {
                Button("STOP") { item.stopAction?() }
            }
        }
    }

    private func color(for sessionItemType: SessionItemType) -> Color {
        switch sessionItemType {
        case .view:     return .rumViewColor
        case .resource: return .rumResourceColor
        case .action:   return .rumActionColor
        case .error:    return .rumErrorColor
        }
    }

    private func label(for sessionItemType: SessionItemType) -> String {
        switch sessionItemType {
        case .view:     return "RUM View"
        case .resource: return "RUM Resource"
        case .action:   return "RUM Action"
        case .error:    return "RUM Error"
        }
    }
}

// MARK - Preview

@available(iOS 13.0, *)
struct DebugRUMSessionViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DebugRUMSessionView()
                .previewLayout(.fixed(width: 400, height: 500))
                .preferredColorScheme(.light)
            DebugRUMSessionView()
                .previewLayout(.fixed(width: 400, height: 500))
                .preferredColorScheme(.dark)
        }
    }
}
