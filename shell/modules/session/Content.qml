// Patched copy of caelestia-dots/shell — modules/session/Content.qml
// caelestia-void modifications:
//  - "Boot into Windows" SessionButton (last in the column) — arms EFI
//    BootNext via /usr/local/bin/caelestia-boot-windows.
//  - single-key shortcuts while the menu is open: l/s/h/r/w.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Column {
    id: root

    required property DrawerVisibilities visibilities

    padding: Tokens.padding.large
    spacing: Tokens.spacing.large

    // caelestia-void: single-key shortcuts while the power menu is open.
    // l logout · s shutdown · h hibernate · r reboot · w Windows.
    // Unhandled key events bubble up here from the focused SessionButton.
    Keys.onPressed: event => {
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            return;

        let target = null;
        switch (event.key) {
        case Qt.Key_L:
            target = logout;
            break;
        case Qt.Key_S:
            target = shutdown;
            break;
        case Qt.Key_H:
            target = hibernate;
            break;
        case Qt.Key_R:
            target = reboot;
            break;
        case Qt.Key_W:
            target = windows;
            break;
        }

        if (target) {
            target.forceActiveFocus();
            Quickshell.execDetached(target.command);
            event.accepted = true;
        }
    }

    SessionButton {
        id: logout

        icon: Config.session.icons.logout
        command: Config.session.commands.logout

        KeyNavigation.down: shutdown

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (!root.visibilities.launcher)
                    logout.forceActiveFocus();
            }

            target: root.visibilities
        }
    }

    SessionButton {
        id: shutdown

        icon: Config.session.icons.shutdown
        command: Config.session.commands.shutdown

        KeyNavigation.up: logout
        KeyNavigation.down: hibernate
    }

    AnimatedImage {
        width: Tokens.sizes.session.button
        height: Tokens.sizes.session.button
        sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)

        playing: visible
        asynchronous: true
        speed: Config.general.sessionGifSpeed
        source: Paths.absolutePath(Config.paths.sessionGif)
        fillMode: AnimatedImage.PreserveAspectFit
    }

    SessionButton {
        id: hibernate

        icon: Config.session.icons.hibernate
        command: Config.session.commands.hibernate

        KeyNavigation.up: shutdown
        KeyNavigation.down: reboot
    }

    SessionButton {
        id: reboot

        icon: Config.session.icons.reboot
        command: Config.session.commands.reboot

        KeyNavigation.up: hibernate
        KeyNavigation.down: windows
    }

    // caelestia-void: one-shot reboot into Windows. The helper sets EFI
    // BootNext to the Windows Boot Manager entry, so only the next boot
    // goes to Windows — the permanent BootOrder is left untouched.
    SessionButton {
        id: windows

        icon: "laptop_windows"
        command: ["sudo", "-n", "/usr/local/bin/caelestia-boot-windows"]

        KeyNavigation.up: reboot
    }

    component SessionButton: StyledRect {
        id: button

        required property string icon
        required property list<string> command

        implicitWidth: Tokens.sizes.session.button
        implicitHeight: Tokens.sizes.session.button

        radius: Tokens.rounding.large
        color: button.activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer

        Keys.onEnterPressed: Quickshell.execDetached(button.command)
        Keys.onReturnPressed: Quickshell.execDetached(button.command)
        Keys.onEscapePressed: root.visibilities.session = false
        Keys.onPressed: event => {
            if (!Config.session.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if ((event.key === Qt.Key_J || event.key === Qt.Key_N) && KeyNavigation.down) {
                    KeyNavigation.down.focus = true;
                    event.accepted = true;
                } else if ((event.key === Qt.Key_K || event.key === Qt.Key_P) && KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab && KeyNavigation.down) {
                KeyNavigation.down.focus = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                if (KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            }
        }

        StateLayer {
            radius: parent.radius
            color: button.activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            onClicked: Quickshell.execDetached(button.command)
        }

        MaterialIcon {
            anchors.centerIn: parent

            text: button.icon
            color: button.activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            font.pointSize: Tokens.font.size.extraLarge
            font.weight: 500
        }
    }
}
