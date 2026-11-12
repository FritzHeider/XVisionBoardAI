//
//  SubscriptionView.swift
//  XVisionBoardAI
//
//  The ManifestMe Pro paywall. Plans and prices come from the RevenueCat
//  offering (falling back to fetching the products directly), so nothing about
//  price, period or trial is hard-coded here.
//
//  What App Review checks on this screen, and where it lives:
//    • price and billing period per plan        → PlanRow
//    • what's included                          → features (must match StoreManager gates)
//    • renewal terms next to the purchase button → renewalTerms(_:)
//    • Restore Purchases                         → toolbar, trailing
//    • Terms of Use + Privacy Policy             → purchaseSection
//    • a visible way to close                    → toolbar, leading
//

import SwiftUI
import RevenueCat

// MARK: - Trigger

/// Why the paywall opened. Only the headline changes; the plans, terms and
/// controls are identical in every case.
enum PaywallTrigger {
    case general
    case boardLimit
    case audio

    var headline: String {
        switch self {
        case .general:    return "Unlock ManifestMe Pro"
        case .boardLimit: return "You’ve made your free board"
        case .audio:      return "Read-aloud affirmations are Pro"
        }
    }

    var subtitle: String {
        switch self {
        case .general:    return "Create as many vision boards as you like and keep them with you every day."
        case .boardLimit: return "Pro lets you create as many vision boards as you like."
        case .audio:      return "Hear your affirmations read aloud each morning, plus unlimited boards."
        }
    }
}

// MARK: - SubscriptionView

struct SubscriptionView: View {
    var trigger: PaywallTrigger = .general

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(StoreManager.self) private var storeManager

    @State private var selectedID: String?
    @State private var loadState: LoadState = .loading
    @State private var isPurchasing = false
    @State private var infoMessage: String?
    @State private var showingInfoAlert = false
    @State private var showingErrorAlert = false

    private enum LoadState { case loading, loaded, failed }

    // MARK: Plans

    /// Packages from the current offering, keyed by product ID, so a purchase
    /// goes through the package when one exists (keeps RevenueCat attribution).
    private var packagesByID: [String: Package] {
        Dictionary(
            (storeManager.currentOffering?.availablePackages ?? []).map { ($0.storeProduct.productIdentifier, $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    /// Plans to show, ordered weekly → monthly → yearly.
    private var products: [StoreProduct] {
        let fromOffering = (storeManager.currentOffering?.availablePackages ?? []).map(\.storeProduct)
        let source = fromOffering.isEmpty ? storeManager.fallbackProducts : fromOffering
        return source.sorted { periodRank($0) < periodRank($1) }
    }

    private var selectedProduct: StoreProduct? {
        products.first { $0.productIdentifier == selectedID } ?? defaultProduct
    }

    /// Yearly when offered, otherwise the longest period available.
    private var defaultProduct: StoreProduct? {
        products.first { $0.subscriptionPeriod?.unit == .year } ?? products.last
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.astralBlack.ignoresSafeArea()

                Ellipse()
                    .fill(Color.astralGold.opacity(0.14))
                    .frame(width: 340, height: 340)
                    .blur(radius: 90)
                    .offset(x: -60, y: -260)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                ScrollView {
                    VStack(alignment: .leading, spacing: AstralTheme.Spacing.lg) {
                        header
                        // Plans before features: on a small phone (iPhone SE) the
                        // pinned purchase footer otherwise covers the plan list,
                        // including the plan the button would buy.
                        plans
                        features
                        // At the accessibility sizes a pinned footer would cover
                        // most of the screen, so it scrolls with the content.
                        if typeSize.isAccessibilitySize {
                            purchaseSection
                        }
                    }
                    .padding(.horizontal, AstralTheme.Spacing.lg)
                    .padding(.top, AstralTheme.Spacing.sm)
                    .padding(.bottom, AstralTheme.Spacing.lg)
                }
                .scrollBounceBehavior(.basedOnSize)
                .safeAreaInset(edge: .bottom) {
                    if !typeSize.isAccessibilitySize {
                        purchaseSection
                            .padding(.horizontal, AstralTheme.Spacing.lg)
                            .padding(.top, AstralTheme.Spacing.md)
                            .padding(.bottom, AstralTheme.Spacing.sm)
                            .background(alignment: .top) {
                                // Opaque so scrolled content never shows through the
                                // terms text, with a short fade above it.
                                VStack(spacing: 0) {
                                    LinearGradient(colors: [Color.astralBlack.opacity(0), .astralBlack],
                                                   startPoint: .top, endPoint: .bottom)
                                        .frame(height: 24)
                                        .offset(y: -24)
                                        .padding(.bottom, -24)
                                    Color.astralBlack
                                }
                                .ignoresSafeArea(edges: .bottom)
                                .accessibilityHidden(true)
                            }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.astralTextMuted)
                            .frame(width: 44, height: 44)
                            .contentShape(.rect)
                    }
                    .accessibilityLabel("Close")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Restore") { restore() }
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.astralTextMuted)
                        .disabled(isPurchasing || storeManager.isLoading)
                        .accessibilityLabel("Restore Purchases")
                }
            }
        }
        .task { await load() }
        .alert("Something Went Wrong", isPresented: $showingErrorAlert, presenting: storeManager.errorMessage) { _ in
            Button("OK", role: .cancel) { storeManager.errorMessage = nil }
        } message: { error in
            Text(error)
        }
        .onChange(of: storeManager.errorMessage) { _, error in
            showingErrorAlert = (error != nil)
        }
        .alert("Restore Purchases", isPresented: $showingInfoAlert, presenting: infoMessage) { _ in
            Button("OK", role: .cancel) { infoMessage = nil }
        } message: { message in
            Text(message)
        }
        .onChange(of: infoMessage) { _, message in
            showingInfoAlert = (message != nil)
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: AstralTheme.Spacing.sm) {
            Text(trigger.headline)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(Color.astralText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(trigger.subtitle)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.astralTextMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Every row must match a gate that exists in StoreManager
    /// (canCreateVisionBoard, canExportHD, canUseAudioAffirmations). Do not add
    /// aspirational rows: App Review checks these in sandbox.
    private var features: some View {
        VStack(alignment: .leading, spacing: AstralTheme.Spacing.md) {
            FeatureRow(icon: "infinity", title: "Unlimited vision boards", detail: "Free includes 1")
            FeatureRow(icon: "photo.fill", title: "HD exports, no watermark", detail: "Wallpapers and prints at full quality")
            FeatureRow(icon: "speaker.wave.2.fill", title: "Audio affirmations", detail: "Your affirmations read aloud")
        }
        .padding(AstralTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.astralSurface)
        .clipShape(.rect(cornerRadius: AstralTheme.Radius.lg, style: .continuous))
    }

    @ViewBuilder
    private var plans: some View {
        switch loadState {
        case .loading where products.isEmpty:
            HStack(spacing: AstralTheme.Spacing.md) {
                ProgressView().tint(Color.astralViolet)
                Text("Loading plans…")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 120)

        case .failed where products.isEmpty:
            VStack(spacing: AstralTheme.Spacing.sm) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.title2)
                    .foregroundStyle(Color.astralTextMuted)
                    .accessibilityHidden(true)
                Text("Plans couldn’t load. Check your connection and try again.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Try Again") { Task { await load(force: true) } }
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.astralViolet)
                    .frame(minHeight: 44)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AstralTheme.Spacing.md)

        default:
            VStack(spacing: AstralTheme.Spacing.sm) {
                ForEach(products, id: \.productIdentifier) { product in
                    PlanRow(
                        title: planTitle(product),
                        price: "\(product.localizedPriceString)/\(periodLabel(product))",
                        trial: trialText(product),
                        perWeek: product.subscriptionPeriod?.unit == .year ? product.localizedPricePerWeek : nil,
                        isBestValue: product.subscriptionPeriod?.unit == .year && products.count > 1,
                        isSelected: product.productIdentifier == selectedProduct?.productIdentifier
                    ) {
                        selectedID = product.productIdentifier
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Plans")
        }
    }

    private var purchaseSection: some View {
        VStack(spacing: AstralTheme.Spacing.sm) {
            Button {
                purchase()
            } label: {
                ZStack {
                    if isPurchasing {
                        ProgressView().tint(Color.astralBlack)
                    } else {
                        Text(ctaTitle)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 54)
                .foregroundStyle(Color.astralBlack)
                .background(
                    Capsule().fill(
                        LinearGradient(colors: [.astralViolet, .astralIndigo],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                )
                .opacity(selectedProduct == nil ? 0.45 : 1)
            }
            .disabled(selectedProduct == nil || isPurchasing)

            if let product = selectedProduct {
                Text(renewalTerms(product))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: AstralTheme.Spacing.lg) {
                Link("Terms of Use", destination: AppLinks.termsOfUse)
                Link("Privacy Policy", destination: AppLinks.privacyPolicy)
            }
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(Color.astralTextMuted)
            .frame(minHeight: 32)
        }
    }

    // MARK: Text

    private var ctaTitle: String {
        guard let product = selectedProduct else { return "Subscribe" }
        return trialText(product) == nil ? "Subscribe" : "Start Free Trial"
    }

    private func planTitle(_ product: StoreProduct) -> String {
        switch product.subscriptionPeriod?.unit {
        case .week:  return "Weekly"
        case .month: return "Monthly"
        case .year:  return "Yearly"
        default:     return product.localizedTitle
        }
    }

    /// "week", "month", "year" — or "3 months" for multi-unit periods.
    private func periodLabel(_ product: StoreProduct) -> String {
        guard let period = product.subscriptionPeriod else { return "period" }
        return unitText(period.unit, value: period.value)
    }

    private func unitName(_ unit: SubscriptionPeriod.Unit) -> String {
        switch unit {
        case .day:   return "day"
        case .week:  return "week"
        case .month: return "month"
        case .year:  return "year"
        @unknown default: return "period"
        }
    }

    private func unitText(_ unit: SubscriptionPeriod.Unit, value: Int) -> String {
        let name = unitName(unit)
        return value == 1 ? name : "\(value) \(name)s"
    }

    /// "3-day free trial" when the product has a free-trial intro offer.
    private func trialText(_ product: StoreProduct) -> String? {
        guard let intro = product.introductoryDiscount, intro.paymentMode == .freeTrial else { return nil }
        let period = intro.subscriptionPeriod
        return "\(period.value)-\(unitName(period.unit)) free trial"
    }

    /// App Review requires the auto-renewal terms next to the purchase button.
    private func renewalTerms(_ product: StoreProduct) -> String {
        let price = "\(product.localizedPriceString) per \(periodLabel(product))"
        if let trial = trialText(product) {
            return "\(trial.prefix(1).uppercased() + trial.dropFirst()), then \(price). Auto-renews until cancelled. Cancel anytime in Settings at least 24 hours before the trial ends."
        }
        return "\(price). Auto-renews until cancelled. Cancel anytime in Settings at least 24 hours before renewal."
    }

    private func periodRank(_ product: StoreProduct) -> Int {
        switch product.subscriptionPeriod?.unit {
        case .day:   return 0
        case .week:  return 1
        case .month: return 2
        case .year:  return 3
        default:     return 4
        }
    }

    // MARK: Actions

    private func load(force: Bool = false) async {
        loadState = .loading
        if force || storeManager.currentOffering == nil {
            await storeManager.fetchCurrentOffering()
        }
        if storeManager.currentOffering?.availablePackages.isEmpty ?? true {
            await storeManager.fetchFallbackProducts()
        }
        loadState = products.isEmpty ? .failed : .loaded
    }

    private func purchase() {
        guard let product = selectedProduct, !isPurchasing else { return }
        isPurchasing = true
        Task {
            let succeeded: Bool
            if let package = packagesByID[product.productIdentifier] {
                succeeded = await storeManager.purchase(package: package)
            } else {
                succeeded = await storeManager.purchase(product: product)
            }
            isPurchasing = false
            // Cancelling the system sheet returns here so another plan can be
            // picked; only a completed purchase closes the paywall.
            if succeeded { dismiss() }
        }
    }

    private func restore() {
        Task {
            if await storeManager.restorePurchases() {
                dismiss()
            } else if storeManager.errorMessage == nil {
                infoMessage = "No previous purchases were found for this Apple Account."
            }
        }
    }
}

// MARK: - Rows

private struct FeatureRow: View {
    let icon: String
    let title: String
    let detail: String

    /// The tile grows with the icon, which grows with Dynamic Type. A fixed
    /// 28pt box let the glyph spill out at the accessibility sizes.
    @ScaledMetric(relativeTo: .subheadline) private var tileSize: CGFloat = 28
    @ScaledMetric(relativeTo: .subheadline) private var tileRadius: CGFloat = 8

    var body: some View {
        HStack(alignment: .top, spacing: AstralTheme.Spacing.md) {
            Image(systemName: icon)
                .scaledFont(size: 16, relativeTo: .subheadline, weight: .semibold)
                .foregroundStyle(Color.astralGold)
                .frame(width: tileSize, height: tileSize)
                .background(Color.astralGold.opacity(0.14), in: .rect(cornerRadius: tileRadius))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.astralText)
                Text(detail)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PlanRow: View {
    let title: String
    let price: String
    let trial: String?
    let perWeek: String?
    let isBestValue: Bool
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    private var trialLabel: String? {
        trial.map { $0.prefix(1).uppercased() + $0.dropFirst() + " included" }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AstralTheme.Spacing.xs) {
                if isBestValue {
                    Text("BEST VALUE")
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .tracking(0.5)
                        .foregroundStyle(Color.astralBlack)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.astralGold, in: .capsule)
                }
                // Side by side normally; stacked at the accessibility sizes so
                // the price never truncates.
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: AstralTheme.Spacing.xs) {
                        nameBlock
                        priceBlock(alignment: .leading)
                    }
                } else {
                    HStack(alignment: .center, spacing: AstralTheme.Spacing.md) {
                        nameBlock
                        Spacer(minLength: 0)
                        priceBlock(alignment: .trailing)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(AstralTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AstralTheme.Radius.md, style: .continuous)
                    .fill(isSelected ? Color.astralViolet.opacity(0.16) : Color.astralSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AstralTheme.Radius.md, style: .continuous)
                    .strokeBorder(isSelected ? Color.astralViolet : Color.white.opacity(0.08),
                                  lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) plan, \(price)\(trial.map { ", \($0)" } ?? "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Color.astralText)
            if let trialLabel {
                Text(trialLabel)
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.astralGold)
            }
        }
    }

    private func priceBlock(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(price)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Color.astralText)
            if let perWeek {
                Text("\(perWeek)/week")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)
            }
        }
    }
}

// MARK: - Paywall Gating Modifier

extension View {
    /// Presents the paywall if the user doesn't have the Pro entitlement.
    func requiresProEntitlement(isPresented: Binding<Bool>, trigger: PaywallTrigger = .general) -> some View {
        self.sheet(isPresented: isPresented) {
            SubscriptionView(trigger: trigger)
        }
    }
}

#Preview("Board limit") {
    SubscriptionView(trigger: .boardLimit)
        .environment(StoreManager())
        .environment(UserManager())
}
