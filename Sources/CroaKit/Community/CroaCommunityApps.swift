import SwiftUI

/// A self-contained SwiftUI catalogue, ready to present in a sheet or a tab.
public struct CroaCommunityApps: View {
    private let client: CroaCommunityClient
    private let theme: CroaTheme
    @State private var model: CroaCommunityModel
    @State private var selectedApp: CroaCommunityApp?
    @State private var reloadID = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.self) private var environment
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(excludingAppStoreID: String? = nil, client: CroaCommunityClient = .init(), theme: CroaTheme = .system) {
        self.client = client
        self.theme = theme
        _model = State(initialValue: CroaCommunityModel(client: client, excludingAppStoreID: excludingAppStoreID))
    }

    private var appearance: CroaResolvedTheme { theme.resolve(in: colorScheme) }
    private var accent: Color { appearance.tint }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    catalogue
                    communityFooter
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .modifier(CroaCatalogueBackground(appearance: appearance))
            .refreshable { await model.load() }
            .navigationTitle(Text("Les apps du collectif", bundle: .module))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $model.query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: Text("App, développeur, catégorie…", bundle: .module))
            #else
            .searchable(text: $model.query, prompt: Text("App, développeur, catégorie…", bundle: .module))
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { reloadID += 1 } label: {
                        Label { Text("Actualiser", bundle: .module) } icon: { Image(systemName: "arrow.clockwise") }
                    }
                    .disabled(model.isLoading)
                }
                if isPresented {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { dismiss() } label: {
                            Label { Text("Fermer", bundle: .module) } icon: { Image(systemName: "xmark") }
                        }
                    }
                }
            }
            .task(id: reloadID) { await model.load() }
            .sheet(item: $selectedApp) { app in
                CroaCommunityDetail(app: app, client: client, theme: theme)
            }
        }
        .modifier(CroaThemeStyle(appearance: appearance))
        .accessibilityIdentifier("croakit.community")
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 560)
        #endif
    }

    @ViewBuilder private var catalogue: some View {
        if model.apps.isEmpty && model.isLoading {
            ProgressView { Text("Chargement des apps…", bundle: .module) }.frame(maxWidth: .infinity).padding(.vertical, 40)
        } else if model.apps.isEmpty && model.failed {
            ContentUnavailableView {
                Label { Text("Le catalogue est indisponible", bundle: .module) } icon: { Image(systemName: "wifi.exclamationmark") }
                    .font(appearance.font.font(.title2, weight: .bold))
            } description: {
                Text("Vérifiez votre connexion ou retrouvez les apps sur cmdf.io.", bundle: .module)
                    .font(appearance.font.font(.body)).foregroundStyle(appearance.secondary)
            } actions: {
                Button { reloadID += 1 } label: { Text("Réessayer", bundle: .module) }
                    .foregroundStyle(appearance.textOnTint(in: environment))
                    .buttonStyle(.borderedProminent)
                Link(destination: CroaCommunityClient.catalogueURL) { Text("Voir sur cmdf.io", bundle: .module) }
            }
        } else if model.hasLoaded {
            VStack(alignment: .leading, spacing: 12) {
                if model.failed {
                    Label {
                        Text("Actualisation indisponible. Les dernières apps chargées restent affichées.", bundle: .module)
                    } icon: {
                        Image(systemName: "wifi.exclamationmark")
                    }
                    .font(appearance.font.font(.footnote)).foregroundStyle(appearance.secondary)
                }
                if !model.apps.isEmpty { filters }
                if model.filteredApps.isEmpty {
                    ContentUnavailableView {
                        Label {
                            if model.isFiltered {
                                Text("Aucune app ne correspond", bundle: .module)
                            } else {
                                Text("Les premières apps arrivent", bundle: .module)
                            }
                        } icon: {
                            Image(systemName: "square.grid.2x2")
                        }
                        .font(appearance.font.font(.title2, weight: .bold))
                    } description: {
                        Group {
                            if model.isFiltered {
                                Text("Essayez un autre nom ou une autre catégorie.", bundle: .module)
                            } else {
                                Text("Proposez votre application à la communauté.", bundle: .module)
                            }
                        }
                        .font(appearance.font.font(.body)).foregroundStyle(appearance.secondary)
                    } actions: {
                        if model.isFiltered { Button { model.resetFilters() } label: { Text("Tout effacer", bundle: .module) } }
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 12)], spacing: 12) {
                        ForEach(model.filteredApps) { app in
                            Button { selectedApp = app } label: { CroaCommunityRow(app: app, appearance: appearance) }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("croakit.community.app.\(app.slug)")
                        }
                    }
                }
            }
        }
    }

    private var filters: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 10))

        return VStack(alignment: .leading, spacing: 8) {
            layout {
                HStack(spacing: 10) {
                    CroaFrog(width: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Communauté ⌘+F", bundle: .module)
                            .font(appearance.font.font(.caption, weight: .semibold)).foregroundStyle(accent)
                        Text("\(model.filteredApps.count) apps", bundle: .module)
                            .font(appearance.font.font(.caption)).foregroundStyle(appearance.secondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Menu {
                    Picker(selection: $model.category) {
                        Text("Toutes les catégories", bundle: .module).tag("")
                        ForEach(model.categories, id: \.self) { Text(verbatim: $0).tag($0) }
                    } label: {
                        Text("Catégorie", bundle: .module)
                    }
                } label: {
                    Label {
                        if model.category.isEmpty {
                            Text("Catégories", bundle: .module)
                        } else {
                            Text(verbatim: model.category)
                        }
                    } icon: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    .font(appearance.font.font(.subheadline)).padding(.vertical, 8)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    tagButton(Text("Toutes", bundle: .module), value: "")
                    if model.apps.contains(where: { $0.tags.contains("duo") }) {
                        tagButton(Text("Compatible Duo", bundle: .module), value: "duo")
                    }
                    // The Build Challenge keeps its name in every language.
                    if model.apps.contains(where: { $0.tags.contains("build-challenge") }) {
                        tagButton(Text(verbatim: "Build Challenge"), value: "build-challenge")
                    }
                    if model.apps.contains(where: { $0.tags.contains("founder") }) {
                        tagButton(Text("Fondateurs", bundle: .module), value: "founder")
                    }
                }
            }
        }
    }

    private func tagButton(_ title: Text, value: String) -> some View {
        Button { model.tag = value } label: {
            title.font(appearance.font.font(.subheadline, weight: .medium))
                .padding(.horizontal, 14).frame(minHeight: 44)
                .foregroundStyle(model.tag == value ? accent : appearance.secondary)
                .background(model.tag == value ? accent.opacity(0.12) : appearance.surface, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(model.tag == value ? .isSelected : [])
    }

    private var communityFooter: some View {
        Text("⌘+F c'est le regroupement des développeurs Apple francophones. Retrouvez nous sur [cmdf.io](https://cmdf.io).",
             bundle: .module)
            .font(appearance.font.font(.footnote))
            .foregroundStyle(appearance.secondary)
            .padding(.vertical, 8)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("croakit.community.about")
    }
}

struct CroaCommunityRow: View {
    let app: CroaCommunityApp
    let appearance: CroaResolvedTheme
    var body: some View {
        HStack(spacing: 14) {
            CroaCommunityIcon(app: app, size: 60, appearance: appearance)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: app.name).font(appearance.font.font(.headline)).foregroundStyle(appearance.foreground).lineLimit(2)
                if let developer = app.developer {
                    Text(verbatim: developer).font(appearance.font.font(.caption)).foregroundStyle(appearance.secondary).lineLimit(2)
                }
                Text(verbatim: app.category).font(appearance.font.font(.caption)).foregroundStyle(appearance.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(appearance.font.font(.caption, weight: .semibold)).foregroundStyle(appearance.secondary.opacity(0.6))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(appearance.surface, in: RoundedRectangle(cornerRadius: 20))
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

struct CroaCommunityIcon: View {
    let app: CroaCommunityApp
    let size: CGFloat
    let appearance: CroaResolvedTheme
    var body: some View {
        AsyncImage(url: app.artworkURL) { image in
            image.resizable().scaledToFit()
        } placeholder: {
            Image(systemName: "app.dashed").resizable().scaledToFit().padding(size * 0.2).foregroundStyle(appearance.secondary)
        }
        .frame(width: size, height: size)
        .background(appearance.surface, in: RoundedRectangle(cornerRadius: size * 0.22))
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
        .accessibilityHidden(true)
    }
}
