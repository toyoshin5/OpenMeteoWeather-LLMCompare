import Foundation

struct WeatherResponse: Codable {
    let latitude: Double
    let longitude: Double
    let currentWeather: CurrentWeather
    let hourly: HourlyWeather
    let daily: DailyWeather
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case currentWeather = "current_weather"
        case hourly
        case daily
    }
}

struct CurrentWeather: Codable {
    let temperature: Double
    let windspeed: Double
    let winddirection: Double
    let weathercode: Int
    let time: String
}

struct HourlyWeather: Codable {
    let time: [String]
    let temperature2m: [Double]
    let weathercode: [Int]
    let precipitationProbability: [Int]
    let relativehumidity2m: [Int]
    let apparentTemperature: [Double]
    let precipitation: [Double]
    let surfacePressure: [Double]
    let cloudcover: [Int]
    let visibility: [Double]
    let windgusts10m: [Double]
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case weathercode
        case precipitationProbability = "precipitation_probability"
        case relativehumidity2m = "relativehumidity_2m"
        case apparentTemperature = "apparent_temperature"
        case precipitation
        case surfacePressure = "surface_pressure"
        case cloudcover
        case visibility
        case windgusts10m = "windgusts_10m"
    }
}

struct DailyWeather: Codable {
    let time: [String]
    let weathercode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let sunrise: [String]
    let sunset: [String]
    let precipitationSum: [Double]
    let precipitationProbabilityMax: [Int]
    let uvIndexMax: [Double]
    let windspeed10mMax: [Double]
    let windgusts10mMax: [Double]
    
    enum CodingKeys: String, CodingKey {
        case time
        case weathercode
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case sunrise
        case sunset
        case precipitationSum = "precipitation_sum"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case uvIndexMax = "uv_index_max"
        case windspeed10mMax = "windspeed_10m_max"
        case windgusts10mMax = "windgusts_10m_max"
    }
}

enum WeatherCode: Int {
    case clearSky = 0
    case mainlyClear = 1
    case partlyCloudy = 2
    case overcast = 3
    case fog = 45
    case depositingRimeFog = 48
    case drizzleLight = 51
    case drizzleModerate = 53
    case drizzleDense = 55
    case freezingDrizzleLight = 56
    case freezingDrizzleDense = 57
    case rainSlight = 61
    case rainModerate = 63
    case rainHeavy = 65
    case freezingRainLight = 66
    case freezingRainHeavy = 67
    case snowSlight = 71
    case snowModerate = 73
    case snowHeavy = 75
    case snowGrains = 77
    case rainShowersSlight = 80
    case rainShowersModerate = 81
    case rainShowersViolent = 82
    case snowShowersSlight = 85
    case snowShowersHeavy = 86
    case thunderstormSlight = 95
    case thunderstormWithHail = 96
    case thunderstormWithHeavyHail = 99
    
    var description: String {
        switch self {
        case .clearSky: return "快晴"
        case .mainlyClear: return "晴れ"
        case .partlyCloudy: return "曇りがち"
        case .overcast: return "曇り"
        case .fog: return "霧"
        case .depositingRimeFog: return "着氷性の霧"
        case .drizzleLight: return "軽い霧雨"
        case .drizzleModerate: return "霧雨"
        case .drizzleDense: return "濃い霧雨"
        case .freezingDrizzleLight: return "軽い凍結性霧雨"
        case .freezingDrizzleDense: return "凍結性霧雨"
        case .rainSlight: return "小雨"
        case .rainModerate: return "雨"
        case .rainHeavy: return "大雨"
        case .freezingRainLight: return "軽い凍結性の雨"
        case .freezingRainHeavy: return "凍結性の雨"
        case .snowSlight: return "小雪"
        case .snowModerate: return "雪"
        case .snowHeavy: return "大雪"
        case .snowGrains: return "雪粒"
        case .rainShowersSlight: return "軽いにわか雨"
        case .rainShowersModerate: return "にわか雨"
        case .rainShowersViolent: return "強いにわか雨"
        case .snowShowersSlight: return "軽いにわか雪"
        case .snowShowersHeavy: return "にわか雪"
        case .thunderstormSlight: return "雷雨"
        case .thunderstormWithHail: return "雹を伴う雷雨"
        case .thunderstormWithHeavyHail: return "強い雹を伴う雷雨"
        }
    }
    
    var symbolName: String {
        switch self {
        case .clearSky: return "sun.max.fill"
        case .mainlyClear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .overcast: return "cloud.fill"
        case .fog, .depositingRimeFog: return "cloud.fog.fill"
        case .drizzleLight, .drizzleModerate, .drizzleDense:
            return "cloud.drizzle.fill"
        case .freezingDrizzleLight, .freezingDrizzleDense:
            return "cloud.sleet.fill"
        case .rainSlight, .rainModerate:
            return "cloud.rain.fill"
        case .rainHeavy:
            return "cloud.heavyrain.fill"
        case .freezingRainLight, .freezingRainHeavy:
            return "cloud.sleet.fill"
        case .snowSlight, .snowModerate:
            return "cloud.snow.fill"
        case .snowHeavy:
            return "snowflake"
        case .snowGrains:
            return "cloud.snow.fill"
        case .rainShowersSlight, .rainShowersModerate, .rainShowersViolent:
            return "cloud.sun.rain.fill"
        case .snowShowersSlight, .snowShowersHeavy:
            return "cloud.snow.fill"
        case .thunderstormSlight:
            return "cloud.bolt.fill"
        case .thunderstormWithHail, .thunderstormWithHeavyHail:
            return "cloud.bolt.rain.fill"
        }
    }
    
    var color: String {
        switch self {
        case .clearSky, .mainlyClear:
            return "#FFD700"
        case .partlyCloudy:
            return "#87CEEB"
        case .overcast:
            return "#708090"
        case .fog, .depositingRimeFog:
            return "#B0C4DE"
        case .drizzleLight, .drizzleModerate, .drizzleDense,
             .rainSlight, .rainModerate, .rainHeavy:
            return "#4682B4"
        case .freezingDrizzleLight, .freezingDrizzleDense,
             .freezingRainLight, .freezingRainHeavy:
            return "#5F9EA0"
        case .snowSlight, .snowModerate, .snowHeavy, .snowGrains:
            return "#E0FFFF"
        case .rainShowersSlight, .rainShowersModerate, .rainShowersViolent:
            return "#87CEFA"
        case .snowShowersSlight, .snowShowersHeavy:
            return "#B0E0E6"
        case .thunderstormSlight, .thunderstormWithHail, .thunderstormWithHeavyHail:
            return "#483D8B"
        }
    }
    
    var gradientColors: [String] {
        switch self {
        case .clearSky, .mainlyClear:
            return ["#FFD700", "#FF8C00"]
        case .partlyCloudy:
            return ["#87CEEB", "#4682B4"]
        case .overcast:
            return ["#B0C4DE", "#708090"]
        case .fog, .depositingRimeFog:
            return ["#D3D3D3", "#A9A9A9"]
        case .drizzleLight, .drizzleModerate, .drizzleDense:
            return ["#B0C4DE", "#778899"]
        case .rainSlight, .rainModerate:
            return ["#4682B4", "#2F4F4F"]
        case .rainHeavy:
            return ["#1E90FF", "#000080"]
        case .freezingDrizzleLight, .freezingDrizzleDense,
             .freezingRainLight, .freezingRainHeavy:
            return ["#5F9EA0", "#2F4F4F"]
        case .snowSlight, .snowModerate, .snowHeavy, .snowGrains:
            return ["#E0FFFF", "#87CEEB"]
        case .rainShowersSlight, .rainShowersModerate, .rainShowersViolent:
            return ["#87CEFA", "#4682B4"]
        case .snowShowersSlight, .snowShowersHeavy:
            return ["#B0E0E6", "#87CEEB"]
        case .thunderstormSlight, .thunderstormWithHail, .thunderstormWithHeavyHail:
            return ["#483D8B", "#191970"]
        }
    }
}
