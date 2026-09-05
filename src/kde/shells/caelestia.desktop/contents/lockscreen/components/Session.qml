/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import ".."
import QtQuick.Layouts
import org.kde.plasma.plasma5support as Plasma5Support

Item {
    id: root
    
    property bool isAuthenticating: false
    property real centerScale: 1.0
    
    property color clPrimary
    property color clSurfaceVariantFg
    
    implicitWidth: 32 * centerScale
    implicitHeight: 32 * centerScale
    
    opacity: isAuthenticating ? 0 : 1
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 150 } }

    Plasma5Support.DataSource {
        id: sessionActionSource
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => disconnectSource(source)
    }

    Text {
        anchors.centerIn: parent
        text: "logout"
        font.family: Config.fontIcon
        font.pixelSize: Config.sizeLarge * centerScale
        color: logoutMouse.containsMouse ? root.clPrimary : root.clSurfaceVariantFg
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: logoutMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: sessionActionSource.connectSource("qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout 2>/dev/null")
    }
}
