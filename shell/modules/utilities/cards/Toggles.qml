pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.bar.popouts as BarPopouts

StyledRect {
    id: root

    required property DrawerVisibilities visibilities
    required property BarPopouts.Wrapper popouts

    readonly property var quickToggles: {
        const seenIds = new Set();

        const list = Config.utilities.quickToggles.filter(item => {
            if (!(item.enabled ?? true))
                return false;

            if (seenIds.has(item.id)) {
                return false;
            }

            if (item.id === "vpn") {
                return GlobalConfig.utilities.vpn.provider.some(p => typeof p === "object" ? (p.enabled === true) : false);
            }

            seenIds.add(item.id);
            return true;
        });

        // Always expose the disable-while-typing toggle — it is not part of
        // the Caelestia default quickToggles list, so append it here rather
        // than requiring a shell.json override.
        if (!list.some(item => item.id === "dwt"))
            list.push({
                id: "dwt",
                enabled: true
            });

        return list;
    }
    readonly property int splitIndex: Math.ceil(quickToggles.length / 2)
    readonly property bool needExtraRow: quickToggles.length > 6

    // --- Touchpad disable-while-typing -------------------------------------
    // Persisted as a Hyprland variable override in hypr-dwt.conf, which is
    // sourced by ~/.config/caelestia/hypr-vars.conf — so the choice survives
    // shell reloads, Hyprland reloads and reboots. The runtime effect is
    // applied immediately via HyprExtras.
    property bool dwtEnabled: true

    function dwtFileContent(on: bool): string {
        return `# Managed by the Caelestia control-centre touchpad toggle.\n$touchpadDisableTyping = ${on}\n`;
    }

    function setDwt(on: bool): void {
        dwtEnabled = on;
        dwtFile.setText(dwtFileContent(on));
        Hypr.extras.applyOptions({
            "input:touchpad:disable_while_typing": on ? 1 : 0
        });
    }

    FileView {
        id: dwtFile

        printErrors: false
        path: `${Quickshell.env("HOME")}/.config/caelestia/hypr-dwt.conf`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const m = text().match(/\$touchpadDisableTyping\s*=\s*(\w+)/i);
            if (m)
                root.dwtEnabled = m[1].toLowerCase() === "true";
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => setText(root.dwtFileContent(root.dwtEnabled)));
        }
    }

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    radius: Tokens.rounding.normal
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.normal

        StyledText {
            text: qsTr("Quick Toggles")
            font.pointSize: Tokens.font.size.normal
        }

        QuickToggleRow {
            rowModel: root.needExtraRow ? root.quickToggles.slice(0, root.splitIndex) : root.quickToggles
        }

        QuickToggleRow {
            visible: root.needExtraRow
            rowModel: root.needExtraRow ? root.quickToggles.slice(root.splitIndex) : []
        }
    }

    component QuickToggleRow: RowLayout {
        property var rowModel: []

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        Repeater {
            model: parent.rowModel

            delegate: DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "wifi"
                    delegate: Toggle {
                        icon: "wifi"
                        checked: Nmcli.wifiEnabled
                        onClicked: Nmcli.toggleWifi()
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: Toggle {
                        icon: "bluetooth"
                        checked: Bluetooth.defaultAdapter?.enabled ?? false // qmllint disable unresolved-type
                        onClicked: {
                            const adapter = Bluetooth.defaultAdapter; // qmllint disable unresolved-type
                            if (adapter)
                                adapter.enabled = !adapter.enabled;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "mic"
                    delegate: Toggle {
                        icon: "mic"
                        checked: !Audio.sourceMuted
                        onClicked: {
                            const audio = Audio.source?.audio;
                            if (audio)
                                audio.muted = !audio.muted;
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "settings"
                    delegate: Toggle {
                        icon: "settings"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        toggle: false
                        onClicked: {
                            root.visibilities.utilities = false;
                            root.popouts.detach("network");
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "gameMode"
                    delegate: Toggle {
                        icon: "gamepad"
                        checked: GameMode.enabled
                        onClicked: GameMode.enabled = !GameMode.enabled
                    }
                }
                DelegateChoice {
                    roleValue: "dnd"
                    delegate: Toggle {
                        icon: "notifications_off"
                        checked: Notifs.dnd
                        onClicked: Notifs.dnd = !Notifs.dnd
                    }
                }
                DelegateChoice {
                    roleValue: "vpn"
                    delegate: Toggle {
                        icon: "vpn_key"
                        checked: VPN.connected && VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        enabled: !VPN.connecting
                        toggle: VPN.status.state !== "needs-auth" && VPN.status.state !== "error"
                        inactiveOnColour: Colours.palette.m3onSurfaceVariant
                        onClicked: VPN.toggle()
                    }
                }
                DelegateChoice {
                    roleValue: "dwt"
                    delegate: Toggle {
                        icon: "do_not_touch"
                        checked: root.dwtEnabled
                        onClicked: root.setDwt(!root.dwtEnabled)
                    }
                }
            }
        }
    }

    component Toggle: IconButton {
        Layout.fillWidth: true
        Layout.preferredWidth: implicitWidth + (stateLayer.pressed ? Tokens.padding.large : internalChecked ? Tokens.padding.smaller : 0)
        radius: stateLayer.pressed ? Tokens.rounding.small / 2 : internalChecked ? Tokens.rounding.small : Tokens.rounding.normal
        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        toggle: true
        radiusAnim.duration: Tokens.anim.durations.expressiveFastSpatial
        radiusAnim.easing: Tokens.anim.expressiveFastSpatial

        Behavior on Layout.preferredWidth {
            Anim {
                type: Anim.FastSpatial
            }
        }
    }
}
