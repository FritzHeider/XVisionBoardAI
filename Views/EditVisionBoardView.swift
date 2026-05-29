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
                Color.astralBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AstralTheme.Spacing.xl) {
                        titleSection
                        goalsSection
                        Spacer(minLength: 100)
                    }
                    .padding(AstralTheme.Spacing.lg)
                }
            }
            .navigationTitle("Edit Vision Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.astralTextMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(Color.astralGold)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var titleSection: some View {
        VStack(spacing: AstralTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AstralTheme.Spacing.xs) {
                Text("Title")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.astralTextMuted)
                    .textCase(.uppercase)
                    .kerning(0.5)

                TextField("Vision board title", text: $title)
                    .padding(AstralTheme.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: AstralTheme.Radius.md)
                            .fill(Color.astralSurface)
                            .overlay {
                                RoundedRectangle(cornerRadius: AstralTheme.Radius.md)
                                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                            }
                    }
                    .foregroundStyle(Color.astralText)
                    .tint(Color.astralViolet)
            }

            VStack(alignment: .leading, spacing: AstralTheme.Spacing.xs) {
                Text("Description")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.astralTextMuted)
                    .textCase(.uppercase)
                    .kerning(0.5)

                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .padding(AstralTheme.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: AstralTheme.Radius.md)
                            .fill(Color.astralSurface)
                            .overlay {
                                RoundedRectangle(cornerRadius: AstralTheme.Radius.md)
                                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                            }
                    }
                    .foregroundStyle(Color.astralText)
                    .tint(Color.astralViolet)
                    .scrollContentBackground(.hidden)
            }
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: AstralTheme.Spacing.md) {
            Text("Manifestation Goals")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.astralText)

            HStack(spacing: AstralTheme.Spacing.sm) {
                TextField("New goal…", text: $newGoalText)
                    .padding(AstralTheme.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: AstralTheme.Radius.md)
                            .fill(Color.astralSurface)
                            .overlay {
                                RoundedRectangle(cornerRadius: AstralTheme.Radius.md)
                                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                            }
                    }
                    .foregroundStyle(Color.astralText)
                    .tint(Color.astralViolet)

                Button("Add") {
                    let trimmed = newGoalText.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    goals.append(ManifestationGoal(title: trimmed))
                    newGoalText = ""
                }
                .astralButton(.primary, isEnabled: !newGoalText.trimmingCharacters(in: .whitespaces).isEmpty)
                .disabled(newGoalText.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            ForEach(goals.indices, id: \.self) { i in
                HStack(spacing: AstralTheme.Spacing.md) {
                    Button {
                        goals[i].isAchieved.toggle()
                        if goals[i].isAchieved {
                            goals[i].markAchieved()
                        } else {
                            goals[i].unmarkAchieved()
                        }
                    } label: {
                        Image(systemName: goals[i].isAchieved ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(goals[i].isAchieved ? Color.astralGold : Color.astralTextDim)
                            .font(.title3)
                    }

                    Text(goals[i].title)
                        .foregroundStyle(Color.astralText)
                        .strikethrough(goals[i].isAchieved, color: .astralGold)

                    Spacer()

                    Button {
                        goals.remove(at: i)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(Color.astralError.opacity(0.7))
                    }
                }
                .padding(AstralTheme.Spacing.md)
                .astralCard()
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
