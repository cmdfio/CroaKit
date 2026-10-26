import SwiftUI
import CroaKit

@main
struct CroaKitDemoApp: App {
    @State private var theme = DemoTheme.system

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Signature", systemImage: "signature") { DemoView(theme: $theme) }
                Tab("Communauté", systemImage: "square.grid.2x2") { CroaKit.communityApps(theme: theme.value) }
            }
        }
    }
}

private struct DemoView: View {
    @Binding var theme: DemoTheme
    @State private var animations = true

    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 24)
            Text("CroaKit")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Picker("Thème", selection: $theme) {
                ForEach(DemoTheme.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.menu)
            CroaKit.footer(firstName: "Clément", animationsEnabled: animations, theme: theme.value)
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

private enum DemoTheme: String, CaseIterable, Identifiable {
    case system = "Système"
    case pond = "Étang"
    case paper = "Papier"
    case custom = "Sur mesure"
    var id: Self { self }

    var value: CroaTheme {
        switch self {
        case .system: .system
        case .pond: .pond
        case .paper: .paper
        case .custom:
            .custom(
                background: .gradient(LinearGradient(colors: [.indigo, Color(red: 0.12, green: 0.14, blue: 0.32)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing)),
                font: .custom("AvenirNext-Regular"), tint: .mint,
                foreground: .white, secondaryForeground: .white.opacity(0.8), colorScheme: .dark
            )
        }
    }
}
