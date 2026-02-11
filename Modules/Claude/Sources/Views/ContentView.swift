import SwiftUI

struct ContentView: View {
    let screenTitle: String
    @StateObject private var weatherService = WeatherService()
    @State private var showError = false

    init(screenTitle: String = "札幌の天気") {
        self.screenTitle = screenTitle
    }

    private var backgroundGradient: LinearGradient {
        guard let weatherData = weatherService.weatherData,
              let current = weatherData.current else {
            return LinearGradient(
                colors: [
                    Color.blue.opacity(0.6),
                    Color.cyan.opacity(0.4),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        let condition = WeatherCondition(code: current.weatherCode)
        let colors: [Color]

        switch condition {
        case .clearSky, .mainlyClear:
            colors = [
                Color(red: 0.4, green: 0.7, blue: 1.0),
                Color(red: 0.5, green: 0.8, blue: 1.0),
                Color.white
            ]
        case .partlyCloudy:
            colors = [
                Color(red: 0.5, green: 0.6, blue: 0.8),
                Color(red: 0.6, green: 0.7, blue: 0.9),
                Color.white.opacity(0.9)
            ]
        case .overcast, .fog:
            colors = [
                Color.gray.opacity(0.5),
                Color.gray.opacity(0.3),
                Color.white.opacity(0.8)
            ]
        case .rain, .drizzle:
            colors = [
                Color(red: 0.3, green: 0.4, blue: 0.6),
                Color(red: 0.4, green: 0.5, blue: 0.7),
                Color.gray.opacity(0.4)
            ]
        case .snow:
            colors = [
                Color.cyan.opacity(0.4),
                Color.blue.opacity(0.2),
                Color.white
            ]
        case .thunderstorm:
            colors = [
                Color.purple.opacity(0.5),
                Color.gray.opacity(0.5),
                Color.gray.opacity(0.3)
            ]
        case .unknown:
            colors = [
                Color.blue.opacity(0.6),
                Color.cyan.opacity(0.4),
                Color.white
            ]
        }

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated Background
                backgroundGradient
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.0), value: weatherService.weatherData?.current?.weatherCode)

                if weatherService.isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text("読み込み中...")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 5)
                    }
                } else if let weatherData = weatherService.weatherData {
                    ScrollView {
                        VStack(spacing: 28) {
                            // Location Header
                            VStack(spacing: 6) {
                                HStack(spacing: 8) {
                                    Image(systemName: "location.fill")
                                        .font(.title3)
                                        .foregroundStyle(.white)

                                    Text("札幌市")
                                        .font(.system(size: 34, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .shadow(color: .black.opacity(0.2), radius: 3)

                                Text("Sapporo, Hokkaido")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.2), radius: 2)
                            }
                            .padding(.top, 8)

                            // Current Weather
                            if let current = weatherData.current {
                                CurrentWeatherView(current: current)
                                    .padding(.horizontal, 20)
                                    .transition(.scale.combined(with: .opacity))
                            }

                            // Hourly Forecast
                            if let hourly = weatherData.hourly {
                                HourlyForecastView(hourly: hourly)
                                    .padding(.horizontal, 20)
                                    .transition(.scale.combined(with: .opacity))
                            }

                            // Weekly Forecast
                            if let daily = weatherData.daily {
                                WeeklyForecastView(daily: daily)
                                    .padding(.horizontal, 20)
                                    .transition(.scale.combined(with: .opacity))
                            }

                            // Footer
                            HStack(spacing: 6) {
                                Image(systemName: "cloud.fill")
                                    .font(.caption2)
                                Text("Powered by Open-Meteo API")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 20)
                        }
                        .padding(.vertical)
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "cloud.slash")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.2), radius: 5)

                        Text("天気情報を取得できません")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.2), radius: 3)

                        Button {
                            Task {
                                await weatherService.fetchWeather()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("再読み込み")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            }
                        }
                    }
                }
            }
            .navigationTitle(screenTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await weatherService.fetchWeather()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                            .shadow(color: .black.opacity(0.2), radius: 2)
                    }
                    .disabled(weatherService.isLoading)
                }
            }
            .task {
                await weatherService.fetchWeather()
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") {
                    showError = false
                }
                Button("再試行") {
                    Task {
                        await weatherService.fetchWeather()
                    }
                }
            } message: {
                Text(weatherService.errorMessage ?? "不明なエラーが発生しました")
            }
            .onChange(of: weatherService.errorMessage) { newValue in
                if newValue != nil {
                    showError = true
                }
            }
        }
    }
}

struct ClaudeContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
