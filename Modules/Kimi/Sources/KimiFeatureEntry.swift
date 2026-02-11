import SwiftUI

public struct KimiWeatherRootView: View {
    private let screenTitle: String

    public init(screenTitle: String) {
        self.screenTitle = screenTitle
    }

    public var body: some View {
        ContentView(screenTitle: screenTitle)
    }
}
