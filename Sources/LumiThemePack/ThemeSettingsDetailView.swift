#if canImport(AppKit)
import AppKit
#endif
import LumiUI
import ProviderTheme
import SwiftUI

private typealias AppThemeValue = ProviderTheme.LumiTheme
private typealias AppThemeAppearanceKind = ProviderTheme.ThemeAppearanceKind

private enum ThemeAppearanceFilter: String, CaseIterable, Identifiable {
    case all, dark, light, system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: LumiThemePackLocalization.string("All")
        case .dark: LumiThemePackLocalization.string("Dark")
        case .light: LumiThemePackLocalization.string("Light")
        case .system: LumiThemePackLocalization.string("Follow System")
        }
    }

    func matches(_ kind: AppThemeAppearanceKind) -> Bool {
        switch self {
        case .all: true
        case .dark: kind == .dark
        case .light: kind == .light
        case .system: kind == .system
        }
    }
}

/// 外观设置详情：使用新版 ProviderTheme，恢复旧版的搜索、筛选、双栏浏览、
/// 主题预览与显式应用状态。
@MainActor
public struct ThemeSettingsDetailView: View {
    let theme: any ThemeProviding

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var themeObservation: ThemeSettingsObservationModel
    @LumiUI.LumiTheme private var uiTheme: any LumiUI.LumiUITheme
    @State private var selectedID: String?
    @State private var searchText = ""
    @State private var appearanceFilter: ThemeAppearanceFilter = .all

    /// 数据根目录提供者；用于「打开数据目录」按钮，未注入时不展示该按钮。
    private let dataRootDirectory: URL?

    public init(theme: any ThemeProviding, dataRootDirectory: URL? = nil) {
        self.theme = theme
        self.dataRootDirectory = dataRootDirectory
        _themeObservation = StateObject(wrappedValue: ThemeSettingsObservationModel(theme: theme))
    }

    private var filteredThemes: [AppThemeValue] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return theme.themes.filter { item in
            appearanceFilter.matches(item.appearanceKind)
                && (keyword.isEmpty
                    || item.displayName.localizedCaseInsensitiveContains(keyword)
                    || item.description.localizedCaseInsensitiveContains(keyword)
                    || item.id.localizedCaseInsensitiveContains(keyword))
        }
    }

    private var selectedTheme: AppThemeValue? {
        if let selectedID, let item = theme.themes.first(where: { $0.id == selectedID }) {
            return item
        }
        return filteredThemes.first ?? theme.themes.first
    }

    public var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                compactBody
            } else {
                regularBody
            }
        }
        .onAppear { selectedID = theme.selectedThemeId ?? selectedTheme?.id }
        .onReceive(themeObservation.$revision) { _ in selectedID = theme.selectedThemeId }
        .onChange(of: filteredThemes.map(\.id)) { _, ids in
            guard let selectedID, ids.contains(selectedID) else {
                self.selectedID = ids.first
                return
            }
        }
    }

    private var compactBody: some View {
        AppSettingsContentScaffold(maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: 16) {
                headerStats
                themeFilterControls
                AppDivider()

                LazyVStack(spacing: 4) {
                    ForEach(filteredThemes) { item in
                        NavigationLink {
                            ThemePreviewPane(
                                item: item,
                                isActive: theme.selectedThemeId == item.id,
                                onApply: { try? theme.selectTheme(id: item.id) }
                            )
                            .navigationTitle(item.displayName)
#if os(iOS)
                            .navigationBarTitleDisplayMode(.inline)
#endif
                        } label: {
                            themeListRowContent(item)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 9)
                        }
                        .buttonStyle(.plain)
                    }

                    if filteredThemes.isEmpty {
                        AppEmptyState(icon: "magnifyingglass", title: LumiThemePackLocalization.string("No Themes Found"))
                            .padding(.vertical, 32)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var regularBody: some View {
        AppSettingsContentScaffold(scrollsContent: false, maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: 14) {
                headerStats

                HStack(spacing: 0) {
                    themeListPane.frame(width: 300)
                    AppDivider(.vertical)
                    themeDetailPane
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(minHeight: 520, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(uiTheme.divider, lineWidth: 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var headerStats: some View {
        HStack(spacing: 10) {
            Label(String(format: LumiThemePackLocalization.string("%lld Themes"), Int64(theme.themes.count)), systemImage: "paintpalette")
            if let activeID = theme.selectedThemeId,
               let active = theme.themes.first(where: { $0.id == activeID }) {
                Text(String(format: LumiThemePackLocalization.string("Current: %@"), active.displayName))
            }
            Spacer()
#if DEBUG && canImport(AppKit)
            AppButton(LumiThemePackLocalization.string("Open Data Directory"), systemImage: "folder", style: .warning, size: .small) {
                openDataDirectory()
            }
#endif
        }
        .font(.appCaption)
        .foregroundStyle(uiTheme.textSecondary)
    }

    private var themeListPane: some View {
        VStack(spacing: 0) {
            themeFilterControls

            AppDivider()

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredThemes) { item in themeListRow(item) }
                    if filteredThemes.isEmpty {
                        AppEmptyState(icon: "magnifyingglass", title: LumiThemePackLocalization.string("No Themes Found"))
                            .padding(.vertical, 32)
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: .infinity)
        }
        .appSurface(style: .panel, cornerRadius: 0)
    }

    private var themeFilterControls: some View {
        VStack(spacing: 10) {
            AppSearchBar(text: $searchText, placeholder: LocalizedStringKey(LumiThemePackLocalization.string("Search Themes")))
            Picker(LumiThemePackLocalization.string("Theme Type"), selection: $appearanceFilter) {
                ForEach(ThemeAppearanceFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(12)
    }

    private func themeListRow(_ item: AppThemeValue) -> some View {
        let isSelected = selectedTheme?.id == item.id
        return AppListRow(isSelected: isSelected, action: {
            withAnimation(.easeInOut(duration: 0.2)) { selectedID = item.id }
        }) {
            themeListRowContent(item)
        }
    }

    private func themeListRowContent(_ item: AppThemeValue) -> some View {
        let isActive = theme.selectedThemeId == item.id
        return HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 6) {
                Image(systemName: item.iconName)
                    .font(.appBody)
                    .foregroundStyle(item.resolvedIconColor)
                    .frame(width: 22, height: 22)
                Circle()
                    .fill(isActive ? uiTheme.success : uiTheme.textTertiary.opacity(0.45))
                    .frame(width: 6, height: 6)
            }
            .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayName)
                    .font(.appCaptionEmphasized)
                    .foregroundStyle(uiTheme.textPrimary)
                    .lineLimit(1)
                Text(item.description)
                    .font(.appMicro)
                    .foregroundStyle(uiTheme.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var themeDetailPane: some View {
        if let selectedTheme {
            ThemePreviewPane(
                item: selectedTheme,
                isActive: theme.selectedThemeId == selectedTheme.id,
                onApply: { try? theme.selectTheme(id: selectedTheme.id) }
            )
        } else {
            AppEmptyState(icon: "paintpalette", title: LumiThemePackLocalization.string("Select a Theme"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Debug Helpers

    #if DEBUG && canImport(AppKit)
    /// 打开当前 App 的数据根目录（由 Storage 层决定，含版本隔离目录）。
    private func openDataDirectory() {
        guard let dataRootDirectory else { return }
        NSWorkspace.shared.open(dataRootDirectory)
    }
    #endif
}

@MainActor
private final class ThemeSettingsObservationModel: ObservableObject {
    @Published private(set) var revision = 0
    private var handle: (any ThemeProvidingObserverHandle)?

    init(theme: any ThemeProviding) {
        handle = theme.addObserver { [weak self] _ in
            self?.revision += 1
        }
    }

}

private struct ThemePreviewPane: View {
    let item: AppThemeValue
    let isActive: Bool
    let onApply: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var palette: LumiThemePalette { item.palette }
    private var primary: Color { palette.accentPrimary.color() }
    private var secondary: Color { palette.accentSecondary.color() }
    private var background: Color { palette.backgroundMedium.color() }
    private var elevated: Color { palette.backgroundLight.color() }
    private var textPrimary: Color { palette.textPrimary.color() }
    private var textSecondary: Color { palette.textSecondary.color() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                AppDivider()
                preview
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
    }

    @ViewBuilder
    private var header: some View {
        if horizontalSizeClass == .compact {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    previewIcon
                    headerText
                }
                headerAction
            }
        } else {
            HStack(alignment: .top, spacing: 16) {
                previewIcon
                headerText
                headerAction
            }
        }
    }

    private var previewIcon: some View {
        Image(systemName: item.iconName)
            .font(.system(size: 38, weight: .semibold))
            .foregroundStyle(item.resolvedIconColor)
            .frame(width: 64, height: 64)
            .background(primary.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var headerText: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(item.displayName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(textPrimary)
            Text(item.description)
                .font(.appCaption)
                .foregroundStyle(textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(appearanceLabel)
                .font(.appMicro)
                .foregroundStyle(textSecondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var headerAction: some View {
        if isActive {
            AppTag(LumiThemePackLocalization.string("Currently Using"), style: .accent)
        } else {
            AppButton(LumiThemePackLocalization.string("Use"), systemImage: "paintbrush.fill", style: .primary, size: .small, action: onApply)
        }
    }

    private var appearanceLabel: String {
        switch item.appearanceKind {
        case .dark: LumiThemePackLocalization.string("Dark Theme")
        case .light: LumiThemePackLocalization.string("Light Theme")
        case .system: LumiThemePackLocalization.string("Follow System Appearance")
        }
    }

    private var preview: some View {
        AppSettingsSection(title: LumiThemePackLocalization.string("Typography & Actions"), subtitle: LumiThemePackLocalization.string("Theme Color & Elevation Preview"), spacing: 12) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(LumiThemePackLocalization.string("Primary Text")).font(.appBody).foregroundStyle(textPrimary)
                    Text(LumiThemePackLocalization.string("Secondary Text")).font(.appCaption).foregroundStyle(textSecondary)
                    Text(LumiThemePackLocalization.string("Theme Color & Elevation Preview")).font(.appMicro).foregroundStyle(textSecondary.opacity(0.75))
                }
                HStack(spacing: 8) {
                    previewButton(LumiThemePackLocalization.string("Primary Action"), fill: primary, foreground: .white)
                    previewButton(LumiThemePackLocalization.string("Secondary Action"), fill: elevated, foreground: textPrimary)
                    previewButton(LumiThemePackLocalization.string("Tertiary Action"), fill: secondary.opacity(0.18), foreground: secondary)
                }
                HStack(spacing: 10) {
                    colorSwatch(LumiThemePackLocalization.string("Primary Color"), primary)
                    colorSwatch(LumiThemePackLocalization.string("Secondary Color"), secondary)
                    colorSwatch(LumiThemePackLocalization.string("Background"), background)
                    colorSwatch(LumiThemePackLocalization.string("Elevated"), elevated)
                }
            }
            .padding(16)
            .background(elevated.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func previewButton(_ title: String, fill: Color, foreground: Color) -> some View {
        Text(title)
            .font(.appMicroEmphasized)
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func colorSwatch(_ title: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color)
                .frame(width: 44, height: 28)
            Text(title)
                .font(.appMicro)
                .foregroundStyle(textSecondary)
        }
    }
}
