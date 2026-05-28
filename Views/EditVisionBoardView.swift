//
//  EditVisionBoardView.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI

struct EditVisionBoardView: View {
    let visionBoard: VisionBoard
    @Environment(\.dismiss) private var dismiss
    @Environment(VisionBoardManager.self) var visionBoardManager

    @State private var title: String
    @State private var description: String
    @State private var goals: [ManifestationGoal]
    @State private var newGoalText = ""

    init(visionBoard: VisionBoard) {
        self.visionBoard = visionBoard
        _title = State(initialValue: visionBoard.title)
        _description = State(initialValue: visionBoard.description)
        _goals = State(initialValue: visionBoard.manifestationGoals)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicBlack.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        titleSection
                        goalsSection
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Vision Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.cosmicWhite)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .foregroundColor(.cosmicGold)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var titleSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.cosmicWhite)
                TextField("Vision board title", text: $title)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.cosmicGray))
                    .foregroundColor(.cosmicWhite)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.cosmicWhite)
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.cosmicGray))
                    .foregroundColor(.cosmicWhite)
                    .scrollContentBackground(.hidden)
            }
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manifestation Goals")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.cosmicWhite)

            // Add goal
            HStack {
                TextField("New goal...", text: $newGoalText)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.cosmicGray))
                    .foregroundColor(.cosmicWhite)
                Button("Add") {
                    let trimmed = newGoalText.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    goals.append(ManifestationGoal(title: trimmed))
                    newGoalText = ""
                }
                .cosmicButton()
                .disabled(newGoalText.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // Goals list
            ForEach(goals.indices, id: \.self) { i in
                HStack(spacing: 12) {
                    Button {
                        goals[i].isAchieved.toggle()
                        if goals[i].isAchieved {
                            goals[i].markAchieved()
                        } else {
                            goals[i].unmarkAchieved()
                        }
                    } label: {
                        Image(systemName: goals[i].isAchieved ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(goals[i].isAchieved ? .cosmicGold : .gray)
                            .font(.title3)
                    }
                    Text(goals[i].title)
                        .foregroundColor(.cosmicWhite)
                        .strikethrough(goals[i].isAchieved, color: .cosmicGold)
                    Spacer()
                    Button {
                        goals.remove(at: i)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
                .padding()
                .cosmicCard()
            }
        }
    }

    private func save() {
        var updated = visionBoard
        updated.title = title
        updated.description = description
        updated.manifestationGoals = goals
        updated.updatedAt = Date()
        visionBoardManager.updateVisionBoard(updated)
        dismiss()
    }
}

#Preview {
    EditVisionBoardView(visionBoard: VisionBoard.sampleVisionBoard)
        .environment(VisionBoardManager())
}
