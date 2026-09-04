/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property var multiplex: ({})
    readonly property bool hasMedia: Boolean(multiplex && multiplex.title)
    property real centerScale: 1.0

    property color clSurface: "#131317"
    property color clSurfaceContainer: "#201f23"
    property color clSurfaceFg: "#e5e1e7"
    property color clSurfaceVariantFg: "#c8c5d1"

    signal previousRequested()
    signal playPauseRequested()
    signal nextRequested()

    radius: 20 * centerScale
    color: clSurfaceContainer
    clip: true

    Image {
        anchors.fill: parent
        source: root.hasMedia ? (root.multiplex.artUrl || "") : ""
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        color: root.clSurface
        opacity: 0.6
        visible: root.hasMedia
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.9
        spacing: 8 * centerScale
        visible: root.hasMedia

        Text {
            Layout.fillWidth: true
            text: root.multiplex.title || ""
            font { pixelSize: 18 * centerScale; family: "Outfit"; weight: Font.Medium }
            color: root.clSurfaceFg
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            text: root.multiplex.artist || ""
            font { pixelSize: 14 * centerScale; family: "Outfit" }
            color: root.clSurfaceVariantFg
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16 * centerScale
            Layout.topMargin: 12 * centerScale

            Rectangle {
                width: 36 * centerScale
                height: 36 * centerScale
                radius: 18 * centerScale
                color: Qt.rgba(255, 255, 255, 0.1)

                Text {
                    anchors.centerIn: parent
                    text: "skip_previous"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20 * centerScale
                    color: root.clSurfaceFg
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.previousRequested()
                }
            }

            Rectangle {
                width: 64 * centerScale
                height: 42 * centerScale
                radius: 21 * centerScale
                color: root.clSurfaceFg

                Text {
                    anchors.centerIn: parent
                    text: root.multiplex.status === "Playing" ? "pause" : "play_arrow"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 24 * centerScale
                    color: root.clSurface
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.playPauseRequested()
                }
            }

            Rectangle {
                width: 36 * centerScale
                height: 36 * centerScale
                radius: 18 * centerScale
                color: Qt.rgba(255, 255, 255, 0.1)

                Text {
                    anchors.centerIn: parent
                    text: "skip_next"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20 * centerScale
                    color: root.clSurfaceFg
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.nextRequested()
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: "No Media Playing"
        font { pixelSize: 16 * centerScale; family: "Outfit" }
        color: root.clSurfaceVariantFg
        visible: !root.hasMedia
    }
}
