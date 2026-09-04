/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import M3Shapes
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property string userImage: ""
    property string userName: ""
    property real centerScale: 1.0
    property int profileShape: MaterialShape.Pentagon
    property color clSurfaceContainerHighest: "#353438"
    property color clSurfaceVariantFg: "#c8c5d1"

    MaterialShape {
        id: shape
        anchors.centerIn: parent
        implicitSize: root.width
        shape: root.profileShape
        color: root.clSurfaceContainerHighest
    }

    Text {
        anchors.centerIn: parent
        text: "person"
        font.family: "Material Symbols Rounded"
        font.pixelSize: root.width * 0.4
        color: root.clSurfaceVariantFg
        visible: profileImage.status !== Image.Ready
    }

    Image {
        id: profileImage
        anchors.fill: shape
        source: (root.userImage && root.userImage.toString().length > 0)
            ? root.userImage
            : (root.userName ? ("file:///home/" + root.userName + "/.face") : "")
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: shape
        }
    }
}
