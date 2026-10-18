import ProviderTheme
import Testing
@testable import LumiThemePack

/// `ThemeAppearanceFilter` 与 `ThemeFilter` 的搜索 / 外观筛选语义。
@Suite("主题搜索与筛选")
@MainActor
struct ThemeFilterTests {

    // MARK: - 外观筛选匹配

    @Test("all 匹配所有外观类型")
    func allFilterMatchesEverything() {
        for kind in [ThemeAppearanceKind.dark, .light, .system] {
            #expect(ThemeAppearanceFilter.all.matches(kind))
        }
    }

    @Test("具体外观筛选只匹配自身")
    func specificFilterMatchesOnlySameKind() {
        #expect(ThemeAppearanceFilter.dark.matches(.dark))
        #expect(!ThemeAppearanceFilter.dark.matches(.light))
        #expect(!ThemeAppearanceFilter.dark.matches(.system))

        #expect(ThemeAppearanceFilter.light.matches(.light))
        #expect(!ThemeAppearanceFilter.light.matches(.dark))

        #expect(ThemeAppearanceFilter.system.matches(.system))
        #expect(!ThemeAppearanceFilter.system.matches(.dark))
    }

    @Test("筛选器覆盖四种模式且 id 为 rawValue")
    func filterCasesAreComplete() {
        #expect(ThemeAppearanceFilter.allCases.map(\.rawValue) == ["all", "dark", "light", "system"])
        #expect(ThemeAppearanceFilter.allCases.map(\.id) == ["all", "dark", "light", "system"])
    }

    @Test("各筛选器标题互不相同")
    func filterTitlesAreDistinct() {
        let titles = ThemeAppearanceFilter.allCases.map(\.title)
        #expect(Set(titles).count == titles.count)
        #expect(titles.allSatisfy { !$0.isEmpty })
    }

    // MARK: - 空关键字

    @Test("空关键字返回全部主题")
    func emptySearchReturnsAll() {
        let themes = [
            ThemeFixture.theme(id: "a", appearanceKind: .dark),
            ThemeFixture.theme(id: "b", appearanceKind: .light),
        ]

        let result = ThemeFilter.filter(themes: themes, searchText: "", filter: .all)

        #expect(result.map(\.id) == ["a", "b"])
    }

    @Test("仅含空白的关键字视为空关键字")
    func whitespaceOnlySearchReturnsAll() {
        let themes = [ThemeFixture.theme(id: "a"), ThemeFixture.theme(id: "b")]

        let result = ThemeFilter.filter(themes: themes, searchText: "   \n\t ", filter: .all)

        #expect(result.map(\.id) == ["a", "b"])
    }

    @Test("空主题列表返回空结果")
    func emptyThemesReturnEmpty() {
        let result = ThemeFilter.filter(themes: [], searchText: "any", filter: .all)

        #expect(result.isEmpty)
    }

    // MARK: - 关键字匹配

    @Test("按 displayName 匹配")
    func matchesDisplayName() {
        let themes = [
            ThemeFixture.theme(id: "x", displayName: "Dracula"),
            ThemeFixture.theme(id: "y", displayName: "Solarized"),
        ]

        let result = ThemeFilter.filter(themes: themes, searchText: "dracula", filter: .all)

        #expect(result.map(\.id) == ["x"])
    }

    @Test("按 description 匹配")
    func matchesDescription() {
        let themes = [
            ThemeFixture.theme(id: "x", description: "High contrast and striking"),
            ThemeFixture.theme(id: "y", description: "Soft and warm"),
        ]

        let result = ThemeFilter.filter(themes: themes, searchText: "contrast", filter: .all)

        #expect(result.map(\.id) == ["x"])
    }

    @Test("按 id 匹配，可用于搜索 vscode-dark 这类带连字符的 id")
    func matchesID() {
        let themes = [
            ThemeFixture.theme(id: "vscode-auto"),
            ThemeFixture.theme(id: "vscode-dark"),
            ThemeFixture.theme(id: "dracula"),
        ]

        let result = ThemeFilter.filter(themes: themes, searchText: "vscode-dark", filter: .all)

        #expect(result.map(\.id) == ["vscode-dark"])
    }

    @Test("关键字大小写不敏感")
    func searchIsCaseInsensitive() {
        let themes = [ThemeFixture.theme(id: "x", displayName: "One Dark")]

        for keyword in ["one dark", "ONE DARK", "oNe DaRk"] {
            let result = ThemeFilter.filter(themes: themes, searchText: keyword, filter: .all)
            #expect(result.map(\.id) == ["x"], "关键字 \(keyword) 应命中")
        }
    }

    @Test("关键字首尾空白被裁剪后仍可匹配")
    func searchTrimsWhitespace() {
        let themes = [ThemeFixture.theme(id: "x", displayName: "Nebula")]

        let result = ThemeFilter.filter(themes: themes, searchText: "  nebula\n", filter: .all)

        #expect(result.map(\.id) == ["x"])
    }

    @Test("不匹配任何字段时返回空")
    func nonMatchingSearchReturnsEmpty() {
        let themes = [ThemeFixture.theme(id: "x", displayName: "Nebula", description: "Pink")]

        let result = ThemeFilter.filter(themes: themes, searchText: "zzz", filter: .all)

        #expect(result.isEmpty)
    }

    @Test("多主题命中时保持输入顺序")
    func resultsKeepInputOrder() {
        let themes = [
            ThemeFixture.theme(id: "c", displayName: "Code"),
            ThemeFixture.theme(id: "a", displayName: "Code"),
            ThemeFixture.theme(id: "b", displayName: "Code"),
            ThemeFixture.theme(id: "d", displayName: "Other"),
        ]

        let result = ThemeFilter.filter(themes: themes, searchText: "code", filter: .all)

        #expect(result.map(\.id) == ["c", "a", "b"])
    }

    @Test("目录主题可通过名称与 id 检索到")
    func searchableAgainstRealCatalog() {
        let themes = LumiThemeCatalog.all

        let byName = ThemeFilter.filter(themes: themes, searchText: "VS Code", filter: .all)
        #expect(byName.count >= 1)

        let byID = ThemeFilter.filter(themes: themes, searchText: "one-dark", filter: .all)
        #expect(byID.map(\.id) == ["one-dark"])

        let byIconLikeTerm = ThemeFilter.filter(themes: themes, searchText: "zzzz", filter: .all)
        #expect(byIconLikeTerm.isEmpty)
    }

    // MARK: - 组合筛选

    @Test("外观筛选与关键字同时生效")
    func appearanceFilterAndSearchCombine() {
        let themes = [
            ThemeFixture.theme(id: "dark-theme", displayName: "Theme", appearanceKind: .dark),
            ThemeFixture.theme(id: "light-theme", displayName: "Theme", appearanceKind: .light),
        ]

        let result = ThemeFilter.filter(themes: themes, searchText: "theme", filter: .dark)

        #expect(result.map(\.id) == ["dark-theme"])
    }

    @Test("外观筛选可独立于关键字生效")
    func appearanceFilterAlone() {
        let themes = [
            ThemeFixture.theme(id: "d1", appearanceKind: .dark),
            ThemeFixture.theme(id: "d2", appearanceKind: .dark),
            ThemeFixture.theme(id: "l1", appearanceKind: .light),
            ThemeFixture.theme(id: "s1", appearanceKind: .system),
        ]

        #expect(ThemeFilter.filter(themes: themes, searchText: "", filter: .dark).map(\.id) == ["d1", "d2"])
        #expect(ThemeFilter.filter(themes: themes, searchText: "", filter: .light).map(\.id) == ["l1"])
        #expect(ThemeFilter.filter(themes: themes, searchText: "", filter: .system).map(\.id) == ["s1"])
        #expect(ThemeFilter.filter(themes: themes, searchText: "", filter: .all).count == 4)
    }

    @Test("外观筛选与关键字互斥时返回空")
    func conflictingFiltersReturnEmpty() {
        let themes = [ThemeFixture.theme(id: "light", appearanceKind: .light)]

        let result = ThemeFilter.filter(themes: themes, searchText: "light", filter: .dark)

        #expect(result.isEmpty)
    }

    @Test("筛选真实目录时各外观均有命中")
    func filterRealCatalogByAppearance() {
        let themes = LumiThemeCatalog.all

        #expect(!ThemeFilter.filter(themes: themes, searchText: "", filter: .dark).isEmpty)
        #expect(!ThemeFilter.filter(themes: themes, searchText: "", filter: .light).isEmpty)
        #expect(!ThemeFilter.filter(themes: themes, searchText: "", filter: .system).isEmpty)
        #expect(ThemeFilter.filter(themes: themes, searchText: "", filter: .all).count == themes.count)
    }
}
