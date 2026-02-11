import Foundation

enum WeatherError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .decodingError:
            return "データの解析に失敗しました"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        }
    }
}

class WeatherService {
    static let shared = WeatherService()
    
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    
    // 札幌の座標
    private let sapporoLatitude = 43.0642
    private let sapporoLongitude = 141.3469
    
    private init() {}
    
    func fetchSapporoWeather() async throws -> WeatherResponse {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(sapporoLatitude)),
            URLQueryItem(name: "longitude", value: String(sapporoLongitude)),
            URLQueryItem(name: "current_weather", value: "true"),
            URLQueryItem(name: "hourly", value: "temperature_2m,weathercode,precipitation_probability,relativehumidity_2m,apparent_temperature,precipitation,surface_pressure,cloudcover,visibility,windgusts_10m"),
            URLQueryItem(name: "daily", value: "weathercode,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_sum,precipitation_probability_max,uv_index_max,windspeed_10m_max,windgusts_10m_max"),
            URLQueryItem(name: "timezone", value: "Asia/Tokyo"),
            URLQueryItem(name: "forecast_days", value: "7")
        ]
        
        guard let url = components?.url else {
            throw WeatherError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw WeatherError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            let weatherResponse = try decoder.decode(WeatherResponse.self, from: data)
            return weatherResponse
            
        } catch let error as WeatherError {
            throw error
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            throw WeatherError.decodingError
        } catch {
            throw WeatherError.networkError(error)
        }
    }
}
