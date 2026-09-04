/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    property var fetchInfo: []
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
    radius: cardRadius
    color: clSurfaceContainer

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20 * centerScale
        spacing: 12 * centerScale

        // Titlebar
        Rectangle {
            Layout.fillWidth: true
            height: 32 * centerScale
            radius: 16 * centerScale
            color: root.clSurfaceContainerHigh

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4 * centerScale
                spacing: 8 * centerScale

                Rectangle {
                    width: 26
                    height: 26
                    radius: 8
                    color: root.clPrimary
                    Text {
                        anchors.centerIn: parent
                        text: ">"
                        font { pixelSize: 15; family: "Outfit"; weight: Font.Bold }
                        color: root.clSurface
                    }
                }
                Text {
                    text: "caelestiafetch.sh"
                    font { pixelSize: 15; family: "Outfit"; weight: Font.Medium }
                    color: root.clSurfaceVariantFg
                    Layout.fillWidth: true
                }
            }
        }

        // Body: Distro Icon + Info Rows
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            Kirigami.Icon {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                Layout.alignment: Qt.AlignVCenter
                source: {
                    if (root.fetchInfo && Array.isArray(root.fetchInfo)) {
                        for (var i = 0; i < root.fetchInfo.length; i++) {
                            if (root.fetchInfo[i].type === "OS" && root.fetchInfo[i].result && root.fetchInfo[i].result.id) {
                                return root.fetchInfo[i].result.id;
                            }
                        }
                    }
                    return "distributor-logo";
                }
                fallback: "distributor-logo"
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: root.fetchInfo
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: modelData.type.toUpperCase() + " :"
                            font { pixelSize: 15; family: "Outfit"; weight: Font.Medium }
                            color: root.clSurfaceVariantFg
                            Layout.minimumWidth: 78
                        }
                        Text {
                            text: {
                                if (modelData.type === "Uptime") {
                                    var totalSec = modelData.result.uptime > 1000000 ? Math.floor(modelData.result.uptime / 1000) : modelData.result.uptime;
                                    var h = Math.floor(totalSec / 3600);
                                    var m = Math.floor((totalSec % 3600) / 60);
                                    return (h > 0 ? (h + " hours, ") : "") + m + " mins";
                                }
                                if (modelData.type === "Packages") return modelData.result.all;
                                if (modelData.type === "Kernel") return modelData.result.release;
                                return modelData.result.name || "";
                            }
                            font { pixelSize: 15; family: "Outfit" }
                            color: root.clSurfaceFg
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

        // Terminal Dot Palette
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            Repeater {
                model: root.clTerms
                Rectangle {
                    width: 15
                    height: 15
                    radius: 7.5
                    color: modelData
                }
            }
        }
    }
}
