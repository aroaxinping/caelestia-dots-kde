/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami

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

    property real cardRadius: 26
    radius: cardRadius * centerScale
    color: clSurfaceContainer

    readonly property string logoSource: {
        if (!fetchInfo) return "distributor-logo";
        if (typeof fetchInfo === "object" && !Array.isArray(fetchInfo)) {
            return fetchInfo.id || "distributor-logo";
        }
        if (Array.isArray(fetchInfo)) {
            for (var i = 0; i < fetchInfo.length; i++) {
                if (fetchInfo[i].type === "OS" && fetchInfo[i].result && fetchInfo[i].result.id) {
                    return fetchInfo[i].result.id;
                }
            }
        }
        return "distributor-logo";
    }

    readonly property var rowsModel: {
        if (!fetchInfo) {
            return [
                { key: "OS  :", val: "" },
                { key: "WM  :", val: "KDE" },
                { key: "USER:", val: "" },
                { key: "UP  :", val: "" }
            ];
        }
        if (typeof fetchInfo === "object" && !Array.isArray(fetchInfo)) {
            return [
                { key: "OS  :", val: fetchInfo.os || "" },
                { key: "WM  :", val: fetchInfo.wm || "KDE" },
                { key: "USER:", val: fetchInfo.user || "" },
                { key: "UP  :", val: fetchInfo.uptime || "" }
            ];
        }
        if (Array.isArray(fetchInfo)) {
            var osVal = "", wmVal = "KDE", userVal = "", upVal = "";
            for (var i = 0; i < fetchInfo.length; i++) {
                var item = fetchInfo[i];
                if (item.type === "OS") osVal = item.result.name || "";
                else if (item.type === "WM") wmVal = item.result.name || "KDE";
                else if (item.type === "Uptime") {
                    var totalSec = item.result.uptime > 1000000 ? Math.floor(item.result.uptime / 1000) : item.result.uptime;
                    var h = Math.floor(totalSec / 3600);
                    var m = Math.floor((totalSec % 3600) / 60);
                    upVal = (h > 0 ? (h + " hours, ") : "") + m + " mins";
                }
            }
            return [
                { key: "OS  :", val: osVal },
                { key: "WM  :", val: wmVal },
                { key: "USER:", val: userVal },
                { key: "UP  :", val: upVal }
            ];
        }
        return [];
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18 * root.centerScale
        spacing: 12 * root.centerScale

        // Titlebar (no enclosing box, matching reference image)
        RowLayout {
            Layout.fillWidth: true
            spacing: 10 * root.centerScale

            Rectangle {
                Layout.preferredWidth: 28 * root.centerScale
                Layout.preferredHeight: 26 * root.centerScale
                implicitWidth: Layout.preferredWidth
                implicitHeight: Layout.preferredHeight
                radius: 9 * root.centerScale
                color: root.clPrimary

                Text {
                    anchors.centerIn: parent
                    text: ">"
                    font { pixelSize: 14 * root.centerScale; family: "Outfit"; weight: Font.Bold }
                    color: root.clSurface
                }
            }

            Text {
                text: "caelestiafetch.sh"
                font { pixelSize: 15 * root.centerScale; family: "Outfit"; weight: Font.Medium }
                color: root.clSurfaceVariantFg
                Layout.fillWidth: true
            }
        }

        // Body: Colorized Distro Icon + 4 System Info Rows
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16 * root.centerScale

            Item {
                Layout.preferredWidth: 88 * root.centerScale
                Layout.preferredHeight: 88 * root.centerScale
                implicitWidth: Layout.preferredWidth
                implicitHeight: Layout.preferredHeight
                Layout.alignment: Qt.AlignVCenter

                Kirigami.Icon {
                    id: distroIcon
                    anchors.fill: parent
                    source: root.logoSource
                    fallback: "distributor-logo"
                    visible: false
                }

                MultiEffect {
                    anchors.fill: distroIcon
                    source: distroIcon
                    colorization: 1.0
                    colorizationColor: root.clPrimary
                    brightness: 0.35
                    contrast: 0.1
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                spacing: 5 * root.centerScale

                Repeater {
                    model: root.rowsModel

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8 * root.centerScale

                        Text {
                            text: modelData.key
                            font { pixelSize: 14 * root.centerScale; family: "Outfit"; weight: Font.Medium }
                            color: root.clSurfaceVariantFg
                        }

                        Text {
                            text: modelData.val
                            font { pixelSize: 14 * root.centerScale; family: "Outfit" }
                            color: root.clSurfaceFg
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

        // Terminal Dot Palette (7 dots, evenly spaced)
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 14 * root.centerScale

            Repeater {
                model: root.clTerms && root.clTerms.length ? root.clTerms.slice(0, 7) : []

                Rectangle {
                    Layout.preferredWidth: 20 * root.centerScale
                    Layout.preferredHeight: 20 * root.centerScale
                    implicitWidth: Layout.preferredWidth
                    implicitHeight: Layout.preferredHeight
                    radius: 10 * root.centerScale
                    color: modelData
                }
            }
        }
    }
}
