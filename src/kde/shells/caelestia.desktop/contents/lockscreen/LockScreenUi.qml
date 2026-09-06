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
    // use12h: read from ~/.config/caelestia/shell.json services.useTwelveHourClock if set,
    // otherwise fall back to the system locale — same logic as serviceconfig.hpp default.
    property bool use12h: Qt.locale().timeFormat(Locale.ShortFormat).toLowerCase().indexOf("a") !== -1
    property bool isCaelestiaMode: false
    property bool recolourLogo: true
    property bool hideNotifs: false
    property bool enableFprint: true
    property int maxFprintTries: 3
    property int fprintTries: 0
    property int profilePicShape: 13
    property bool rotateProfilePic: false
    property bool syncWallpaper: true
    property var sessionIcons: ({})
    property bool showSleep: true
    property bool showHibernate: false
    property bool showSwitchUser: true
    property bool showLogout: true
    property bool showReboot: false
    property bool showShutdown: false
    property bool blurWallpaper: false

    readonly property bool hasFingerprint: enableFprint && (fprintTries < maxFprintTries) && Boolean(authenticator.authenticatorTypes & ScreenLocker.Authenticator.Fingerprint)
    readonly property bool fprintDisabledDueToTries: enableFprint && (fprintTries >= maxFprintTries) && Boolean(authenticator.authenticatorTypes & ScreenLocker.Authenticator.Fingerprint)
    readonly property real bgRadius: 42 * (lockHeight / 1080)
    readonly property real bgMargin: 16 * (lockHeight / 1080)
    readonly property real cardRadius: bgRadius - bgMargin
    readonly property color clCardBg: Qt.rgba(clSurfaceContainer.r, clSurfaceContainer.g, clSurfaceContainer.b, 0.55)
    readonly property color clCardBgHigh: Qt.rgba(clSurfaceContainerHigh.r, clSurfaceContainerHigh.g, clSurfaceContainerHigh.b, 0.55)

    // Material You palette — defaults from Catppuccin Mocha dark.
    // All components receive these via explicit property bindings from this root
    // so there is one single source of truth and per-component defaults cannot drift.
    // Values are overridden by schemeLoader below once scheme.json is read.
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

    readonly property bool isAuthenticating: authHandler.isAuthenticating
    readonly property var activePasswordPill: isPortrait ? portraitPasswordPill : passwordPill
    property string authMessage: ""
    property bool ready: false

    Timer {
        id: readyTimer
        interval: 50
        running: true
        onTriggered: lockScreenUi.ready = true
    }

    // XHR file:// is blocked inside kscreenlocker, so read scheme.json and
    // shell.json via cat. The scheme.json 'mode' field ('dark'/'light') switches
    // between the light and dark palette variants.
    Plasma5Support.DataSource {
        id: schemeLoader
        engine: "executable"
        connectedSources: ["cat ~/.local/state/caelestia/scheme.json 2>/dev/null"]
        onNewData: (source, data) => {
            var stdout = data["stdout"] || "";
            if (!stdout) return;
            try {
                var d = JSON.parse(stdout);
                // scheme.json may contain top-level colours or a colours sub-key
                var c = d.colours || d;
                // 'mode' field: 'dark' or 'light' — select the right variant
                // Light mode inverts some roles (surface ↔ onSurface etc.)
                // For now we read the colours block as-is; both light and dark
                // scheme.json files already contain the correct per-mode values.
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

    // Read user clock-format preference from ~/.config/caelestia/shell.json
    // Respects the useTwelveHourClock setting set via Nexus settings.
    Plasma5Support.DataSource {
        id: configLoader
        engine: "executable"
        connectedSources: ["cat ~/.config/caelestia/shell.json 2>/dev/null"]
        onNewData: (source, data) => {
            var stdout = data["stdout"] || "";
            if (!stdout) return;
            try {
                var cfg = JSON.parse(stdout);
                var svc = cfg.services || {};
                if (typeof svc.useTwelveHourClock === "boolean")
                    lockScreenUi.use12h = svc.useTwelveHourClock;
                
                if (typeof cfg.caelestiaMode === "boolean")
                    lockScreenUi.isCaelestiaMode = cfg.caelestiaMode;
                else if (typeof svc.caelestiaMode === "boolean")
                    lockScreenUi.isCaelestiaMode = svc.caelestiaMode;
                else if (cfg.general && typeof cfg.general.caelestiaMode === "boolean")
                    lockScreenUi.isCaelestiaMode = cfg.general.caelestiaMode;

                var lk = cfg.lock || {};
                if (typeof lk.recolourLogo === "boolean")
                    lockScreenUi.recolourLogo = lk.recolourLogo;
                if (typeof lk.hideNotifs === "boolean")
                    lockScreenUi.hideNotifs = lk.hideNotifs;
                if (typeof lk.enableFprint === "boolean")
                    lockScreenUi.enableFprint = lk.enableFprint;
                if (typeof lk.maxFprintTries === "number")
                    lockScreenUi.maxFprintTries = lk.maxFprintTries;
                if (typeof lk.profilePicShape === "number")
                    lockScreenUi.profilePicShape = lk.profilePicShape;
                if (typeof lk.rotateProfilePic === "boolean")
                    lockScreenUi.rotateProfilePic = lk.rotateProfilePic;
                if (typeof lk.syncWallpaper === "boolean")
                    lockScreenUi.syncWallpaper = lk.syncWallpaper;
                if (typeof lk.blurWallpaper === "boolean")
                    lockScreenUi.blurWallpaper = lk.blurWallpaper;
                if (cfg.session && cfg.session.icons)
                    lockScreenUi.sessionIcons = cfg.session.icons;
                if (typeof lk.showSleep === "boolean")
                    lockScreenUi.showSleep = lk.showSleep;
                if (typeof lk.showHibernate === "boolean")
                    lockScreenUi.showHibernate = lk.showHibernate;
                if (typeof lk.showSwitchUser === "boolean")
                    lockScreenUi.showSwitchUser = lk.showSwitchUser;
                if (typeof lk.showLogout === "boolean")
                    lockScreenUi.showLogout = lk.showLogout;
                if (typeof lk.showReboot === "boolean")
                    lockScreenUi.showReboot = lk.showReboot;
                if (typeof lk.showShutdown === "boolean")
                    lockScreenUi.showShutdown = lk.showShutdown;
            } catch(e) {}
        }
    }

    // Fetch system info via the external helper script instead of an inline
    // python3 -c one-liner. Inline shell-command concatenation runs pre-auth
    // and is a security concern flagged in review.
    // Qt.resolvedUrl resolves relative to this QML file's installed location,
    // giving the correct absolute path regardless of where the shell is installed.
    readonly property string sysinfoScriptPath: {
        var url = Qt.resolvedUrl("scripts/sysinfo.py").toString();
        // Strip "file://" prefix (url is always file:///absolute/path on Linux)
        return url.startsWith("file://") ? url.slice(7) : url;
    }

    Plasma5Support.DataSource {
        id: fetchLoader
        engine: "executable"
        connectedSources: ["python3 " + lockScreenUi.sysinfoScriptPath]
        property var fetchInfo: null
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
        // Fixed command strings — no concatenation. send() only ever receives one
        // of three literal values from MediaCard signals (lines 448-450).
        readonly property var actionCmds: ({
            "previous":  "caelestia-shell-ipc call mpris previous",
            "playPause": "caelestia-shell-ipc call mpris playPause",
            "next":      "caelestia-shell-ipc call mpris next"
        })
        function send(action) {
            var cmd = actionCmds[action];
            if (cmd) connectSource(cmd);
        }
    }

    property var liveNotifs: []

    property bool ignoreNotifs: false

    Plasma5Support.DataSource {
        id: notifLoader
        engine: "executable"
        connectedSources: ["cat ~/.local/state/caelestia/notifs.json 2>/dev/null"]
        onNewData: (source, data) => {
            var stdout = data["stdout"] || "";
            disconnectSource(source);
            if (!stdout) return;
            if (lockScreenUi.ignoreNotifs) return;
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
            lockScreenUi.liveNotifs = [];
            lockScreenUi.ignoreNotifs = true;
            ignoreTimer.restart();
        }
    }

    Timer {
        id: ignoreTimer
        interval: 3500
        onTriggered: lockScreenUi.ignoreNotifs = false;
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

    AuthHandler {
        id: authHandler
        authenticatorTarget: (typeof authenticator !== "undefined") ? authenticator : null
        fprintTries: lockScreenUi.fprintTries
        onShakeRequested: if (activePasswordPill) activePasswordPill.shake()
        onFocusSecretRequested: if (activePasswordPill) activePasswordPill.forceActiveFocus()
        onSucceeded: {
            lockScreenUi.fprintTries = 0;
            Qt.quit();
        }
        onMessageChanged: msg => {
            if (msg) {
                msgExitAnim.stop();
                var wasEmpty = !lockScreenUi.authMessage;
                lockScreenUi.authMessage = msg;
                var isVisible = lockScreenUi.isPortrait ? (portraitErrorText && portraitErrorText.visible) : (errorText && errorText.visible);
                if (wasEmpty || !isVisible) {
                    msgAppearAnim.restart();
                }
            } else {
                msgAppearAnim.stop();
                msgFlashAnim.stop();
                msgExitAnim.start();
            }
        }
        onClearPasswordRequested: {
            if (passwordPill) passwordPill.clearPassword();
            if (portraitPasswordPill) portraitPasswordPill.clearPassword();
            if (typeof root !== "undefined" && typeof root.clearPassword === "function") root.clearPassword();
        }
        onNotificationRepeated: {
            msgExitAnim.stop();
            msgFlashAnim.restart();
            if (activePasswordPill) activePasswordPill.shake();
            if (typeof root !== "undefined" && typeof root.notificationRepeated === "function") root.notificationRepeated();
        }
    }

    function handleMessage(msg) { authHandler.handleMessage(msg); }
    function startLogin(pass) {
        msgExitAnim.stop();
        msgAppearAnim.stop();
        msgFlashAnim.stop();
        errorText.visible = false;
        portraitErrorText.visible = false;
        errorText.opacity = 0;
        portraitErrorText.opacity = 0;
        lockScreenUi.authMessage = "";
        authHandler.startLogin(pass);
    }

    SessionManagement { id: sessionManagement }
    KeyboardIndicator.KeyState { id: capsLockState; key: Qt.Key_CapsLock }
    Connections { target: sessionManagement; function onAboutToSuspend() { root.clearPassword(); } }
    Connections {
        target: root
        function onClearPassword() {
            if (passwordPill) passwordPill.clearPassword();
            if (portraitPasswordPill) portraitPasswordPill.clearPassword();
        }
    }

    // Error text: appear → flash → exit
    SequentialAnimation {
        id: msgAppearAnim
        PropertyAction { target: errorText; property: "visible"; value: true }
        PropertyAction { target: portraitErrorText; property: "visible"; value: true }
        ParallelAnimation {
            NumberAnimation { target: errorText; property: "scale"; from: 0.7; to: 1; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: errorText; property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: portraitErrorText; property: "scale"; from: 0.7; to: 1; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: portraitErrorText; property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
        }
        onFinished: msgFlashAnim.start()
    }
    SequentialAnimation {
        id: msgFlashAnim; loops: 2
        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation { target: errorText; property: "opacity"; to: 0.3; duration: 150 }
                NumberAnimation { target: errorText; property: "opacity"; to: 1; duration: 150 }
            }
            SequentialAnimation {
                NumberAnimation { target: portraitErrorText; property: "opacity"; to: 0.3; duration: 150 }
                NumberAnimation { target: portraitErrorText; property: "opacity"; to: 1; duration: 150 }
            }
        }
    }
    SequentialAnimation {
        id: msgExitAnim
        ParallelAnimation {
            NumberAnimation { target: errorText; property: "scale"; to: 0.7; duration: 400; easing.type: Easing.InOutQuad }
            NumberAnimation { target: errorText; property: "opacity"; to: 0; duration: 400; easing.type: Easing.InOutQuad }
            NumberAnimation { target: portraitErrorText; property: "scale"; to: 0.7; duration: 400; easing.type: Easing.InOutQuad }
            NumberAnimation { target: portraitErrorText; property: "opacity"; to: 0; duration: 400; easing.type: Easing.InOutQuad }
        }
        PropertyAction { target: errorText; property: "visible"; value: false }
        PropertyAction { target: portraitErrorText; property: "visible"; value: false }
        onFinished: {
            lockScreenUi.authMessage = "";
            if (typeof root !== "undefined" && typeof root.notification !== "undefined") {
                root.notification = "";
            }
        }
    }

    FastBlur {
        id: wallpaperBlur
        anchors.fill: parent
        source: wallpaper
        radius: 64
        visible: false
    }

    Item {
        id: fullWallpaperBlurOverlay
        anchors.fill: parent
        visible: lockScreenUi.blurWallpaper
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        ShaderEffectSource {
            anchors.fill: parent
            sourceItem: wallpaperBlur
            live: true
        }
    }

    FocusScope {
        id: lockScreenRoot
        anchors.fill: parent
        focus: true
        opacity: lockScreenUi.ready ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }

        Component.onCompleted: authenticator.startAuthenticating()

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.ArrowCursor
            onPressed: mouse => {
                if (activePasswordPill) activePasswordPill.forceActiveFocus();
                mouse.accepted = false;
            }
        }

        // kscreenlocker may not hand focus to the greeter immediately
        Item {
            Timer {
                interval: 300; repeat: true; running: true
                property int n: 0
                onTriggered: {
                    if (activePasswordPill) activePasswordPill.forceActiveFocus();
                    if (++n >= 10) repeat = false;
                }
            }
        }

        Keys.onPressed: event => {
            if (activePasswordPill) activePasswordPill.forceActiveFocus();
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

            Behavior on height {
                enabled: lockScreenUi.ready
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            Item {
                anchors.fill: lockBg
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle { width: lockBg.width; height: lockBg.height; radius: lockBg.radius }
                }

                ShaderEffectSource {
                    anchors.fill: parent
                    sourceItem: wallpaperBlur
                    sourceRect: Qt.rect(landscapeContent.x, landscapeContent.y, landscapeContent.width, landscapeContent.height)
                    live: true
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(lockScreenUi.clSurfaceContainer.r, lockScreenUi.clSurfaceContainer.g, lockScreenUi.clSurfaceContainer.b, 0.35)
                }
            }

            Rectangle {
                id: lockBg
                anchors.fill: parent
                color: "transparent"
                border.color: Qt.rgba(lockScreenUi.clSurfaceVariantFg.r, lockScreenUi.clSurfaceVariantFg.g, lockScreenUi.clSurfaceVariantFg.b, 0.12)
                border.width: 1
                radius: lockScreenUi.bgRadius
            }

            RowLayout {
                id: landscapeLayout
                anchors.fill: parent
                anchors.margins: lockScreenUi.bgMargin
                spacing: 40 * (lockScreenUi.lockHeight / 1080)

                // Left Column
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 16 * lockScreenUi.centerScale

                    WeatherCard {
                        Layout.fillWidth: true
                        cardRadius: lockScreenUi.cardRadius
                        centerScale: lockScreenUi.centerScale
                        weatherInfo: weatherLoader.weatherInfo
                        clSurfaceContainer: lockScreenUi.clCardBg
                        clSurfaceFg: lockScreenUi.clSurfaceFg
                        clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                        clPrimary: lockScreenUi.clPrimary
                    }

                    CaelestiafetchCard {
                        Layout.fillWidth: true
                        cardRadius: lockScreenUi.cardRadius
                        centerScale: lockScreenUi.centerScale
                        fetchInfo: fetchLoader.fetchInfo
                        clTerms: lockScreenUi.clTerms
                        recolourLogo: lockScreenUi.recolourLogo
                        clSurface: lockScreenUi.clSurface
                        clSurfaceContainer: lockScreenUi.clCardBg
                        clSurfaceContainerHigh: lockScreenUi.clCardBgHigh
                        clSurfaceContainerHighest: lockScreenUi.clSurfaceContainerHighest
                        clSurfaceFg: lockScreenUi.clSurfaceFg
                        clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                        clPrimary: lockScreenUi.clPrimary
                    }

                    MediaCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        cardRadius: lockScreenUi.cardRadius
                        centerScale: lockScreenUi.centerScale
                        mediaInfo: lockScreenUi.liveMedia
                        clSurface: lockScreenUi.clSurface
                        clSurfaceContainer: lockScreenUi.clCardBg
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
                    Layout.topMargin: 20 * lockScreenUi.centerScale
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
                        profileShape: lockScreenUi.profilePicShape
                        rotateShape: lockScreenUi.rotateProfilePic
                        userImage: (typeof kscreenlocker_userImage !== "undefined" && kscreenlocker_userImage) ? kscreenlocker_userImage.toString() : ""
                        userName: typeof kscreenlocker_userName !== "undefined" ? kscreenlocker_userName : ""
                        clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                        clSurfaceContainerHighest: lockScreenUi.clSurfaceContainerHighest
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
                        focus: !lockScreenUi.isPortrait
                        isAuthenticating: lockScreenUi.isAuthenticating
                        graceLocked: authHandler.graceLocked
                        lockoutActive: authHandler.lockoutActive
                        lockoutText: authHandler.lockoutText
                        hasFingerprint: lockScreenUi.hasFingerprint
                        fprintDisabledDueToTries: lockScreenUi.fprintDisabledDueToTries
                        clError: lockScreenUi.clError
                        clSurfaceContainer: lockScreenUi.clCardBg
                        clSurfaceContainerHigh: lockScreenUi.clCardBgHigh
                        clSurfaceFg: lockScreenUi.clSurfaceFg
                        clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                        clPrimary: lockScreenUi.clPrimary
                        clPrimaryFg: lockScreenUi.clPrimaryFg
                        onLoginRequested: pass => lockScreenUi.startLogin(pass)
                    }

                    Session {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 4 * lockScreenUi.centerScale
                        centerScale: lockScreenUi.centerScale
                        isAuthenticating: lockScreenUi.isAuthenticating
                        clPrimary: lockScreenUi.clPrimary
                        clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                        sessionManagement: sessionManagement
                        customIcons: lockScreenUi.sessionIcons
                        showSleep: lockScreenUi.showSleep
                        showHibernate: lockScreenUi.showHibernate
                        showSwitchUser: lockScreenUi.showSwitchUser
                        showLogout: lockScreenUi.showLogout
                        showReboot: lockScreenUi.showReboot
                        showShutdown: lockScreenUi.showShutdown
                    }

                    // Status Messages (Caps Lock, Errors / Logs, Fingerprint)
                    Item {
                        id: landscapeStatusContainer
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64 * lockScreenUi.centerScale
                        implicitHeight: Layout.preferredHeight
                        Layout.topMargin: 2 * lockScreenUi.centerScale
                        Layout.bottomMargin: 6 * lockScreenUi.centerScale

                        Column {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            spacing: 4 * lockScreenUi.centerScale

                            Text {
                                id: capsText
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                visible: capsLockState.locked && !lockScreenUi.authMessage
                                text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status", "Caps Lock is on")
                                font { pixelSize: LockScreenConfig.sizeSmall; family: LockScreenConfig.fontBody }
                                color: lockScreenUi.clSurfaceVariantFg
                                wrapMode: Text.WordWrap
                                opacity: visible ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                            }

                            Text {
                                id: errorText
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                visible: false
                                text: lockScreenUi.authMessage
                                font { pixelSize: LockScreenConfig.sizeSmall; family: LockScreenConfig.fontBody }
                                color: lockScreenUi.clError
                                wrapMode: Text.WordWrap
                                scale: 0.7; opacity: 0
                            }

                            Text {
                                id: fpHint
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                visible: lockScreenUi.hasFingerprint
                                text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:usagetip", "(or scan your fingerprint on the reader)")
                                font { pixelSize: LockScreenConfig.sizeVerySmall; family: LockScreenConfig.fontBody }
                                color: lockScreenUi.clSurfaceVariantFg
                                wrapMode: Text.WordWrap
                            }
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
                        cardRadius: lockScreenUi.cardRadius
                        centerScale: lockScreenUi.centerScale
                        liveCpu: lockScreenUi.liveCpu
                        liveTemp: lockScreenUi.liveTemp
                        liveRam: lockScreenUi.liveRam
                        liveDisk: lockScreenUi.liveDisk
                        cpuPercentage: Cpu.percentage ?? 0
                        memoryPercentage: Memory.percentage ?? 0
                        storagePercentage: Storage.percentage ?? 0
                        clSurface: lockScreenUi.clSurface
                        clSurfaceContainer: lockScreenUi.clCardBg
                        clSurfaceContainerHigh: lockScreenUi.clCardBgHigh
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
                        cardRadius: lockScreenUi.cardRadius
                        centerScale: lockScreenUi.centerScale
                        liveNotifs: lockScreenUi.liveNotifs
                        isCaelestiaMode: lockScreenUi.isCaelestiaMode
                        hideNotifs: lockScreenUi.hideNotifs
                        clSurfaceContainer: lockScreenUi.clCardBg
                        clSurfaceContainerHigh: lockScreenUi.clCardBgHigh
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
        // TODO: The portrait branch currently re-instantiates ClockWidget,
        // ProfileAvatar, GreetingPill and PasswordPill independently instead of
        // sharing the landscape instances via visible/states. This means both
        // branches can drift if one is updated without the other.
        // Tracked as technical debt — refactor to a single shared ColumnLayout
        // with Layout.visible switching per isPortrait.
        Item {
            id: portraitContent
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.9, lockScreenUi.lockShort)
            height: portraitLayout.implicitHeight + 64 * lockScreenUi.centerScale
            visible: lockScreenUi.isPortrait

            Behavior on height {
                enabled: lockScreenUi.ready
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            Item {
                anchors.fill: portraitBg
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle { width: portraitBg.width; height: portraitBg.height; radius: lockScreenUi.bgRadius }
                }

                ShaderEffectSource {
                    anchors.fill: parent
                    sourceItem: wallpaperBlur
                    sourceRect: Qt.rect(portraitContent.x, portraitContent.y, portraitContent.width, portraitContent.height)
                    live: true
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(lockScreenUi.clSurfaceContainer.r, lockScreenUi.clSurfaceContainer.g, lockScreenUi.clSurfaceContainer.b, 0.35)
                }
            }

            Rectangle {
                id: portraitBg
                anchors.fill: parent
                color: "transparent"
                border.color: Qt.rgba(lockScreenUi.clSurfaceVariantFg.r, lockScreenUi.clSurfaceVariantFg.g, lockScreenUi.clSurfaceVariantFg.b, 0.12)
                border.width: 1
                radius: lockScreenUi.bgRadius
            }

            ColumnLayout {
                id: portraitLayout
                anchors.centerIn: parent
                width: parent.width - 48 * lockScreenUi.centerScale
                spacing: 20 * lockScreenUi.centerScale

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    spacing: 24 * lockScreenUi.centerScale

                    ProfileAvatar {
                        Layout.preferredWidth: lockScreenUi.centerWidth * 0.4
                        Layout.preferredHeight: Layout.preferredWidth
                        centerScale: lockScreenUi.centerScale
                        profileShape: lockScreenUi.profilePicShape
                        rotateShape: lockScreenUi.rotateProfilePic
                        userImage: (typeof kscreenlocker_userImage !== "undefined" && kscreenlocker_userImage) ? kscreenlocker_userImage.toString() : ""
                        userName: typeof kscreenlocker_userName !== "undefined" ? kscreenlocker_userName : ""
                        clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                        clSurfaceContainerHighest: lockScreenUi.clSurfaceContainerHighest
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
                    Layout.bottomMargin: 8 * lockScreenUi.centerScale
                    centerScale: lockScreenUi.centerScale
                    greetingInfo: lockScreenUi.greetingInfo
                    userName: typeof kscreenlocker_userName !== "undefined" ? kscreenlocker_userName : "User"
                    pillColor: lockScreenUi.clCardBg
                    clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                    clPrimary: lockScreenUi.clPrimary
                }

                PasswordPill {
                    id: portraitPasswordPill
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8 * lockScreenUi.centerScale
                    Layout.bottomMargin: 8 * lockScreenUi.centerScale
                    centerScale: lockScreenUi.centerScale
                    centerWidth: lockScreenUi.centerWidth
                    focus: lockScreenUi.isPortrait
                    isAuthenticating: lockScreenUi.isAuthenticating
                    graceLocked: authHandler.graceLocked
                    lockoutActive: authHandler.lockoutActive
                    lockoutText: authHandler.lockoutText
                    hasFingerprint: lockScreenUi.hasFingerprint
                    fprintDisabledDueToTries: lockScreenUi.fprintDisabledDueToTries
                    clError: lockScreenUi.clError
                    clSurfaceContainer: lockScreenUi.clCardBg
                    clSurfaceContainerHigh: lockScreenUi.clCardBgHigh
                    clSurfaceFg: lockScreenUi.clSurfaceFg
                    clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                    clPrimary: lockScreenUi.clPrimary
                    clPrimaryFg: lockScreenUi.clPrimaryFg
                    onLoginRequested: pass => lockScreenUi.startLogin(pass)
                }

                Session {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4 * lockScreenUi.centerScale
                    Layout.bottomMargin: 4 * lockScreenUi.centerScale
                    centerScale: lockScreenUi.centerScale
                    isAuthenticating: lockScreenUi.isAuthenticating
                    clPrimary: lockScreenUi.clPrimary
                    clSurfaceVariantFg: lockScreenUi.clSurfaceVariantFg
                    sessionManagement: sessionManagement
                    customIcons: lockScreenUi.sessionIcons
                    showSleep: lockScreenUi.showSleep
                    showHibernate: lockScreenUi.showHibernate
                    showSwitchUser: lockScreenUi.showSwitchUser
                    showLogout: lockScreenUi.showLogout
                    showReboot: lockScreenUi.showReboot
                    showShutdown: lockScreenUi.showShutdown
                }

                // Status Messages (Caps Lock, Errors / Logs, Fingerprint)
                Item {
                    id: portraitStatusContainer
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64 * lockScreenUi.centerScale
                    implicitHeight: Layout.preferredHeight
                    Layout.topMargin: 4 * lockScreenUi.centerScale
                    Layout.bottomMargin: 8 * lockScreenUi.centerScale

                    Column {
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        spacing: 4 * lockScreenUi.centerScale

                        Text {
                            id: portraitCapsText
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            visible: capsLockState.locked && !lockScreenUi.authMessage
                            text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status", "Caps Lock is on")
                            font { pixelSize: LockScreenConfig.sizeSmall; family: LockScreenConfig.fontBody }
                            color: lockScreenUi.clSurfaceVariantFg
                            wrapMode: Text.WordWrap
                            opacity: visible ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                        }

                        Text {
                            id: portraitErrorText
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            visible: false
                            text: lockScreenUi.authMessage
                            font { pixelSize: LockScreenConfig.sizeSmall; family: LockScreenConfig.fontBody }
                            color: lockScreenUi.clError
                            wrapMode: Text.WordWrap
                            scale: 0.7; opacity: 0
                        }

                        Text {
                            id: portraitFpHint
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            visible: lockScreenUi.hasFingerprint
                            text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:usagetip", "(or scan your fingerprint on the reader)")
                            font { pixelSize: LockScreenConfig.sizeVerySmall; family: LockScreenConfig.fontBody }
                            color: lockScreenUi.clSurfaceVariantFg
                            wrapMode: Text.WordWrap
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
        }
    }

    Binding { target: root; property: "viewVisible"; value: true }
}
