import Foundation

class WeatherService: ObservableObject {
    @Published var weather: WeatherResponse?
    @Published var errorMessage: String?

    func fetchWeather() async {
        let urlString =
            "https://api.open-meteo.com/v1/forecast?latitude=43.0642&longitude=141.3469&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,showers,snowfall,weather_code,cloud_cover,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m&hourly=temperature_2m,precipitation_probability,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max,wind_speed_10m_max&timezone=Asia%2FTokyo"

        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL"
            }
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
            DispatchQueue.main.async {
                self.weather = decodedResponse
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to fetch weather: \(error.localizedDescription)"
            }
        }
    }
}
