/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property var greetingInfo: ({ greeting: "Good day", icon: "sunny", iconColor: "#c2c1ff" })
    property string userName: "User"
    property real centerScale: 1.0

    property color pillColor: Qt.rgba(255, 255, 255, 0.08)
    property color clSurfaceVariantFg: "#c8c5d1"
    property color clPrimary: "#c2c1ff"

    color: pillColor
    radius: height / 2
    implicitWidth: greetingRow.implicitWidth + 32
    implicitHeight: greetingRow.implicitHeight + 16

    RowLayout {
        id: greetingRow
        anchors.centerIn: parent
        spacing: 10

        Text {
            text: root.greetingInfo ? (root.greetingInfo.icon || "") : ""
            font.family: "Material Symbols Rounded"
            font.pixelSize: 20
            color: root.greetingInfo ? (root.greetingInfo.iconColor || root.clPrimary) : root.clPrimary
        }
        RowLayout {
            spacing: 4
            Text {
                text: (root.greetingInfo ? root.greetingInfo.greeting : "") + ","
                color: root.clSurfaceVariantFg
                font { pixelSize: 15; family: "Rubik" }
            }
            Text {
                text: root.userName || "User"
                color: root.clPrimary
                font { pixelSize: 15; family: "Rubik"; weight: Font.Bold }
            }
        }
    }
}
