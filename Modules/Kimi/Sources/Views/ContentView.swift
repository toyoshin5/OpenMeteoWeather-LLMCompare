import SwiftUI

struct ContentView: View {
    let screenTitle: String
    @StateObject private var viewModel = WeatherViewModel()
    @State private var selectedDayIndex = 0
    @State private var showAllHours = false

    init(screenTitle: String = "札幌の天気") {
        self.screenTitle = screenTitle
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(weatherCode: viewModel.currentWeatherCode)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if viewModel.isLoading {
                            LoadingView()
                        } else if let error = viewModel.errorMessage {
                            ErrorView(message: error, retryAction: {
                                Task { await viewModel.fetchWeather() }
                            })
                        } else if viewModel.weather != nil {
                            CurrentWeatherSection(viewModel: viewModel)
                            
                            WeatherDetailsSection(viewModel: viewModel)
                            
                            HourlyForecastSection(
                                viewModel: viewModel,
                                showAllHours: $showAllHours
                            )
                            
                            DailyForecastSection(
                                viewModel: viewModel,
                                selectedIndex: $selectedDayIndex
                            )
                            
                            DetailedDayInfo(viewModel: viewModel, selectedIndex: selectedDayIndex)
                            
                            AirQualitySection(viewModel: viewModel)
                            
                            SunMoonSection(viewModel: viewModel, selectedIndex: selectedDayIndex)
                        } else {
                            EmptyStateView()
                        }
                    }
                    .padding(.vertical, 20)
                }
                .refreshable {
                    await viewModel.fetchWeather()
                }
            }
            .navigationTitle(screenTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    RefreshButton(viewModel: viewModel)
                }
            }
        }
        .task {
            await viewModel.fetchWeather()
        }
    }
}

// MARK: - Animated Background

struct AnimatedBackground: View {
    let weatherCode: WeatherCode?
    @State private var isAnimating = false
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.016, paused: false)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                // Base gradient
                let gradient = Gradient(colors: backgroundColors)
                let rect = CGRect(origin: .zero, size: size)
                context.fill(Path(rect), with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: size.height)
                ))
                
                // Animated orbs
                for i in 0..<3 {
                    let offset = CGFloat(i) * 2.0
                    let x = size.width * 0.5 + cos(time + offset) * size.width * 0.3
                    let y = size.height * 0.5 + sin(time * 0.7 + offset) * size.height * 0.3
                    let orbSize: CGFloat = 200 + CGFloat(i) * 50
                    
                    var orbPath = Path()
                    orbPath.addEllipse(in: CGRect(
                        x: x - orbSize/2,
                        y: y - orbSize/2,
                        width: orbSize,
                        height: orbSize
                    ))
                    
                    context.fill(orbPath, with: .color(orbColors[i].opacity(0.3)))
                }
            }
        }
    }
    
    private var backgroundColors: [Color] {
        if let code = weatherCode {
            return code.gradientColors.map { colorFromHex($0) }
        }
        return [.blue.opacity(0.3), .purple.opacity(0.3)]
    }
    
    private var orbColors: [Color] {
        if let code = weatherCode {
            return [
                colorFromHex(code.color).opacity(0.5),
                colorFromHex(code.color).opacity(0.3),
                .white.opacity(0.2)
            ]
        }
        return [.blue, .purple, .pink]
    }
}

// MARK: - Current Weather Section

struct CurrentWeatherSection: View {
    @ObservedObject var viewModel: WeatherViewModel
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Weather Icon with animation
            ZStack {
                // Glow effect
                if let code = viewModel.currentWeatherCode {
                    Circle()
                        .fill(colorFromHex(code.color).opacity(0.3))
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                }
                
                if let code = viewModel.currentWeatherCode {
                    Image(systemName: code.symbolName)
                        .font(.system(size: 120))
                        .foregroundColor(colorFromHex(code.color))
                        .shadow(color: colorFromHex(code.color).opacity(0.5), radius: 20)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                }
            }
            .frame(height: 200)
            
            // Weather description
            if let code = viewModel.currentWeatherCode {
                Text(code.description)
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            // Main temperature
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(viewModel.currentTemperature)
                    .font(.system(size: 96, weight: .thin, design: .rounded))
                
                Text("°C")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.secondary)
                    .offset(y: -20)
            }
            
            // Feels like
            HStack(spacing: 8) {
                Image(systemName: "thermometer.medium")
                    .foregroundColor(.orange)
                Text("体感温度 \(viewModel.currentApparentTemperature)°C")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Wind info row
            HStack(spacing: 32) {
                WeatherMetricItem(
                    icon: "wind",
                    value: viewModel.currentWindSpeed,
                    unit: "km/h",
                    label: "風速"
                )
                
                Divider()
                    .frame(height: 40)
                
                WeatherMetricItem(
                    icon: "location.north",
                    value: viewModel.currentWindDirection,
                    unit: "",
                    label: "風向"
                )
                
                Divider()
                    .frame(height: 40)
                
                WeatherMetricItem(
                    icon: "tornado",
                    value: viewModel.currentWindGusts,
                    unit: "km/h",
                    label: "突風"
                )
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal)
        .onAppear {
            isAnimating = true
        }
    }
}

struct WeatherMetricItem: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                Text(value)
                    .font(.system(size: 22, weight: .semibold))
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Weather Details Section

struct WeatherDetailsSection: View {
    @ObservedObject var viewModel: WeatherViewModel
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            DetailCard(
                icon: "humidity.fill",
                iconColor: .cyan,
                title: "湿度",
                value: "\(viewModel.currentHumidity)%",
                subtitle: "露点 \(viewModel.currentDewPoint)°C"
            )
            
            DetailCard(
                icon: "gauge.with.dots.needle.67percent",
                iconColor: .orange,
                title: "気圧",
                value: "\(viewModel.currentPressure) hPa",
                subtitle: viewModel.pressureTrend
            )
            
            DetailCard(
                icon: "eye.fill",
                iconColor: .mint,
                title: "視程",
                value: "\(viewModel.currentVisibility) km",
                subtitle: "良好"
            )
            
            DetailCard(
                icon: "cloud.rain.fill",
                iconColor: .blue,
                title: "降水量",
                value: "\(viewModel.currentPrecipitation) mm",
                subtitle: "過去1時間"
            )
            
            DetailCard(
                icon: "cloud.fill",
                iconColor: .gray,
                title: "雲量",
                value: "\(viewModel.currentCloudCover)%",
                subtitle: viewModel.cloudCoverDescription
            )
            
            DetailCard(
                icon: "sparkles",
                iconColor: .yellow,
                title: "UV指数",
                value: viewModel.currentUVIndex,
                subtitle: viewModel.uvIndexDescription
            )
        }
        .padding(.horizontal)
    }
}

struct DetailCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.15))
                    .cornerRadius(12)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Hourly Forecast Section

struct HourlyForecastSection: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var showAllHours: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("24時間予報", systemImage: "clock")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAllHours.toggle()
                    }
                }) {
                    Text(showAllHours ? "折りたたむ" : "すべて表示")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            // Temperature Chart
            if !viewModel.hourlyForecasts.isEmpty {
                TemperatureChartView(data: viewModel.temperatureChartData)
                    .frame(height: 100)
                    .padding(.horizontal)
            }
            
            // Hourly list
            let forecasts = showAllHours ? viewModel.hourlyForecasts : Array(viewModel.hourlyForecasts.prefix(8))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(forecasts.indices, id: \.self) { index in
                        let forecast = forecasts[index]
                        HourlyCell(forecast: forecast, isNow: index == 0)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }
}

struct TemperatureChartView: View {
    let data: [(hour: String, temp: Double)]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let padding: CGFloat = 20
            
            let chartWidth = width - padding * 2
            let chartHeight = height - padding * 2
            
            let temps = data.map { $0.temp }
            let minTemp = temps.min() ?? 0
            let maxTemp = temps.max() ?? 1
            let tempRange = maxTemp - minTemp
            
            ZStack {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<3) { i in
                        HStack {
                            Divider()
                                .background(Color.secondary.opacity(0.2))
                        }
                        if i < 2 {
                            Spacer()
                        }
                    }
                }
                
                // Temperature line
                Path { path in
                    for (index, point) in data.enumerated() {
                        let x = padding + CGFloat(index) * (chartWidth / CGFloat(data.count - 1))
                        let normalizedTemp = tempRange > 0 ? (point.temp - minTemp) / tempRange : 0.5
                        let y = padding + chartHeight * (1 - CGFloat(normalizedTemp))
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 3
                )
                
                // Data points
                ForEach(data.indices, id: \.self) { index in
                    let point = data[index]
                    let x = padding + CGFloat(index) * (chartWidth / CGFloat(data.count - 1))
                    let normalizedTemp = tempRange > 0 ? (point.temp - minTemp) / tempRange : 0.5
                    let y = padding + chartHeight * (1 - CGFloat(normalizedTemp))
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.orange, lineWidth: 2)
                        )
                        .position(x: x, y: y)
                }
            }
        }
    }
}

struct HourlyCell: View {
    let forecast: (time: String, temp: Double, code: WeatherCode?, pop: Int, humidity: Int, apparentTemp: Double)
    let isNow: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Text(isNow ? "現在" : forecast.time)
                .font(.caption)
                .fontWeight(isNow ? .bold : .regular)
                .foregroundColor(isNow ? .accentColor : .secondary)
            
            if let code = forecast.code {
                Image(systemName: code.symbolName)
                    .font(.title2)
                    .foregroundColor(colorFromHex(code.color))
            }
            
            Text("\(String(format: "%.0f", forecast.temp))°")
                .font(.system(size: 18, weight: .semibold))
            
            if forecast.pop > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "umbrella.fill")
                        .font(.caption2)
                    Text("\(forecast.pop)%")
                        .font(.caption2)
                }
                .foregroundColor(.blue)
            }
            
            HStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.caption2)
                Text("\(forecast.humidity)%")
                    .font(.caption2)
            }
            .foregroundColor(.cyan)
        }
        .frame(width: 60)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isNow ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isNow ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Daily Forecast Section

struct DailyForecastSection: View {
    @ObservedObject var viewModel: WeatherViewModel
    @Binding var selectedIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("7日間予報", systemImage: "calendar")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(viewModel.dailyForecasts.indices, id: \.self) { index in
                    let forecast = viewModel.dailyForecasts[index]
                    DailyRow(
                        forecast: forecast,
                        isSelected: selectedIndex == index,
                        isLast: index == viewModel.dailyForecasts.count - 1
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }
}

struct DailyRow: View {
    let forecast: DailyForecast
    let isSelected: Bool
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(forecast.date)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
                    .frame(width: 85, alignment: .leading)
                
                if let code = forecast.code {
                    Image(systemName: code.symbolName)
                        .font(.title3)
                        .foregroundColor(colorFromHex(code.color))
                        .frame(width: 36)
                }
                
                Spacer()
                
                // Precipitation
                if forecast.popMax > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "umbrella.fill")
                            .font(.caption2)
                        Text("\(forecast.popMax)%")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .frame(width: 50)
                } else {
                    Spacer()
                        .frame(width: 50)
                }
                
                // Temperature range bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background bar
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        // Temperature range
                        let range = forecast.maxTemp - forecast.minTemp
                        let normalizedMin = (forecast.minTemp + 10) / 50 // Assuming range -10 to 40
                        let normalizedMax = (forecast.maxTemp + 10) / 50
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: max(0, (normalizedMax - normalizedMin) * geometry.size.width),
                                height: 6
                            )
                            .offset(x: normalizedMin * geometry.size.width)
                    }
                }
                .frame(width: 60, height: 20)
                
                // Temperature values
                HStack(spacing: 8) {
                    Text("\(String(format: "%.0f", forecast.maxTemp))°")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.orange)
                    
                    Text("\(String(format: "%.0f", forecast.minTemp))°")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.cyan)
                }
                .frame(width: 80, alignment: .trailing)
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            
            if !isLast {
                Divider()
                    .padding(.leading, 20)
            }
        }
    }
}

// MARK: - Detailed Day Info

struct DetailedDayInfo: View {
    @ObservedObject var viewModel: WeatherViewModel
    let selectedIndex: Int
    
    var body: some View {
        if selectedIndex < viewModel.dailyForecasts.count {
            let forecast = viewModel.dailyForecasts[selectedIndex]
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("\(forecast.date)の詳細情報")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                VStack(spacing: 12) {
                    // Sun times
                    HStack(spacing: 12) {
                        InfoTile(
                            icon: "sunrise.fill",
                            iconColor: .orange,
                            title: "日の出",
                            value: forecast.sunrise,
                            subtitle: ""
                        )
                        
                        InfoTile(
                            icon: "sunset.fill",
                            iconColor: .purple,
                            title: "日の入り",
                            value: forecast.sunset,
                            subtitle: ""
                        )
                    }
                    
                    // UV and Precipitation
                    HStack(spacing: 12) {
                        InfoTile(
                            icon: "sun.max.fill",
                            iconColor: .yellow,
                            title: "最大UV指数",
                            value: String(format: "%.1f", forecast.uvIndex),
                            subtitle: uvDescription(forecast.uvIndex)
                        )
                        
                        InfoTile(
                            icon: "drop.fill",
                            iconColor: .blue,
                            title: "降水量",
                            value: String(format: "%.1f mm", forecast.precipitationSum),
                            subtitle: "合計"
                        )
                    }
                    
                    // Wind
                    HStack(spacing: 12) {
                        InfoTile(
                            icon: "wind",
                            iconColor: .cyan,
                            title: "最大風速",
                            value: String(format: "%.1f km/h", forecast.windMax),
                            subtitle: ""
                        )
                        
                        InfoTile(
                            icon: "tornado",
                            iconColor: .red,
                            title: "最大突風",
                            value: String(format: "%.1f km/h", forecast.windGustMax),
                            subtitle: ""
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal)
        }
    }
    
    private func uvDescription(_ uv: Double) -> String {
        switch uv {
        case 0...2: return "低い"
        case 3...5: return "中程度"
        case 6...7: return "高い"
        case 8...10: return "非常に高い"
        default: return "極端"
        }
    }
}

struct InfoTile: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.15))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Air Quality Section

struct AirQualitySection: View {
    @ObservedObject var viewModel: WeatherViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("空気質指数", systemImage: "aqi.medium")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(viewModel.airQualityDescription)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(viewModel.airQualityColor.opacity(0.2))
                    .foregroundColor(viewModel.airQualityColor)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            // AQI Gauge
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .yellow, .orange, .red, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 12)
                        
                        // Indicator
                        let position = min(CGFloat(viewModel.airQualityIndex) / 200.0 * geometry.size.width, geometry.size.width - 16)
                        Circle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                            .shadow(radius: 4)
                            .overlay(
                                Circle()
                                    .stroke(viewModel.airQualityColor, lineWidth: 3)
                            )
                            .position(x: position + 10, y: 6)
                    }
                }
                .frame(height: 24)
                
                HStack {
                    Text("0")
                    Spacer()
                    Text("50")
                    Spacer()
                    Text("100")
                    Spacer()
                    Text("150")
                    Spacer()
                    Text("200+")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }
            
            // Pollutants
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                PollutantItem(name: "PM2.5", value: viewModel.pm25, unit: "μg/m³")
                PollutantItem(name: "PM10", value: viewModel.pm10, unit: "μg/m³")
                PollutantItem(name: "O₃", value: viewModel.o3, unit: "μg/m³")
                PollutantItem(name: "NO₂", value: viewModel.no2, unit: "μg/m³")
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }
}

struct PollutantItem: View {
    let name: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            Spacer()
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Sun & Moon Section

struct SunMoonSection: View {
    @ObservedObject var viewModel: WeatherViewModel
    let selectedIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("太陽と月", systemImage: "sun.max.circle")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                // Sun
                CelestialBodyCard(
                    title: "太陽",
                    icon: "sun.max.fill",
                    color: .orange,
                    riseTime: selectedIndex < viewModel.dailyForecasts.count ? viewModel.dailyForecasts[selectedIndex].sunrise : "--:--",
                    setTime: selectedIndex < viewModel.dailyForecasts.count ? viewModel.dailyForecasts[selectedIndex].sunset : "--:--",
                    extraInfo: "昼間: \(viewModel.daylightHours)時間"
                )
                
                // Moon
                CelestialBodyCard(
                    title: "月",
                    icon: viewModel.moonPhaseIcon,
                    color: .purple,
                    riseTime: viewModel.moonrise,
                    setTime: viewModel.moonset,
                    extraInfo: viewModel.moonPhaseDescription
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }
}

struct CelestialBodyCard: View {
    let title: String
    let icon: String
    let color: Color
    let riseTime: String
    let setTime: String
    let extraInfo: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "arrow.up")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(riseTime)
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(setTime)
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                }
            }
            
            Text(extraInfo)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Supporting Views

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.accentColor, lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }
            
            Text("天気情報を取得中...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
        .onAppear {
            isAnimating = true
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("天気情報を取得するには")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("下にスワイプするか、更新ボタンをタップしてください")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("エラーが発生しました")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: retryAction) {
                Label("再試行", systemImage: "arrow.clockwise")
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }
}

struct RefreshButton: View {
    @ObservedObject var viewModel: WeatherViewModel
    @State private var isRotating = false
    
    var body: some View {
        Button(action: {
            isRotating = true
            Task {
                await viewModel.fetchWeather()
                isRotating = false
            }
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .rotationEffect(Angle(degrees: isRotating ? 360 : 0))
                .animation(isRotating ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRotating)
        }
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.5 : 1.0)
    }
}

// MARK: - Helper Functions

func colorFromHex(_ hex: String) -> Color {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
    
    var rgb: UInt64 = 0
    
    Scanner(string: hexSanitized).scanHexInt64(&rgb)
    
    let red = Double((rgb & 0xFF0000) >> 16) / 255.0
    let green = Double((rgb & 0x00FF00) >> 8) / 255.0
    let blue = Double(rgb & 0x0000FF) / 255.0
    
    return Color(red: red, green: green, blue: blue)
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
