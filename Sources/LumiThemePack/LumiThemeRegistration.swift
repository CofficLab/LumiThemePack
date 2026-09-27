import ProviderTheme

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
