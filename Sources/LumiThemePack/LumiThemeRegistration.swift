import ProviderTheme

/// Canonical theme-count and identity contract shared by every host app.
public enum LumiThemeContract {
    /// The three built-in appearance choices that are not part of the shared
    /// catalog. The shared `lumi` theme replaces the built-in `lumi` entry.
    public static let additionalBuiltinThemeIDs: [String] = [
        "lumi-system",
        "lumi-dark",
        "lumi-light",
    ]

    public static let catalogThemeCount = 19
    public static let selectableThemeCount = catalogThemeCount + additionalBuiltinThemeIDs.count

    /// The complete selectable ID set after the catalog is registered over
    /// `ProviderTheme.BuiltinThemes.all`.
    public static var selectableThemeIDs: [String] {
        LumiThemeCatalog.all.map(\.id) + additionalBuiltinThemeIDs
    }
}

/// Registers or removes the shared theme catalog through the host's theme provider.
@MainActor
public enum LumiThemeRegistration {
    public static func register(in provider: any ThemeProviding) {
        LumiThemeCatalog.all.forEach(provider.registerTheme)
    }

    public static func unregister(from provider: any ThemeProviding) {
        LumiThemeCatalog.all.forEach { provider.unregisterTheme(id: $0.id) }
    }
}
