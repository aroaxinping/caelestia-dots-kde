/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.private.sessions
import ".."

Item {
    id: root

    property real centerScale: 1.0
    property real centerWidth: 600 * centerScale
    property bool isAuthenticating: false
    property bool graceLocked: false
    property bool hasFingerprint: false

    property color clSurfaceContainer: "#201f23"
    property color clSurfaceContainerHigh: "#2a292e"
    property color clSurfaceFg: "#e5e1e7"
    property color clSurfaceVariantFg: "#c8c5d1"
    property color clPrimary: "#c2c1ff"
    property color clPrimaryFg: "#2a2a60"

    property alias text: passwordBox.text
    property real shakeX: 0
    property real pillWidth: passwordBox.text.length > 0
        ? root.centerWidth * 0.82
        : root.centerWidth * 0.58

    signal loginRequested(string password)

    function forceActiveFocus() {
        passwordBox.forceActiveFocus();
    }

    function shake() {
        rejectAnim.restart();
    }

    function clearPassword() {
        passwordBox.forceActiveFocus();
        passwordBox.text = "";
        passwordBox.text = Qt.binding(() => PasswordSync.password);
    }

    implicitWidth: pillWidth
    implicitHeight: 60 * centerScale
    transform: Translate { x: root.shakeX }

    SequentialAnimation {
        id: rejectAnim
        NumberAnimation { target: root; property: "shakeX"; to: -20; duration: 80; easing.type: Easing.InQuad }
        NumberAnimation { target: root; property: "shakeX"; to: 16; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeX"; to: -10; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeX"; to: 0; duration: 120; easing.type: Easing.OutQuad }
    }

    Rectangle {
        id: pillRect
        width: root.pillWidth
        height: parent.implicitHeight
        anchors.horizontalCenter: parent.horizontalCenter
        radius: height / 2
        color: root.clSurfaceContainer
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.InOutCubic } }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: root.forceActiveFocus()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14 * root.centerScale
            anchors.rightMargin: 8 * root.centerScale
            spacing: 10 * root.centerScale

            Item {
                Layout.fillHeight: true
                implicitWidth: height

                Text {
                    anchors.centerIn: parent
                    text: root.hasFingerprint ? "fingerprint" : "lock"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22 * root.centerScale
                    color: root.clSurfaceVariantFg
                    visible: !root.isAuthenticating
                }

                // Spinner while authenticating
                Item {
                    id: spinner
                    anchors.centerIn: parent
                    width: 22 * root.centerScale; height: width
                    visible: root.isAuthenticating
                    Rectangle {
                        width: parent.width * 0.3; height: width; radius: width / 2
                        color: root.clPrimary
                        x: parent.width / 2 - width / 2; y: 0
                    }
                    RotationAnimation on rotation {
                        from: 0; to: 360; duration: 1200
                        loops: Animation.Infinite; running: spinner.visible
                    }
                }
            }

            PlasmaComponents3.TextField {
                id: passwordBox
                Layout.fillWidth: true
                Layout.fillHeight: true
                echoMode: TextInput.Password
                font { pixelSize: 16 * root.centerScale; family: "Rubik" }
                text: PasswordSync.password
                placeholderText: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:placeholder", "Password")
                enabled: !root.graceLocked
                focus: true
                cursorVisible: activeFocus
                background: Item {}
                color: root.clSurfaceFg
                placeholderTextColor: root.clSurfaceVariantFg
                onAccepted: root.loginRequested(passwordBox.text)
            }
            Binding { target: PasswordSync; property: "password"; value: passwordBox.text }

            Item {
                implicitWidth: implicitHeight
                implicitHeight: parent.height - 12 * root.centerScale

                Rectangle {
                    id: enterBtn
                    anchors.fill: parent
                    radius: passwordBox.text.length > 0 ? width * 0.25 : width / 2
                    color: passwordBox.text.length > 0 ? root.clPrimary : root.clSurfaceContainerHigh
                    scale: enterMouse.pressed ? 0.85 : (enterMouse.containsMouse ? 0.95 : 1.0)

                    Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 300 } }
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.centerIn: parent
                        text: "arrow_forward"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 20 * root.centerScale
                        color: passwordBox.text.length > 0 ? root.clPrimaryFg : root.clSurfaceVariantFg
                        rotation: passwordBox.text.length > 0 ? 0 : 90
                        Behavior on color { ColorAnimation { duration: 300 } }
                        Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: enterMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: passwordBox.text.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.loginRequested(passwordBox.text)
                    }
                }
            }
        }
    }
}
