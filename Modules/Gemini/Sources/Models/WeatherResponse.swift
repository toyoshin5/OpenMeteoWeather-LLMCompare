import Foundation

struct WeatherResponse: Codable {
    let currentWeather: CurrentWeather
    let daily: Daily
    
    enum CodingKeys: String, CodingKey {
        case currentWeather = "current_weather"
        case daily
    }
}

struct CurrentWeather: Codable {
    let temperature: Double
    let weathercode: Int
    let windspeed: Double
    let winddirection: Double
    let time: String
}

struct Daily: Codable {
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let apparentTemperatureMax: [Double]
    let uvIndexMax: [Double]
    let sunrise: [String]
    let sunset: [String]
    
    enum CodingKeys: String, CodingKey {
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case apparentTemperatureMax = "apparent_temperature_max"
        case uvIndexMax = "uv_index_max"
        case sunrise, sunset
    }
}

struct WeatherDisplayData {
    let temperature: Double
    let maxTemp: Double
    let minTemp: Double
    let apparentTemp: Double
    let weatherCode: Int
    let windSpeed: Double
    let uvIndex: Double
    let sunrise: String
    let sunset: String
    let lastUpdate: Date
    
    var conditionText: String {
        switch weatherCode {
        case 0: return "快晴"
        case 1, 2, 3: return "晴れ時々曇り"
        case 45, 48: return "霧"
        case 51, 53, 55: return "小雨"
        case 61, 63, 65: return "雨"
        case 71, 73, 75: return "雪"
        case 95, 96, 99: return "雷雨"
        default: return "不明"
        }
    }
    
    var systemImage: String {
        switch weatherCode {
        case 0: return "sun.max.fill"
        case 1, 2, 3: return "cloud.sun.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55: return "cloud.drizzle.fill"
        case 61, 63, 65: return "cloud.rain.fill"
        case 71, 73, 75: return "snow"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "questionmark.circle"
        }
    }
}
