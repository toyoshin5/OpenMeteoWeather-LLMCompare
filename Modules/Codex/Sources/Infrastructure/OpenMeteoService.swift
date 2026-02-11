import Foundation

protocol WeatherServicing {
    func fetchCurrentWeather() async throws -> WeatherSnapshot
}

enum OpenMeteoServiceError: LocalizedError {
    case invalidURL
    case badStatusCode(Int)
    case invalidDate(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not build API URL."
        case .badStatusCode(let code):
            return "Weather API returned HTTP \(code)."
        case .invalidDate(let raw):
            return "Could not parse observation time: \(raw)"
        }
    }
}

struct OpenMeteoService: WeatherServicing {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func fetchCurrentWeather() async throws -> WeatherSnapshot {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.open-meteo.com"
        components.path = "/v1/forecast"
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "43.0642"),
            URLQueryItem(name: "longitude", value: "141.3469"),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,is_day,precipitation,rain,showers,snowfall,weather_code,cloud_cover,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m"),
            URLQueryItem(name: "hourly", value: "temperature_2m,apparent_temperature,relative_humidity_2m,precipitation_probability,weather_code,wind_speed_10m"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_sum,precipitation_probability_max,wind_speed_10m_max,wind_gusts_10m_max"),
            URLQueryItem(name: "forecast_days", value: "10"),
            URLQueryItem(name: "timezone", value: "Asia/Tokyo")
        ]

        guard let url = components.url else {
            throw OpenMeteoServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw OpenMeteoServiceError.badStatusCode(httpResponse.statusCode)
        }

        let payload = try decoder.decode(OpenMeteoResponse.self, from: data)
        let timezone = TimeZone(identifier: payload.timezone)

        guard let observedAt = parseDateTime(payload.current.time, timezone: timezone) else {
            throw OpenMeteoServiceError.invalidDate(payload.current.time)
        }

        let units = WeatherUnits(
            temperature: payload.currentUnits.temperature2m,
            precipitation: payload.currentUnits.precipitation,
            pressure: payload.currentUnits.surfacePressure,
            windSpeed: payload.currentUnits.windSpeed10m
        )

        let current = CurrentConditions(
            temperature: payload.current.temperature2m,
            apparentTemperature: payload.current.apparentTemperature,
            humidity: payload.current.relativeHumidity2m,
            isDay: payload.current.isDay == 1,
            weatherCode: payload.current.weatherCode,
            cloudCover: payload.current.cloudCover,
            precipitation: payload.current.precipitation,
            rain: payload.current.rain,
            showers: payload.current.showers,
            snowfall: payload.current.snowfall,
            surfacePressure: payload.current.surfacePressure,
            windSpeed: payload.current.windSpeed10m,
            windDirection: payload.current.windDirection10m,
            windGusts: payload.current.windGusts10m
        )

        let hourly = buildHourlyForecast(from: payload, observedAt: observedAt, timezone: timezone)
        let daily = buildDailyForecast(from: payload, timezone: timezone)

        return WeatherSnapshot(
            cityName: "Sapporo",
            timezone: payload.timezone,
            latitude: payload.latitude,
            longitude: payload.longitude,
            elevation: payload.elevation,
            observedAt: observedAt,
            current: current,
            units: units,
            hourlyForecast: hourly,
            dailyForecast: daily
        )
    }

    private func buildHourlyForecast(
        from payload: OpenMeteoResponse,
        observedAt: Date,
        timezone: TimeZone?
    ) -> [HourlyForecast] {
        let hourly = payload.hourly
        let maxCount = min(
            hourly.time.count,
            hourly.temperature2m.count,
            hourly.apparentTemperature.count,
            hourly.relativeHumidity2m.count,
            hourly.precipitationProbability.count,
            hourly.weatherCode.count,
            hourly.windSpeed10m.count
        )

        guard maxCount > 0 else {
            return []
        }

        var all: [HourlyForecast] = []
        all.reserveCapacity(maxCount)

        for index in 0..<maxCount {
            guard let date = parseDateTime(hourly.time[index], timezone: timezone) else {
                continue
            }

            all.append(
                HourlyForecast(
                    date: date,
                    temperature: hourly.temperature2m[index],
                    apparentTemperature: hourly.apparentTemperature[index],
                    humidity: hourly.relativeHumidity2m[index],
                    precipitationProbability: hourly.precipitationProbability[index],
                    weatherCode: hourly.weatherCode[index],
                    windSpeed: hourly.windSpeed10m[index]
                )
            )
        }

        guard !all.isEmpty else {
            return []
        }

        let startIndex = all.firstIndex(where: { $0.date >= observedAt }) ?? 0
        return Array(all.dropFirst(startIndex).prefix(24))
    }

    private func buildDailyForecast(from payload: OpenMeteoResponse, timezone: TimeZone?) -> [DailyForecast] {
        let daily = payload.daily
        let maxCount = min(
            daily.time.count,
            daily.weatherCode.count,
            daily.temperature2mMax.count,
            daily.temperature2mMin.count,
            daily.sunrise.count,
            daily.sunset.count,
            daily.uvIndexMax.count,
            daily.precipitationSum.count,
            daily.precipitationProbabilityMax.count,
            daily.windSpeed10mMax.count,
            daily.windGusts10mMax.count
        )

        guard maxCount > 0 else {
            return []
        }

        var forecasts: [DailyForecast] = []
        forecasts.reserveCapacity(maxCount)

        for index in 0..<maxCount {
            guard
                let date = parseDayDate(daily.time[index], timezone: timezone),
                let sunrise = parseDateTime(daily.sunrise[index], timezone: timezone),
                let sunset = parseDateTime(daily.sunset[index], timezone: timezone)
            else {
                continue
            }

            forecasts.append(
                DailyForecast(
                    date: date,
                    weatherCode: daily.weatherCode[index],
                    minTemperature: daily.temperature2mMin[index],
                    maxTemperature: daily.temperature2mMax[index],
                    sunrise: sunrise,
                    sunset: sunset,
                    uvIndexMax: daily.uvIndexMax[index],
                    precipitationSum: daily.precipitationSum[index],
                    precipitationProbabilityMax: daily.precipitationProbabilityMax[index],
                    windSpeedMax: daily.windSpeed10mMax[index],
                    windGustsMax: daily.windGusts10mMax[index]
                )
            )
        }

        return Array(forecasts.prefix(7))
    }

    private func parseDateTime(_ raw: String, timezone: TimeZone?) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: raw) {
            return date
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: raw) {
            return date
        }

        let minuteFormatter = DateFormatter()
        minuteFormatter.locale = Locale(identifier: "en_US_POSIX")
        minuteFormatter.timeZone = timezone
        minuteFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        if let date = minuteFormatter.date(from: raw) {
            return date
        }

        minuteFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return minuteFormatter.date(from: raw)
    }

    private func parseDayDate(_ raw: String, timezone: TimeZone?) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timezone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: raw)
    }
}
