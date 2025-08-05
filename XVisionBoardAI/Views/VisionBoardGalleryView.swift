//
//  VisionBoardGalleryView.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI

struct VisionBoardGalleryView: View {
    @EnvironmentObject var visionBoardManager: VisionBoardManager
    @EnvironmentObject var userManager: UserManager
    
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
            case .all: return "photo.stack"
            case .favorites: return "heart.fill"
            case .recent: return "clock.fill"
            }
        }
    }
    
    var filteredVisionBoards: [VisionBoard] {
        var boards = visionBoardManager.visionBoards
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .favorites:
            boards = boards.filter { $0.isFavorite }
        case .recent:
            boards = boards.sorted { $0.createdAt > $1.createdAt }.prefix(10).map { $0 }
        }
        
        // Apply search
        if !searchText.isEmpty {
            boards = boards.filter { board in
                board.title.localizedCaseInsensitiveContains(searchText) ||
                board.description.localizedCaseInsensitiveContains(searchText) ||
                board.manifestationGoals.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return boards
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicBlack.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and filters
                    searchAndFiltersSection
                    
                    if filteredVisionBoards.isEmpty {
                        emptyStateView
                    } else {
                        // Vision boards grid
                        visionBoardsGrid
                    }
                }
            }
            .navigationTitle("My Vision Boards")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateView = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.cosmicPurple)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateView) {
            CreateVisionBoardView()
        }
        .sheet(item: $selectedVisionBoard) { visionBoard in
            VisionBoardDetailView(visionBoard: visionBoard)
        }
    }
    
    // MARK: - Search and Filters Section
    
    private var searchAndFiltersSection: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.cosmicWhite.opacity(0.7))
                
                TextField("Search vision boards...", text: $searchText)
                    .foregroundColor(.cosmicWhite)
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .foregroundColor(.cosmicPurple)
                    .font(.caption)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cosmicGray)
            )
            
            // Filter options
            HStack(spacing: 12) {
                ForEach(FilterOption.allCases, id: \.self) { filter in
                    FilterButton(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.cosmicBlack)
    }
    
    // MARK: - Vision Boards Grid
    
    private var visionBoardsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(filteredVisionBoards) { visionBoard in
                    VisionBoardGridItem(visionBoard: visionBoard) {
                        selectedVisionBoard = visionBoard
                        visionBoardManager.incrementViewCount(visionBoard)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: selectedFilter == .all ? "photo.stack" : selectedFilter.systemImage)
                .font(.system(size: 60))
                .foregroundColor(.cosmicPurple.opacity(0.6))
            
            VStack(spacing: 12) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cosmicWhite)
                
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundColor(.cosmicWhite.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            if selectedFilter == .all && searchText.isEmpty {
                Button("Create Your First Vision Board") {
                    showingCreateView = true
                }
                .cosmicButton()
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results Found"
        }
        
        switch selectedFilter {
        case .all:
            return "No Vision Boards Yet"
        case .favorites:
            return "No Favorites Yet"
        case .recent:
            return "No Recent Boards"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms or browse all vision boards."
        }
        
        switch selectedFilter {
        case .all:
            return "Start your manifestation journey by creating your first personalized vision board."
        case .favorites:
            return "Mark vision boards as favorites by tapping the heart icon."
        case .recent:
            return "Your recently created vision boards will appear here."
        }
    }
}

// MARK: - Supporting Views

struct FilterButton: View {
    let filter: VisionBoardGalleryView.FilterOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.systemImage)
                    .font(.caption)
                
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .black : .cosmicWhite)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.cosmicGold : Color.cosmicGray)
            )
        }
    }
}

struct VisionBoardGridItem: View {
    let visionBoard: VisionBoard
    let action: () -> Void
    @EnvironmentObject var visionBoardManager: VisionBoardManager
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Preview image
                ZStack {
                    if let firstImage = visionBoard.images.first?.image {
                        Image(uiImage: firstImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 140)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cosmicGray)
                            .frame(height: 140)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.fill")
                                        .font(.title)
                                        .foregroundColor(.cosmicWhite.opacity(0.5))
                                    
                                    Text("\(visionBoard.layout.imageCount) Images")
                                        .font(.caption)
                                        .foregroundColor(.cosmicWhite.opacity(0.7))
                                }
                            )
                    }
                    
                    // Overlay badges
                    VStack {
                        HStack {
                            if visionBoard.isPersonalized {
                                PersonalizedBadge()
                            }
                            
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
                    .padding(8)
                }
                .cornerRadius(12)
                
                // Title and info
                VStack(alignment: .leading, spacing: 4) {
                    Text(visionBoard.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.cosmicWhite)
                        .lineLimit(2)
                    
                    Text(visionBoard.formattedCreatedDate)
                        .font(.caption)
                        .foregroundColor(.cosmicWhite.opacity(0.7))
                    
                    if !visionBoard.manifestationGoals.isEmpty {
                        Text(visionBoard.manifestationGoals.prefix(2).joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.cosmicPurple)
                            .lineLimit(1)
                    }
                }
            }
        }
        .cosmicCard()
    }
}

struct PersonalizedBadge: View {
    var body: some View {
        Text("YOU")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.black)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.cosmicGold)
            .clipShape(Capsule())
    }
}

struct FavoriteButton: View {
    let visionBoard: VisionBoard
    @EnvironmentObject var visionBoardManager: VisionBoardManager
    
    var body: some View {
        Button(action: {
            visionBoardManager.toggleFavorite(visionBoard)
        }) {
            Image(systemName: visionBoard.isFavorite ? "heart.fill" : "heart")
                .foregroundColor(visionBoard.isFavorite ? .cosmicPink : .cosmicWhite)
                .font(.caption)
                .padding(6)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.6))
                )
        }
    }
}

struct StyleBadge: View {
    let style: VisionBoardStyle
    
    var body: some View {
        Text(style.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.cosmicWhite)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(style.primaryColor.opacity(0.8))
            )
    }
}

struct ViewCountBadge: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "eye.fill")
                .font(.caption2)
            
            Text("\(count)")
                .font(.caption2)
        }
        .foregroundColor(.cosmicWhite)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
        )
    }
}

#Preview {
    VisionBoardGalleryView()
        .environmentObject(VisionBoardManager())
        .environmentObject(UserManager())
}

