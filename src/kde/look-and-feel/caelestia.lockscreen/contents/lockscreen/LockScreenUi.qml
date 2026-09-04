/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.workspace.components as PW
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import org.kde.kscreenlocker as ScreenLocker

import org.kde.plasma.private.sessions

Item {
    id: lockScreenUi

    readonly property real centerScale: Math.min(1, Math.min(width, height) / 1440)
    readonly property real centerWidth: 600 * centerScale
    readonly property bool isPortrait: height > width * 1.2
    readonly property bool use12h: Qt.locale().timeFormat(Locale.ShortFormat).indexOf("AP") !== -1
                                || Qt.locale().timeFormat(Locale.ShortFormat).indexOf("ap") !== -1

    // Material You palette — defaults from Catppuccin Mocha,
    // overridden by scheme.json at lock time via DataSource below.
    property color clSurface: "#131317"
    property color clSurfaceFg: "#e5e1e7"
    property color clSurfaceContainer: "#201f23"
    property color clSurfaceContainerHigh: "#2a292e"
    property color clSurfaceContainerHighest: "#353438"
    property color clPrimary: "#c2c1ff"
    property color clSecondary: "#c6c4e0"
    property color clPrimaryFg: "#2a2a60"
    property color clError: "#ffb4ab"
    property color clSurfaceVariantFg: "#c8c5d1"

    property bool isAuthenticating: false
    property string authMessage: ""

    // XHR file:// is blocked inside kscreenlocker, so read scheme.json via cat
    Plasma5Support.DataSource {
        id: schemeLoader
        engine: "executable"
        connectedSources: ["cat /home/" + kscreenlocker_userName + "/.local/state/caelestia/scheme.json 2>/dev/null"]
        onNewData: (source, data) => {
            var stdout = data["stdout"] || "";
            if (!stdout) return;
            try {
                var c = JSON.parse(stdout);
                c = c.colours || c;
                if (c.surface) clSurface = "#" + c.surface;
                if (c.onSurface) clSurfaceFg = "#" + c.onSurface;
                if (c.surfaceContainer) clSurfaceContainer = "#" + c.surfaceContainer;
                if (c.surfaceContainerHigh) clSurfaceContainerHigh = "#" + c.surfaceContainerHigh;
                if (c.surfaceContainerHighest) clSurfaceContainerHighest = "#" + c.surfaceContainerHighest;
                if (c.primary) clPrimary = "#" + c.primary;
                if (c.secondary) clSecondary = "#" + c.secondary;
                if (c.onPrimary) clPrimaryFg = "#" + c.onPrimary;
                if (c.error) clError = "#" + c.error;
                if (c.onSurfaceVariant) clSurfaceVariantFg = "#" + c.onSurfaceVariant;
            } catch(e) {}
        }
    }

    function startLogin() {
        if (passwordBox.text.length === 0) return;
        isAuthenticating = true;
        authenticator.respond(passwordBox.text);
    }

    Connections {
        target: authenticator
        function onFailed(kind) {
            if (kind !== 0) return;
            lockScreenUi.isAuthenticating = false;
            lockScreenUi.authMessage = i18ndc("plasma_shell_org.kde.plasma.desktop",
                "@info:status", "Unlocking failed");
            graceLockTimer.restart();
            notificationRemoveTimer.restart();
            rejectAnim.start();
            msgAppearAnim.start();
        }
        function onSucceeded() { Qt.quit(); }
        function onInfoMessageChanged() {
            lockScreenUi.authMessage = authenticator.infoMessage;
            if (lockScreenUi.authMessage) msgAppearAnim.start();
        }
        function onErrorMessageChanged() {
            lockScreenUi.authMessage = authenticator.errorMessage;
            if (lockScreenUi.authMessage) msgAppearAnim.start();
        }
        function onPromptForSecretChanged() { passwordBox.forceActiveFocus(); }
    }

    SessionManagement { id: sessionManagement }
    KeyboardIndicator.KeyState { id: capsLockState; key: Qt.Key_CapsLock }
    Connections { target: sessionManagement; function onAboutToSuspend() { root.clearPassword(); } }

    Timer { id: notificationRemoveTimer; interval: 3000; onTriggered: msgExitAnim.start() }
    Timer {
        id: graceLockTimer; interval: 3000
        onTriggered: { root.clearPassword(); authenticator.startAuthenticating(); }
    }

    // Error text: appear → flash → exit (matches original StateMessage.qml)
    SequentialAnimation {
        id: msgAppearAnim
        PropertyAction { target: errorText; property: "visible"; value: true }
        ParallelAnimation {
            NumberAnimation { target: errorText; property: "scale"; from: 0.7; to: 1; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: errorText; property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
        }
        onFinished: msgFlashAnim.start()
    }
    SequentialAnimation {
        id: msgFlashAnim; loops: 2
        NumberAnimation { target: errorText; property: "opacity"; to: 0.3; duration: 150 }
        NumberAnimation { target: errorText; property: "opacity"; to: 1; duration: 150 }
    }
    SequentialAnimation {
        id: msgExitAnim
        ParallelAnimation {
            NumberAnimation { target: errorText; property: "scale"; to: 0.7; duration: 400; easing.type: Easing.InOutQuad }
            NumberAnimation { target: errorText; property: "opacity"; to: 0; duration: 400; easing.type: Easing.InOutQuad }
        }
        PropertyAction { target: errorText; property: "visible"; value: false }
        onFinished: lockScreenUi.authMessage = ""
    }

    SequentialAnimation {
        id: rejectAnim
        NumberAnimation { target: passwordPill; property: "shakeX"; to: -20; duration: 80; easing.type: Easing.InQuad }
        NumberAnimation { target: passwordPill; property: "shakeX"; to: 16; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: passwordPill; property: "shakeX"; to: -10; duration: 80; easing.type: Easing.InOutQuad }
        NumberAnimation { target: passwordPill; property: "shakeX"; to: 0; duration: 120; easing.type: Easing.OutQuad }
    }

    Item { anchors.fill: parent; children: [wallpaper] }

    FocusScope {
        id: lockScreenRoot
        anchors.fill: parent
        focus: true

        Component.onCompleted: authenticator.startAuthenticating()

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.ArrowCursor
            onPressed: mouse => { passwordBox.forceActiveFocus(); mouse.accepted = false; }
        }

        // kscreenlocker may not hand focus to the greeter immediately
        Item {
            Timer {
                interval: 300; repeat: true; running: true
                property int n: 0
                onTriggered: { passwordBox.forceActiveFocus(); if (++n >= 10) repeat = false; }
            }
        }

        Keys.onPressed: event => { passwordBox.forceActiveFocus(); event.accepted = false; }
        Keys.onEscapePressed: root.clearPassword()

        // ── Landscape ──
        ColumnLayout {
            anchors.centerIn: parent
            width: lockScreenUi.centerWidth
            spacing: 20 * lockScreenUi.centerScale
            visible: !lockScreenUi.isPortrait

            Row {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 16 * lockScreenUi.centerScale
                spacing: 8 * lockScreenUi.centerScale

                Text {
                    id: hoursText
                    text: formatHours(new Date())
                    font { pixelSize: 180 * lockScreenUi.centerScale; weight: Font.Medium; family: "Rubik" }
                    color: lockScreenUi.clPrimary

                    function formatHours(d) {
                        var h = d.getHours();
                        if (lockScreenUi.use12h) { h = h % 12; if (h === 0) h = 12; }
                        return h < 10 ? "0" + h : "" + h;
                    }
                }

                Text {
                    text: ":"
                    font { pixelSize: 180 * lockScreenUi.centerScale; weight: Font.Medium; family: "Rubik" }
                    color: lockScreenUi.clPrimary
                    anchors.baseline: hoursText.baseline
                }

                Text {
                    id: minutesText
                    text: formatMinutes(new Date())
                    font {
                        pixelSize: (lockScreenUi.use12h ? 100 : 180) * lockScreenUi.centerScale
                        weight: Font.Medium; family: "Rubik"
                    }
                    color: lockScreenUi.clSecondary
                    anchors.baseline: hoursText.baseline

                    function formatMinutes(d) {
                        var m = d.getMinutes();
                        return m < 10 ? "0" + m : "" + m;
                    }
                }

                Rectangle {
                    visible: lockScreenUi.use12h
                    width: ampmLabel.implicitWidth + 16 * lockScreenUi.centerScale
                    height: ampmLabel.implicitHeight + 8 * lockScreenUi.centerScale
                    radius: height / 2
                    color: lockScreenUi.clSurfaceContainerHigh
                    anchors.bottom: minutesText.bottom
                    anchors.bottomMargin: 8 * lockScreenUi.centerScale

                    Text {
                        id: ampmLabel
                        anchors.centerIn: parent
                        text: new Date().getHours() >= 12 ? "PM" : "AM"
                        font { pixelSize: 14 * lockScreenUi.centerScale; weight: Font.DemiBold; family: "Rubik" }
                        color: lockScreenUi.clSurfaceFg
                    }
                }

                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: {
                        var now = new Date();
                        hoursText.text = hoursText.formatHours(now);
                        minutesText.text = minutesText.formatMinutes(now);
                        if (lockScreenUi.use12h) ampmLabel.text = now.getHours() >= 12 ? "PM" : "AM";
                    }
                }
            }

            Text {
                id: dateText
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(new Date(), "dddd . d MMM").toUpperCase()
                font { pixelSize: 16 * lockScreenUi.centerScale; weight: Font.DemiBold; letterSpacing: 1.2; family: "Rubik" }
                color: lockScreenUi.clSurfaceFg

                Timer {
                    interval: 60000; running: true; repeat: true
                    onTriggered: dateText.text = Qt.formatDate(new Date(), "dddd . d MMM").toUpperCase()
                }
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 32 * lockScreenUi.centerScale
                Layout.bottomMargin: 24 * lockScreenUi.centerScale
                implicitWidth: lockScreenUi.centerWidth * 0.7
                implicitHeight: implicitWidth

                Rectangle {
                    id: profileCircle
                    anchors.fill: parent
                    radius: width / 2
                    color: lockScreenUi.clSurfaceContainerHighest

                    Image {
                        id: profileImage
                        anchors.fill: parent
                        source: kscreenlocker_userImage || ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle { width: profileImage.width; height: profileImage.height; radius: profileCircle.radius }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: parent.width * 0.45
                        color: lockScreenUi.clSurfaceVariantFg
                        visible: profileImage.status !== Image.Ready
                    }
                }
            }

            Item {
                id: passwordPill
                Layout.alignment: Qt.AlignHCenter
                property real shakeX: 0
                property real pillWidth: passwordBox.text.length > 0
                    ? lockScreenUi.centerWidth * 0.82
                    : lockScreenUi.centerWidth * 0.58

                implicitWidth: pillWidth
                implicitHeight: 60 * lockScreenUi.centerScale
                transform: Translate { x: passwordPill.shakeX }

                Rectangle {
                    id: pillRect
                    width: passwordPill.pillWidth
                    height: parent.implicitHeight
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: height / 2
                    color: lockScreenUi.clSurfaceContainer
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.InOutCubic } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        onClicked: passwordBox.forceActiveFocus()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14 * lockScreenUi.centerScale
                        anchors.rightMargin: 8 * lockScreenUi.centerScale
                        spacing: 10 * lockScreenUi.centerScale

                        Item {
                            Layout.fillHeight: true
                            implicitWidth: height

                            Text {
                                anchors.centerIn: parent
                                text: (authenticator.authenticatorTypes & ScreenLocker.Authenticator.Fingerprint) ? "" : ""
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 22 * lockScreenUi.centerScale
                                color: lockScreenUi.clSurfaceVariantFg
                                visible: !lockScreenUi.isAuthenticating
                            }

                            // Spinner while authenticating
                            Item {
                                id: spinner
                                anchors.centerIn: parent
                                width: 22 * lockScreenUi.centerScale; height: width
                                visible: lockScreenUi.isAuthenticating
                                Rectangle {
                                    width: parent.width * 0.3; height: width; radius: width / 2
                                    color: lockScreenUi.clPrimary
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
                            font { pixelSize: 16 * lockScreenUi.centerScale; family: "Rubik" }
                            text: PasswordSync.password
                            placeholderText: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:placeholder", "Password")
                            enabled: !authenticator.graceLocked
                            focus: true
                            cursorVisible: activeFocus
                            background: Item {}
                            color: lockScreenUi.clSurfaceFg
                            placeholderTextColor: lockScreenUi.clSurfaceVariantFg
                            onAccepted: lockScreenUi.startLogin()

                            Connections {
                                target: root
                                function onClearPassword() {
                                    passwordBox.forceActiveFocus();
                                    passwordBox.text = "";
                                    passwordBox.text = Qt.binding(() => PasswordSync.password);
                                }
                            }
                        }
                        Binding { target: PasswordSync; property: "password"; value: passwordBox.text }

                        Item {
                            implicitWidth: implicitHeight
                            implicitHeight: parent.height - 12 * lockScreenUi.centerScale

                            Rectangle {
                                id: enterBtn
                                anchors.fill: parent
                                radius: passwordBox.text.length > 0 ? width * 0.25 : width / 2
                                color: passwordBox.text.length > 0 ? lockScreenUi.clPrimary : lockScreenUi.clSurfaceContainerHigh
                                scale: enterMouse.pressed ? 0.85 : (enterMouse.containsMouse ? 0.95 : 1.0)

                                Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 300 } }
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: ""
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 20 * lockScreenUi.centerScale
                                    color: passwordBox.text.length > 0 ? lockScreenUi.clPrimaryFg : lockScreenUi.clSurfaceVariantFg
                                    rotation: passwordBox.text.length > 0 ? 0 : 90
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                    Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    id: enterMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: passwordBox.text.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: lockScreenUi.startLogin()
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.topMargin: 8 * lockScreenUi.centerScale
                implicitHeight: Math.max(capsText.implicitHeight, errorText.implicitHeight, fpHint.implicitHeight)

                Text {
                    id: capsText
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: capsLockState.locked && !lockScreenUi.authMessage
                    text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status", "Caps Lock is on")
                    font { pixelSize: 13 * lockScreenUi.centerScale; family: "Rubik" }
                    color: lockScreenUi.clSurfaceVariantFg
                    wrapMode: Text.WordWrap
                    opacity: visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }

                Text {
                    id: errorText
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: false
                    text: lockScreenUi.authMessage
                    font { pixelSize: 13 * lockScreenUi.centerScale; family: "Rubik" }
                    color: lockScreenUi.clError
                    wrapMode: Text.WordWrap
                    scale: 0.7; opacity: 0
                }

                Text {
                    id: fpHint
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: (errorText.visible ? errorText : (capsText.visible ? capsText : parent)).bottom
                    anchors.topMargin: 6 * lockScreenUi.centerScale
                    visible: authenticator.authenticatorTypes & ScreenLocker.Authenticator.Fingerprint
                    text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:usagetip", "(or scan your fingerprint on the reader)")
                    font { pixelSize: 11 * lockScreenUi.centerScale; family: "Rubik" }
                    color: lockScreenUi.clSurfaceVariantFg
                }
            }
        }

        // ── Portrait ──
        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width * 0.9
            spacing: 20 * lockScreenUi.centerScale
            visible: lockScreenUi.isPortrait

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                spacing: 24 * lockScreenUi.centerScale

                Rectangle {
                    Layout.preferredWidth: lockScreenUi.centerWidth * 0.4
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: width / 2
                    color: lockScreenUi.clSurfaceContainerHighest

                    Image {
                        id: portraitProfileImage
                        anchors.fill: parent
                        source: kscreenlocker_userImage || ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle { width: portraitProfileImage.width; height: portraitProfileImage.height; radius: width / 2 }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: parent.width * 0.45
                        color: lockScreenUi.clSurfaceVariantFg
                        visible: portraitProfileImage.status !== Image.Ready
                    }
                }

                ColumnLayout {
                    spacing: 4 * lockScreenUi.centerScale

                    Row {
                        spacing: 6 * lockScreenUi.centerScale
                        Text {
                            id: portraitHours
                            text: hoursText.text
                            font { pixelSize: 120 * lockScreenUi.centerScale; weight: Font.Medium; family: "Rubik" }
                            color: lockScreenUi.clPrimary
                        }
                        Text {
                            text: ":"
                            font { pixelSize: 120 * lockScreenUi.centerScale; weight: Font.Medium; family: "Rubik" }
                            color: lockScreenUi.clPrimary
                            anchors.baseline: portraitHours.baseline
                        }
                        Text {
                            text: minutesText.text
                            font {
                                pixelSize: (lockScreenUi.use12h ? 70 : 120) * lockScreenUi.centerScale
                                weight: Font.Medium; family: "Rubik"
                            }
                            color: lockScreenUi.clSecondary
                            anchors.baseline: portraitHours.baseline
                        }
                    }

                    Text {
                        text: dateText.text
                        font { pixelSize: 14 * lockScreenUi.centerScale; weight: Font.DemiBold; letterSpacing: 1.0; family: "Rubik" }
                        color: lockScreenUi.clSurfaceFg
                    }
                }
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 16 * lockScreenUi.centerScale
                property real pillWidth: passwordBox.text.length > 0
                    ? lockScreenUi.centerWidth * 0.8
                    : lockScreenUi.centerWidth * 0.55
                implicitWidth: pillWidth
                implicitHeight: 56 * lockScreenUi.centerScale

                Rectangle {
                    width: parent.pillWidth; height: parent.implicitHeight
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: height / 2
                    color: lockScreenUi.clSurfaceContainer
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.InOutCubic } }

                    MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onClicked: passwordBox.forceActiveFocus() }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6 * lockScreenUi.centerScale
                        anchors.rightMargin: 6 * lockScreenUi.centerScale
                        spacing: 10 * lockScreenUi.centerScale

                        Item {
                            Layout.fillHeight: true; implicitWidth: height
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 22 * lockScreenUi.centerScale
                                color: lockScreenUi.clSurfaceVariantFg
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            color: "transparent"
                            Text {
                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left
                                text: passwordBox.text.length > 0 ? "•".repeat(passwordBox.text.length) : passwordBox.placeholderText
                                font { pixelSize: 16 * lockScreenUi.centerScale; family: "Rubik" }
                                color: passwordBox.text.length > 0 ? lockScreenUi.clSurfaceFg : lockScreenUi.clSurfaceVariantFg
                            }
                            MouseArea { anchors.fill: parent; onClicked: passwordBox.forceActiveFocus() }
                        }

                        Item {
                            implicitWidth: implicitHeight; implicitHeight: parent.height - 12 * lockScreenUi.centerScale
                            Rectangle {
                                anchors.fill: parent
                                radius: passwordBox.text.length > 0 ? width * 0.25 : width / 2
                                color: passwordBox.text.length > 0 ? lockScreenUi.clPrimary : lockScreenUi.clSurfaceContainerHigh
                                Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 300 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: ""
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 20 * lockScreenUi.centerScale
                                    color: passwordBox.text.length > 0 ? lockScreenUi.clPrimaryFg : lockScreenUi.clSurfaceVariantFg
                                    rotation: passwordBox.text.length > 0 ? 0 : 90
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                    Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                }
                                MouseArea {
                                    anchors.fill: parent; hoverEnabled: true
                                    cursorShape: passwordBox.text.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: lockScreenUi.startLogin()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: Kirigami.Units.smallSpacing }
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.ToolButton {
            icon.name: "input-keyboard"
            PW.KeyboardLayoutSwitcher { id: kls; anchors.fill: parent; acceptedButtons: Qt.NoButton }
            text: kls.layoutNames.longName
            onClicked: kls.keyboardLayout.switchToNextLayout()
            visible: kls.hasMultipleKeyboardLayouts
            Layout.fillHeight: true
        }
        Item { Layout.fillWidth: true }
    }

    Binding { target: root; property: "viewVisible"; value: true }
}
