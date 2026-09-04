/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property var weatherInfo: null
    property real centerScale: 1.0

    property color clSurfaceContainer: "#201f23"
    property color clSurfaceFg: "#e5e1e7"
    property color clSurfaceVariantFg: "#c8c5d1"
    property color clPrimary: "#c2c1ff"

    function getWeatherSymbol(desc, code) {
        var d = (desc || "").toLowerCase();
        if (d.indexOf("sunny") !== -1 || d.indexOf("clear") !== -1) return "clear_day";
        if (d.indexOf("partly") !== -1) return "partly_cloudy_day";
        if (d.indexOf("cloud") !== -1 || d.indexOf("overcast") !== -1) return "cloud";
        if (d.indexOf("rain") !== -1 || d.indexOf("drizzle") !== -1 || d.indexOf("shower") !== -1) return "rainy";
        if (d.indexOf("thunder") !== -1 || d.indexOf("storm") !== -1) return "thunderstorm";
        if (d.indexOf("snow") !== -1 || d.indexOf("blizzard") !== -1 || d.indexOf("ice") !== -1) return "weather_snowy";
        if (d.indexOf("fog") !== -1 || d.indexOf("mist") !== -1 || d.indexOf("haze") !== -1) return "foggy";
        if (d.indexOf("wind") !== -1) return "air";
        return "cloud";
    }

    property real cardRadius: 26
    radius: cardRadius
    color: clSurfaceContainer

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.weatherInfo ? root.weatherInfo.current_condition[0].weatherDesc[0].value : ""
            font { pixelSize: 17; family: "Outfit" }
            color: root.clSurfaceVariantFg
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Text {
                text: root.weatherInfo ? root.weatherInfo.current_condition[0].temp_C + "°C" : ""
                font { pixelSize: 42; family: "Outfit"; weight: Font.Medium }
                color: root.clSurfaceFg
            }

            Text {
                text: root.weatherInfo ? root.getWeatherSymbol(root.weatherInfo.current_condition[0].weatherDesc[0].value, root.weatherInfo.current_condition[0].weatherCode) : ""
                font.family: "Material Symbols Rounded"
                font.pixelSize: 34
                color: root.clPrimary
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.weatherInfo ? "Feels like " + root.weatherInfo.current_condition[0].FeelsLikeC + "°C" : ""
            font { pixelSize: 15; family: "Outfit" }
            color: root.clSurfaceVariantFg
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.weatherInfo ? "High " + root.weatherInfo.weather[0].maxtempC + "°C • Low " + root.weatherInfo.weather[0].mintempC + "°C" : ""
            font { pixelSize: 15; family: "Outfit" }
            color: root.clSurfaceVariantFg
        }
    }
}
