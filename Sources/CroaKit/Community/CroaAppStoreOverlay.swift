import SwiftUI
#if os(iOS)
import StoreKit
#endif

/// A dismissible native install card, scoped to one app-detail presentation.
struct CroaAppStoreOverlay: ViewModifier {
    let app: CroaCommunityApp
    #if os(iOS)
    @State private var isPresented = false
    @State private var hasPresented = false
    #endif

    @ViewBuilder func body(content: Content) -> some View {
        #if os(iOS)
        if let identifier = app.storeOverlayID {
            content
                .safeAreaPadding(.bottom, isPresented ? 100 : 0)
                .appStoreOverlay(isPresented: $isPresented) {
                    let configuration = SKOverlay.AppConfiguration(appIdentifier: identifier, position: .bottom)
                    configuration.userDismissible = true
                    return configuration
                }
                .onAppear {
                    // Loading the detail again must not bring back a card the user dismissed.
                    guard !hasPresented else { return }
                    hasPresented = true
                    isPresented = true
                }
                .onDisappear { isPresented = false }
        } else {
            content
        }
        #else
        content
        #endif
    }
}
