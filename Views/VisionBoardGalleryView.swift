import SwiftUI

struct VisionBoardGalleryView: View {
    @Environment(VisionBoardManager.self) var visionBoardManager
    @Environment(UserManager.self) var userManager
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all
    @State private var showingCreateView = false
    @State private var selectedVisionBoard: VisionBoard?

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case favorites = "Favorites"
        case recent = "Recent"

        var systemImage: String {
            switch self {
            case .all: "photo.stack"
            case .favorites: "heart.fill"
            case .recent: "clock.fill"
            }
        }
    }

    var filteredVisionBoards: [VisionBoard] {
        var boards = visionBoardManager.visionBoards
        switch selectedFilter {
        case .all: break
        case .favorites: boards = boards.filter { $0.isFavorite }
        case .recent: boards = boards.sorted { $0.createdAt > $1.createdAt }.prefix(10).map { $0 }
        }
        if !searchText.isEmpty {
            boards = boards.filter { board in
                board.title.localizedCaseInsensitiveContains(searchText) ||
                board.description.localizedCaseInsensitiveContains(searchText) ||
                board.manifestationGoals.contains { $0.title.localizedCaseInsensitiveContains(searchText) }
            }
        }
        return boards
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.astralBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchAndFiltersSection

                    if filteredVisionBoards.isEmpty {
                        emptyStateView
                    } else {
                        visionBoardsGrid
                    }
                }
            }
            .navigationTitle("My Vision Boards")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus") { showingCreateView = true }
                        .foregroundStyle(Color.astralViolet)
                }
            }
        }
        .sheet(isPresented: $showingCreateView) { CreateVisionBoardView() }
        .sheet(item: $selectedVisionBoard) { VisionBoardDetailView(visionBoard: $0) }
    }

    // MARK: - Search + Filters

    private var searchAndFiltersSection: some View {
        VStack(spacing: AstralTheme.Spacing.md) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.astralTextMuted)

                TextField("Search vision boards…", text: $searchText)
                    .foregroundStyle(Color.astralText)
                    .tint(Color.astralViolet)

                if !searchText.isEmpty {
                    Button("Clear") { searchText = "" }
                        .foregroundStyle(Color.astralViolet)
                        .font(.system(.caption, design: .rounded))
                }
            }
            .padding(AstralTheme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: AstralTheme.Radius.md)
                    .fill(Color.astralSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: AstralTheme.Radius.md)
                            .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                    }
            }

            HStack(spacing: AstralTheme.Spacing.sm) {
                ForEach(FilterOption.allCases, id: \.self) { filter in
                    FilterButton(filter: filter, isSelected: selectedFilter == filter) {
                        withAnimation(AstralTheme.Motion.quick) { selectedFilter = filter }
                    }
                }
                Spacer()
            }
        }
        .padding(AstralTheme.Spacing.md)
        .background(Color.astralBlack)
    }

    // MARK: - Grid

    private var gridColumns: [GridItem] {
        let count = sizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible()), count: count)
    }

    private var visionBoardsGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns,
                      spacing: AstralTheme.Spacing.md) {
                ForEach(filteredVisionBoards) { board in
                    VisionBoardGridItem(visionBoard: board) {
                        selectedVisionBoard = board
                        visionBoardManager.incrementViewCount(board)
                    }
                }
            }
            .padding(AstralTheme.Spacing.md)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AstralTheme.Spacing.lg) {
            Spacer()

            Image(systemName: selectedFilter == .all ? "photo.stack" : selectedFilter.systemImage)
                .font(.system(size: 56))
                .foregroundStyle(Color.astralViolet.opacity(0.5))

            VStack(spacing: AstralTheme.Spacing.sm) {
                Text(emptyStateTitle)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.astralText)

                Text(emptyStateMessage)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)
                    .multilineTextAlignment(.center)
            }

            if selectedFilter == .all && searchText.isEmpty {
                Button("Create Your First Vision Board") { showingCreateView = true }
                    .astralButton(.primary)
            }

            Spacer()
        }
        .padding(AstralTheme.Spacing.xl)
    }

    private var emptyStateTitle: String {
        if !searchText.isEmpty { return "No Results Found" }
        return switch selectedFilter {
        case .all: "No Vision Boards Yet"
        case .favorites: "No Favorites Yet"
        case .recent: "No Recent Boards"
        }
    }

    private var emptyStateMessage: String {
        if !searchText.isEmpty { return "Try adjusting your search terms or browse all vision boards." }
        return switch selectedFilter {
        case .all: "Start your manifestation journey by creating your first personalized vision board."
        case .favorites: "Mark vision boards as favorites by tapping the heart icon."
        case .recent: "Your recently created vision boards will appear here."
        }
    }
}

// MARK: - FilterButton

struct FilterButton: View {
    let filter: VisionBoardGalleryView.FilterOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: filter.systemImage)
                    .font(.system(size: 11, weight: .semibold))
                Text(filter.rawValue)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(isSelected ? Color.black : Color.astralText)
            .padding(.horizontal, AstralTheme.Spacing.md)
            .padding(.vertical, 7)
            .background {
                Capsule()
                    .fill(isSelected
                          ? AnyShapeStyle(Color.auroraGradient)
                          : AnyShapeStyle(Color.astralSurface))
            }
        }
    }
}

// MARK: - VisionBoardGridItem

struct VisionBoardGridItem: View {
    let visionBoard: VisionBoard
    let action: () -> Void
    @Environment(VisionBoardManager.self) var visionBoardManager

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AstralTheme.Spacing.sm) {
                ZStack {
                    if let firstImage = visionBoard.images.first?.image {
                        Image(uiImage: firstImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 140)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: AstralTheme.Radius.md)
                            .fill(
                                LinearGradient(
                                    colors: [Color.astralViolet.opacity(0.3), Color.astralIndigo.opacity(0.2)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 140)
                            .overlay {
                                VStack(spacing: 6) {
                                    Image(systemName: "photo.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color.astralTextMuted)
                                    Text("\(visionBoard.layout.imageCount) Images")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(Color.astralTextMuted)
                                }
                            }
                    }

                    // Overlay badges
                    VStack {
                        HStack {
                            if visionBoard.isPersonalized { PersonalizedBadge() }
                            Spacer()
                            FavoriteButton(visionBoard: visionBoard)
                        }
                        Spacer()
                        HStack {
                            StyleBadge(style: visionBoard.style)
                            Spacer()
                            ViewCountBadge(count: visionBoard.viewCount)
                        }
                    }
                    .padding(AstralTheme.Spacing.sm)
                }
                .clipShape(RoundedRectangle(cornerRadius: AstralTheme.Radius.md, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(visionBoard.title)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.astralText)
                        .lineLimit(2)

                    Text(visionBoard.formattedCreatedDate)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Color.astralTextMuted)

                    if !visionBoard.manifestationGoals.isEmpty {
                        Text(visionBoard.manifestationGoals.prefix(2).map(\.title).joined(separator: ", "))
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Color.astralViolet)
                            .lineLimit(1)
                    }
                }
            }
        }
        .astralCard()
    }
}

// MARK: - Small Badge Views

struct PersonalizedBadge: View {
    var body: some View {
        Text("YOU")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color.black)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.astralGold)
            .clipShape(Capsule())
    }
}

struct FavoriteButton: View {
    let visionBoard: VisionBoard
    @Environment(VisionBoardManager.self) var visionBoardManager

    var body: some View {
        Button {
            visionBoardManager.toggleFavorite(visionBoard)
        } label: {
            Image(systemName: visionBoard.isFavorite ? "heart.fill" : "heart")
                .foregroundStyle(visionBoard.isFavorite ? Color.astralRose : Color.astralText)
                .font(.caption)
                .padding(6)
                .background(Circle().fill(Color.black.opacity(0.55)))
        }
    }
}

struct StyleBadge: View {
    let style: VisionBoardStyle

    var body: some View {
        Text(style.displayName)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.astralText)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(style.primaryColor.opacity(0.75))
            }
    }
}

struct ViewCountBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "eye.fill").font(.system(size: 9))
            Text("\(count)").font(.system(size: 10, design: .rounded))
        }
        .foregroundStyle(Color.astralText)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background {
            RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.55))
        }
    }
}

#Preview {
    VisionBoardGalleryView()
        .environment(VisionBoardManager())
        .environment(UserManager())
}
