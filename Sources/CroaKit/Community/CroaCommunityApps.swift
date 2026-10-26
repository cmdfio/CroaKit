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
                VStack(alignment: .leading, spacing: 24) {
                    introduction
                    catalogue
                    submission
                }
                .padding(20)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
            .modifier(CroaCatalogueBackground(appearance: appearance))
            .refreshable { await model.load() }
            .navigationTitle("Les apps du collectif")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $model.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "App, développeur, catégorie…")
            #else
            .searchable(text: $model.query, prompt: "App, développeur, catégorie…")
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { reloadID += 1 } label: { Label("Actualiser", systemImage: "arrow.clockwise") }
                        .disabled(model.isLoading)
                }
                if isPresented {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fermer", systemImage: "xmark") { dismiss() }
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

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LA COMMUNAUTÉ ⌘+F")
                        .font(appearance.font.font(.caption, weight: .semibold)).tracking(1.1).foregroundStyle(accent)
                    Text("Des idées d’ici.\nDes apps pour vous.")
                        .font(appearance.font.font(.title2, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                CroaFrog(width: 48)
            }
            Text("Découvrez les créations de développeuses et développeurs francophones.")
                .font(appearance.font.font(.subheadline)).foregroundStyle(appearance.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private var catalogue: some View {
        if model.apps.isEmpty && model.isLoading {
            ProgressView("Chargement des apps…").frame(maxWidth: .infinity).padding(.vertical, 40)
        } else if model.apps.isEmpty && model.failed {
            ContentUnavailableView {
                Label("Le catalogue est indisponible", systemImage: "wifi.exclamationmark")
                    .font(appearance.font.font(.title2, weight: .bold))
            } description: {
                Text("Vérifiez votre connexion ou retrouvez les apps sur cmdf.io.")
                    .font(appearance.font.font(.body)).foregroundStyle(appearance.secondary)
            } actions: {
                Button("Réessayer") { reloadID += 1 }
                    .foregroundStyle(appearance.textOnTint(in: environment))
                    .buttonStyle(.borderedProminent)
                Link("Voir sur cmdf.io", destination: CroaCommunityClient.catalogueURL)
            }
        } else if model.hasLoaded {
            VStack(alignment: .leading, spacing: 16) {
                if model.failed {
                    Label("Actualisation indisponible. Les dernières apps chargées restent affichées.", systemImage: "wifi.exclamationmark")
                        .font(appearance.font.font(.footnote)).foregroundStyle(appearance.secondary)
                }
                if !model.apps.isEmpty { filters }
                if model.filteredApps.isEmpty {
                    ContentUnavailableView {
                        Label(model.isFiltered ? "Aucune app ne correspond" : "Les premières apps arrivent", systemImage: "square.grid.2x2")
                            .font(appearance.font.font(.title2, weight: .bold))
                    } description: {
                        Text(model.isFiltered ? "Essayez un autre nom ou une autre catégorie." : "Proposez votre application à la communauté.")
                            .font(appearance.font.font(.body)).foregroundStyle(appearance.secondary)
                    } actions: {
                        if model.isFiltered { Button("Tout effacer") { model.resetFilters() } }
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(model.filteredApps.count) app\(model.filteredApps.count == 1 ? "" : "s")")
                    .font(appearance.font.font(.subheadline, weight: .semibold)).foregroundStyle(appearance.secondary)
                Spacer()
                Menu {
                    Picker("Catégorie", selection: $model.category) {
                        Text("Toutes les catégories").tag("")
                        ForEach(model.categories, id: \.self) { Text($0).tag($0) }
                    }
                } label: {
                    Label(model.category.isEmpty ? "Catégories" : model.category, systemImage: "line.3.horizontal.decrease")
                        .font(appearance.font.font(.subheadline)).padding(.vertical, 8)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    tagButton("Toutes", value: "")
                    if model.apps.contains(where: { $0.tags.contains("duo") }) { tagButton("Compatible Duo", value: "duo") }
                    if model.apps.contains(where: { $0.tags.contains("build-challenge") }) { tagButton("Build Challenge", value: "build-challenge") }
                    if model.apps.contains(where: { $0.tags.contains("founder") }) { tagButton("Fondateurs", value: "founder") }
                }
            }
        }
    }

    private func tagButton(_ title: String, value: String) -> some View {
        Button { model.tag = value } label: {
            Text(verbatim: title).font(appearance.font.font(.subheadline, weight: .medium))
                .padding(.horizontal, 14).frame(minHeight: 44)
                .foregroundStyle(model.tag == value ? accent : appearance.secondary)
                .background(model.tag == value ? accent.opacity(0.12) : appearance.surface, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(model.tag == value ? .isSelected : [])
    }

    private var submission: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider().padding(.bottom, 6)
            Text("Votre app a sa place ici.").font(appearance.font.font(.headline))
            Text("Proposez-la sur cmdf.io. L’équipe du collectif la valide avant son apparition dans le catalogue.")
                .font(appearance.font.font(.subheadline)).foregroundStyle(appearance.secondary)
            Link(destination: CroaCommunityClient.submissionURL) {
                Label("Ajouter mon application", systemImage: "plus")
                    .font(appearance.font.font(.subheadline, weight: .semibold)).padding(.vertical, 8)
            }
            .accessibilityIdentifier("croakit.community.submit")
        }
        .fixedSize(horizontal: false, vertical: true)
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
