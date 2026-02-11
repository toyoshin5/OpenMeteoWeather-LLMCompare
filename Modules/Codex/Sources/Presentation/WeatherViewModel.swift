import Foundation

@MainActor
final class WeatherViewModel: ObservableObject {
    enum ViewState {
        case idle
        case loading
        case loaded(WeatherSnapshot)
        case failed(String)
    }

    @Published private(set) var state: ViewState = .idle

    private let service: WeatherServicing

    init(service: WeatherServicing) {
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            let weather = try await service.fetchCurrentWeather()
            state = .loaded(weather)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
