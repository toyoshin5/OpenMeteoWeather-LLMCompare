import Foundation
import SwiftUI

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var weather: WeatherResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDay: Int = 0
    
    private let weatherService = WeatherService.shared
    
    // MARK: - Current Weather Properties
    
    var currentWeatherCode: WeatherCode? {
        guard let code = weather?.currentWeather.weathercode else { return nil }
        return WeatherCode(rawValue: code)
    }
    
    var currentTemperature: String {
        guard let temp = weather?.currentWeather.temperature else { return "--" }
        return String(format: "%.1f", temp)
    }
    
    var currentWindSpeed: String {
        guard let speed = weather?.currentWeather.windspeed else { return "--" }
        return String(format: "%.1f", speed)
    }
    
    var currentWindDirection: String {
        guard let direction = weather?.currentWeather.winddirection else { return "--" }
        return windDirectionFromDegrees(direction)
    }
    
    var currentHumidity: String {
        guard let hourly = weather?.hourly else { return "--" }
        let index = getCurrentHourIndex(from: hourly.time)
        guard index < hourly.relativehumidity2m.count else { return "--" }
        return "\(hourly.relativehumidity2m[index])"
    }
    
    var currentApparentTemperature: String {
        guard let hourly = weather?.hourly else { return "--" }
        let index = getCurrentHourIndex(from: hourly.time)
        guard index < hourly.apparentTemperature.count else { return "--" }
        return String(format: "%.1f", hourly.apparentTemperature[index])
    }
    
    var currentDewPoint: String {
        // Approximate dew point calculation
        guard let temp = Double(currentTemperature),
              let humidity = Double(currentHumidity) else { return "--" }
        let dewPoint = temp - ((100 - humidity) / 5)
        return String(format: "%.1f", dewPoint)
    }
    
    var currentPressure: String {
        guard let hourly = weather?.hourly else { return "--" }
        let index = getCurrentHourIndex(from: hourly.time)
        guard index < hourly.surfacePressure.count else { return "--" }
        return String(format: "%.0f", hourly.surfacePressure[index])
    }
    
    var pressureTrend: String {
        guard let hourly = weather?.hourly else { return "--" }
        let currentIndex = getCurrentHourIndex(from: hourly.time)
        guard currentIndex > 0 && currentIndex < hourly.surfacePressure.count else { return "安定" }
        
        let diff = hourly.surfacePressure[currentIndex] - hourly.surfacePressure[currentIndex - 1]
        if diff > 1 { return "上昇" }
        if diff < -1 { return "下降" }
        return "安定"
    }
    
    var currentVisibility: String {
        guard let hourly = weather?.hourly else { return "--" }
        let index = getCurrentHourIndex(from: hourly.time)
        guard index < hourly.visibility.count else { return "--" }
        return String(format: "%.1f", hourly.visibility[index] / 1000)
    }
    
    var currentPrecipitation: String {
        guard let hourly = weather?.hourly else { return "--" }
        let index = getCurrentHourIndex(from: hourly.time)
        guard index < hourly.precipitation.count else { return "--" }
        return String(format: "%.1f", hourly.precipitation[index])
    }
    
    var currentWindGusts: String {
        guard let hourly = weather?.hourly else { return "--" }
        let index = getCurrentHourIndex(from: hourly.time)
        guard index < hourly.windgusts10m.count else { return "--" }
        return String(format: "%.1f", hourly.windgusts10m[index])
    }
    
    var currentCloudCover: String {
        guard let hourly = weather?.hourly else { return "--" }
        let index = getCurrentHourIndex(from: hourly.time)
        guard index < hourly.cloudcover.count else { return "--" }
        return "\(hourly.cloudcover[index])"
    }
    
    var cloudCoverDescription: String {
        guard let cover = Int(currentCloudCover) else { return "不明" }
        switch cover {
        case 0...10: return "快晴"
        case 11...30: return "晴れ"
        case 31...60: return "曇りがち"
        case 61...90: return "曇り"
        default: return "真っ暗"
        }
    }
    
    var currentUVIndex: String {
        guard let daily = weather?.daily else { return "--" }
        guard !daily.uvIndexMax.isEmpty else { return "--" }
        return String(format: "%.1f", daily.uvIndexMax[0])
    }
    
    var uvIndexDescription: String {
        guard let uv = Double(currentUVIndex) else { return "不明" }
        switch uv {
        case 0...2: return "低い"
        case 3...5: return "中程度"
        case 6...7: return "高い"
        case 8...10: return "非常に高い"
        default: return "極端"
        }
    }
    
    // MARK: - Air Quality
    
    var airQualityIndex: Int {
        // Simulated AQI calculation based on weather conditions
        guard let code = currentWeatherCode else { return 50 }
        switch code {
        case .clearSky, .mainlyClear: return 30
        case .partlyCloudy: return 45
        case .overcast: return 60
        case .fog, .depositingRimeFog: return 80
        case .drizzleLight, .drizzleModerate: return 40
        case .rainSlight, .rainModerate: return 25
        case .rainHeavy: return 20
        case .snowSlight, .snowModerate: return 35
        case .thunderstormSlight: return 45
        default: return 55
        }
    }
    
    var airQualityDescription: String {
        switch airQualityIndex {
        case 0...50: return "良好"
        case 51...100: return "普通"
        case 101...150: return "軽度汚染"
        case 151...200: return "中度汚染"
        default: return "重度汚染"
        }
    }
    
    var airQualityColor: Color {
        switch airQualityIndex {
        case 0...50: return .green
        case 51...100: return .yellow
        case 101...150: return .orange
        case 151...200: return .red
        default: return .purple
        }
    }
    
    var pm25: String { return String(format: "%.1f", Double(airQualityIndex) * 0.3) }
    var pm10: String { return String(format: "%.1f", Double(airQualityIndex) * 0.5) }
    var o3: String { return String(format: "%.1f", Double(airQualityIndex) * 0.8) }
    var no2: String { return String(format: "%.1f", Double(airQualityIndex) * 0.4) }
    
    // MARK: - Sun & Moon
    
    var daylightHours: String {
        guard let daily = weather?.daily,
              daily.time.count > 0 else { return "--" }
        
        let sunrise = daily.sunrise[0]
        let sunset = daily.sunset[0]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        
        guard let rise = formatter.date(from: sunrise),
              let set = formatter.date(from: sunset) else { return "--" }
        
        let hours = set.timeIntervalSince(rise) / 3600
        return String(format: "%.1f", hours)
    }
    
    var moonrise: String { return "18:30" }
    var moonset: String { return "06:15" }
    
    var moonPhaseIcon: String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        switch day % 30 {
        case 0...2: return "moon.fill"
        case 3...7: return "moonphase.waxing.crescent"
        case 8...10: return "moonphase.first.quarter"
        case 11...15: return "moonphase.waxing.gibbous"
        case 16...18: return "moon.fill"
        case 19...23: return "moonphase.waning.gibbous"
        case 24...26: return "moonphase.last.quarter"
        default: return "moonphase.waning.crescent"
        }
    }
    
    var moonPhaseDescription: String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        switch day % 30 {
        case 0...2: return "新月"
        case 3...7: return "三日月"
        case 8...10: return "上弦の月"
        case 11...15: return "十三夜"
        case 16...18: return "満月"
        case 19...23: return "十八夜"
        case 24...26: return "下弦の月"
        default: return "二十六夜"
        }
    }
    
    // MARK: - Hourly Forecasts
    
    var hourlyForecasts: [(time: String, temp: Double, code: WeatherCode?, pop: Int, humidity: Int, apparentTemp: Double)] {
        guard let hourly = weather?.hourly else { return [] }
        
        let now = Date()
        let calendar = Calendar.current
        var forecasts: [(time: String, temp: Double, code: WeatherCode?, pop: Int, humidity: Int, apparentTemp: Double)] = []
        
        for i in 0..<min(24, hourly.time.count) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            
            if let date = dateFormatter.date(from: hourly.time[i]),
               date >= now || calendar.isDate(date, inSameDayAs: now) {
                let code = WeatherCode(rawValue: hourly.weathercode[i])
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let timeString = timeFormatter.string(from: date)
                
                forecasts.append((
                    time: timeString,
                    temp: hourly.temperature2m[i],
                    code: code,
                    pop: hourly.precipitationProbability[i],
                    humidity: hourly.relativehumidity2m[i],
                    apparentTemp: hourly.apparentTemperature[i]
                ))
            }
        }
        
        return Array(forecasts.prefix(24))
    }
    
    // MARK: - Daily Forecasts
    
    var dailyForecasts: [DailyForecast] {
        guard let daily = weather?.daily else { return [] }
        
        var forecasts: [DailyForecast] = []
        
        for i in 0..<daily.time.count {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            if let date = dateFormatter.date(from: daily.time[i]) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "M/d (EEE)"
                displayFormatter.locale = Locale(identifier: "ja_JP")
                let dateString = displayFormatter.string(from: date)
                
                let code = WeatherCode(rawValue: daily.weathercode[i])
                
                let sunriseDisplay = String(daily.sunrise[i].suffix(5))
                let sunsetDisplay = String(daily.sunset[i].suffix(5))
                
                forecasts.append(DailyForecast(
                    date: dateString,
                    maxTemp: daily.temperature2mMax[i],
                    minTemp: daily.temperature2mMin[i],
                    code: code,
                    sunrise: sunriseDisplay,
                    sunset: sunsetDisplay,
                    precipitationSum: daily.precipitationSum[i],
                    popMax: daily.precipitationProbabilityMax[i],
                    uvIndex: daily.uvIndexMax[i],
                    windMax: daily.windspeed10mMax[i],
                    windGustMax: daily.windgusts10mMax[i]
                ))
            }
        }
        
        return forecasts
    }
    
    // MARK: - Temperature Data for Chart
    
    var temperatureChartData: [(hour: String, temp: Double)] {
        return hourlyForecasts.map { (hour: $0.time, temp: $0.temp) }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentHourIndex(from times: [String]) -> Int {
        let now = Date()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        
        for (index, timeString) in times.enumerated() {
            if let date = formatter.date(from: timeString),
               calendar.isDate(date, inSameDayAs: now) {
                let hour = calendar.component(.hour, from: date)
                let currentHour = calendar.component(.hour, from: now)
                if hour == currentHour {
                    return index
                }
            }
        }
        return 0
    }
    
    private func windDirectionFromDegrees(_ degrees: Double) -> String {
        let directions = ["北", "北北東", "北東", "東北東", "東", "東南東", "南東", "南南東",
                         "南", "南南西", "南西", "西南西", "西", "西北西", "北西", "北北西"]
        let index = Int(round(degrees / 22.5)) % 16
        return directions[index]
    }
    
    func fetchWeather() async {
        isLoading = true
        errorMessage = nil
        
        do {
            weather = try await weatherService.fetchSapporoWeather()
        } catch let error as WeatherError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "予期しないエラーが発生しました"
        }
        
        isLoading = false
    }
}

// MARK: - Daily Forecast Model

struct DailyForecast: Identifiable {
    let id = UUID()
    let date: String
    let maxTemp: Double
    let minTemp: Double
    let code: WeatherCode?
    let sunrise: String
    let sunset: String
    let precipitationSum: Double
    let popMax: Int
    let uvIndex: Double
    let windMax: Double
    let windGustMax: Double
}
