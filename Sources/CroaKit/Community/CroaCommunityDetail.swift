import SwiftUI

struct CroaCommunityDetail: View {
    let app: CroaCommunityApp
    let client: CroaCommunityClient
    let theme: CroaTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.self) private var environment
    @State private var detail: CroaCommunityAppDetail?
    @State private var failed = false
    @State private var reloadID = 0
    @State private var expanded = false
    @Environment(\.dismiss) private var dismiss

    private var appearance: CroaResolvedTheme { theme.resolve(in: colorScheme) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    if let detail {
                        if !detail.screenshotURLs.isEmpty { screenshots(detail.screenshotURLs) }
                        if let blurb = detail.blurb, !blurb.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Le mot de l’équipe", bundle: .module).font(appearance.font.font(.headline))
                                Text(verbatim: blurb).font(appearance.font.font(.body)).textSelection(.enabled)
                            }
                        }
                        if let description = detail.description, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("À propos", bundle: .module).font(appearance.font.font(.headline))
                                Text(verbatim: description).font(appearance.font.font(.body)).foregroundStyle(appearance.secondary)
                                    .lineLimit(expanded ? nil : 8).textSelection(.enabled)
                                if !expanded {
                                    Button { expanded = true } label: { Text("Lire la suite", bundle: .module) }
                                        .font(appearance.font.font(.subheadline, weight: .semibold))
                                }
                            }
                        }
                        if let version = detail.version {
                            Text("Version \(version)", bundle: .module).font(appearance.font.font(.footnote)).foregroundStyle(appearance.secondary)
                        }
                    } else if failed {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("La présentation n’a pas pu être chargée.", bundle: .module).foregroundStyle(appearance.secondary)
                            Button { reloadID += 1 } label: { Text("Réessayer", bundle: .module) }
                        }
                    } else {
                        ProgressView { Text("Chargement de la présentation…", bundle: .module) }.frame(maxWidth: .infinity).padding(.vertical, 24)
                    }
                    Divider()
                    Link(destination: app.communityURL) { Text("Voir la fiche sur cmdf.io", bundle: .module) }
                        .font(appearance.font.font(.subheadline, weight: .semibold))
                    Text("Informations et visuels fournis par le développeur et l’App Store.", bundle: .module)
                        .font(appearance.font.font(.caption)).foregroundStyle(appearance.secondary)
                }
                .padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity, alignment: .center)
            }
            .modifier(CroaCatalogueBackground(appearance: appearance))
            .navigationTitle(Text("Découvrir l’app", bundle: .module))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Label { Text("Fermer", bundle: .module) } icon: { Image(systemName: "xmark") }
                    }
                }
            }
            .task(id: reloadID) {
                failed = false
                do {
                    let loaded = try await client.detail(for: app)
                    try Task.checkCancellation()
                    detail = loaded
                } catch is CancellationError {
                } catch let error as URLError where error.code == .cancelled {
                } catch { failed = true }
            }
        }
        .modifier(CroaThemeStyle(appearance: appearance))
        .modifier(CroaAppStoreOverlay(app: app))
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 560)
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 18) {
                CroaCommunityIcon(app: app, size: 88, appearance: appearance)
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: app.name).font(appearance.font.font(.title2, weight: .bold)).fixedSize(horizontal: false, vertical: true)
                    if let developer = app.developer { Text(verbatim: developer).font(appearance.font.font(.subheadline)).foregroundStyle(appearance.secondary) }
                    Text(verbatim: app.category).font(appearance.font.font(.caption)).foregroundStyle(appearance.secondary)
                }
            }
            if let url = app.appStoreURL {
                Link(destination: url) {
                    Label { Text("Voir sur l’App Store", bundle: .module) } icon: { Image(systemName: "arrow.up.forward") }
                        .font(appearance.font.font(.headline)).frame(maxWidth: .infinity).padding(.vertical, 6)
                        .foregroundStyle(appearance.textOnTint(in: environment))
                }
                .buttonStyle(.borderedProminent)
            }
            if let detail {
                HStack(spacing: 16) {
                    if let price = detail.price { Text(verbatim: price) }
                    if let rating = detail.rating, rating.isFinite, (0...5).contains(rating) {
                        Label(rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                        if let count = detail.ratingCount, count > 0 { Text("\(count) avis", bundle: .module) }
                    }
                }
                .font(appearance.font.font(.footnote)).foregroundStyle(appearance.secondary)
            }
        }
    }

    private func screenshots(_ urls: [URL]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("En images", bundle: .module).font(appearance.font.font(.headline))
            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(urls, id: \.self) { url in
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image): image.resizable().scaledToFit()
                            case .failure: Image(systemName: "photo").foregroundStyle(appearance.secondary)
                            default: ProgressView()
                            }
                        }
                        .frame(width: 190, height: 350)
                        .background(appearance.surface, in: RoundedRectangle(cornerRadius: 16))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .accessibilityLabel(Text("Capture de \(app.name)", bundle: .module))
                    }
                }
            }
        }
    }
}
