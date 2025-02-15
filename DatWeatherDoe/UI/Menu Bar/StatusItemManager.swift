//
//  StatusItemManager.swift
//  DatWeatherDoe
//
//  Created by Inder Dhir on 1/15/22.
//  Copyright © 2022 Inder Dhir. All rights reserved.
//

import AppKit

final class StatusItemManager {

    var button: NSStatusBarButton? { statusItem.button }

    private let statusItem = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.variableLength
    )
    private lazy var unknownString = NSLocalizedString("Unknown", comment: "Unknown location")

    init(menu: NSMenu, configureSelector: Selector) {
        statusItem.menu = menu
        statusItem.button?.action = configureSelector

        setupDropdownMenu()
    }

    func updateStatusItemWith(
        weatherData: WeatherData,
        temperatureOptions: TemperatureTextBuilder.Options
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }

            if let textualRepresentation = weatherData.textualRepresentation {
                self.statusItem.button?.title = textualRepresentation
            }
            if weatherData.showWeatherIcon {
                self.statusItem.button?.image = self.getImageFrom(weatherData: weatherData)
                self.statusItem.button?.imagePosition = .imageLeading
            } else {
                self.statusItem.button?.image = nil
            }

            self.updateReadOnlyData(weatherData: weatherData, temperatureOptions: temperatureOptions)
        }
    }

    func updateStatusItemWith(error: String) {
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.button?.title = error
            self?.statusItem.button?.image = nil

            self?.clearNonInteractiveMenuOptions()
        }
    }

    private func setupDropdownMenu() {
        // By making the images "templates",
        // macOS knows to adjust the image colour based on the desktop settings
        // (light, dark), so they remain visible either way.
        let iconMapper = DropdownIconMapper()

        locationMenuItem?.image = iconMapper.map(.location)
        locationMenuItem?.image?.isTemplate = true

        temperatureForecastMenuItem?.image = iconMapper.map(.thermometer)
        temperatureForecastMenuItem?.image?.isTemplate = true

        sunRiseSetMenuItem?.image = iconMapper.map(.sun)
        sunRiseSetMenuItem?.image?.isTemplate = true

        windMenuItem?.image = iconMapper.map(.wind)
        windMenuItem?.image?.isTemplate = true
    }

    private func updateReadOnlyData(
        weatherData: WeatherData,
        temperatureOptions: TemperatureTextBuilder.Options
    ) {
        let locationTitle = [
            getLocationFrom(weatherData: weatherData),
            getConditionItemFrom(weatherData: weatherData)
        ].joined(separator: " - ")
        locationMenuItem?.attributedTitle = NSAttributedString(
            string: locationTitle,
            attributes: constructMenuItemAttributes()
        )

        let temperatureForecastTitle = getWeatherTextFrom(
            weatherData: weatherData,
            temperatureOptions: temperatureOptions
        )
        temperatureForecastMenuItem?.attributedTitle = NSAttributedString(
            string: temperatureForecastTitle,
            attributes: constructMenuItemAttributes()
        )

        let sunriseSetTitle = getSunRiseSetFrom(
            weatherData: weatherData)
        sunRiseSetMenuItem?.attributedTitle = NSAttributedString(
            string: sunriseSetTitle,
            attributes: constructMenuItemAttributes()
        )

        let windSpeedTitle = getWindSpeedItemFrom(
            weatherData: weatherData)
        windMenuItem?.attributedTitle = NSAttributedString(
            string: windSpeedTitle,
            attributes: constructMenuItemAttributes()
        )
    }

    private func getImageFrom(weatherData: WeatherData) -> NSImage? {
        let image = WeatherConditionImageMapper().map(weatherData.weatherCondition)
        image?.accessibilityDescription = WeatherConditionTextMapper().map(weatherData.weatherCondition)
        image?.isTemplate = true
        return image
    }

    private func getLocationFrom(weatherData: WeatherData) -> String {
        weatherData.location ?? unknownString
    }

    private func getWeatherTextFrom(
        weatherData: WeatherData,
        temperatureOptions: TemperatureTextBuilder.Options
    ) -> String {
        TemperatureForecastTextBuilder(
            temperatureData: weatherData.temperatureData,
            options: temperatureOptions
        ).build()
    }

    private func getSunRiseSetFrom(weatherData: WeatherData) -> String {
        SunriseAndSunsetTextBuilder(
            sunset: weatherData.sunset,
            sunrise: weatherData.sunrise
        ).build()
    }

    private func getConditionItemFrom(weatherData: WeatherData) -> String {
        WeatherConditionTextMapper().map(weatherData.weatherCondition)
    }

    private func getWindSpeedItemFrom(weatherData: WeatherData) -> String {
        let windSpeedStr = [String(weatherData.windData.speed), "m/s"].joined()
        let windDegreesStr = [String(weatherData.windData.degrees), TemperatureHelpers.degreeString].joined()
        let windDirectionStr = ["(", WindDirection.getDirectionStr(weatherData), ")"].joined()
        let windAndDegreesStr = [windSpeedStr, windDegreesStr].joined(separator: " - ")
        let windFullStr = [windAndDegreesStr, windDirectionStr].joined(separator: " ")
        return windFullStr
    }

    private func clearNonInteractiveMenuOptions() {
        locationMenuItem?.title = unknownString
        temperatureForecastMenuItem?.title = unknownString
        sunRiseSetMenuItem?.title = unknownString
        windMenuItem?.title = unknownString
    }

    private var locationMenuItem: NSMenuItem? { statusItem.menu?.item(at: 0) }
    private var temperatureForecastMenuItem: NSMenuItem? { statusItem.menu?.item(at: 1) }
    private var sunRiseSetMenuItem: NSMenuItem? { statusItem.menu?.item(at: 2) }
    private var windMenuItem: NSMenuItem? { statusItem.menu?.item(at: 3) }

    private func constructMenuItemAttributes() -> [NSAttributedString.Key: Any] {
        [
            .foregroundColor: NSColor.black,
            .font: NSFont.boldSystemFont(ofSize: 14),
        ]
    }
}
