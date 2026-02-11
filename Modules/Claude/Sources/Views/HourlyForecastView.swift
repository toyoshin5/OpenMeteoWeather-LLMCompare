import SwiftUI
import Charts

struct HourlyForecastView: View {
    let hourly: HourlyForecast

    // Get next 24 hours of data
    private var next24Hours: [HourForecast] {
        Array(hourly.hours.prefix(24))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("24時間予報")
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
            HourlyTemperatureChart(hours: next24Hours)
                .frame(height: 200)
                .padding(.vertical, 8)

            // Horizontal scrolling forecast
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(next24Hours) { hour in
                        HourlyForecastCard(hour: hour)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
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

struct HourlyTemperatureChart: View {
    let hours: [HourForecast]

    var body: some View {
        Chart {
            ForEach(Array(hours.enumerated()), id: \.offset) { index, hour in
                // Temperature line
                LineMark(
                    x: .value("時間", index),
                    y: .value("気温", hour.temperature)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)

                // Area under the line
                AreaMark(
                    x: .value("時間", index),
                    y: .value("気温", hour.temperature)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange.opacity(0.3), .red.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                // Points
                if index % 3 == 0 {
                    PointMark(
                        x: .value("時間", index),
                        y: .value("気温", hour.temperature)
                    )
                    .foregroundStyle(.orange)
                    .symbolSize(60)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 3)) { value in
                if let index = value.as(Int.self), index < hours.count {
                    AxisValueLabel {
                        Text(hours[index].hourOnly)
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
    }
}

struct HourlyForecastCard: View {
    let hour: HourForecast

    private var condition: WeatherCondition {
        WeatherCondition(code: hour.weatherCode)
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
        VStack(spacing: 12) {
            // Time
            Text(hour.hourOnly)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

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
                    .frame(width: 50, height: 50)

                Image(systemName: condition.sfSymbol)
                    .font(.title3)
                    .foregroundStyle(iconColor)
            }

            // Temperature
            Text("\(Int(hour.temperature))°")
                .font(.headline)
                .fontWeight(.bold)

            // Precipitation
            if hour.precipitation > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text("\(Int(hour.precipitation))%")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
        }
        .frame(width: 70)
        .padding(.vertical, 12)
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

struct HourlyForecastView_Previews: PreviewProvider {
    static var previews: some View {
        HourlyForecastView(
            hourly: HourlyForecast(
                time: (0..<24).map { i in
                    let date = Calendar.current.date(byAdding: .hour, value: i, to: Date())!
                    let formatter = ISO8601DateFormatter()
                    return formatter.string(from: date)
                },
                temperature: [2, 1, 0, -1, -2, -1, 0, 1, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2, 1, 0, -1, -2, -1, 0],
                weatherCode: [0, 0, 1, 1, 2, 2, 3, 3, 61, 61, 3, 2, 1, 1, 2, 3, 3, 61, 61, 3, 2, 1, 1, 0],
                precipitation: [0, 0, 0, 5, 10, 15, 20, 30, 40, 50, 40, 30, 20, 10, 5, 0, 0, 10, 20, 15, 10, 5, 0, 0]
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
