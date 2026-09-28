import ProviderTheme
import Testing

@testable import LumiThemePack

@Suite("LumiThemePack contract")
struct LumiThemePackTests {
    @Test("canonical catalog has 19 unique stable IDs")
    func canonicalCatalog() {
        let themes = LumiThemeCatalog.all
        let ids = themes.map(\.id)

        #expect(themes.count == LumiThemeContract.catalogThemeCount)
        #expect(Set(ids).count == ids.count)
        #expect(ids == [
            "lumi", "midnight", "sky", "aurora", "nebula", "void",
            "spring", "summer", "autumn", "winter", "github", "orchard",
            "mountain", "vscode-auto", "vscode-dark", "vscode-light",
            "river", "one-dark", "dracula",
        ])
    }

    @Test("shared registration produces 22 selectable themes")
    @MainActor
    func sharedRegistration() {
        let provider = DefaultThemeProviding()

        LumiThemeRegistration.register(in: provider)

        #expect(provider.themes.count == LumiThemeContract.selectableThemeCount)
        #expect(Set(provider.themes.map(\.id)) == Set(LumiThemeContract.selectableThemeIDs))
    }
}
