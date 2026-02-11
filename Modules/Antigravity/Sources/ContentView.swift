import SwiftUI

struct ContentView: View {
    @StateObject private var weatherService = WeatherService()

    var body: some View {
        ZStack {
            // Dynamic Background
            BackgroundView(
                isDay: weatherService.weather?.current.isDay ?? 1,
                weatherCode: weatherService.weather?.current.weatherCode ?? 0)

            if let weather = weatherService.weather {
                ScrollView {
                    VStack(spacing: 20) {
                        // Current Weather Header
                        CurrentWeatherHeader(current: weather.current, daily: weather.daily)

                        // Hourly Forecast
                        HourlyForecastView(hourly: weather.hourly)

                        // Daily Forecast
                        DailyForecastView(daily: weather.daily)

                        // Details Grid
                        WeatherDetailsGrid(current: weather.current)
                    }
                    .padding()
                }
            } else if let errorMessage = weatherService.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                    Text(errorMessage)
                        .foregroundStyle(.white)
                        .padding()
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }
        }
        .task {
            await weatherService.fetchWeather()
        }
    }
}

// MARK: - Subviews

struct BackgroundView: View {
    let isDay: Int
    let weatherCode: Int

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    var gradientColors: [Color] {
        if isDay == 1 {
            // Day
            switch weatherCode {
            case 0, 1: return [.blue, .cyan]
            case 2, 3: return [.gray, .blue]
            case 61...67, 80...82: return [.gray, .blue.opacity(0.6)]
            default: return [.blue, .teal]
            }
        } else {
            // Night
            return [.black, .blue.opacity(0.4)]
        }
    }
}

struct CurrentWeatherHeader: View {
    let current: CurrentWeather
    let daily: DailyWeather

    var body: some View {
        VStack(spacing: 5) {
            Text("Sapporo")
                .font(.largeTitle)
                .fontWeight(.medium)
                .foregroundStyle(.white)

            Text("\(Int(current.temperature2m))°")
                .font(.system(size: 96, weight: .thin))
                .foregroundStyle(.white)

            Text(WeatherDescription.description(for: current.weatherCode))
                .font(.title3)
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 12) {
                Text("H: \(Int(daily.temperature2mMax.first ?? 0))°")
                Text("L: \(Int(daily.temperature2mMin.first ?? 0))°")
            }
            .font(.title3)
            .foregroundStyle(.white)
        }
        .padding(.top, 40)
        .shadow(radius: 4)
    }
}

struct HourlyForecastView: View {
    let hourly: HourlyWeather

    var body: some View {
        VStack(alignment: .leading) {
            Text("HOURLY FORECAST")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(0..<24, id: \.self) { index in
                        if index < hourly.time.count {
                            HourlyCell(
                                time: hourly.time[index],
                                temp: hourly.temperature2m[index],
                                code: hourly.weatherCode[index]
                            )
                        }
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            .cornerRadius(15)
        }
    }
}

struct HourlyCell: View {
    let time: String
    let temp: Double
    let code: Int

    var formattedTime: String {
        // Simple extraction of HH:mm from ISO string
        let components = time.split(separator: "T")
        if components.count > 1 {
            return String(components[1])
        }
        return time
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(formattedTime)
                .font(.subheadline)
                .foregroundStyle(.white)

            Image(systemName: WeatherDescription.icon(for: code))
                .symbolRenderingMode(.multicolor)
                .font(.title2)

            Text("\(Int(temp))°")
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
}

struct DailyForecastView: View {
    let daily: DailyWeather

    var body: some View {
        VStack(alignment: .leading) {
            Text("7-DAY FORECAST")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.leading)

            VStack(spacing: 0) {
                ForEach(0..<min(7, daily.time.count), id: \.self) { index in
                    DailyRow(
                        day: daily.time[index],
                        code: daily.weatherCode[index],
                        minTemp: daily.temperature2mMin[index],
                        maxTemp: daily.temperature2mMax[index]
                    )

                    if index < min(7, daily.time.count) - 1 {
                        Divider().background(.white.opacity(0.2))
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(15)
        }
    }
}

struct DailyRow: View {
    let day: String
    let code: Int
    let minTemp: Double
    let maxTemp: Double

    var dayName: String {
        // Format date string to day name if possible, otherwise use date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: day) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
        return day
    }

    var body: some View {
        HStack {
            Text(dayName)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 100, alignment: .leading)

            Spacer()

            Image(systemName: WeatherDescription.icon(for: code))
                .symbolRenderingMode(.multicolor)
                .font(.title3)

            Spacer()

            HStack(spacing: 8) {
                Text("\(Int(minTemp))°")
                    .foregroundStyle(.white.opacity(0.6))

                // Simple bar visual
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .yellow], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: 100, height: 4)

                Text("\(Int(maxTemp))°")
                    .foregroundStyle(.white)
            }
        }
        .padding(.vertical, 8)
    }
}

struct WeatherDetailsGrid: View {
    let current: CurrentWeather

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            DetailCell(
                title: "Feels Like", value: "\(Int(current.apparentTemperature))°",
                icon: "thermometer")
            DetailCell(title: "Humidity", value: "\(current.relativeHumidity2m)%", icon: "humidity")
            DetailCell(title: "Wind", value: "\(Int(current.windSpeed10m)) km/h", icon: "wind")
            DetailCell(title: "Pressure", value: "\(Int(current.pressureMsl)) hPa", icon: "gauge")
            DetailCell(title: "Cloud Cover", value: "\(current.cloudCover)%", icon: "cloud")
            DetailCell(title: "UV Index", value: "Low", icon: "sun.max")  // UV is daily, just placeholder or use max
        }
    }
}

struct DetailCell: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.6))

            Text(value)
                .font(.title2)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
}
