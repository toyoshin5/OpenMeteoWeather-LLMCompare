import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WeatherViewModel()
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(.top, 100)
                    } else if let data = viewModel.displayData {
                        // メイン情報
                        VStack(spacing: 8) {
                            Text("札幌市")
                                .font(.system(size: 34, weight: .medium))
                                .foregroundColor(.white)
                            
                            Image(systemName: data.systemImage)
                                .renderingMode(.original)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                            
                            Text("\(Int(data.temperature))°")
                                .font(.system(size: 80, weight: .thin))
                                .foregroundColor(.white)
                            
                            Text(data.conditionText)
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.9))
                            
                            HStack {
                                Text("最高: \(Int(data.maxTemp))°")
                                Text("最低: \(Int(data.minTemp))°")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                        }
                        .padding(.top, 40)
                        
                        // 詳細情報グリッド
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            InfoCard(title: "体感温度", value: "\(Int(data.apparentTemp))°", icon: "thermometer.medium")
                            InfoCard(title: "UV指数", value: String(format: "%.1f", data.uvIndex), icon: "sun.max")
                            InfoCard(title: "風速", value: "\(Int(data.windSpeed)) km/h", icon: "wind")
                            InfoCard(title: "日の出", value: data.sunrise, icon: "sunrise.fill")
                            InfoCard(title: "日の入り", value: data.sunset, icon: "sunset.fill")
                            InfoCard(title: "更新日時", value: data.lastUpdate.formatted(date: .omitted, time: .shortened), icon: "clock.fill")
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            Task { await viewModel.fetchWeather() }
                        }) {
                            Label("更新", systemImage: "arrow.clockwise")
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }
                        .padding(.vertical)
                    } else if let error = viewModel.errorMessage {
                        VStack {
                            Text(error)
                                .foregroundColor(.white)
                                .padding()
                            Button("再試行") {
                                Task { await viewModel.fetchWeather() }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 100)
                    }
                }
            }
        }
        .onAppear {
            Task { await viewModel.fetchWeather() }
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white.opacity(0.7))
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
