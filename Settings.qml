import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI
import "./Services"

ColumnLayout {
    id: root
    spacing: Style.marginL

    property var pluginApi: null

    // Read from pluginApi (user's saved settings) with manifest fallback
    property bool editSplash:
        pluginApi?.pluginSettings?.splash ??
        pluginApi?.manifest?.metadata?.defaultSettings?.splash ??
        true

    property real editSplashOffset:
        pluginApi?.pluginSettings?.splash_offset ??
        pluginApi?.manifest?.metadata?.defaultSettings?.splash_offset ??
        20

    property real editSplashOpacity:
        pluginApi?.pluginSettings?.splash_opacity ??
        pluginApi?.manifest?.metadata?.defaultSettings?.splash_opacity ??
        0.8

    property bool editIpc:
        pluginApi?.pluginSettings?.ipc ??
        pluginApi?.manifest?.metadata?.defaultSettings?.ipc ??
        true

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("Hyprpaper", "Cannot save: pluginApi is null")
            return
        }

        // Save to plugin settings
        pluginApi.pluginSettings.splash = root.editSplash
        pluginApi.pluginSettings.splash_offset = root.editSplashOffset
        pluginApi.pluginSettings.splash_opacity = root.editSplashOpacity
        pluginApi.pluginSettings.ipc = root.editIpc
        pluginApi.saveSettings()

        Hyprpaper.updateHyprpaperConf(
            root.editSplash,
            root.editSplashOffset,
            root.editSplashOpacity,
            root.editIpc
        )

        Logger.i("Hyprpaper", "Settings saved successfully")
    }

    // ========================================
    // Misc Options Section
    // ========================================

    NText {
        text: "Misc Options"
        pointSize: Style.fontSizeM
        font.weight: Style.fontWeightBold
        color: Color.mOnSurface
        Layout.fillWidth: true
    }

    // Splash Toggle
    NToggle {
        id: splashToggle
        label: "Enable Splash"
        description: "Render the Hyprland splash over the wallpaper"
        checked: root.editSplash
        onToggled: (checked) => root.editSplash = checked
        Layout.fillWidth: true
    }

    // Splash Offset
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NText {
            text: "Splash Offset"
            color: Color.mOnSurface
            Layout.preferredWidth: 120
        }

        NSlider {
            id: offsetSlider
            from: 0
            to: 100
            stepSize: 1
            value: root.editSplashOffset
            onMoved: root.editSplashOffset = value
            Layout.fillWidth: true
        }

        NText {
            text: Math.round(root.editSplashOffset).toString()
            color: Color.mOnSurfaceVariant
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
        }
    }

    // Splash Opacity
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NText {
            text: "Splash Opacity"
            color: Color.mOnSurface
            Layout.preferredWidth: 120
        }

        NSlider {
            id: opacitySlider
            from: 0
            to: 1.0
            stepSize: 0.1
            value: root.editSplashOpacity
            onMoved: root.editSplashOpacity = value
            Layout.fillWidth: true
        }

        NText {
            text: root.editSplashOpacity.toFixed(1)
            color: Color.mOnSurfaceVariant
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
        }
    }

    // IPC Toggle
    NToggle {
        id: ipcToggle
        label: "Enable IPC"
        description: "WARNING: Disabling this will break the plugin's ability to change wallpapers!"
        checked: root.editIpc
        onToggled: (checked) => root.editIpc = checked
        Layout.fillWidth: true
    }

    Item {
        Layout.fillHeight: true
    }
}