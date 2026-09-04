/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    property var liveNotifs: []
    property real centerScale: 1.0

    property color clSurfaceContainer: "#201f23"
    property color clSurfaceContainerHighest: "#353438"
    property color clSurfaceFg: "#e5e1e7"
    property color clSurfaceVariantFg: "#c8c5d1"

    signal clearAllRequested()

    function formatNotifTime(timeStr) {
        if (!timeStr) return "now";
        try {
            var t = new Date(timeStr);
            var diff = Math.floor((new Date() - t) / 1000);
            if (isNaN(diff) || diff < 60) return "now";
            if (diff < 3600) return Math.floor(diff / 60) + "m";
            if (diff < 86400) return Math.floor(diff / 3600) + "h";
            return Math.floor(diff / 86400) + "d";
        } catch(e) {
            return "now";
        }
    }

    radius: 20 * centerScale
    color: clSurfaceContainer
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18 * centerScale
        spacing: 12 * centerScale

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: root.liveNotifs.length > 0
                      ? (root.liveNotifs.length + (root.liveNotifs.length === 1 ? " notification" : " notifications"))
                      : "Notifications"
                font { pixelSize: 14 * centerScale; family: "Outfit"; weight: Font.Medium }
                color: root.clSurfaceVariantFg
            }

            Rectangle {
                width: 26 * centerScale
                height: 26 * centerScale
                radius: width / 2
                color: Qt.rgba(255, 255, 255, 0.08)
                visible: root.liveNotifs.length > 0

                Text {
                    anchors.centerIn: parent
                    text: "delete_sweep"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16 * centerScale
                    color: root.clSurfaceVariantFg
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearAllRequested()
                }
            }
        }

        // Empty State
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            visible: root.liveNotifs.length === 0
            spacing: 8 * centerScale

            Item { Layout.fillHeight: true }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "notifications_off"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 32 * centerScale
                color: root.clSurfaceVariantFg
                opacity: 0.5
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No Notifications"
                font { pixelSize: 14 * centerScale; family: "Outfit" }
                color: root.clSurfaceVariantFg
                opacity: 0.7
            }

            Item { Layout.fillHeight: true }
        }

        // Notifications List
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8 * centerScale
            boundsBehavior: Flickable.StopAtBounds
            visible: root.liveNotifs.length > 0
            model: root.liveNotifs

            delegate: Rectangle {
                width: ListView.view.width
                height: notifRowLayout.implicitHeight + 16 * root.centerScale
                radius: 12 * root.centerScale
                color: root.clSurfaceContainerHighest

                RowLayout {
                    id: notifRowLayout
                    anchors.fill: parent
                    anchors.margins: 10 * root.centerScale
                    spacing: 10 * root.centerScale

                    // Icon Container
                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        width: 32 * root.centerScale
                        height: 32 * root.centerScale
                        radius: 16 * root.centerScale
                        color: root.clSurfaceContainer
                        clip: true

                        Image {
                            id: notifImg
                            anchors.fill: parent
                            source: modelData.image && !modelData.image.startsWith("image://") ? ("file://" + modelData.image) : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: 18 * root.centerScale
                            height: 18 * root.centerScale
                            source: modelData.appIcon || modelData.appName || "preferences-desktop-notification"
                            fallback: "preferences-desktop-notification"
                            visible: !notifImg.visible
                        }
                    }

                    // Text Content
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2 * root.centerScale

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: modelData.summary || modelData.appName || "Notification"
                                font { pixelSize: 13 * root.centerScale; family: "Outfit"; weight: Font.Medium }
                                color: root.clSurfaceFg
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.formatNotifTime(modelData.time)
                                font { pixelSize: 11 * root.centerScale; family: "Outfit" }
                                color: root.clSurfaceVariantFg
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.body || ""
                            font { pixelSize: 12 * root.centerScale; family: "Outfit" }
                            color: root.clSurfaceVariantFg
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.WordWrap
                            visible: Boolean(text && text.length > 0)
                        }
                    }
                }
            }
        }
    }
}
