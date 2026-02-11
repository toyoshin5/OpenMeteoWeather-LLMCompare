import Foundation

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var displayData: WeatherDisplayData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let weatherService = WeatherService()
    
    func fetchWeather() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await weatherService.fetchSapporoWeather()
            
            // APIレスポンスを表示用データに変換
            self.displayData = WeatherDisplayData(
                temperature: response.currentWeather.temperature,
                maxTemp: response.daily.temperature2mMax.first ?? 0,
                minTemp: response.daily.temperature2mMin.first ?? 0,
                apparentTemp: response.daily.apparentTemperatureMax.first ?? 0,
                weatherCode: response.currentWeather.weathercode,
                windSpeed: response.currentWeather.windspeed,
                uvIndex: response.daily.uvIndexMax.first ?? 0,
                sunrise: formatTime(response.daily.sunrise.first),
                sunset: formatTime(response.daily.sunset.first),
                lastUpdate: Date()
            )
        } catch {
            self.errorMessage = "天気の取得に失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func formatTime(_ iso8601: String?) -> String {
        guard let iso8601 = iso8601 else { return "--:--" }
        // シンプルに時刻部分だけを抜き出す
        return iso8601.components(separatedBy: "T").last ?? iso8601
    }
}
