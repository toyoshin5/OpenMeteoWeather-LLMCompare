import SwiftUI

public struct GeminiWeatherRootView: View {
    private let screenTitle: String

    public init(screenTitle: String) {
        self.screenTitle = screenTitle
    }

    public var body: some View {
        ContentView()
            .navigationTitle(screenTitle)
            .navigationBarTitleDisplayMode(.inline)
    }
}
