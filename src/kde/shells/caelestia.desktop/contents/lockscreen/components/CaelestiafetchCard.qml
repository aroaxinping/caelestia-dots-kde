/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import ".."
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: root

    property var fetchInfo: null
    property var clTerms: []
    property real centerScale: 1.0

    property color clSurfaceContainer: "#201f23"
    property color clSurfaceContainerHigh: "#2a292e"
    property color clSurfaceContainerHighest: "#353438"
    property color clSurface: "#131317"
    property color clSurfaceFg: "#e5e1e7"
    property color clSurfaceVariantFg: "#c8c5d1"
    property color clPrimary: "#c2c1ff"
    property bool recolourLogo: true

    property real cardRadius: 26
    radius: cardRadius
    color: clSurfaceContainer
    // Shrinks-to-fit: titlebar (36) + logo (180) + dots (28) + 2×spacing (12) + 2×margin (18)
    // Matches Quickshell's Fetch.qml content-driven height
    implicitHeight: (36 + 180 + 28 + 2 * 12 + 2 * 18) * centerScale

    // Resolve SVG logo path from python3 provider; falls back to a generic icon
    readonly property string logoPath: {
        if (fetchInfo && fetchInfo.logoPath) return fetchInfo.logoPath;
        return "";
    }

    // Single monospace string per row keeps all colons on one vertical line.
    // Fallback values are kept generic — this is a public repo.
    readonly property var fetchLines: {
        var osStr = "";
        var wmStr = "KDE";
        var userStr = "";
        var upStr = "";

        if (fetchInfo) {
            if (typeof fetchInfo === "object" && !Array.isArray(fetchInfo)) {
                if (fetchInfo.os)     osStr   = fetchInfo.os;
                if (fetchInfo.wm)     wmStr   = fetchInfo.wm;
                if (fetchInfo.user)   userStr = fetchInfo.user;
                if (fetchInfo.uptime) upStr   = fetchInfo.uptime;
            } else if (Array.isArray(fetchInfo)) {
                for (var i = 0; i < fetchInfo.length; i++) {
                    var item = fetchInfo[i];
                    if (item.type === "OS") osStr = item.result.name || osStr;
                    else if (item.type === "WM") wmStr = item.result.name || wmStr;
                    else if (item.type === "USER") userStr = item.result.name || userStr;
                    else if (item.type === "Uptime") {
                        var s = item.result.uptime > 1000000 ? Math.floor(item.result.uptime / 1000) : item.result.uptime;
                        var h = Math.floor(s / 3600);
                        var m = Math.floor((s % 3600) / 60);
                        upStr = (h > 0 ? (h + " hours, ") : "") + m + " mins";
                    }
                }
            }
        }

        return [
            "OS  : " + osStr,
            "WM  : " + wmStr,
            "USER: " + userStr,
            "UP  : " + upStr
        ];
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18 * root.centerScale
        spacing: 12 * root.centerScale

        // Titlebar row: "> " pill + "caelestiafetch.sh"
        RowLayout {
            Layout.fillWidth: true
            spacing: 10 * root.centerScale

            Rectangle {
                Layout.preferredWidth: 34 * root.centerScale
                Layout.preferredHeight: 34 * root.centerScale
                implicitWidth: Layout.preferredWidth
                implicitHeight: Layout.preferredHeight
                radius: 10 * root.centerScale
                color: root.clPrimary

                Text {
                    anchors.centerIn: parent
                    text: ">"
                    // Font sizes here are NOT multiplied by centerScale — matches the
                    // convention used by all other lockscreen cards (MediaCard, NotifDock, etc.)
                    font {
                        pixelSize: LockScreenConfig.sizeSmall
                        family: LockScreenConfig.fontMono
                        weight: Font.Bold
                    }
                    color: root.clSurface
                }
            }

            Text {
                text: "caelestiafetch.sh"
                font {
                    pixelSize: LockScreenConfig.sizeSmall
                    family: LockScreenConfig.fontMono
                }
                color: root.clSurfaceFg
                Layout.fillWidth: true
            }
        }

        // Body: large vector logo (left) + 4 monospace info lines (right)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 20 * root.centerScale

            Item {
                Layout.preferredWidth: 180 * root.centerScale
                Layout.preferredHeight: 180 * root.centerScale
                implicitWidth: Layout.preferredWidth
                implicitHeight: Layout.preferredHeight
                Layout.alignment: Qt.AlignVCenter

                // Use a high-res Image for crisp SVG rendering, falling back
                // to nothing (transparent) when no logo path is available.
                Image {
                    id: distroIcon
                    anchors.fill: parent
                    source: root.logoPath
                    sourceSize.width: 512
                    sourceSize.height: 512
                    fillMode: Image.PreserveAspectFit
                    visible: false
                }

                MultiEffect {
                    anchors.fill: distroIcon
                    source: distroIcon
                    colorization: root.recolourLogo ? 1.0 : 0.0
                    colorizationColor: root.clPrimary
                    brightness: root.recolourLogo ? 0.5 : 0.0
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 7

                Repeater {
                    model: root.fetchLines

                    Text {
                        required property string modelData
                        text: modelData
                        font {
                            family: LockScreenConfig.fontMono
                            // Fixed px — same convention as MediaCard, NotifDock, GreetingPill
                            pixelSize: LockScreenConfig.sizeSmall
                        }
                        color: root.clSurfaceFg
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // Terminal dot palette — uses clTerms from scheme.json; empty while colors load
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16 * root.centerScale

            Repeater {
                model: root.clTerms && root.clTerms.length ? root.clTerms.slice(0, 7) : []

                Rectangle {
                    required property string modelData
                    Layout.preferredWidth: 28 * root.centerScale
                    Layout.preferredHeight: 28 * root.centerScale
                    implicitWidth: Layout.preferredWidth
                    implicitHeight: Layout.preferredHeight
                    radius: 14 * root.centerScale
                    color: modelData
                }
            }
        }
    }
}
