/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

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

    property color clSurfaceContainerHigh: "#2a292e"
    property color clSurfaceFg: "#e5e1e7"
    property color clSurfaceVariantFg: "#c8c5d1"
    property color clPrimary: "#c2c1ff"
    property color clSecondary: "#c6c4e0"

    radius: 20 * centerScale
    color: "transparent"

    RowLayout {
        anchors.fill: parent
        spacing: 4 * centerScale

        // CPU Polygon (Points Left)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Canvas {
                id: cpuCanvas
                anchors.fill: parent
                Connections {
                    target: root
                    function onLiveCpuChanged() { cpuCanvas.requestPaint(); }
                    function onCpuPercentageChanged() { cpuCanvas.requestPaint(); }
                }
                onPaint: {
                    var ctx = getContext("2d"); var w = width; var h = height;
                    ctx.beginPath(); ctx.moveTo(w*0.3, 0); ctx.lineTo(w, 0); ctx.lineTo(w*0.8, h); ctx.lineTo(w*0.3, h); ctx.lineTo(0, h*0.5); ctx.closePath();
                    ctx.fillStyle = root.clSurfaceContainerHigh; ctx.fill();

                    ctx.save();
                    ctx.clip();

                    var fillPercent = Math.max(0, Math.min(1.0, root.cpuPercentage));
                    var waveHeight = h * 0.08;
                    var startY = h - (h * fillPercent);
                    ctx.beginPath();
                    ctx.moveTo(0, h); ctx.lineTo(w, h); ctx.lineTo(w, startY);
                    ctx.bezierCurveTo(w*0.75, startY - waveHeight, w*0.25, startY + waveHeight, 0, startY);
                    ctx.closePath();

                    ctx.fillStyle = Qt.rgba(root.clPrimary.r, root.clPrimary.g, root.clPrimary.b, 0.4);
                    ctx.fill();
                    ctx.restore();
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2 * centerScale
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "memory"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20 * centerScale
                    color: root.clSurfaceVariantFg
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.liveCpu + "%"
                    font { pixelSize: 14 * centerScale; family: "Outfit" }
                    color: root.clSurfaceFg
                }
            }

            Text {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8 * centerScale
                text: root.liveTemp + "°C"
                font { pixelSize: 10 * centerScale; family: "Outfit" }
                color: root.clSurfaceVariantFg
            }
        }

        // RAM Polygon (Inverted Trapezoid)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Canvas {
                id: ramCanvas
                anchors.fill: parent
                Connections {
                    target: root
                    function onLiveRamChanged() { ramCanvas.requestPaint(); }
                    function onMemoryPercentageChanged() { ramCanvas.requestPaint(); }
                }
                onPaint: {
                    var ctx = getContext("2d"); var w = width; var h = height;
                    ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(w, 0); ctx.lineTo(w*0.8, h); ctx.lineTo(w*0.2, h); ctx.closePath();
                    ctx.fillStyle = root.clSurfaceContainerHigh; ctx.fill();

                    ctx.save();
                    ctx.clip();

                    var fillPercent = Math.max(0, Math.min(1.0, root.memoryPercentage));
                    var waveHeight = h * 0.08;
                    var startY = h - (h * fillPercent);
                    ctx.beginPath();
                    ctx.moveTo(0, h); ctx.lineTo(w, h); ctx.lineTo(w, startY);
                    ctx.bezierCurveTo(w*0.75, startY + waveHeight, w*0.25, startY - waveHeight, 0, startY);
                    ctx.closePath();

                    ctx.fillStyle = Qt.rgba(root.clSecondary.r, root.clSecondary.g, root.clSecondary.b, 0.4);
                    ctx.fill();
                    ctx.restore();
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2 * centerScale
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "memory_alt"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20 * centerScale
                    color: root.clSurfaceVariantFg
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.liveRam + "%"
                    font { pixelSize: 14 * centerScale; family: "Outfit" }
                    color: root.clSurfaceFg
                }
            }
        }

        // Storage Polygon (Points Right)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Canvas {
                id: diskCanvas
                anchors.fill: parent
                Connections {
                    target: root
                    function onLiveDiskChanged() { diskCanvas.requestPaint(); }
                    function onStoragePercentageChanged() { diskCanvas.requestPaint(); }
                }
                onPaint: {
                    var ctx = getContext("2d"); var w = width; var h = height;
                    ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(w*0.7, 0); ctx.lineTo(w, h*0.5); ctx.lineTo(w*0.7, h); ctx.lineTo(w*0.2, h); ctx.closePath();
                    ctx.fillStyle = root.clSurfaceContainerHigh; ctx.fill();

                    ctx.save();
                    ctx.clip();

                    var fillPercent = Math.max(0, Math.min(1.0, root.storagePercentage));
                    var waveHeight = h * 0.08;
                    var startY = h - (h * fillPercent);
                    ctx.beginPath();
                    ctx.moveTo(0, h); ctx.lineTo(w, h); ctx.lineTo(w, startY);
                    ctx.bezierCurveTo(w*0.75, startY - waveHeight, w*0.25, startY + waveHeight, 0, startY);
                    ctx.closePath();

                    ctx.fillStyle = Qt.rgba(root.clSurfaceFg.r, root.clSurfaceFg.g, root.clSurfaceFg.b, 0.2);
                    ctx.fill();
                    ctx.restore();
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2 * centerScale
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "hard_disk"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20 * centerScale
                    color: root.clSurfaceVariantFg
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.liveDisk + "%"
                    font { pixelSize: 14 * centerScale; family: "Outfit" }
                    color: root.clSurfaceFg
                }
            }
        }
    }
}
