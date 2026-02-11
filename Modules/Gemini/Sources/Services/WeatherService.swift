import Foundation

enum WeatherError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
}

class WeatherService {
    // 札幌の座標: 緯度 43.0667, 経度 141.3500
    private let sapporoURLString = "https://api.open-meteo.com/v1/forecast?latitude=43.0642&longitude=141.3469&current_weather=true&daily=temperature_2m_max,temperature_2m_min,apparent_temperature_max,uv_index_max,sunrise,sunset&timezone=Asia%2FTokyo"
    
    func fetchSapporoWeather() async throws -> WeatherResponse {
        guard let url = URL(string: sapporoURLString) else {
            throw WeatherError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(WeatherResponse.self, from: data)
            return response
        } catch {
            throw WeatherError.decodingError(error)
        }
    }
}
