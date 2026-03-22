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

  // Settings access pattern
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Edit copies of settings
  property bool editSplash: cfg.splash ?? defaults.splash ?? true
  property real editSplashOffset: cfg.splash_offset ?? defaults.splash_offset ?? 20
  property real editSplashOpacity: cfg.splash_opacity ?? defaults.splash_opacity ?? 0.8
  property bool editIpc: cfg.ipc ?? defaults.ipc ?? true

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Hyprpaper", "Cannot save: pluginApi is null")
      return
    }

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

  NText {
    text: pluginApi?.tr("settings.miscOptions")
    pointSize: Style.fontSizeM
    font.weight: Style.fontWeightBold
    color: Color.mOnSurface
    Layout.fillWidth: true
  }

  NToggle {
    id: splashToggle
    label: pluginApi?.tr("settings.enableSplash")
    description: pluginApi?.tr("settings.splashDescription")
    checked: root.editSplash
    onToggled: (checked) => root.editSplash = checked
    Layout.fillWidth: true
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NText {
      text: pluginApi?.tr("settings.splashOffset")
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

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NText {
      text: pluginApi?.tr("settings.splashOpacity")
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

  NToggle {
    id: ipcToggle
    label: pluginApi?.tr("settings.enableIpc")
    description: pluginApi?.tr("settings.ipcDescription")
    checked: root.editIpc
    onToggled: (checked) => root.editIpc = checked
    Layout.fillWidth: true
  }

  Item {
    Layout.fillHeight: true
  }
}
