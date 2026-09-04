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
import Caelestia.Services

import "components"

Item {
    id: lockScreenUi

    ServiceRef { service: Cpu }
    ServiceRef { service: Memory }
    ServiceRef { service: Storage }

    readonly property real lockHeight: Math.min(width, height)
    readonly property real lockLong: lockHeight * 0.7 * (16.0 / 9.0)
    readonly property real lockShort: lockHeight * 0.7
    readonly property real centerScale: Math.min(1, lockHeight / 1440)
    readonly property real centerWidth: 600 * centerScale
    readonly property bool isPortrait: height > width * 1.2
    readonly property bool use12h: Qt.locale().timeFormat(Locale.ShortFormat).toLowerCase().indexOf("a") !== -1

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
    property color clPrimaryContainer: "#744550"
    property color clSecondaryContainer: "#4f343a"
    property color clTertiary: "#fedeff"
    property color clOnTertiary: "#694a6f"
    property color clOutline: "#837174"

    property var clTerms: []

    property bool isAuthenticating: false
    property string authMessage: ""

    // XHR file:// is blocked inside kscreenlocker, so read scheme.json via cat
    Plasma5Support.DataSource {
        id: schemeLoader
        engine: "executable"
        connectedSources: ["cat ~/.local/state/caelestia/scheme.json 2>/dev/null"]
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
                if (c.primaryContainer) clPrimaryContainer = "#" + c.primaryContainer;
                if (c.secondaryContainer) clSecondaryContainer = "#" + c.secondaryContainer;
                if (c.tertiary) clTertiary = "#" + c.tertiary;
                if (c.onTertiary) clOnTertiary = "#" + c.onTertiary;
                if (c.outline) clOutline = "#" + c.outline;
                var terms = [];
                for (var i = 0; i < 8; i++) {
                    if (c["term" + i]) terms.push("#" + c["term" + i]);
                }
                if (terms.length > 0) lockScreenUi.clTerms = terms;
                lockScreenUi.greetingInfo = lockScreenUi.getGreeting();
            } catch(e) {}
        }
    }

    Plasma5Support.DataSource {
        id: fetchLoader
        engine: "executable"
        connectedSources: ["fastfetch -s os:kernel:uptime:packages --format json"]
        property var fetchInfo: []
        onNewData: (source, data) => {
            var stdout = data["stdout"] || "";
            if (!stdout) return;
            try {
                fetchInfo = JSON.parse(stdout);
            } catch(e) {}
        }
    }

    Plasma5Support.DataSource {
        id: weatherLoader
        engine: "executable"
        connectedSources: ["curl -s 'wttr.in/?format=j1'"]
        property var weatherInfo: null
        onNewData: (source, data) => {
            var stdout = data["stdout"] || "";
            if (!stdout) return;
            try {
                weatherInfo = JSON.parse(stdout);
            } catch(e) {}
        }
    }

    Timer {
        id: weatherTimer
        interval: 600000
        repeat: true
        running: true
        onTriggered: {
            weatherLoader.disconnectSource("curl -s 'wttr.in/?format=j1'");
            weatherLoader.connectSource("curl -s 'wttr.in/?format=j1'");
        }
    }

    readonly property int liveCpu: Math.round((Cpu.percentage ?? 0) * 100)
    readonly property int liveTemp: Math.round(Cpu.temperature ?? 0)
    readonly property int liveRam: Math.round((Memory.percentage ?? 0) * 100)
    readonly property int liveDisk: Math.round((Storage.percentage ?? 0) * 100)
    property var liveMedia: ({})

    Plasma5Support.DataSource {
        id: mprisSource
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            var stdout = data["stdout"] || "";
            disconnectSource(source);
            if (!stdout) return;
            try {
                var info = JSON.parse(stdout);
                if (info && typeof info === "object") {
                    lockScreenUi.liveMedia = info;
                }
            } catch(e) {}
        }
        function poll() {
            connectSource("python3 -c 'import json, subprocess; get = lambda p: subprocess.run([\"caelestia-shell-ipc\", \"call\", \"mpris\", \"getActive\", p], capture_output=True, text=True).stdout.strip(); t, a, u, s = get(\"trackTitle\"), get(\"trackArtist\"), get(\"trackArtUrl\"), get(\"playbackState\"); t = \"\" if t == \"No active player\" else t; print(json.dumps({\"title\": t, \"artist\": a, \"artUrl\": u, \"status\": \"Playing\" if s == \"1\" else \"Paused\"}))'");
        }
    }

    Timer {
        id: mprisTimer
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: mprisSource.poll()
    }

    Plasma5Support.DataSource {
        id: mediaActionSource
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source);
            mprisSource.poll();
        }
        function send(action) {
            connectSource("caelestia-shell-ipc call mpris " + action);
        }
    }

    property var liveNotifs: []

    Plasma5Support.DataSource {
        id: notifLoader
        engine: "executable"
        connectedSources: ["cat ~/.local/state/caelestia/notifs.json 2>/dev/null"]
        onNewData: (source, data) => {
            var stdout = data["stdout"] || "";
            disconnectSource(source);
            if (!stdout) return;
            try {
                var arr = JSON.parse(stdout);
                if (Array.isArray(arr)) {
                    lockScreenUi.liveNotifs = arr;
                }
            } catch(e) {}
        }
        function poll() {
            connectSource("cat ~/.local/state/caelestia/notifs.json 2>/dev/null");
        }
    }

    Timer {
        id: notifTimer
        interval: 3000
        repeat: true
        running: true
        onTriggered: notifLoader.poll()
    }

    Plasma5Support.DataSource {
        id: notifActionSource
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source);
            notifLoader.poll();
        }
        function clearAll() {
            connectSource("caelestia-shell-ipc call notifs clear");
        }
    }

    property var greetingInfo: getGreeting()
    function getGreeting() {
        var hour = new Date().getHours();
        if (hour >= 5 && hour < 12) return { greeting: qsTr("Good morning"), icon: "sunny", iconColor: lockScreenUi.clPrimary };
        if (hour >= 12 && hour < 17) return { greeting: qsTr("Good afternoon"), icon: "light_mode", iconColor: lockScreenUi.clPrimary };
        if (hour >= 17 && hour < 22) return { greeting: qsTr("Good evening"), icon: "routine", iconColor: lockScreenUi.clSecondary };
        return { greeting: qsTr("Good night"), icon: "bedtime", iconColor: lockScreenUi.clPrimary };
    }

    Timer {
        interval: 60000; running: true; repeat: true
        onTriggered: lockScreenUi.greetingInfo = lockScreenUi.getGreeting()
    }

    function startLogin(pass) {
        var p = pass !== undefined ? pass : (passwordPill ? passwordPill.text : "");
        if (!p || p.length === 0) return;
        isAuthenticating = true;
        authenticator.respond(p);
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
            if (passwordPill) passwordPill.shake();
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
        function onPromptForSecretChanged() {
            if (passwordPill) passwordPill.forceActiveFocus();
        }
    }

    SessionManagement { id: sessionManagement }
    KeyboardIndicator.KeyState { id: capsLockState; key: Qt.Key_CapsLock }
    Connections { target: sessionManagement; function onAboutToSuspend() { root.clearPassword(); } }
    Connections {
        target: root
        function onClearPassword() {
            if (passwordPill) passwordPill.clearPassword();
        }
    }

    Timer { id: notificationRemoveTimer; interval: 3000; onTriggered: msgExitAnim.start() }
    Timer {
        id: graceLockTimer; interval: 3000
        onTriggered: { root.clearPassword(); authenticator.startAuthenticating(); }
    }

    // Error text: appear → flash → exit
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

    Item { id: bgItem; anchors.fill: parent; children: [wallpaper] }

    FocusScope {
        id: lockScreenRoot
        anchors.fill: parent
        focus: true

        Component.onCompleted: authenticator.startAuthenticating()

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.ArrowCursor
            onPressed: mouse => {
                if (passwordPill) passwordPill.forceActiveFocus();
                mouse.accepted = false;
            }
        }

        // kscreenlocker may not hand focus to the greeter immediately
        Item {
            Timer {
                interval: 300; repeat: true; running: true
                property int n: 0
                onTriggered: {
                    if (passwordPill) passwordPill.forceActiveFocus();
                    if (++n >= 10) repeat = false;
                }
            }
        }

        Keys.onPressed: event => {
            if (passwordPill) passwordPill.forceActiveFocus();
            event.accepted = false;
        }
        Keys.onEscapePressed: root.clearPassword()

        // ── Landscape Layout ──
        Item {
            id: landscapeContent
            anchors.centerIn: parent
            width: lockScreenUi.lockLong
            height: lockScreenUi.lockShort
            visible: !lockScreenUi.isPortrait

            ShaderEffectSource {
                id: bgSource
                anchors.fill: lockBg
                sourceItem: bgItem
                sourceRect: Qt.rect(landscapeContent.x, landscapeContent.y, landscapeContent.width, landscapeContent.height)
            }
            Item {
                anchors.fill: lockBg
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle { width: lockBg.width; height: lockBg.height; radius: lockBg.radius }
                }
                FastBlur { anchors.fill: parent; source: bgSource; radius: 64 }
                Rectangle { anchors.fill: parent; color: lockScreenUi.clSurface; opacity: 0.6 }
            }
            Rectangle {
                id: lockBg
                anchors.fill: parent
                color: Qt.rgba(lockScreenUi.clSurfaceContainer.r, lockScreenUi.clSurfaceContainer.g, lockScreenUi.clSurfaceContainer.b, 0.45)
                radius: 42 * (lockScreenUi.lockHeight / 1080)
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16 * (lockScreenUi.lockHeight / 1080)
                spacing: 40 * (lockScreenUi.lockHeight / 1080)

                // Left Column
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 16 * lockScreenUi.centerScale

                    WeatherCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 1
                        centerScale: lockScreenUi.centerScale
                        weatherInfo: weatherLoader.weatherInfo
                        clSurfaceContainer: lockScreenUi.clSurfaceContainer
                        clSurfaceFg: lockScreenUi.clSurfaceFg
                        clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                        clPrimary: lockScreenUi.clPrimary
                    }

                    CaelestiafetchCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 1
                        centerScale: lockScreenUi.centerScale
                        fetchInfo: fetchLoader.fetchInfo
                        clTerms: lockScreenUi.clTerms
                        clSurface: lockScreenUi.clSurface
                        clSurfaceContainer: lockScreenUi.clSurfaceContainer
                        clSurfaceContainerHigh: lockScreenUi.clSurfaceContainerHigh
                        clSurfaceContainerHighest: lockScreenUi.clSurfaceContainerHighest
                        clSurfaceFg: lockScreenUi.clSurfaceFg
                        clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                        clPrimary: lockScreenUi.clPrimary
                    }

                    MediaCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 1
                        centerScale: lockScreenUi.centerScale
                        multiplex: lockScreenUi.liveMedia
                        clSurface: lockScreenUi.clSurface
                        clSurfaceContainer: lockScreenUi.clSurfaceContainer
                        clSurfaceFg: lockScreenUi.clSurfaceFg
                        clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                        clPrimary: lockScreenUi.clPrimary
                        onPreviousRequested: mediaActionSource.send("previous")
                        onPlayPauseRequested: mediaActionSource.send("playPause")
                        onNextRequested: mediaActionSource.send("next")
                    }
                }

                // Center Column
                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    Layout.preferredWidth: lockScreenUi.centerWidth
                    Layout.fillWidth: false
                    Layout.fillHeight: true
                    spacing: 20 * lockScreenUi.centerScale

                    ClockWidget {
                        Layout.alignment: Qt.AlignHCenter
                        use12h: lockScreenUi.use12h
                        centerScale: lockScreenUi.centerScale
                        clPrimary: lockScreenUi.clPrimary
                        clSecondary: lockScreenUi.clSecondary
                        clSurfaceContainerHigh: lockScreenUi.clSurfaceContainerHigh
                        clSurfaceFg: lockScreenUi.clSurfaceFg
                        clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                    }

                    ProfileAvatar {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 24 * lockScreenUi.centerScale
                        Layout.bottomMargin: 16 * lockScreenUi.centerScale
                        implicitWidth: lockScreenUi.centerWidth * 0.7
                        implicitHeight: implicitWidth
                        centerScale: lockScreenUi.centerScale
                        userImage: (typeof kscreenlocker_userImage !== "undefined" && kscreenlocker_userImage) ? kscreenlocker_userImage.toString() : ""
                        userName: typeof kscreenlocker_userName !== "undefined" ? kscreenlocker_userName : ""
                        clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                    }

                    GreetingPill {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 16 * lockScreenUi.centerScale
                        centerScale: lockScreenUi.centerScale
                        greetingInfo: lockScreenUi.greetingInfo
                        userName: typeof kscreenlocker_userName !== "undefined" ? kscreenlocker_userName : "User"
                        clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                        clPrimary: lockScreenUi.clPrimary
                    }

                    PasswordPill {
                        id: passwordPill
                        Layout.alignment: Qt.AlignHCenter
                        centerScale: lockScreenUi.centerScale
                        centerWidth: lockScreenUi.centerWidth
                        isAuthenticating: lockScreenUi.isAuthenticating
                        graceLocked: Boolean(authenticator.graceLocked)
                        hasFingerprint: Boolean(authenticator.authenticatorTypes & ScreenLocker.Authenticator.Fingerprint)
                        clSurfaceContainer: lockScreenUi.clSurfaceContainer
                        clSurfaceContainerHigh: lockScreenUi.clSurfaceContainerHigh
                        clSurfaceFg: lockScreenUi.clSurfaceFg
                        clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                        clPrimary: lockScreenUi.clPrimary
                        clPrimaryFg: lockScreenUi.clPrimaryFg
                        onLoginRequested: pass => lockScreenUi.startLogin(pass)
                    }

                    // Status Messages (Caps Lock, Errors, Fingerprint)
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
                            font { pixelSize: 14; family: "Rubik" }
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
                            font { pixelSize: 14; family: "Rubik" }
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
                            font { pixelSize: 12; family: "Rubik" }
                            color: lockScreenUi.clSurfaceVariantFg
                        }
                    }
                }

                // Right Column
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 16 * lockScreenUi.centerScale

                    ResourcesCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 170 * lockScreenUi.centerScale
                        centerScale: lockScreenUi.centerScale
                        liveCpu: lockScreenUi.liveCpu
                        liveTemp: lockScreenUi.liveTemp
                        liveRam: lockScreenUi.liveRam
                        liveDisk: lockScreenUi.liveDisk
                        cpuPercentage: Cpu.percentage ?? 0
                        memoryPercentage: Memory.percentage ?? 0
                        storagePercentage: Storage.percentage ?? 0
                        clSurface: lockScreenUi.clSurface
                        clSurfaceContainer: lockScreenUi.clSurfaceContainer
                        clSurfaceContainerHigh: lockScreenUi.clSurfaceContainerHigh
                        clSurfaceContainerHighest: lockScreenUi.clSurfaceContainerHighest
                        clPrimaryContainer: lockScreenUi.clPrimaryContainer
                        clSecondaryContainer: lockScreenUi.clSecondaryContainer
                        clTertiary: lockScreenUi.clTertiary
                        clOnTertiary: lockScreenUi.clOnTertiary
                        clOutline: lockScreenUi.clOutline
                        clSurfaceFg: lockScreenUi.clSurfaceFg
                        clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                        clPrimary: lockScreenUi.clPrimary
                        clSecondary: lockScreenUi.clSecondary
                        clError: lockScreenUi.clError
                    }

                    NotifDock {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        centerScale: lockScreenUi.centerScale
                        liveNotifs: lockScreenUi.liveNotifs
                        clSurfaceContainer: lockScreenUi.clSurfaceContainer
                        clSurfaceContainerHigh: lockScreenUi.clSurfaceContainerHigh
                        clSurfaceContainerHighest: lockScreenUi.clSurfaceContainerHighest
                        clSecondaryContainer: lockScreenUi.clSecondaryContainer
                        clSurfaceFg: lockScreenUi.clSurfaceFg
                        clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                        clOutline: lockScreenUi.clOutline
                        onClearAllRequested: notifActionSource.clearAll()
                    }
                }
            }
        }

        // ── Portrait Layout ──
        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.9, lockScreenUi.lockShort)
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
                        source: (typeof kscreenlocker_userImage !== "undefined" && kscreenlocker_userImage) ? kscreenlocker_userImage.toString() : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle { width: portraitProfileImage.width; height: portraitProfileImage.height; radius: width / 2 }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "person"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: parent.width * 0.45
                        color: lockScreenUi.clSurfaceVariantFg
                        visible: portraitProfileImage.status !== Image.Ready
                    }
                }

                ClockWidget {
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    use12h: lockScreenUi.use12h
                    centerScale: lockScreenUi.centerScale
                    clPrimary: lockScreenUi.clPrimary
                    clSecondary: lockScreenUi.clSecondary
                    clSurfaceContainerHigh: lockScreenUi.clSurfaceContainerHigh
                    clSurfaceFg: lockScreenUi.clSurfaceFg
                    clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                }
            }

            GreetingPill {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 16 * lockScreenUi.centerScale
                centerScale: lockScreenUi.centerScale
                greetingInfo: lockScreenUi.greetingInfo
                userName: typeof kscreenlocker_userName !== "undefined" ? kscreenlocker_userName : "User"
                pillColor: lockScreenUi.clSurfaceContainer
                clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                clPrimary: lockScreenUi.clPrimary
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 16 * lockScreenUi.centerScale
                property real pillWidth: passwordPill && passwordPill.text.length > 0
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

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.IBeamCursor
                        onClicked: if (passwordPill) passwordPill.forceActiveFocus()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6 * lockScreenUi.centerScale
                        anchors.rightMargin: 6 * lockScreenUi.centerScale
                        spacing: 10 * lockScreenUi.centerScale

                        Item {
                            Layout.fillHeight: true; implicitWidth: height
                            Text {
                                anchors.centerIn: parent
                                text: "lock"
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
                                text: (passwordPill && passwordPill.text.length > 0) ? "•".repeat(passwordPill.text.length) : i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:placeholder", "Password")
                                font { pixelSize: 16 * lockScreenUi.centerScale; family: "Rubik" }
                                color: (passwordPill && passwordPill.text.length > 0) ? lockScreenUi.clSurfaceFg : lockScreenUi.clSurfaceVariantFg
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: if (passwordPill) passwordPill.forceActiveFocus()
                            }
                        }

                        Item {
                            implicitWidth: implicitHeight; implicitHeight: parent.height - 12 * lockScreenUi.centerScale
                            Rectangle {
                                anchors.fill: parent
                                radius: (passwordPill && passwordPill.text.length > 0) ? width * 0.25 : width / 2
                                color: (passwordPill && passwordPill.text.length > 0) ? lockScreenUi.clPrimary : lockScreenUi.clSurfaceContainerHigh
                                Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 300 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: "arrow_forward"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 20 * lockScreenUi.centerScale
                                    color: (passwordPill && passwordPill.text.length > 0) ? lockScreenUi.clPrimaryFg : lockScreenUi.clSurfaceVariantFg
                                    rotation: (passwordPill && passwordPill.text.length > 0) ? 0 : 90
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                    Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                }
                                MouseArea {
                                    anchors.fill: parent; hoverEnabled: true
                                    cursorShape: (passwordPill && passwordPill.text.length > 0) ? Qt.PointingHandCursor : Qt.ArrowCursor
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
