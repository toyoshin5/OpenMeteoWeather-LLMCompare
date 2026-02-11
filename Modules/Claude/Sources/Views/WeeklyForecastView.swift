import SwiftUI
import Charts

struct WeeklyForecastView: View {
    let daily: DailyForecast

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("週間予報")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Temperature Chart
            TemperatureChart(days: daily.days)
                .frame(height: 200)
                .padding(.vertical, 8)

            // Daily Forecast List
            VStack(spacing: 12) {
                ForEach(daily.days) { day in
                    DailyForecastRow(day: day)
                }
            }
        }
        .padding()
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

struct TemperatureChart: View {
    let days: [DayForecast]

    var body: some View {
        Chart {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                // Max temperature line
                LineMark(
                    x: .value("日付", index),
                    y: .value("最高気温", day.maxTemp)
                )
                .foregroundStyle(.red)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
                .symbol {
                    Circle()
                        .fill(.red)
                        .frame(width: 10, height: 10)
                }

                // Min temperature line
                LineMark(
                    x: .value("日付", index),
                    y: .value("最低気温", day.minTemp)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
                .symbol {
                    Circle()
                        .fill(.blue)
                        .frame(width: 10, height: 10)
                }

                // Area between max and min
                AreaMark(
                    x: .value("日付", index),
                    yStart: .value("最低気温", day.minTemp),
                    yEnd: .value("最高気温", day.maxTemp)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red.opacity(0.15), .blue.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: days.count)) { value in
                if let index = value.as(Int.self), index < days.count {
                    let dateString = days[index].dateFormatted
                    AxisValueLabel {
                        Text(dateString)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisValueLabel {
                    if let temp = value.as(Double.self) {
                        Text("\(Int(temp))°")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartLegend(position: .top, alignment: .trailing) {
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text("最高")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 6) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                    Text("最低")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

struct DailyForecastRow: View {
    let day: DayForecast
    @State private var isExpanded = false

    private var condition: WeatherCondition {
        WeatherCondition(code: day.weatherCode)
    }

    private var iconColor: Color {
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
        VStack(spacing: 0) {
            // Main Row
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 16) {
                    // Date
                    Text(day.dateFormatted)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(width: 90, alignment: .leading)

                    // Weather Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [iconColor.opacity(0.2), iconColor.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)

                        Image(systemName: condition.sfSymbol)
                            .font(.title3)
                            .foregroundStyle(iconColor)
                    }

                    // Condition
                    Text(condition.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 90, alignment: .leading)

                    Spacer()

                    // Temperature Range
                    HStack(spacing: 8) {
                        Text("\(Int(day.minTemp))°")
                            .foregroundStyle(.blue)
                            .fontWeight(.semibold)

                        // Temperature bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.blue.opacity(0.2))
                                    .frame(height: 4)

                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .orange, .red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * 0.7, height: 4)
                            }
                        }
                        .frame(width: 40)

                        Text("\(Int(day.maxTemp))°")
                            .foregroundStyle(.red)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)

                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)

            // Expanded Details
            if isExpanded {
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal)

                    HStack(spacing: 16) {
                        // Sunrise/Sunset
                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "sunrise.fill")
                                    .foregroundStyle(.orange)
                                Text(day.sunriseFormatted)
                                    .font(.caption)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "sunset.fill")
                                    .foregroundStyle(.purple)
                                Text(day.sunsetFormatted)
                                    .font(.caption)
                            }
                        }

                        Divider()
                            .frame(height: 40)

                        // Precipitation
                        VStack(spacing: 4) {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(.blue)
                            Text("\(day.precipitationProbability)%")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("降水確率")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Divider()
                            .frame(height: 40)

                        // UV Index
                        VStack(spacing: 4) {
                            Image(systemName: "sun.max.fill")
                                .foregroundStyle(.orange)
                            Text(String(format: "%.1f", day.uvIndexMax))
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("UV指数")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(iconColor.opacity(0.2), lineWidth: 1)
        }
    }
}

struct WeeklyForecastView_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyForecastView(
            daily: DailyForecast(
                time: [
                    "2024-01-01", "2024-01-02", "2024-01-03",
                    "2024-01-04", "2024-01-05", "2024-01-06", "2024-01-07"
                ],
                weatherCode: [0, 1, 2, 3, 61, 71, 95],
                temperatureMax: [5.0, 6.0, 4.0, 3.0, 2.0, 1.0, 4.0],
                temperatureMin: [-3.0, -2.0, -4.0, -5.0, -6.0, -7.0, -3.0],
                sunrise: [
                    "2024-01-01T07:06:00+09:00", "2024-01-02T07:06:00+09:00",
                    "2024-01-03T07:06:00+09:00", "2024-01-04T07:06:00+09:00",
                    "2024-01-05T07:07:00+09:00", "2024-01-06T07:07:00+09:00",
                    "2024-01-07T07:07:00+09:00"
                ],
                sunset: [
                    "2024-01-01T16:10:00+09:00", "2024-01-02T16:11:00+09:00",
                    "2024-01-03T16:12:00+09:00", "2024-01-04T16:13:00+09:00",
                    "2024-01-05T16:14:00+09:00", "2024-01-06T16:15:00+09:00",
                    "2024-01-07T16:16:00+09:00"
                ],
                precipitationProbability: [10, 20, 30, 50, 70, 80, 60],
                uvIndexMax: [2.5, 3.0, 2.0, 1.5, 1.0, 0.5, 2.0]
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
