/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property string userImage: ""
    property string userName: ""
    property real centerScale: 1.0
    property color clSurfaceVariantFg: "#c8c5d1"

    Canvas {
        id: pentagonMask
        anchors.fill: parent
        visible: false
        onPaint: {
            var ctx = getContext("2d");
            var w = width; var h = height;
            ctx.beginPath();
            ctx.moveTo(w * 0.5, h * 0.05); // Top point
            ctx.lineTo(w * 0.95, h * 0.38); // Top right
            ctx.lineTo(w * 0.78, h * 0.95); // Bottom right
            ctx.lineTo(w * 0.22, h * 0.95); // Bottom left
            ctx.lineTo(w * 0.05, h * 0.38); // Top left
            ctx.closePath();
            ctx.fillStyle = "white";
            ctx.fill();
        }
    }

    Rectangle {
        id: profileCircle
        anchors.fill: parent
        color: "transparent"

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                var w = width; var h = height;
                ctx.beginPath();
                ctx.moveTo(w * 0.5, h * 0.05);
                ctx.lineTo(w * 0.95, h * 0.38);
                ctx.lineTo(w * 0.78, h * 0.95);
                ctx.lineTo(w * 0.22, h * 0.95);
                ctx.lineTo(w * 0.05, h * 0.38);
                ctx.closePath();
                ctx.fillStyle = "#0c0b10";
                ctx.fill();
            }
        }

        Image {
            id: profileImage
            anchors.fill: parent
            source: (root.userImage && root.userImage.toString().length > 0)
                ? root.userImage
                : (root.userName ? ("file:///home/" + root.userName + "/.face") : "")
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: pentagonMask
            }
        }

        Text {
            anchors.centerIn: parent
            text: "person"
            font.family: "Material Symbols Rounded"
            font.pixelSize: parent.width * 0.45
            color: root.clSurfaceVariantFg
            visible: profileImage.status !== Image.Ready
        }
    }
}
