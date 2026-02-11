import Foundation

struct OpenMeteoResponse: Decodable {
    let latitude: Double
    let longitude: Double
    let elevation: Double
    let timezone: String
    let current: CurrentWeather
    let currentUnits: CurrentUnits
    let hourly: HourlyWeather
    let hourlyUnits: HourlyUnits
    let daily: DailyWeather
    let dailyUnits: DailyUnits

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case elevation
        case timezone
        case current
        case currentUnits = "current_units"
        case hourly
        case hourlyUnits = "hourly_units"
        case daily
        case dailyUnits = "daily_units"
    }
}

struct CurrentWeather: Decodable {
    let time: String
    let temperature2m: Double
    let apparentTemperature: Double
    let relativeHumidity2m: Int
    let isDay: Int
    let precipitation: Double
    let rain: Double
    let showers: Double
    let snowfall: Double
    let weatherCode: Int
    let cloudCover: Int
    let surfacePressure: Double
    let windSpeed10m: Double
    let windDirection10m: Int
    let windGusts10m: Double

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case relativeHumidity2m = "relative_humidity_2m"
        case isDay = "is_day"
        case precipitation
        case rain
        case showers
        case snowfall
        case weatherCode = "weather_code"
        case cloudCover = "cloud_cover"
        case surfacePressure = "surface_pressure"
        case windSpeed10m = "wind_speed_10m"
        case windDirection10m = "wind_direction_10m"
        case windGusts10m = "wind_gusts_10m"
    }
}

struct CurrentUnits: Decodable {
    let temperature2m: String
    let apparentTemperature: String
    let precipitation: String
    let rain: String
    let showers: String
    let snowfall: String
    let surfacePressure: String
    let windSpeed10m: String
    let windGusts10m: String

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case precipitation
        case rain
        case showers
        case snowfall
        case surfacePressure = "surface_pressure"
        case windSpeed10m = "wind_speed_10m"
        case windGusts10m = "wind_gusts_10m"
    }
}

struct HourlyWeather: Decodable {
    let time: [String]
    let temperature2m: [Double]
    let apparentTemperature: [Double]
    let relativeHumidity2m: [Int]
    let precipitationProbability: [Int]
    let weatherCode: [Int]
    let windSpeed10m: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case relativeHumidity2m = "relative_humidity_2m"
        case precipitationProbability = "precipitation_probability"
        case weatherCode = "weather_code"
        case windSpeed10m = "wind_speed_10m"
    }
}

struct HourlyUnits: Decodable {
    let temperature2m: String
    let apparentTemperature: String
    let windSpeed10m: String

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case windSpeed10m = "wind_speed_10m"
    }
}

struct DailyWeather: Decodable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let sunrise: [String]
    let sunset: [String]
    let uvIndexMax: [Double]
    let precipitationSum: [Double]
    let precipitationProbabilityMax: [Int]
    let windSpeed10mMax: [Double]
    let windGusts10mMax: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case sunrise
        case sunset
        case uvIndexMax = "uv_index_max"
        case precipitationSum = "precipitation_sum"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case windSpeed10mMax = "wind_speed_10m_max"
        case windGusts10mMax = "wind_gusts_10m_max"
    }
}

struct DailyUnits: Decodable {
    let temperature2mMax: String
    let temperature2mMin: String
    let uvIndexMax: String
    let precipitationSum: String
    let windSpeed10mMax: String
    let windGusts10mMax: String

    enum CodingKeys: String, CodingKey {
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case uvIndexMax = "uv_index_max"
        case precipitationSum = "precipitation_sum"
        case windSpeed10mMax = "wind_speed_10m_max"
        case windGusts10mMax = "wind_gusts_10m_max"
    }
}

struct WeatherSnapshot {
    let cityName: String
    let timezone: String
    let latitude: Double
    let longitude: Double
    let elevation: Double
    let observedAt: Date
    let current: CurrentConditions
    let units: WeatherUnits
    let hourlyForecast: [HourlyForecast]
    let dailyForecast: [DailyForecast]
}

struct CurrentConditions {
    let temperature: Double
    let apparentTemperature: Double
    let humidity: Int
    let isDay: Bool
    let weatherCode: Int
    let cloudCover: Int
    let precipitation: Double
    let rain: Double
    let showers: Double
    let snowfall: Double
    let surfacePressure: Double
    let windSpeed: Double
    let windDirection: Int
    let windGusts: Double
}

struct WeatherUnits {
    let temperature: String
    let precipitation: String
    let pressure: String
    let windSpeed: String
}

struct HourlyForecast: Identifiable {
    let date: Date
    let temperature: Double
    let apparentTemperature: Double
    let humidity: Int
    let precipitationProbability: Int
    let weatherCode: Int
    let windSpeed: Double

    var id: Date { date }
}

struct DailyForecast: Identifiable {
    let date: Date
    let weatherCode: Int
    let minTemperature: Double
    let maxTemperature: Double
    let sunrise: Date
    let sunset: Date
    let uvIndexMax: Double
    let precipitationSum: Double
    let precipitationProbabilityMax: Int
    let windSpeedMax: Double
    let windGustsMax: Double

    var id: Date { date }
}

enum WeatherCodeMapper {
    static func description(for code: Int) -> String {
        switch code {
        case 0: return "Clear sky"
        case 1: return "Mainly clear"
        case 2: return "Partly cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Fog"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Freezing drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67: return "Freezing rain"
        case 71, 73, 75, 77: return "Snow"
        case 80, 81, 82: return "Rain showers"
        case 85, 86: return "Snow showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Thunderstorm with hail"
        default: return "Unknown"
        }
    }

    static func symbolName(for code: Int, isDay: Bool = true) -> String {
        switch code {
        case 0:
            return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2:
            return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55, 61, 63, 65, 80, 81, 82:
            return "cloud.rain.fill"
        case 56, 57, 66, 67:
            return "cloud.sleet.fill"
        case 71, 73, 75, 77, 85, 86:
            return "cloud.snow.fill"
        case 95, 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
}

enum WindDirectionMapper {
    static func compassLabel(for degree: Int) -> String {
        let normalized = (degree % 360 + 360) % 360
        switch normalized {
        case 337...359, 0..<23: return "N"
        case 23..<68: return "NE"
        case 68..<113: return "E"
        case 113..<158: return "SE"
        case 158..<203: return "S"
        case 203..<248: return "SW"
        case 248..<293: return "W"
        default: return "NW"
        }
    }
}
