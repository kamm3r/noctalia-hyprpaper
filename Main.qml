import QtQuick
import Quickshell.Io
import qs.Services.UI
import qs.Commons
import "./Services"

Item {
  id: root
  property var pluginApi: null

  Component.onCompleted: {
    Hyprpaper.init();
  }

  IpcHandler {
    target: "plugin:hyprpaper"

    function toggle() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(screen => {
          pluginApi.togglePanel(screen);
        });
      }
    }
  }
}