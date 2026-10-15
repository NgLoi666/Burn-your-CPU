import SwiftUI
import UIKit

struct SettingsView: View {
    @Bindable private var orientation = OrientationController.shared

    var body: some View {
        Form {
            Section("Orientation") {
                Toggle("Lock orientation", isOn: $orientation.isLocked)

                Picker("Allow while locked", selection: $orientation.lockedMask) {
                    Text("Portrait").tag(UIInterfaceOrientationMask.portrait)
                    Text("Landscape").tag(UIInterfaceOrientationMask.landscape)
                    Text("All").tag(UIInterfaceOrientationMask.all)
                }
                .disabled(!orientation.isLocked)

                Button("Re-apply orientation now") {
                    orientation.requestRotationUpdate()
                }
            }
            .onChange(of: orientation.isLocked) { _, _ in
                orientation.requestRotationUpdate()
            }
            .onChange(of: orientation.lockedMask) { _, _ in
                orientation.requestRotationUpdate()
            }

            Section("iOS 26 UI keys") {
                LabeledContent("UIDesignRequiresCompatibility", value: "NO — adopt Liquid Glass")
                LabeledContent("UISupportsFullScreenInAssistiveAccess", value: "YES")
                LabeledContent("iPhone orientations", value: "Portrait, Landscape L/R")
                LabeledContent("iPad orientations", value: "All four")
            }
        }
        .navigationTitle("Settings")
    }
}
