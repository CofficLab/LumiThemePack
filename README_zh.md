# LumiThemePack

📖 [中文版](README_zh.md) | [English](README.md)

CofficLab 应用共享的主题目录与主题设置界面。

本包只依赖 `LumiUI` 与来自 `LumiProviders` 的 `ProviderTheme` 能力。宿主应用
保留自己的内核插件元数据、生命周期策略，以及可选的命令或文档贡献。

```swift
import LumiThemePack

LumiThemeRegistration.register(in: themeProvider)
ThemeSettingsDetailView(theme: themeProvider)
let chromeTheme = LumiPaletteChromeTheme(theme: selectedTheme, colorScheme: .dark)
```

在插件关闭时移除共享主题：

```swift
LumiThemeRegistration.unregister(from: themeProvider)
```
