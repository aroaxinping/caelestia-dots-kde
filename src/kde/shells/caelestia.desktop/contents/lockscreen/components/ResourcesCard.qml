/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import M3Shapes
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root

    property int liveCpu: 0
    property int liveTemp: 0
    property int liveRam: 0
    property int liveDisk: 0

    property real cpuPercentage: 0.0
    property real memoryPercentage: 0.0
    property real storagePercentage: 0.0

    property real centerScale: 1.0

    property color clSurface: "#131317"
    property color clSurfaceContainerHigh: "#2a292e"
    property color clSurfaceFg: "#e5e1e7"
    property color clSurfaceVariantFg: "#c8c5d1"
    property color clPrimary: "#c2c1ff"
    property color clSecondary: "#c6c4e0"
    property color clError: "#ffb4ab"

    radius: 20 * centerScale
    color: "transparent"

    RowLayout {
        anchors.fill: parent
        spacing: 12 * centerScale

        // CPU Resource (MaterialShape.Pentagon)
        ResourceItem {
            id: cpu
            Layout.fillWidth: true
            Layout.fillHeight: true
            centerScale: root.centerScale
            icon: "memory"
            value: root.liveCpu + "%"
            shapeType: MaterialShape.Pentagon
            shapeColor: root.clSurfaceContainerHigh
            fillColor: Qt.rgba(root.clPrimary.r, root.clPrimary.g, root.clPrimary.b, 0.38)
            fillPercent: Math.max(0, Math.min(1.0, root.cpuPercentage))
            clSurfaceFg: root.clSurfaceFg
            clSurfaceVariantFg: root.clSurfaceVariantFg

            MaterialShape {
                id: tempBadge
                x: cpu.mShape.pointAtAngle(45).x - implicitSize / 2 + 8 * root.centerScale
                y: cpu.mShape.pointAtAngle(45).y - implicitSize / 2
                shape: root.liveTemp > 90 ? MaterialShape.SoftBurst : MaterialShape.Circle
                color: root.liveTemp > 90 ? root.clError : Qt.rgba(root.clSecondary.r, root.clSecondary.g, root.clSecondary.b, 0.25)
                implicitSize: 28 * root.centerScale

                Text {
                    anchors.centerIn: parent
                    text: root.liveTemp + "°C"
                    font { pixelSize: 10 * root.centerScale; family: "Outfit"; weight: Font.Medium }
                    color: root.liveTemp > 90 ? root.clSurface : root.clSecondary
                }
            }
        }

        // RAM Resource (MaterialShape.Slanted)
        ResourceItem {
            id: ram
            Layout.fillWidth: true
            Layout.fillHeight: true
            centerScale: root.centerScale
            icon: "memory_alt"
            value: root.liveRam + "%"
            shapeType: MaterialShape.Slanted
            shapeColor: root.clSurfaceContainerHigh
            fillColor: Qt.rgba(root.clSecondary.r, root.clSecondary.g, root.clSecondary.b, 0.38)
            fillPercent: Math.max(0, Math.min(1.0, root.memoryPercentage))
            clSurfaceFg: root.clSurfaceFg
            clSurfaceVariantFg: root.clSurfaceVariantFg
        }

        // Storage Resource (MaterialShape.Gem)
        ResourceItem {
            id: disk
            Layout.fillWidth: true
            Layout.fillHeight: true
            centerScale: root.centerScale
            icon: "hard_disk"
            value: root.liveDisk + "%"
            shapeType: MaterialShape.Gem
            shapeColor: root.clSurfaceContainerHigh
            fillColor: Qt.rgba(root.clSurfaceFg.r, root.clSurfaceFg.g, root.clSurfaceFg.b, 0.22)
            fillPercent: Math.max(0, Math.min(1.0, root.storagePercentage))
            clSurfaceFg: root.clSurfaceFg
            clSurfaceVariantFg: root.clSurfaceVariantFg
        }
    }

    component ResourceItem: Item {
        id: res

        property real centerScale: 1.0
        property string icon: ""
        property string value: ""
        property int shapeType: MaterialShape.Circle
        property color shapeColor: "#2a292e"
        property color fillColor: "cyan"
        property real fillPercent: 0.0
        property color clSurfaceFg: "#e5e1e7"
        property color clSurfaceVariantFg: "#c8c5d1"

        readonly property alias mShape: shape

        MaterialShape {
            id: shape
            anchors.fill: parent
            shape: res.shapeType
            color: res.shapeColor
        }

        Item {
            anchors.fill: shape
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: shape
            }

            Shape {
                id: wave
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.max(0, Math.min(parent.height, parent.height * res.fillPercent))
                visible: height > 0

                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillColor: res.fillColor

                    PathSvg {
                        path: {
                            const w = wave.width;
                            const h = wave.height;
                            if (w <= 0 || h <= 0) return "";
                            const a = 2.5 * res.centerScale;
                            const n = 3;
                            const wl = w / n;
                            const half = wl / 2;

                            let d = `M 0,${a} `;
                            for (let i = 0; i < n; ++i) {
                                const x = i * wl;
                                d += `Q ${x + half / 2},${-a} ${x + half},${a} `;
                                d += `Q ${x + half + half / 2},${3 * a} ${x + wl},${a} `;
                            }
                            d += `L ${w},${h} L 0,${h} Z`;
                            return d;
                        }
                    }
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2 * res.centerScale

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: res.icon
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20 * res.centerScale
                color: res.clSurfaceVariantFg
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: res.value
                font { pixelSize: 14 * res.centerScale; family: "Outfit"; weight: Font.Medium }
                color: res.clSurfaceFg
            }
        }
    }
}
