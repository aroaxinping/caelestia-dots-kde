/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import ".."
import QtQuick.Layouts

Rectangle {
    id: root

    property var weatherInfo: null
    property real centerScale: 1.0

    property color clSurfaceContainer: "#201f23"
    property color clSurfaceFg: "#e5e1e7"
    property color clSurfaceVariantFg: "#c8c5d1"
    property color clPrimary: "#c2c1ff"

    property real cardRadius: 26
    radius: cardRadius
    color: clSurfaceContainer

    readonly property var _cc: weatherInfo && weatherInfo.current_condition && weatherInfo.current_condition.length > 0
                               ? weatherInfo.current_condition[0] : null
    readonly property var _wd: _cc && _cc.weatherDesc && _cc.weatherDesc.length > 0
                               ? _cc.weatherDesc[0] : null
    readonly property var _day: weatherInfo && weatherInfo.weather && weatherInfo.weather.length > 0
                                ? weatherInfo.weather[0] : null
    // Natural height = content + vertical padding so the card shrinks-to-fit
    // when Layout.fillHeight is not set (matches Quickshell Content.qml behaviour)
    implicitHeight: weatherContent.implicitHeight + 40 * centerScale

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

    ColumnLayout {
        id: weatherContent
        anchors.centerIn: parent
        spacing: 4
        // Dim the card while weather data is still loading so the user
        // can see placeholders without them looking like real values
        opacity: root._cc ? 1.0 : 0.5
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root._wd ? root._wd.value : "No weather"
            font { pixelSize: LockScreenConfig.sizeSmall; family: LockScreenConfig.fontHeading }
            color: root.clSurfaceVariantFg
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Text {
                text: root._cc ? root._cc.temp_C + "°C" : "--°C"
                font { pixelSize: LockScreenConfig.sizeVeryLarge; family: LockScreenConfig.fontHeading; weight: Font.Medium }
                color: root.clPrimary
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: root._wd
                      ? root.getWeatherSymbol(root._wd.value, root._cc.weatherCode)
                      : "cloud"
                font.family: LockScreenConfig.fontIcon
                font.pixelSize: LockScreenConfig.sizeVeryLarge
                color: root.clPrimary
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root._cc ? "Feels like " + root._cc.FeelsLikeC + "°C" : "Feels like --°C"
            font { pixelSize: LockScreenConfig.sizeSmall; family: LockScreenConfig.fontHeading }
            color: root.clSurfaceVariantFg
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root._day
                  ? "High " + root._day.maxtempC + "°C • Low " + root._day.mintempC + "°C"
                  : "High --°C • Low --°C"
            font { pixelSize: LockScreenConfig.sizeSmall; family: LockScreenConfig.fontHeading }
            color: root.clSurfaceVariantFg
        }
    }
}
