# OpenMeteoWeather-LLMCompare

## 概要
5つのAI Agentの同一要件の天気アプリのUIを比較

```
SwiftUI,Xcodegenを使用して，https://api.open-meteo.com/v1/forecast?を使用して札幌の天気を取得するアプリを作成してください．できるだけ沢山の情報を表示し，UIにもこだわってください．
```

対象とモデルは以下。  

- `Codex: GPT-5.3-Codex`
- `Claude: Claude Code Sonnet 4.5` 
- `Gemini: Gemini CLI Gemini 3 (Auto)` 
- `Kimi: OpenCode Kimi K2.5`  
- `Antigravity: Antigravity Gemini 3 Pro`  

## ビルド 

```bash
xcodegen generate
open OpenMeteoWeather-LLMCompare.xcodeproj
```

## スクリーンショット
| Codex | Claude | Gemini | Kimi | Antigravity |
|---|---|---|---|---|
| <img width="200" alt="image" src="https://github.com/user-attachments/assets/29d37768-c62b-4c52-a41d-198ea466a967" /> | <img width="200" alt="image" src="https://github.com/user-attachments/assets/e8930914-1c6c-4b3f-a4df-b25943db9205" /> | <img width="200" alt="image" src="https://github.com/user-attachments/assets/3ec4320d-1c7b-4b14-8a26-8fef861daa34" /> | <img width="200" alt="image" src="https://github.com/user-attachments/assets/396b80fc-3547-4ead-9160-574f843f7f74" /> | <img width="200" alt="image" src="https://github.com/user-attachments/assets/498a03bf-ed1e-466a-a6fc-dbf7698732f9" /> |
