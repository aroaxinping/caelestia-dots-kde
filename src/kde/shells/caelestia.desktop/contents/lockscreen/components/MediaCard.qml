/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root

    property var multiplex: ({})
    readonly property bool hasMedia: Boolean(multiplex && multiplex.title)
    property real centerScale: 1.0

    property color clSurface: "#131317"
    property color clSurfaceContainer: "#201f23"
    property color clSurfaceFg: "#e5e1e7"
    property color clSurfaceVariantFg: "#c8c5d1"
    property color clPrimary: "#c2c1ff"

    signal previousRequested()
    signal playPauseRequested()
    signal nextRequested()

    radius: 20 * centerScale
    color: clSurfaceContainer

    Item {
        id: bgContainer
        anchors.fill: parent
        visible: root.hasMedia
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: maskRect
        }

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
        }
    }

    Rectangle {
        id: maskRect
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.9
        spacing: 8
        visible: root.hasMedia

        Text {
            Layout.fillWidth: true
            text: root.multiplex.title || ""
            font { pixelSize: 18; family: "Outfit"; weight: Font.Medium }
            color: root.clSurfaceFg
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            text: root.multiplex.artist || ""
            font { pixelSize: 15; family: "Outfit" }
            color: root.clSurfaceVariantFg
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16
            Layout.topMargin: 12

            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: Qt.rgba(255, 255, 255, 0.1)

                Text {
                    anchors.centerIn: parent
                    text: "skip_previous"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                    color: root.clSurfaceFg
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.previousRequested()
                }
            }

            Rectangle {
                width: 66
                height: 42
                radius: 21
                color: root.clPrimary

                Text {
                    anchors.centerIn: parent
                    text: root.multiplex.status === "Playing" ? "pause" : "play_arrow"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 26
                    color: root.clSurface
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.playPauseRequested()
                }
            }

            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: Qt.rgba(255, 255, 255, 0.1)

                Text {
                    anchors.centerIn: parent
                    text: "skip_next"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
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
        font { pixelSize: 16; family: "Outfit" }
        color: root.clSurfaceVariantFg
        visible: !root.hasMedia
    }
}
