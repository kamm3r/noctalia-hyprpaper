import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "./Services"

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  // Settings access pattern
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Bar layout awareness
  readonly property string barPosition: Settings.getBarPositionForScreen(screen?.name)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screen?.name)

  readonly property string screenName: screen?.name ?? ""

  implicitWidth: isVertical ? capsuleHeight : pill.width
  implicitHeight: isVertical ? pill.height : capsuleHeight

  visible: true

  function getCurrentWallpaperName() {
    var path = Hyprpaper.getWallpaper(screenName);
    if (!path || path === "") return "";
    if (Hyprpaper.isSolidColorPath(path)) return pluginApi?.tr("bar.solidColor") ?? "Solid color";
    return path.split('/').pop();
  }

  // Context menu (right-click)
  NPopupContextMenu {
    id: contextMenu
    model: [
      { "label": pluginApi?.tr("menu.settings") ?? "Widget settings", "action": "settings", "icon": "settings" }
    ]
    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(screen);
      if (action === "settings") {
        BarService.openPluginSettings(screen, pluginApi.manifest);
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
      if (mouse.button === Qt.LeftButton) {
        if (pluginApi) pluginApi.togglePanel(root.screen, root);
      } else if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen);
      }
    }
  }

  NIconButtonHot {
    id: pill
    anchors.centerIn: parent
    icon: "wallpaper-selector"
    tooltipText: getCurrentWallpaperName() || pluginApi?.tr("bar.tooltip")
    onClicked: {
      if (pluginApi) {
        pluginApi.togglePanel(root.screen, this);
      }
    }
  }
}
