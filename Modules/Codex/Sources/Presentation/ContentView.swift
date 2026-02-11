import SwiftUI

struct ContentView: View {
    private let screenTitle: String
    @StateObject private var viewModel: WeatherViewModel

    @MainActor
    init(screenTitle: String = "Sapporo Weather") {
        self.screenTitle = screenTitle
        _viewModel = StateObject(wrappedValue: WeatherViewModel(service: OpenMeteoService()))
    }

    @MainActor
    init(screenTitle: String, viewModel: WeatherViewModel) {
        self.screenTitle = screenTitle
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                content
            }
            .navigationTitle(screenTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .labelStyle(.iconOnly)
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private var content: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                loadingView
            case .failed(let message):
                errorView(message: message)
            case .loaded(let weather):
                dashboard(weather)
            }
        }
    }

    private var backgroundGradient: LinearGradient {
        switch viewModel.state {
        case .loaded(let weather):
            if weather.current.isDay {
                return LinearGradient(
                    colors: [
                        Color(red: 0.11, green: 0.35, blue: 0.69),
                        Color(red: 0.16, green: 0.57, blue: 0.85),
                        Color(red: 0.53, green: 0.78, blue: 0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.08, blue: 0.19),
                        Color(red: 0.09, green: 0.15, blue: 0.30),
                        Color(red: 0.16, green: 0.21, blue: 0.41)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        default:
            return LinearGradient(
                colors: [Color(red: 0.12, green: 0.25, blue: 0.50), Color(red: 0.22, green: 0.48, blue: 0.76)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(.white)
            Text("天気データを取得中")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))
            Text("Open-Meteo API から札幌の最新情報を読み込んでいます")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(24)
        .background(cardBackground)
        .padding(.horizontal, 20)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.white)

            Text("読み込みに失敗しました")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Text(message)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.82))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            Button("再試行") {
                Task { await viewModel.load() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.blue)
        }
        .padding(24)
        .background(cardBackground)
        .padding(.horizontal, 20)
    }

    private func dashboard(_ weather: WeatherSnapshot) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                heroCard(weather)
                metricsGrid(weather)
                precipitationCard(weather)
                sunCard(weather)
                hourlyCard(weather)
                dailyCard(weather)
                locationCard(weather)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private func heroCard(_ weather: WeatherSnapshot) -> some View {
        let today = weather.dailyForecast.first
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(weather.cityName)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(weather.current.isDay ? "Daytime" : "Night")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.18), in: Capsule())
                        .foregroundStyle(.white)

                    Text("観測: \(formattedObservedAt(weather.observedAt, timezoneID: weather.timezone))")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                Image(systemName: WeatherCodeMapper.symbolName(for: weather.current.weatherCode, isDay: weather.current.isDay))
                    .font(.system(size: 58, weight: .medium))
                    .symbolRenderingMode(.multicolor)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(weather.current.temperature, specifier: "%.1f")")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(weather.units.temperature)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white.opacity(0.90))
            }

            Text(WeatherCodeMapper.description(for: weather.current.weatherCode))
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            HStack(spacing: 14) {
                infoPill(
                    title: "体感",
                    value: "\(formatNumber(weather.current.apparentTemperature)) \(weather.units.temperature)",
                    symbol: "thermometer.medium"
                )

                if let today {
                    infoPill(
                        title: "最高 / 最低",
                        value: "\(formatNumber(today.maxTemperature)) / \(formatNumber(today.minTemperature)) \(weather.units.temperature)",
                        symbol: "chart.line.uptrend.xyaxis"
                    )
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func metricsGrid(_ weather: WeatherSnapshot) -> some View {
        let today = weather.dailyForecast.first
        let metrics: [(String, String, String, String, Color)] = [
            (
                "湿度",
                "\(weather.current.humidity)%",
                "空気中の水分量",
                "humidity.fill",
                .cyan
            ),
            (
                "雲量",
                "\(weather.current.cloudCover)%",
                "空の被覆率",
                "cloud.fill",
                .indigo
            ),
            (
                "気圧",
                "\(formatNumber(weather.current.surfacePressure, digits: 0)) \(weather.units.pressure)",
                "海面更正気圧",
                "gauge.with.dots.needle.50percent",
                .orange
            ),
            (
                "UV最大",
                formatNumber(today?.uvIndexMax ?? 0),
                "今日の予測最大値",
                "sun.max.trianglebadge.exclamationmark",
                .yellow
            ),
            (
                "風速",
                "\(formatNumber(weather.current.windSpeed)) \(weather.units.windSpeed)",
                "\(WindDirectionMapper.compassLabel(for: weather.current.windDirection)) \(weather.current.windDirection)°",
                "wind",
                .mint
            ),
            (
                "最大瞬間風速",
                "\(formatNumber(weather.current.windGusts)) \(weather.units.windSpeed)",
                "現在の突風",
                "tornado",
                .pink
            )
        ]

        return LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                metricTile(
                    title: metric.0,
                    value: metric.1,
                    subtitle: metric.2,
                    symbol: metric.3,
                    tint: metric.4
                )
            }
        }
    }

    private func precipitationCard(_ weather: WeatherSnapshot) -> some View {
        let now = weather.current
        return VStack(alignment: .leading, spacing: 12) {
            Text("降水内訳")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                precipitationChip(title: "降水量", value: "\(formatNumber(now.precipitation)) \(weather.units.precipitation)")
                precipitationChip(title: "雨", value: formatNumber(now.rain))
                precipitationChip(title: "にわか雨", value: formatNumber(now.showers))
                precipitationChip(title: "降雪", value: formatNumber(now.snowfall))
            }

            if let today = weather.dailyForecast.first {
                Text("今日の降水確率最大: \(today.precipitationProbabilityMax)% / 降水量合計: \(today.precipitationSum, specifier: "%.1f") \(weather.units.precipitation)")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func sunCard(_ weather: WeatherSnapshot) -> some View {
        guard let today = weather.dailyForecast.first else {
            return AnyView(EmptyView())
        }

        let progress = daylightProgress(now: weather.observedAt, sunrise: today.sunrise, sunset: today.sunset)

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text("太陽と日照")
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(formattedHour(today.sunrise, timezoneID: weather.timezone), systemImage: "sunrise.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Text("日の出")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.74))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Label(formattedHour(today.sunset, timezoneID: weather.timezone), systemImage: "sunset.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Text("日の入")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.74))
                    }
                }

                ProgressView(value: progress)
                    .tint(.yellow)

                Text("日照進行: \(Int(progress * 100))%")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.84))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
        )
    }

    private func hourlyCard(_ weather: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("24時間予報")
                .font(.headline)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(weather.hourlyForecast) { hour in
                        VStack(spacing: 8) {
                            Text(formattedHour(hour.date, timezoneID: weather.timezone))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.82))

                            Image(systemName: WeatherCodeMapper.symbolName(for: hour.weatherCode, isDay: weather.current.isDay))
                                .font(.title3)
                                .symbolRenderingMode(.multicolor)

                            Text("\(hour.temperature, specifier: "%.0f")\(weather.units.temperature)")
                                .font(.callout.weight(.bold))
                                .foregroundStyle(.white)

                            Text("体感 \(hour.apparentTemperature, specifier: "%.0f")")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.76))

                            Text("☔︎\(hour.precipitationProbability)%  💧\(hour.humidity)%  🌬\(hour.windSpeed, specifier: "%.0f")")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.76))
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .frame(width: 106)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func dailyCard(_ weather: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7日間予報")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(Array(weather.dailyForecast.enumerated()), id: \.offset) { index, day in
                HStack(spacing: 12) {
                    Text(index == 0 ? "Today" : weekdayLabel(day.date, timezoneID: weather.timezone))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 58, alignment: .leading)

                    Image(systemName: WeatherCodeMapper.symbolName(for: day.weatherCode, isDay: true))
                        .symbolRenderingMode(.multicolor)
                        .frame(width: 24)

                    Text("\(day.minTemperature, specifier: "%.0f") / \(day.maxTemperature, specifier: "%.0f") \(weather.units.temperature)")
                        .font(.subheadline)
                        .foregroundStyle(.white)

                    Spacer(minLength: 8)

                    Text("☔︎\(day.precipitationProbabilityMax)%")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.82))

                    Text("💨\(day.windSpeedMax, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.82))

                    Text("突風\(day.windGustsMax, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.82))
                }

                if day.id != weather.dailyForecast.last?.id {
                    Divider()
                        .overlay(.white.opacity(0.16))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func locationCard(_ weather: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("観測地点")
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                Label("緯度 \(weather.latitude, specifier: "%.4f")", systemImage: "location.north.line.fill")
                Spacer()
                Label("経度 \(weather.longitude, specifier: "%.4f")", systemImage: "location.east.line.fill")
            }
            .font(.subheadline)
            .foregroundStyle(.white)

            HStack {
                Label("標高 \(weather.elevation, specifier: "%.0f") m", systemImage: "mountain.2.fill")
                Spacer()
                Label(weather.timezone, systemImage: "globe.asia.australia.fill")
            }
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.86))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func metricTile(
        title: String,
        value: String,
        subtitle: String,
        symbol: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardBackground)
    }

    private func infoPill(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
            Text(value)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func precipitationChip(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.74))
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 10)
    }

    private func formattedObservedAt(_ date: Date, timezoneID: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: timezoneID)
        formatter.dateFormat = "M/d HH:mm"
        return formatter.string(from: date)
    }

    private func formattedHour(_ date: Date, timezoneID: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: timezoneID)
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func weekdayLabel(_ date: Date, timezoneID: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: timezoneID)
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func daylightProgress(now: Date, sunrise: Date, sunset: Date) -> Double {
        let total = sunset.timeIntervalSince(sunrise)
        guard total > 0 else { return 0 }

        let elapsed = now.timeIntervalSince(sunrise)
        let normalized = elapsed / total
        return min(max(normalized, 0), 1)
    }

    private func formatNumber(_ value: Double, digits: Int = 1) -> String {
        String(format: "%.\(digits)f", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}
