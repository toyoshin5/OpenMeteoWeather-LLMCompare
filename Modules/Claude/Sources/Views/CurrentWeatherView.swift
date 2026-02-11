import SwiftUI

struct CurrentWeatherView: View {
    let current: CurrentWeather

    private var condition: WeatherCondition {
        WeatherCondition(code: current.weatherCode)
    }

    private var backgroundColor: Color {
        switch condition.color {
        case "yellow": return .yellow
        case "orange": return .orange
        case "gray": return .gray
        case "blue": return .blue
        case "cyan": return .cyan
        case "purple": return .purple
        default: return .gray
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Weather Icon & Condition
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [backgroundColor.opacity(0.3), backgroundColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)

                Image(systemName: condition.sfSymbol)
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [backgroundColor, backgroundColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: backgroundColor.opacity(0.3), radius: 10, y: 5)
                }

                Text(condition.description)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(.top, 8)

            // Temperature
            HStack(alignment: .top, spacing: 4) {
                Text(String(format: "%.1f", current.temperature))
                    .font(.system(size: 80, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("°C")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)
            }

            // Feels like temperature
            Text("体感 \(String(format: "%.1f", current.apparentTemperature))°C")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                }

            // Main Info Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                WeatherInfoCard(
                    icon: "humidity.fill",
                    value: "\(current.humidity)%",
                    label: "湿度",
                    color: .blue
                )

                WeatherInfoCard(
                    icon: "wind",
                    value: String(format: "%.1f m/s", current.windSpeed),
                    label: "風速",
                    color: .cyan
                )

                WeatherInfoCard(
                    icon: "gauge.with.dots.needle.bottom.50percent",
                    value: String(format: "%.0f hPa", current.pressure),
                    label: "気圧",
                    color: .purple
                )

                WeatherInfoCard(
                    icon: "eye.fill",
                    value: String(format: "%.1f km", current.visibility / 1000),
                    label: "視程",
                    color: .green
                )

                WeatherInfoCard(
                    icon: "sun.max.fill",
                    value: String(format: "%.1f", current.uvIndex),
                    label: "UV指数",
                    color: .orange
                )

                WeatherInfoCard(
                    icon: "drop.fill",
                    value: String(format: "%.1f mm", current.precipitation),
                    label: "降水量",
                    color: .blue
                )
            }
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background {
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 32)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

struct WeatherInfoCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        }
    }
}

struct CurrentWeatherView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentWeatherView(
            current: CurrentWeather(
                time: "2024-01-01T12:00",
                temperature: -2.5,
                weatherCode: 3,
                humidity: 75,
                windSpeed: 3.2,
                apparentTemperature: -5.0,
                pressure: 1013.25,
                visibility: 10000,
                uvIndex: 2.5,
                precipitation: 0.5
            )
        )
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
