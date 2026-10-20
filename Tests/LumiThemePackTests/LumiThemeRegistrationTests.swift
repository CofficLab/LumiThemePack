import Foundation
import ProviderTheme
import Testing
@testable import LumiThemePack

/// `LumiThemeContract` 的计数与 id 集合契约，以及 `LumiThemeRegistration` 的注册/注销行为。
@Suite("主题注册契约")
@MainActor
struct LumiThemeRegistrationTests {

    // MARK: - 计数契约

    @Test("可选择主题数为目录主题数加三个内置外观")
    func selectableCountIsDerivedFromCatalog() {
        #expect(LumiThemeContract.selectableThemeCount == 22)
        #expect(LumiThemeContract.selectableThemeCount
                == LumiThemeContract.catalogThemeCount
                + LumiThemeContract.additionalBuiltinThemeIDs.count)
    }

    @Test("附加内置主题 id 稳定且与目录 id 不重叠")
    func additionalBuiltinIDsAreStableAndDisjoint() {
        #expect(LumiThemeContract.additionalBuiltinThemeIDs == ["lumi-system", "lumi-dark", "lumi-light"])

        let catalogIDs = Set(LumiThemeCatalog.all.map(\.id))
        let overlap = catalogIDs.intersection(LumiThemeContract.additionalBuiltinThemeIDs)
        #expect(overlap.isEmpty, "目录与内置主题 id 冲突：\(overlap)")
    }

    @Test("可选择 id 集合唯一")
    func selectableIDsAreUnique() {
        let ids = LumiThemeContract.selectableThemeIDs

        #expect(ids.count == LumiThemeContract.selectableThemeCount)
        #expect(Set(ids).count == ids.count)
    }

    // MARK: - 注册

    @Test("注册后 Provider 覆盖内置主题并达到约定数量")
    func registerReachesContractCount() {
        let provider = DefaultThemeProviding()
        let builtinCount = provider.themes.count

        LumiThemeRegistration.register(in: provider)

        #expect(builtinCount == 4, "Provider 默认注册 4 个内置主题")
        #expect(provider.themes.count == LumiThemeContract.selectableThemeCount)
    }

    @Test("注册后 id 集合等于契约定义")
    func registerProducesContractIDs() {
        let provider = DefaultThemeProviding()

        LumiThemeRegistration.register(in: provider)

        #expect(Set(provider.themes.map(\.id)) == Set(LumiThemeContract.selectableThemeIDs))
    }

    @Test("共享 lumi 主题覆盖内置 lumi 而非新增条目")
    func sharedLumiOverridesBuiltin() {
        let provider = DefaultThemeProviding()

        LumiThemeRegistration.register(in: provider)

        let lumis = provider.themes.filter { $0.id == "lumi" }
        #expect(lumis.count == 1)
        #expect(lumis.first?.palette == LumiThemeCatalog.lumi.palette,
                "共享目录应覆盖内置 lumi 的色板")
        #expect(lumis.first?.sortOrder == LumiThemeCatalog.lumi.sortOrder)
    }

    @Test("注册后主题按 sortOrder 升序排列")
    func registerKeepsSortOrder() {
        let provider = DefaultThemeProviding()

        LumiThemeRegistration.register(in: provider)

        let orders = provider.themes.map(\.sortOrder)
        #expect(zip(orders, orders.dropFirst()).allSatisfy { $0 <= $1 })
    }

    @Test("目录 sortOrder 均大于内置 sortOrder，注册后内置主题排在前面")
    func builtinsSortBeforeSharedThemes() {
        let provider = DefaultThemeProviding()

        LumiThemeRegistration.register(in: provider)

        let catalogIDs = Set(LumiThemeCatalog.all.map(\.id))
        let lastBuiltinIndex = provider.themes.lastIndex {
            LumiThemeContract.additionalBuiltinThemeIDs.contains($0.id)
        }
        let firstCatalogIndex = provider.themes.firstIndex { catalogIDs.contains($0.id) }

        #expect(lastBuiltinIndex != nil)
        #expect(firstCatalogIndex != nil)
        if let lastBuiltinIndex, let firstCatalogIndex {
            #expect(lastBuiltinIndex < firstCatalogIndex,
                    "内置 sortOrder(100/200/300) 应小于目录(1000+)")
        }
    }

    @Test("重复注册幂等，不产生重复条目")
    func registerIsIdempotent() {
        let provider = DefaultThemeProviding()

        LumiThemeRegistration.register(in: provider)
        let firstCount = provider.themes.count
        LumiThemeRegistration.register(in: provider)

        #expect(provider.themes.count == firstCount)
        #expect(Set(provider.themes.map(\.id)).count == firstCount)
    }

    // MARK: - 注销

    @Test("注销后仅剩三个内置外观主题")
    func unregisterRemovesSharedThemes() {
        let provider = DefaultThemeProviding()
        LumiThemeRegistration.register(in: provider)

        LumiThemeRegistration.unregister(from: provider)

        // 目录的 `lumi` 覆盖了内置 `lumi`，注销后该 id 不再有来源，
        // 因此只剩三个附加内置主题。
        #expect(Set(provider.themes.map(\.id)) == Set(LumiThemeContract.additionalBuiltinThemeIDs))
        #expect(!provider.themes.contains { $0.id == "lumi" })
    }

    @Test("注销后内置三主题的色板保持不变")
    func unregisterKeepsBuiltinPalettes() {
        let provider = DefaultThemeProviding()
        LumiThemeRegistration.register(in: provider)
        let builtinPalettesBefore = Dictionary(
            uniqueKeysWithValues: provider.themes
                .filter { LumiThemeContract.additionalBuiltinThemeIDs.contains($0.id) }
                .map { ($0.id, $0.palette) }
        )

        LumiThemeRegistration.unregister(from: provider)

        for theme in provider.themes {
            #expect(theme.palette == builtinPalettesBefore[theme.id],
                    "\(theme.id) 的内置色板不应被目录污染")
        }
    }

    @Test("注销未注册的主题不影响现有列表")
    func unregisterIgnoresUnknownIDs() {
        let provider = DefaultThemeProviding()
        let baseline = provider.themes

        provider.unregisterTheme(id: "not-registered")

        #expect(provider.themes == baseline)
    }

    @Test("注销后再注册可恢复目录状态")
    func registerAfterUnregisterRestoresCatalog() {
        let provider = DefaultThemeProviding()
        LumiThemeRegistration.register(in: provider)
        LumiThemeRegistration.unregister(from: provider)

        LumiThemeRegistration.register(in: provider)

        #expect(provider.themes.count == LumiThemeContract.selectableThemeCount)
        #expect(Set(provider.themes.map(\.id)) == Set(LumiThemeContract.selectableThemeIDs))
    }
}
