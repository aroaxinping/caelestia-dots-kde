/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import ".."
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root

    property var mediaInfo: ({})  // renamed from mediaInfo (review)
    readonly property bool hasMedia: Boolean(mediaInfo && mediaInfo.title)
    property real centerScale: 1.0

    property color clSurface: "#131317"
    property color clSurfaceContainer: "#201f23"
    property color clSurfaceFg: "#e5e1e7"
    property color clSurfaceVariantFg: "#c8c5d1"
    property color clPrimary: "#c2c1ff"

    signal previousRequested()
    signal playPauseRequested()
    signal nextRequested()

    property real cardRadius: 26
    radius: cardRadius
    color: clSurfaceContainer

    // Album art background — only shown when media is playing
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
            source: root.hasMedia ? (root.mediaInfo.artUrl || "") : ""
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

    // Single layout always present — mirrors Quickshell Media.qml structure.
    // When no media is playing the content dims and shows placeholder strings.
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.9
        spacing: 8
        // Dim the whole layout while no media is active (matches Quickshell disabled state)
        opacity: root.hasMedia ? 1.0 : 0.55
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Text {
            Layout.fillWidth: true
            // Quickshell: Players.active?.trackTitle ?? "Nothing playing"
            text: root.hasMedia ? (root.mediaInfo.title || "") : qsTr("Nothing playing")
            font { pixelSize: Config.sizeMedium; family: Config.fontHeading; weight: Font.Medium }
            color: root.clSurfaceFg
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            // Quickshell: Players.active?.trackArtist ?? "Try playing some music!"
            text: root.hasMedia ? (root.mediaInfo.artist || "") : qsTr("Try playing some music!")
            font { pixelSize: Config.sizeSmall; family: Config.fontHeading }
            color: root.clSurfaceVariantFg
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16
            Layout.topMargin: 12

            // Previous — Quickshell: disabled when !canGoPrevious
            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: Qt.rgba(255, 255, 255, root.hasMedia ? 0.1 : 0.06)

                Text {
                    anchors.centerIn: parent
                    text: "skip_previous"
                    font.family: Config.fontIcon
                    font.pixelSize: Config.sizeLarge
                    color: root.hasMedia ? root.clSurfaceFg : root.clSurfaceVariantFg
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.hasMedia
                    onClicked: root.previousRequested()
                }
            }

            // Play/Pause — pill shape, primary colour when active
            Rectangle {
                width: 66
                height: 42
                radius: 21
                color: root.hasMedia ? root.clPrimary : Qt.rgba(255, 255, 255, 0.08)

                Text {
                    anchors.centerIn: parent
                    text: (root.hasMedia && root.mediaInfo.status === "Playing") ? "pause" : "play_arrow"
                    font.family: Config.fontIcon
                    font.pixelSize: Config.sizeVeryLarge
                    color: root.hasMedia ? root.clSurface : root.clSurfaceVariantFg
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.hasMedia
                    onClicked: root.playPauseRequested()
                }
            }

            // Next — Quickshell: disabled when !canGoNext
            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: Qt.rgba(255, 255, 255, root.hasMedia ? 0.1 : 0.06)

                Text {
                    anchors.centerIn: parent
                    text: "skip_next"
                    font.family: Config.fontIcon
                    font.pixelSize: Config.sizeLarge
                    color: root.hasMedia ? root.clSurfaceFg : root.clSurfaceVariantFg
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.hasMedia
                    onClicked: root.nextRequested()
                }
            }
        }
    }
}
