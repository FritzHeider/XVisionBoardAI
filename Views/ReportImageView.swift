//
//  ReportImageView.swift
//  XVisionBoardAI
//
//  Sheet for reporting one AI-generated image. The image is hidden on this
//  device the moment Send is tapped, before the network call, so the person
//  never has to see it again even if they're offline. Delivery is best-effort
//  and a failure falls back to an email to support.
//

import SwiftUI

struct ReportImageView: View {
    let boardID: UUID
    let image: VisionBoardImage
    /// Called after the report is filed and the sheet closes, so a presenter
    /// showing the image (e.g. the full-screen viewer) can close too.
    var onReported: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(VisionBoardManager.self) private var visionBoardManager

    @State private var reason: ContentReportReason?
    @State private var details = ""
    @State private var isSending = false
    @State private var outcome: Outcome?
    @FocusState private var detailsFocused: Bool

    private enum Outcome: Identifiable {
        case sent
        case failed
        var id: Self { self }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.astralBlack.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AstralTheme.Spacing.lg) {
                        header
                        reasonList
                        detailsField
                        footer
                    }
                    .padding(.horizontal, AstralTheme.Spacing.lg)
                    .padding(.vertical, AstralTheme.Spacing.md)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Report Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.astralSurface, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.astralViolet)
                        .disabled(isSending)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSending {
                        ProgressView().tint(Color.astralViolet)
                    } else {
                        Button("Send") { send() }
                            .fontWeight(.semibold)
                            .foregroundStyle(reason == nil ? Color.astralTextDim : Color.astralError)
                            .disabled(reason == nil)
                    }
                }
            }
            .interactiveDismissDisabled(isSending)
            .alert(item: $outcome) { outcome in
                switch outcome {
                case .sent:
                    Alert(
                        title: Text("Thanks for reporting"),
                        message: Text("The image is hidden. You can generate a replacement from the board."),
                        dismissButton: .default(Text("OK")) { finish() }
                    )
                case .failed:
                    Alert(
                        title: Text("Image hidden"),
                        message: Text("We couldn't send the report right now. You can email it to us instead."),
                        primaryButton: .default(Text("Email Support")) {
                            openURL(reportMailto)
                            finish()
                        },
                        secondaryButton: .cancel(Text("OK")) { finish() }
                    )
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .top, spacing: AstralTheme.Spacing.md) {
            if let uiImage = image.image {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(.rect(cornerRadius: AstralTheme.Radius.sm))
                    .accessibilityHidden(true)
            }
            Text("AI can get things wrong. Tell us what’s wrong with this image and it will be hidden right away.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Color.astralTextMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var reasonList: some View {
        VStack(spacing: 0) {
            ForEach(Array(ContentReportReason.allCases.enumerated()), id: \.element) { index, option in
                Button {
                    reason = option
                } label: {
                    HStack(spacing: AstralTheme.Spacing.md) {
                        Text(option.title)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.astralText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Image(systemName: reason == option ? "checkmark.circle.fill" : "circle")
                            .font(.system(.title3))
                            .foregroundStyle(reason == option ? Color.astralViolet : Color.astralTextDim)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, AstralTheme.Spacing.md)
                    .padding(.vertical, 12)
                    .frame(minHeight: 50)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(reason == option ? [.isSelected] : [])

                if index < ContentReportReason.allCases.count - 1 {
                    Divider()
                        .overlay(Color.white.opacity(0.08))
                        .padding(.leading, AstralTheme.Spacing.md)
                }
            }
        }
        .background(Color.astralSurface2)
        .clipShape(.rect(cornerRadius: AstralTheme.Radius.md, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Reason")
    }

    private var detailsField: some View {
        VStack(alignment: .leading, spacing: AstralTheme.Spacing.sm) {
            Text("Details (optional)")
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.astralTextMuted)

            TextField("Tell us what went wrong", text: $details, axis: .vertical)
                .lineLimit(2...5)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.astralText)
                .padding(AstralTheme.Spacing.md)
                .background(Color.astralSurface2)
                .clipShape(.rect(cornerRadius: AstralTheme.Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AstralTheme.Radius.md, style: .continuous)
                        .strokeBorder(detailsFocused ? Color.astralViolet.opacity(0.7) : Color.clear, lineWidth: 1)
                )
                .focused($detailsFocused)
                .onChange(of: details) { _, newValue in
                    if newValue.count > ContentReportService.maxDetailsLength {
                        details = String(newValue.prefix(ContentReportService.maxDetailsLength))
                    }
                }
                .accessibilityLabel("Details, optional")

            Text("\(details.count) / \(ContentReportService.maxDetailsLength)")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Color.astralTextDim)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityHidden(true)
        }
    }

    private var footer: some View {
        Text("Reports include the image’s description and style, not your selfie. We review every report within 24 hours.")
            .font(.system(.caption, design: .rounded))
            .foregroundStyle(Color.astralTextDim)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Actions

    private func send() {
        guard let reason, !isSending else { return }
        detailsFocused = false
        isSending = true

        let board = visionBoardManager.visionBoards.first { $0.id == boardID }
        let report = ContentReport(
            reportId: UUID(),
            imageId: image.id,
            reason: reason,
            details: String(details.trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(ContentReportService.maxDetailsLength)),
            prompt: image.prompt,
            style: board?.style.rawValue ?? "unknown",
            isPersonalized: image.isPersonalized,
            appVersion: ContentReportService.appVersion,
            createdAt: .now
        )

        // Hide first: the report's delivery must never decide whether the
        // person keeps seeing the image.
        visionBoardManager.markImageReported(boardID: boardID, imageID: image.id)

        Task {
            do {
                try await ContentReportService.send(report)
                outcome = .sent
            } catch {
                print("[ReportImageView] report delivery failed: \(error)")
                outcome = .failed
            }
            isSending = false
        }
    }

    private func finish() {
        dismiss()
        onReported()
    }

    /// Fallback when the proxy can't be reached. The body carries the same
    /// fields the proxy would have stored.
    private var reportMailto: URL {
        var comps = URLComponents()
        comps.scheme = "mailto"
        comps.path = AppLinks.supportEmail
        let body = """
        Reason: \(reason?.title ?? "-")
        Details: \(details)
        Scene: \(image.prompt)
        Image ID: \(image.id.uuidString)
        App: \(ContentReportService.appVersion)
        """
        comps.queryItems = [
            URLQueryItem(name: "subject", value: "ManifestMe: Image report"),
            URLQueryItem(name: "body", value: body),
        ]
        return comps.url ?? AppLinks.supportMailto
    }
}
