/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool use12h: false
    property real centerScale: 1.0

    property color clSurfaceFg: "#e5e1e7"
    property color clSurfaceVariantFg: "#c8c5d1"

    spacing: 20 * centerScale

    Row {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 16 * centerScale
        spacing: 4 * centerScale

        Text {
            id: hoursText
            text: formatHours(new Date())
            font { pixelSize: 180 * root.centerScale; weight: Font.Thin; family: "Outfit" }
            color: root.clSurfaceFg

            function formatHours(d) {
                var h = d.getHours();
                if (root.use12h) { h = h % 12; if (h === 0) h = 12; }
                return h < 10 ? "0" + h : "" + h;
            }
        }

        Column {
            anchors.top: hoursText.top
            anchors.topMargin: 24 * root.centerScale
            spacing: -18 * root.centerScale

            Text {
                id: minutesText
                text: formatMinutes(new Date())
                font { pixelSize: 70 * root.centerScale; weight: Font.Thin; family: "Outfit" }
                color: root.clSurfaceVariantFg

                function formatMinutes(d) {
                    var m = d.getMinutes();
                    return m < 10 ? "0" + m : "" + m;
                }
            }

            Text {
                id: ampmLabel
                visible: root.use12h
                text: new Date().getHours() >= 12 ? "PM" : "AM"
                font { pixelSize: 28 * root.centerScale; weight: Font.DemiBold; family: "Outfit" }
                color: root.clSurfaceVariantFg
            }
        }

        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: {
                var now = new Date();
                hoursText.text = hoursText.formatHours(now);
                minutesText.text = minutesText.formatMinutes(now);
                if (root.use12h) ampmLabel.text = now.getHours() >= 12 ? "PM" : "AM";
            }
        }
    }

    Text {
        id: dateText
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDate(new Date(), "dddd • d MMM").toUpperCase()
        font { pixelSize: 18 * root.centerScale; weight: Font.DemiBold; letterSpacing: 1.2; family: "Outfit" }
        color: root.clSurfaceFg

        Timer {
            interval: 60000; running: true; repeat: true
            onTriggered: dateText.text = Qt.formatDate(new Date(), "dddd • d MMM").toUpperCase()
        }
    }
}
