import Foundation

@MainActor
final class WeatherService: ObservableObject {
    @Published var weatherData: WeatherResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // 札幌の座標
    private let sapporoLatitude = 43.0642
    private let sapporoLongitude = 141.3469

    func fetchWeather() async {
        isLoading = true
        errorMessage = nil

        // Build comprehensive API request with all available parameters
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(sapporoLatitude)),
            URLQueryItem(name: "longitude", value: String(sapporoLongitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m,apparent_temperature,surface_pressure,visibility,uv_index,precipitation"),
            URLQueryItem(name: "hourly", value: "temperature_2m,weather_code,precipitation_probability"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max,uv_index_max"),
            URLQueryItem(name: "timezone", value: "Asia/Tokyo"),
            URLQueryItem(name: "forecast_days", value: "7")
        ]

        guard let url = components.url else {
            errorMessage = "無効なURLです"
            isLoading = false
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                errorMessage = "サーバーエラーが発生しました"
                isLoading = false
                return
            }

            let decoder = JSONDecoder()
            let weather = try decoder.decode(WeatherResponse.self, from: data)
            weatherData = weather
        } catch {
            errorMessage = "データの取得に失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
