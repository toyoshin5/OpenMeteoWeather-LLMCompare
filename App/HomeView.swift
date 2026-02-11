import SwiftUI
import AntigravityFeature
import ClaudeFeature
import CodexFeature
import GeminiFeature
import KimiFeature

private enum LLMApp: Int, CaseIterable, Identifiable {
    case claude
    case codex
    case gemini
    case kimi
    case antigravity

    var id: Int { rawValue }

    var modelName: String {
        switch self {
        case .claude:
            return "Claude Code Sonnet 4.5"
        case .codex:
            return "Codex GPT-5.2-Codex"
        case .gemini:
            return "Gemini CLI Gemini 3(Auto)"
        case .kimi:
            return "OpenCode Kimi K2.5"
        case .antigravity:
            return "Antigravity Gemini 3 Pro"
        }
    }

    var anonymousName: String {
        switch self {
        case .claude:
            return "Model A"
        case .codex:
            return "Model B"
        case .gemini:
            return "Model C"
        case .kimi:
            return "Model D"
        case .antigravity:
            return "Model E"
        }
    }

    @ViewBuilder
    func destination(screenTitle: String) -> some View {
        switch self {
        case .claude:
            ClaudeWeatherRootView(screenTitle: screenTitle)
        case .codex:
            CodexWeatherRootView(screenTitle: screenTitle)
        case .gemini:
            GeminiWeatherRootView(screenTitle: screenTitle)
        case .kimi:
            KimiWeatherRootView(screenTitle: screenTitle)
        case .antigravity:
            AntigravityWeatherRootView(screenTitle: screenTitle)
        }
    }
}

struct HomeView: View {
    @State private var hideModelNames = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("モデル名を隠す", isOn: $hideModelNames)
                }

                Section("モデル一覧") {
                    ForEach(LLMApp.allCases) { model in
                        NavigationLink {
                            model.destination(screenTitle: displayName(for: model))
                        } label: {
                            HStack {
                                Text(displayName(for: model))
                                    .font(.body)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Weather App")
        }
    }

    private func displayName(for model: LLMApp) -> String {
        hideModelNames ? model.anonymousName : model.modelName
    }
}

#Preview {
    HomeView()
}
