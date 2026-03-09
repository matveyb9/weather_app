// ios/WeatherWidgetExtension/WeatherWidgetBundle.swift
//
// Registers all three widget configurations with WidgetKit.
// This file is the @main entry point of the extension target.

import WidgetKit
import SwiftUI

@main
struct WeatherWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeatherWidgetSmall()
        WeatherWidgetMedium()
        WeatherWidgetLarge()
    }
}
