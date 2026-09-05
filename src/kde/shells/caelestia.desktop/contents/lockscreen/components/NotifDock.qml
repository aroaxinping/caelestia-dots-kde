/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    property var liveNotifs: []
    property real centerScale: 1.0
    property bool isCaelestiaMode: false

    property color clSurfaceContainer: "#201f23"
    property color clSurfaceContainerHigh: "#2a292e"
    property color clSurfaceContainerHighest: "#353438"
    property color clSecondaryContainer: "#4f343a"
    property color clSurfaceFg: "#e5e1e7"
    property color clSurfaceVariantFg: "#c8c5d1"
    property color clOutline: "#837174"

    signal clearAllRequested()

    property var groupedNotifs: []

    function resolveImageUrl(img) {
        if (!img) return "";
        var s = img.toString();
        if (s.startsWith("image://icon/")) {
            s = s.substring("image://icon/".length);
        }
        if (s.startsWith("/")) {
            return "file://" + s;
        }
        return s;
    }

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

    function updateGroups() {
        var list = root.liveNotifs || [];
        if (list.length === 0) {
            groupedNotifs = [];
            return;
        }
        var map = {};
        var order = [];
        for (var i = 0; i < list.length; i++) {
            var n = list[i];
            if (n.closed) continue;
            var app = n.appName || "Notifications";
            if (!map[app]) {
                map[app] = {
                    appName: app,
                    notifs: [],
                    image: "",
                    appIcon: "",
                    urgency: 0,
                    latestTime: n.time || ""
                };
                order.push(app);
            }
            var grp = map[app];
            grp.notifs.push(n);
            if (!grp.image && n.image && n.image.length > 0) {
                grp.image = n.image;
            }
            if (!grp.appIcon && n.appIcon && n.appIcon.length > 0) {
                grp.appIcon = n.appIcon;
            }
            if (n.urgency > grp.urgency) {
                grp.urgency = n.urgency;
            }
        }
        var result = [];
        for (var j = 0; j < order.length; j++) {
            result.push(map[order[j]]);
        }
        groupedNotifs = result;
    }

    onLiveNotifsChanged: updateGroups()
    Component.onCompleted: updateGroups()

    property real cardRadius: 26
    radius: cardRadius
    color: clSurfaceContainer
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16 * centerScale
        spacing: 12 * centerScale

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: root.liveNotifs.length > 0
                      ? (root.liveNotifs.length + (root.liveNotifs.length === 1 ? " notification" : " notifications"))
                      : "Notifications"
                font { pixelSize: 15; family: "Rubik"; weight: Font.Medium }
                color: root.clOutline
                elide: Text.ElideRight
            }

            Rectangle {
                visible: root.liveNotifs.length > 0
                implicitWidth: 32 * root.centerScale
                implicitHeight: 32 * root.centerScale
                radius: height / 2
                color: "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: "clear_all"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20 * root.centerScale
                    color: root.clSurfaceFg
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearAllRequested()
                    onEntered: parent.color = Qt.rgba(255, 255, 255, 0.1)
                    onExited: parent.color = "transparent"
                }
            }
        }

        // Empty/idle state: show DinoGame when there are no notifications.
        // When the game is active it stays visible even if a notification arrives
        // (so the player isn't interrupted mid-jump), matching sidebar behaviour.
        Loader {
            id: dinoLoader
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            // Active when empty OR while game is running
            active: root.liveNotifs.length === 0 || isGameRunning
            readonly property bool isGameRunning: item !== null && item.isPlaying
            opacity: active ? 1 : 0
            visible: active
            Behavior on opacity { NumberAnimation { duration: 250 } }

            sourceComponent: DinoGame {
                width: dinoLoader.width
                height: 200
                // Wire palette so the dino matches card colours
                activeColor: root.clSurfaceVariantFg
                isCaelestiaMode: root.isCaelestiaMode
            }
        }

        // Categorized Notifications List
        ListView {
            id: notifListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 10 * root.centerScale
            boundsBehavior: Flickable.StopAtBounds
            visible: root.liveNotifs.length > 0
            model: root.groupedNotifs

            delegate: Rectangle {
                id: groupCard
                width: ListView.view.width
                radius: 18 * root.centerScale
                color: modelData.urgency === 2 ? root.clSecondaryContainer : root.clSurfaceContainerHigh
                clip: true

                property bool expanded: false

                implicitHeight: groupContent.implicitHeight + 24 * root.centerScale
                Behavior on implicitHeight {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }

                RowLayout {
                    id: groupContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12 * root.centerScale
                    spacing: 12 * root.centerScale

                    // Icon / Image Container (44px)
                    Item {
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: 44 * root.centerScale
                        implicitHeight: 44 * root.centerScale

                        Rectangle {
                            id: iconCircle
                            anchors.fill: parent
                            radius: width / 2
                            color: root.clSurfaceContainerHighest
                            clip: true

                            Image {
                                id: groupImg
                                anchors.fill: parent
                                source: root.resolveImageUrl(modelData.image)
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready
                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle {
                                        width: iconCircle.width
                                        height: iconCircle.height
                                        radius: iconCircle.radius
                                    }
                                }
                            }

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 22 * root.centerScale
                                height: 22 * root.centerScale
                                source: modelData.appIcon || "preferences-desktop-notification"
                                fallback: "preferences-desktop-notification"
                                visible: !groupImg.visible
                            }
                        }

                        // App Badge when both image and appIcon exist
                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: -2 * root.centerScale
                            anchors.bottomMargin: -2 * root.centerScale
                            width: 18 * root.centerScale
                            height: 18 * root.centerScale
                            radius: width / 2
                            color: root.clSurfaceContainerHigh
                            visible: groupImg.visible && Boolean(modelData.appIcon && modelData.appIcon.length > 0)
                            z: 2

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: 11 * root.centerScale
                                height: 11 * root.centerScale
                                source: modelData.appIcon
                            }
                        }
                    }

                    // Content Column
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4 * root.centerScale

                        // Group Header Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8 * root.centerScale

                            Text {
                                Layout.fillWidth: true
                                text: modelData.appName
                                font { pixelSize: 16; family: "Rubik"; weight: Font.Medium }
                                color: root.clSurfaceVariantFg
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.formatNotifTime(modelData.latestTime)
                                font { pixelSize: 14; family: "Rubik" }
                                color: root.clOutline
                            }

                            // Expand / Collapse Pill Button (if > 3 notifications)
                            Rectangle {
                                id: expandPill
                                visible: modelData.notifs.length > 3
                                implicitWidth: expandPillLayout.implicitWidth + 16
                                implicitHeight: 24
                                radius: height / 2
                                color: root.clSurfaceContainerHighest

                                RowLayout {
                                    id: expandPillLayout
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: modelData.notifs.length
                                        font { pixelSize: 13; family: "Rubik"; weight: Font.Medium }
                                        color: root.clSurfaceFg
                                    }

                                    Text {
                                        text: groupCard.expanded ? "expand_less" : "expand_more"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 16
                                        color: root.clSurfaceFg
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: groupCard.expanded = !groupCard.expanded
                                }
                            }
                        }

                        // Notification Lines
                        Repeater {
                            model: groupCard.expanded ? modelData.notifs : modelData.notifs.slice(0, 3)

                            delegate: Item {
                                Layout.fillWidth: true
                                implicitHeight: lineText.implicitHeight

                                Text {
                                    id: lineText
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    textFormat: Text.StyledText
                                    elide: Text.ElideRight
                                    font { pixelSize: 14; family: "Rubik" }
                                    text: {
                                        var sum = (modelData.summary || "").replace(/\n/g, " ");
                                        var body = (modelData.body || "").replace(/\n/g, " ");
                                        sum = sum.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
                                        body = body.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
                                        if (body.length > 0) {
                                            return "<font color='" + root.clSurfaceFg + "'>" + sum + "</font>  <font color='" + root.clOutline + "'>" + body + "</font>";
                                        }
                                        return "<font color='" + root.clSurfaceFg + "'>" + sum + "</font>";
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
