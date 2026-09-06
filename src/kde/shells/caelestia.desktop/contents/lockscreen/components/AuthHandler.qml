/*
    SPDX-FileCopyrightText: 2024 ladybug-me
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.kscreenlocker as ScreenLocker

Item {
    id: root

    property var authenticatorTarget: {
        try {
            return authenticator;
        } catch (e) {
            return null;
        }
    }
    readonly property var activeAuthenticator: authenticatorTarget

    property bool isAuthenticating: false
    property bool graceLocked: false
    property string authMessage: ""

    property int fprintTries: 0
    property int maxFprintTries: 3
    property int timeoutInterval: 15000
    property int notificationDismissInterval: 5000
    property int graceLockInterval: 2100

    signal messageChanged(string message)
    signal shakeRequested()
    signal focusSecretRequested()
    signal clearPasswordRequested()
    signal notificationRepeated()
    signal succeeded()

    function handleMessage(msg) {
        if (!msg || (typeof msg === "string" && msg.trim().length === 0)) return;

        if (typeof parent !== "undefined" && typeof parent.notification !== "undefined") {
            if (!parent.notification) {
                parent.notification += msg;
            } else if (parent.notification.includes(msg)) {
                root.notificationRepeated();
            } else {
                parent.notification += "\n" + msg;
            }
            root.authMessage = parent.notification;
        } else {
            if (!root.authMessage) {
                root.authMessage = msg;
            } else if (!root.authMessage.includes(msg)) {
                root.authMessage += "\n" + msg;
            } else {
                root.notificationRepeated();
            }
        }

        notificationRemoveTimer.restart();
        root.messageChanged(root.authMessage);
    }

    function startLogin(pass) {
        if (!pass || pass.length === 0 || root.isAuthenticating || root.graceLocked) return;
        root.clearAuthMessage();
        root.isAuthenticating = true;
        root.graceLocked = false;
        authTimeoutTimer.restart();
        if (activeAuthenticator && typeof activeAuthenticator.respond === "function") {
            activeAuthenticator.respond(pass);
        }
    }

    function clearAuthMessage() {
        root.authMessage = "";
        if (typeof parent !== "undefined" && typeof parent.notification !== "undefined") {
            parent.notification = "";
        }
        if (typeof root !== "undefined" && typeof root.notification !== "undefined") {
            root.notification = "";
        }
        notificationRemoveTimer.stop();
        root.messageChanged("");
    }

    Timer {
        id: authTimeoutTimer
        interval: root.timeoutInterval
        repeat: false
        onTriggered: {
            if (root.isAuthenticating || root.graceLocked) {
                root.isAuthenticating = false;
                root.graceLocked = false;
                root.clearPasswordRequested();
                if (!root.authMessage) {
                    root.handleMessage(i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status", "Authentication timed out"));
                }
            }
        }
    }

    Timer {
        id: notificationRemoveTimer
        interval: root.notificationDismissInterval
        onTriggered: {
            root.clearAuthMessage();
        }
    }

    Timer {
        id: graceLockTimer
        interval: root.graceLockInterval
        repeat: false
        onTriggered: {
            root.clearPasswordRequested();
            if (activeAuthenticator && typeof activeAuthenticator.startAuthenticating === "function") {
                activeAuthenticator.startAuthenticating();
            }
            fallbackUnlockTimer.restart();
        }
    }

    Timer {
        id: fallbackUnlockTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (root.graceLocked || root.isAuthenticating) {
                root.graceLocked = false;
                root.isAuthenticating = false;
                root.focusSecretRequested();
            }
        }
    }

    Connections {
        target: activeAuthenticator
        ignoreUnknownSignals: true

        function onFailed(kind, auth) {
            authTimeoutTimer.stop();

            if (kind !== 0) {
                if (kind & ScreenLocker.Authenticator.Fingerprint) {
                    root.fprintTries++;
                    if (root.fprintTries >= root.maxFprintTries) {
                        root.handleMessage(i18ndc("plasma_shell_org.kde.plasma.desktop",
                            "@info:status", "Maximum fingerprint attempts reached. Please use password."));
                    }
                }
                return;
            }

            const failMsg = i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status", "Unlocking failed");
            var authErr = (auth && auth.errorMessage) ? auth.errorMessage :
                          (activeAuthenticator && activeAuthenticator.errorMessage ? activeAuthenticator.errorMessage :
                          (activeAuthenticator && activeAuthenticator.infoMessage ? activeAuthenticator.infoMessage : ""));

            if (authErr) {
                root.handleMessage(authErr);
            } else if (!root.authMessage) {
                root.handleMessage(failMsg);
            }

            if (!graceLockTimer.running) {
                root.isAuthenticating = false;
                root.graceLocked = true;
                root.shakeRequested();
                graceLockTimer.interval = root.graceLockInterval;
                graceLockTimer.restart();
            }
        }

        function onNoninteractiveError(kind, auth) {
            if (kind & ScreenLocker.Authenticator.Fingerprint) {
                root.fprintTries++;
                if (root.fprintTries >= root.maxFprintTries) {
                    root.handleMessage(i18ndc("plasma_shell_org.kde.plasma.desktop",
                        "@info:status", "Maximum fingerprint attempts reached. Please use password."));
                } else if (auth && auth.errorMessage) {
                    root.handleMessage(auth.errorMessage);
                }
            }
        }

        function onSucceeded() {
            root.isAuthenticating = false;
            root.graceLocked = false;
            authTimeoutTimer.stop();
            graceLockTimer.stop();
            fallbackUnlockTimer.stop();
            root.fprintTries = 0;
            root.succeeded();
            Qt.quit();
        }

        function onInfoMessageChanged() {
            if (activeAuthenticator && activeAuthenticator.infoMessage) {
                root.handleMessage(activeAuthenticator.infoMessage);
            }
        }

        function onErrorMessageChanged() {
            if (activeAuthenticator && activeAuthenticator.errorMessage) {
                root.handleMessage(activeAuthenticator.errorMessage);
            }
        }

        function onPromptChanged(msg) {
            if (activeAuthenticator && activeAuthenticator.prompt) {
                root.handleMessage(activeAuthenticator.prompt);
            }
        }

        function onPromptForSecretChanged(msg) {
            fallbackUnlockTimer.stop();
            root.graceLocked = false;
            root.isAuthenticating = false;
            authTimeoutTimer.stop();
            root.focusSecretRequested();
        }

        function onLoginFailedDelayStarted(kind, auth, uSecDelay) {
            authTimeoutTimer.stop();
            if (kind !== 0) {
                return;
            }
            root.isAuthenticating = false;
            root.graceLocked = true;
            root.shakeRequested();

            var delayMs = (uSecDelay && uSecDelay > 0) ? (Math.round(uSecDelay / 1000) + 100) : root.graceLockInterval;
            graceLockTimer.interval = delayMs;
            graceLockTimer.restart();

            var msg = (auth && auth.errorMessage) ? auth.errorMessage :
                      (activeAuthenticator && activeAuthenticator.errorMessage ? activeAuthenticator.errorMessage :
                      (activeAuthenticator && activeAuthenticator.infoMessage ? activeAuthenticator.infoMessage : ""));
            if (msg) {
                root.handleMessage(msg);
            } else if (!root.authMessage) {
                root.handleMessage(i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status", "Unlocking failed"));
            }
        }

        function onBusyChanged() {
            if (activeAuthenticator && typeof activeAuthenticator.busy !== "undefined" && !activeAuthenticator.busy) {
                if (root.isAuthenticating && !root.graceLocked && !graceLockTimer.running) {
                    root.isAuthenticating = false;
                    authTimeoutTimer.stop();
                }
            }
        }
    }
}
