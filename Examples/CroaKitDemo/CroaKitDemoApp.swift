import SwiftUI
import CroaKit

@main
struct CroaKitDemoApp: App {
    var body: some Scene {
        WindowGroup { DemoView() }
    }
}

private struct DemoView: View {
    @State private var animations = true

    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 24)
            Text("CroaKit")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            CroaKit.footer(firstName: "Clément", animationsEnabled: animations)
            Spacer(minLength: 24)
            Toggle("Animations", isOn: $animations)
                .frame(maxWidth: 300)
            Text("Touchez la grenouille pour un clin d’œil.\nMaintenez pour la faire sauter.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
