import Foundation

struct WeatherResponse: Codable {
    let current: CurrentWeather
    let hourly: HourlyWeather
    let daily: DailyWeather
}

struct CurrentWeather: Codable {
    let time: String
    let temperature2m: Double
    let weatherCode: Int
    let relativeHumidity2m: Int
    let apparentTemperature: Double
    let pressureMsl: Double
    let windSpeed10m: Double
    let windDirection10m: Int
    let cloudCover: Int
    let isDay: Int

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
        case relativeHumidity2m = "relative_humidity_2m"
        case apparentTemperature = "apparent_temperature"
        case pressureMsl = "pressure_msl"
        case windSpeed10m = "wind_speed_10m"
        case windDirection10m = "wind_direction_10m"
        case cloudCover = "cloud_cover"
        case isDay = "is_day"
    }
}

struct HourlyWeather: Codable {
    let time: [String]
    let temperature2m: [Double]
    let precipitationProbability: [Int]
    let weatherCode: [Int]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case precipitationProbability = "precipitation_probability"
        case weatherCode = "weather_code"
    }
}

struct DailyWeather: Codable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let sunrise: [String]
    let sunset: [String]
    let uvIndexMax: [Double]
    let precipitationProbabilityMax: [Int]
    let windSpeed10mMax: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case sunrise
        case sunset
        case uvIndexMax = "uv_index_max"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case windSpeed10mMax = "wind_speed_10m_max"
    }
}

struct WeatherDescription {
    static func description(for code: Int) -> String {
        switch code {
        case 0: return "Clear sky"
        case 1, 2, 3: return "Mainly clear, partly cloudy, and overcast"
        case 45, 48: return "Fog and depositing rime fog"
        case 51, 53, 55: return "Drizzle: Light, moderate, and dense intensity"
        case 56, 57: return "Freezing Drizzle: Light and dense intensity"
        case 61, 63, 65: return "Rain: Slight, moderate and heavy intensity"
        case 66, 67: return "Freezing Rain: Light and heavy intensity"
        case 71, 73, 75: return "Snow fall: Slight, moderate, and heavy intensity"
        case 77: return "Snow grains"
        case 80, 81, 82: return "Rain showers: Slight, moderate, and violent"
        case 85, 86: return "Snow showers slight and heavy"
        case 95: return "Thunderstorm: Slight or moderate"
        case 96, 99: return "Thunderstorm with slight and heavy hail"
        default: return "Unknown"
        }
    }

    static func icon(for code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2, 3: return "cloud.sun.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 56, 57: return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67: return "cloud.rain.fill"
        case 71, 73, 75, 77: return "cloud.snow.fill"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        case 85, 86: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "questionmark.circle.fill"
        }
    }
}
