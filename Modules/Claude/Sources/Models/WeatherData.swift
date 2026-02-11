import Foundation

// MARK: - API Response Models
struct WeatherResponse: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let current: CurrentWeather?
    let hourly: HourlyForecast?
    let daily: DailyForecast?

    enum CodingKeys: String, CodingKey {
        case latitude, longitude, timezone, current, hourly, daily
    }
}

struct CurrentWeather: Codable {
    let time: String
    let temperature: Double
    let weatherCode: Int
    let humidity: Int
    let windSpeed: Double
    let apparentTemperature: Double
    let pressure: Double
    let visibility: Double
    let uvIndex: Double
    let precipitation: Double

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case weatherCode = "weather_code"
        case humidity = "relative_humidity_2m"
        case windSpeed = "wind_speed_10m"
        case apparentTemperature = "apparent_temperature"
        case pressure = "surface_pressure"
        case visibility
        case uvIndex = "uv_index"
        case precipitation
    }
}

struct HourlyForecast: Codable {
    let time: [String]
    let temperature: [Double]
    let weatherCode: [Int]
    let precipitation: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case weatherCode = "weather_code"
        case precipitation = "precipitation_probability"
    }

    var hours: [HourForecast] {
        guard time.count == temperature.count,
              time.count == weatherCode.count,
              time.count == precipitation.count else {
            return []
        }

        return zip(time, zip(temperature, zip(weatherCode, precipitation))).map { time, data in
            let (temp, codeAndPrec) = data
            let (code, prec) = codeAndPrec
            return HourForecast(time: time, temperature: temp, weatherCode: code, precipitation: prec)
        }
    }
}

struct HourForecast: Identifiable {
    let id = UUID()
    let time: String
    let temperature: Double
    let weatherCode: Int
    let precipitation: Double

    var timeFormatted: String {
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: time) else {
            return time
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    var hourOnly: String {
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: time) else {
            return time
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "H時"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

struct DailyForecast: Codable {
    let time: [String]
    let weatherCode: [Int]
    let temperatureMax: [Double]
    let temperatureMin: [Double]
    let sunrise: [String]
    let sunset: [String]
    let precipitationProbability: [Int]
    let uvIndexMax: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
        case sunrise
        case sunset
        case precipitationProbability = "precipitation_probability_max"
        case uvIndexMax = "uv_index_max"
    }

    var days: [DayForecast] {
        guard time.count == weatherCode.count,
              time.count == temperatureMax.count,
              time.count == temperatureMin.count,
              time.count == sunrise.count,
              time.count == sunset.count,
              time.count == precipitationProbability.count,
              time.count == uvIndexMax.count else {
            return []
        }

        return (0..<time.count).map { i in
            DayForecast(
                date: time[i],
                weatherCode: weatherCode[i],
                maxTemp: temperatureMax[i],
                minTemp: temperatureMin[i],
                sunrise: sunrise[i],
                sunset: sunset[i],
                precipitationProbability: precipitationProbability[i],
                uvIndexMax: uvIndexMax[i]
            )
        }
    }
}

struct DayForecast: Identifiable {
    let id = UUID()
    let date: String
    let weatherCode: Int
    let maxTemp: Double
    let minTemp: Double
    let sunrise: String
    let sunset: String
    let precipitationProbability: Int
    let uvIndexMax: Double

    var dateFormatted: String {
        guard let date = ISO8601DateFormatter().date(from: date + "T00:00:00Z") else {
            return date
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    var sunriseFormatted: String {
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: sunrise) else {
            return sunrise
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    var sunsetFormatted: String {
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: sunset) else {
            return sunset
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Weather Code Mapping
enum WeatherCondition {
    case clearSky
    case mainlyClear
    case partlyCloudy
    case overcast
    case fog
    case drizzle
    case rain
    case snow
    case thunderstorm
    case unknown

    init(code: Int) {
        switch code {
        case 0: self = .clearSky
        case 1: self = .mainlyClear
        case 2: self = .partlyCloudy
        case 3: self = .overcast
        case 45, 48: self = .fog
        case 51, 53, 55, 56, 57: self = .drizzle
        case 61, 63, 65, 66, 67, 80, 81, 82: self = .rain
        case 71, 73, 75, 77, 85, 86: self = .snow
        case 95, 96, 99: self = .thunderstorm
        default: self = .unknown
        }
    }

    var description: String {
        switch self {
        case .clearSky: return "快晴"
        case .mainlyClear: return "晴れ"
        case .partlyCloudy: return "曇り時々晴れ"
        case .overcast: return "曇り"
        case .fog: return "霧"
        case .drizzle: return "霧雨"
        case .rain: return "雨"
        case .snow: return "雪"
        case .thunderstorm: return "雷雨"
        case .unknown: return "不明"
        }
    }

    var sfSymbol: String {
        switch self {
        case .clearSky: return "sun.max.fill"
        case .mainlyClear: return "sun.max"
        case .partlyCloudy: return "cloud.sun.fill"
        case .overcast: return "cloud.fill"
        case .fog: return "cloud.fog.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    var color: String {
        switch self {
        case .clearSky, .mainlyClear: return "yellow"
        case .partlyCloudy: return "orange"
        case .overcast, .fog: return "gray"
        case .drizzle, .rain: return "blue"
        case .snow: return "cyan"
        case .thunderstorm: return "purple"
        case .unknown: return "gray"
        }
    }
}
