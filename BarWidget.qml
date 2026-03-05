import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.Panels.Settings
import qs.Services.Hardware
import qs.Services.UI
import qs.Widgets
import "./Services"

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  readonly property string screenName: screen?.name ?? ""

  implicitWidth: pill.width
  implicitHeight: pill.height

  visible: true

  scale: 1.0

  function getCurrentWallpaperName() {
    var path = Hyprpaper.getWallpaper(screenName);
    if (!path || path === "") return "";
    if (Hyprpaper.isSolidColorPath(path)) return "Solid color";
    return path.split('/').pop();
  }

  BarPill {
    id: pill

    screen: root.screen
    oppositeDirection: BarService.getPillDirection(root)
    customIconColor: Color.resolveColorKeyOptional(root.iconColorKey)
    customTextColor: Color.resolveColorKeyOptional(root.textColorKey)
    icon: "wallpaper-selector"
    autoHide: false
    text: ""
    tooltipText: getCurrentWallpaperName() || pluginApi?.tr("bar.tooltip")
    onClicked: {
      if (pluginApi) {
        pluginApi.openPanel(root.screen, this);
      }
    }
    onRightClicked: {
      Hyprpaper.setRandomWallpaper();
    }
  }

  MouseArea {
    anchors.fill: pill
    onPressed: root.scale = 0.97
    onReleased: root.scale = 1.0
    onClicked: {
      if (pluginApi) {
        pluginApi.openPanel(root.screen, pill);
      }
    }
  }

  Behavior on scale {
    NumberAnimation {
      duration: 150
      easing.type: Easing.OutCubic
    }
  }
}
