import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import qs.Services.UI
import "./Services"

Popup {
  id: root

  property var screen

  width: 440
  height: contentColumn.implicitHeight + Style.marginL * 2
  padding: Style.marginL
  modal: true
  dim: false
  closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

  function showAt(item) {
    open();
  }

  function hide() {
    close();
  }

  function updateResolution(triggerSearch) {
    if (typeof Wallhaven === "undefined") return;

    var width = Settings.data.wallpaper.wallhavenResolutionWidth || "";
    var height = Settings.data.wallpaper.wallhavenResolutionHeight || "";
    var mode = Settings.data.wallpaper.wallhavenResolutionMode || "atleast";

    if (width && height) {
      var resolution = width + "x" + height;
      if (mode === "atleast") {
        Wallhaven.minResolution = resolution;
        Wallhaven.resolutions = "";
      } else {
        Wallhaven.minResolution = "";
        Wallhaven.resolutions = resolution;
      }
    } else {
      Wallhaven.minResolution = "";
      Wallhaven.resolutions = "";
    }

    if (triggerSearch && Settings.data.wallpaper.useWallhaven) {
      Wallhaven.search(Settings.data.wallpaper.wallhavenQuery || "", 1);
    }
  }

  background: Rectangle {
    color: Color.mSurface
    radius: Style.radiusL
    border.color: Color.mOutline
    border.width: Style.borderM
  }

  contentItem: ColumnLayout {
    id: contentColumn
    spacing: Style.marginM

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NIcon {
        icon: "settings"
        pointSize: Style.fontSizeL
        color: Color.mPrimary
      }

      NText {
        text: pluginApi?.tr("wallpaper.panel.wallhaven-settings-title") || "Wallhaven Settings"
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightBold
        color: Color.mOnSurface
        Layout.fillWidth: true
      }

      NIconButton {
        icon: "close"
        tooltipText: pluginApi?.tr("common.close") || "Close"
        baseSize: Style.baseWidgetSize * 0.8
        onClicked: root.hide()
      }
    }

    NDivider {
      Layout.fillWidth: true
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NText {
        text: pluginApi?.tr("wallpaper.panel.apikey-label") || "API Key"
        color: Color.mOnSurface
        pointSize: Style.fontSizeM
      }

      NTextInput {
        id: apiKeyInput
        Layout.fillWidth: true
        placeholderText: pluginApi?.tr("wallpaper.panel.apikey-placeholder") || "Enter API key..."
        text: Settings.data.wallpaper.wallhavenApiKey || ""

        Component.onCompleted: {
          if (apiKeyInput.inputItem) {
            apiKeyInput.inputItem.echoMode = TextInput.Password;
          }
        }

        onEditingFinished: {
          Settings.data.wallpaper.wallhavenApiKey = text;
        }
      }

      NText {
        text: pluginApi?.tr("wallpaper.panel.apikey-help") || "Get a free API key from wallhaven.cc"
        color: Color.mOnSurfaceVariant
        pointSize: Style.fontSizeS
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }

    NDivider {
      Layout.fillWidth: true
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NText {
        text: pluginApi?.tr("wallpaper.panel.sorting-label") || "Sorting"
        color: Color.mOnSurface
        pointSize: Style.fontSizeM
        Layout.preferredWidth: implicitWidth
      }

      NComboBox {
        Layout.fillWidth: true
        Layout.minimumWidth: 200
        model: [
          { "key": "date_added", "name": pluginApi?.tr("wallpaper.panel.sorting-date-added") || "Date Added" },
          { "key": "relevance", "name": pluginApi?.tr("wallpaper.panel.sorting-relevance") || "Relevance" },
          { "key": "random", "name": pluginApi?.tr("common.random") || "Random" },
          { "key": "views", "name": pluginApi?.tr("wallpaper.panel.sorting-views") || "Views" },
          { "key": "favorites", "name": pluginApi?.tr("wallpaper.panel.sorting-favorites") || "Favorites" },
          { "key": "toplist", "name": pluginApi?.tr("wallpaper.panel.sorting-toplist") || "Toplist" }
        ]
        currentKey: Settings.data.wallpaper.wallhavenSorting || "relevance"
        onSelected: key => {
          Settings.data.wallpaper.wallhavenSorting = key;
          if (typeof Wallhaven !== "undefined") {
            Wallhaven.sorting = key;
            Wallhaven.search(Settings.data.wallpaper.wallhavenQuery || "", 1);
          }
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NText {
        text: pluginApi?.tr("wallpaper.panel.order-label") || "Order"
        color: Color.mOnSurface
        pointSize: Style.fontSizeM
        Layout.preferredWidth: implicitWidth
      }

      NComboBox {
        Layout.fillWidth: true
        Layout.minimumWidth: 200
        model: [
          { "key": "desc", "name": pluginApi?.tr("wallpaper.panel.order-desc") || "Descending" },
          { "key": "asc", "name": pluginApi?.tr("wallpaper.panel.order-asc") || "Ascending" }
        ]
        currentKey: Settings.data.wallpaper.wallhavenOrder || "desc"
        onSelected: key => {
          Settings.data.wallpaper.wallhavenOrder = key;
          if (typeof Wallhaven !== "undefined") {
            Wallhaven.order = key;
            Wallhaven.search(Settings.data.wallpaper.wallhavenQuery || "", 1);
          }
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NText {
        text: pluginApi?.tr("wallpaper.panel.purity-label") || "Purity"
        color: Color.mOnSurface
        pointSize: Style.fontSizeM
        Layout.preferredWidth: implicitWidth
      }

      Item { Layout.fillWidth: true }

      RowLayout {
        spacing: Style.marginL

        function getPurityValue(index) {
          var purity = Settings.data.wallpaper.wallhavenPurity || "100";
          return purity.length > index && purity.charAt(index) === "1";
        }

        function updatePurity(sfw, sketchy, nsfw) {
          var purity = (sfw ? "1" : "0") + (sketchy ? "1" : "0") + (nsfw ? "1" : "0");
          Settings.data.wallpaper.wallhavenPurity = purity;
          sfwToggle.checked = sfw;
          sketchyToggle.checked = sketchy;
          nsfwToggle.checked = nsfw;
          if (typeof Wallhaven !== "undefined") {
            Wallhaven.purity = purity;
            Wallhaven.search(Settings.data.wallpaper.wallhavenQuery || "", 1);
          }
        }

        Connections {
          target: Settings.data.wallpaper
          function onWallhavenPurityChanged() {
            sfwToggle.checked = purityRow.getPurityValue(0);
            sketchyToggle.checked = purityRow.getPurityValue(1);
            nsfwToggle.checked = purityRow.getPurityValue(2);
          }
        }

        Component.onCompleted: {
          sfwToggle.checked = purityRow.getPurityValue(0);
          sketchyToggle.checked = purityRow.getPurityValue(1);
          nsfwToggle.checked = purityRow.getPurityValue(2);
        }

        RowLayout {
          spacing: Style.marginS

          NText {
            text: "SFW"
            color: Color.mOnSurface
            pointSize: Style.fontSizeS
          }

          Rectangle {
            width: 20
            height: 20
            radius: 4
            color: sfwToggle.checked ? Color.mPrimary : Color.mSurface
            border.color: Color.mOutline
            border.width: 1

            NIcon {
              visible: sfwToggle.checked
              icon: "check"
              color: Color.mOnPrimary
              anchors.centerIn: parent
              pointSize: 12
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: sfwToggle.toggled(!sfwToggle.checked)
            }
          }
        }

        RowLayout {
          spacing: Style.marginS

          NText {
            text: "Sketchy"
            color: Color.mOnSurface
            pointSize: Style.fontSizeS
          }

          Rectangle {
            width: 20
            height: 20
            radius: 4
            color: sketchyToggle.checked ? Color.mPrimary : Color.mSurface
            border.color: Color.mOutline
            border.width: 1

            NIcon {
              visible: sketchyToggle.checked
              icon: "check"
              color: Color.mOnPrimary
              anchors.centerIn: parent
              pointSize: 12
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: sketchyToggle.toggled(!sketchyToggle.checked)
            }
          }
        }

        RowLayout {
          spacing: Style.marginS

          NText {
            text: "NSFW"
            color: Color.mOnSurface
            pointSize: Style.fontSizeS
          }

          Rectangle {
            width: 20
            height: 20
            radius: 4
            color: nsfwToggle.checked ? Color.mPrimary : Color.mSurface
            border.color: Color.mOutline
            border.width: 1

            NIcon {
              visible: nsfwToggle.checked
              icon: "check"
              color: Color.mOnPrimary
              anchors.centerIn: parent
              pointSize: 12
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: nsfwToggle.toggled(!nsfwToggle.checked)
            }
          }
        }

        QtObject {
          id: sfwToggle
          property bool checked: false
          signal toggled(bool checked)
          onToggled: checked => purityRow.updatePurity(checked, purityRow.getPurityValue(1), purityRow.getPurityValue(2))
        }

        QtObject {
          id: sketchyToggle
          property bool checked: false
          signal toggled(bool checked)
          onToggled: checked => purityRow.updatePurity(purityRow.getPurityValue(0), checked, purityRow.getPurityValue(2))
        }

        QtObject {
          id: nsfwToggle
          property bool checked: false
          signal toggled(bool checked)
          onToggled: checked => purityRow.updatePurity(purityRow.getPurityValue(0), purityRow.getPurityValue(1), checked)
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NText {
        text: pluginApi?.tr("wallpaper.panel.ratios-label") || "Aspect Ratio"
        color: Color.mOnSurface
        pointSize: Style.fontSizeM
        Layout.preferredWidth: implicitWidth
      }

      NComboBox {
        Layout.fillWidth: true
        Layout.minimumWidth: 200
        model: [
          { "key": "", "name": pluginApi?.tr("wallpaper.panel.ratios-any") || "Any" },
          { "key": "landscape", "name": "Landscape" },
          { "key": "portrait", "name": "Portrait" },
          { "key": "16x9", "name": "16:9" },
          { "key": "16x10", "name": "16:10" },
          { "key": "21x9", "name": "21:9" },
          { "key": "9x16", "name": "9:16" },
          { "key": "1x1", "name": "1:1" }
        ]
        currentKey: Settings.data.wallpaper.wallhavenRatios || ""
        onSelected: key => {
          Settings.data.wallpaper.wallhavenRatios = key;
          if (typeof Wallhaven !== "undefined") {
            Wallhaven.ratios = key;
            Wallhaven.search(Settings.data.wallpaper.wallhavenQuery || "", 1);
          }
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginS

      NText {
        text: pluginApi?.tr("wallpaper.panel.resolution-label") || "Resolution"
        color: Color.mOnSurface
        pointSize: Style.fontSizeM
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NTextInput {
          id: resolutionWidthInput
          Layout.preferredWidth: 80
          placeholderText: "Width"
          inputMethodHints: Qt.ImhDigitsOnly
          text: Settings.data.wallpaper.wallhavenResolutionWidth || ""

          onEditingFinished: {
            Settings.data.wallpaper.wallhavenResolutionWidth = text;
            updateResolution(false);
          }
        }

        NText {
          text: "×"
          color: Color.mOnSurface
        }

        NTextInput {
          id: resolutionHeightInput
          Layout.preferredWidth: 80
          placeholderText: "Height"
          inputMethodHints: Qt.ImhDigitsOnly
          text: Settings.data.wallpaper.wallhavenResolutionHeight || ""

          onEditingFinished: {
            Settings.data.wallpaper.wallhavenResolutionHeight = text;
            updateResolution(false);
          }
        }
      }
    }

    NDivider {
      Layout.fillWidth: true
      Layout.topMargin: Style.marginM
    }

    NButton {
      Layout.fillWidth: true
      text: pluginApi?.tr("common.apply") || "Apply"
      onClicked: {
        if (typeof Wallhaven !== "undefined" && Settings.data.wallpaper.useWallhaven) {
          Wallhaven.categories = Settings.data.wallpaper.wallhavenCategories;
          Wallhaven.purity = Settings.data.wallpaper.wallhavenPurity;
          Wallhaven.sorting = Settings.data.wallpaper.wallhavenSorting;
          Wallhaven.order = Settings.data.wallpaper.wallhavenOrder;
          Wallhaven.ratios = Settings.data.wallpaper.wallhavenRatios;
          Wallhaven.apiKey = Settings.data.wallpaper.wallhavenApiKey;
          updateResolution(false);
          Wallhaven.search(Settings.data.wallpaper.wallhavenQuery || "", 1);
          Qt.callLater(() => root.hide());
        }
      }
    }
  }
}
