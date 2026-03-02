import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.Theming
import qs.Services.UI
import qs.Widgets
import "Services/UI" as PluginServices

Item {
  id: root

  property var pluginApi: null

  PluginServices.HyprpaperService {
    id: hyprpaperService
  }

  PluginServices.WallhavenService {
    id: wallhavenService
  }

  readonly property bool allowAttach: true
  readonly property int contentPreferredWidth: 800
  readonly property int contentPreferredHeight: 600

  property var contentItem: null

  function onDownPressed() {
    if (!contentItem) return;
    var view = contentItem.screenRepeater.itemAt(contentItem.currentScreenIndex);
    if (view?.gridView) {
      if (!view.gridView.hasActiveFocus) {
        view.gridView.forceActiveFocus();
        if (view.gridView.currentIndex < 0 && view.gridView.model.count > 0) {
          view.gridView.currentIndex = 0;
        }
      } else {
        if (view.gridView.currentIndex < 0 && view.gridView.model.count > 0) {
          view.gridView.currentIndex = 0;
        } else {
          view.gridView.moveCurrentIndexDown();
        }
      }
    }
  }

  function onUpPressed() {
    if (!contentItem) return;
    var view = contentItem.screenRepeater.itemAt(contentItem.currentScreenIndex);
    if (view?.gridView?.hasActiveFocus) {
      if (view.gridView.currentIndex < 0 && view.gridView.model.count > 0) {
        view.gridView.currentIndex = 0;
      } else {
        view.gridView.moveCurrentIndexUp();
      }
    }
  }

  function onLeftPressed() {
    if (!contentItem) return;
    var view = contentItem.screenRepeater.itemAt(contentItem.currentScreenIndex);
    if (view?.gridView?.hasActiveFocus) {
      if (view.gridView.currentIndex < 0 && view.gridView.model.count > 0) {
        view.gridView.currentIndex = 0;
      } else {
        view.gridView.moveCurrentIndexLeft();
      }
    }
  }

  function onRightPressed() {
    if (!contentItem) return;
    var view = contentItem.screenRepeater.itemAt(contentItem.currentScreenIndex);
    if (view?.gridView?.hasActiveFocus) {
      if (view.gridView.currentIndex < 0 && view.gridView.model.count > 0) {
        view.gridView.currentIndex = 0;
      } else {
        view.gridView.moveCurrentIndexRight();
      }
    }
  }

  function onReturnPressed() {
    if (!contentItem) return;

    if (contentItem.wallhavenView && contentItem.wallhavenView.visible && contentItem.wallhavenView.pageInput && contentItem.wallhavenView.pageInput.inputItem.activeFocus) {
      contentItem.wallhavenView.submitPage();
      return;
    }

    var view = contentItem.screenRepeater.itemAt(contentItem.currentScreenIndex);
    if (view?.gridView?.hasActiveFocus) {
      var gridView = view.gridView;
      if (gridView.currentIndex >= 0 && gridView.currentIndex < gridView.model.count) {
        var item = gridView.model.get(gridView.currentIndex);
        view.selectItem(item.path, item.isDirectory);
      }
    }
  }

  function onEnterPressed() {
    onReturnPressed();
  }

  anchors.fill: parent

  Rectangle {
    anchors.fill: parent
    color: Color.mSurface
    radius: Style.radiusL
    border.color: Color.mOutline
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      Rectangle {
        id: headerBox
        Layout.fillWidth: true
        Layout.preferredHeight: headerColumn.implicitHeight + Style.marginL * 2
        color: Color.mSurfaceVariant
        radius: Style.radiusM

        ColumnLayout {
          id: headerColumn
          anchors.fill: parent
          anchors.margins: Style.marginL
          spacing: Style.marginM

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NIcon {
              icon: "wallpaper-selector"
              pointSize: Style.fontSizeXXL
              color: Color.mPrimary
            }

            NText {
              text: "Wallpaper"
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              color: Color.mOnSurface
              Layout.fillWidth: true
            }

            NIconButton {
              icon: "palette"
              tooltipText: "Solid color"
              baseSize: Style.baseWidgetSize * 0.8
              colorBg: Settings.data.wallpaper.useSolidColor ? Color.mPrimary : Color.mSurfaceVariant
              colorFg: Settings.data.wallpaper.useSolidColor ? Color.mOnPrimary : Color.mPrimary
              onClicked: solidColorPicker.open()
            }

            NIconButton {
              icon: "close"
              tooltipText: "Close"
              baseSize: Style.baseWidgetSize * 0.8
              onClicked: root.pluginApi?.closePanel()
            }
          }

          NDivider {
            Layout.fillWidth: true
          }

          NToggle {
            label: "Apply to all monitors"
            description: "Set the same wallpaper on all screens"
            checked: Settings.data.wallpaper.setWallpaperOnAllMonitors
            onToggled: checked => Settings.data.wallpaper.setWallpaperOnAllMonitors = checked
            Layout.fillWidth: true
          }

          NTabBar {
            id: screenTabBar
            visible: (!Settings.data.wallpaper.setWallpaperOnAllMonitors || Settings.data.wallpaper.enableMultiMonitorDirectories)
            Layout.fillWidth: true
            currentIndex: panelContent.currentScreenIndex
            onCurrentIndexChanged: panelContent.currentScreenIndex = currentIndex
            spacing: Style.marginM
            distributeEvenly: true

            Repeater {
              model: Quickshell.screens
              NTabButton {
                required property var modelData
                required property int index
                text: modelData.name || ("Screen " + (index + 1))
                tabIndex: index
                checked: screenTabBar.currentIndex === index
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NTextInput {
              id: searchInput
              placeholderText: Settings.data.wallpaper.useWallhaven ? "Search Wallhaven..." : "Search wallpapers..."
              fontSize: Style.fontSizeM
              Layout.fillWidth: true

              property bool initializing: true

              Component.onCompleted: {
                if (Settings.data.wallpaper.useWallhaven) {
                  searchInput.text = Settings.data.wallpaper.wallhavenQuery || "";
                } else {
                  searchInput.text = panelContent.filterText || "";
                }
                Qt.callLater(function() {
                  searchInput.initializing = false;
                });
              }

              Connections {
                target: Settings.data.wallpaper
                function onUseWallhavenChanged() {
                  if (Settings.data.wallpaper.useWallhaven) {
                    searchInput.text = Settings.data.wallpaper.wallhavenQuery || "";
                  } else {
                    searchInput.text = panelContent.filterText || "";
                  }
                }
              }

              onTextChanged: {
                if (initializing) return;
                if (Settings.data.wallpaper.useWallhaven) {
                  wallhavenSearchDebounceTimer.restart();
                } else {
                  searchDebounceTimer.restart();
                }
              }

              onEditingFinished: {
                if (Settings.data.wallpaper.useWallhaven) {
                  wallhavenSearchDebounceTimer.stop();
                  if (typeof WallhavenService !== "undefined" && text !== WallhavenService.currentQuery) {
                    Settings.data.wallpaper.wallhavenQuery = text;
                    panelContent.wallhavenView.loading = true;
                    WallhavenService.search(text, 1);
                  }
                }
              }

              Keys.onPressed: event => {
                if (Keybinds.checkKey(event, 'down', Settings)) {
                  if (Settings.data.wallpaper.useWallhaven) {
                    if (panelContent.wallhavenView && panelContent.wallhavenView.gridView) {
                      panelContent.wallhavenView.gridView.forceActiveFocus();
                    }
                  } else {
                    var currentView = panelContent.screenRepeater.itemAt(panelContent.currentScreenIndex);
                    if (currentView && currentView.gridView) {
                      currentView.gridView.forceActiveFocus();
                    }
                  }
                  event.accepted = true;
                }
              }
            }

            NIconButton {
              icon: Settings.data.colorSchemes.darkMode ? "moon" : "sun"
              tooltipText: Settings.data.colorSchemes.darkMode ? "Switch to light mode" : "Switch to dark mode"
              baseSize: Style.baseWidgetSize * 0.8
              onClicked: Settings.data.colorSchemes.darkMode = !Settings.data.colorSchemes.darkMode
            }

            NIconButton {
              icon: "color-swatch"
              tooltipText: Settings.data.colorSchemes.useWallpaperColors ? "Color extraction enabled" : "Color extraction disabled"
              baseSize: Style.baseWidgetSize * 0.8
              onClicked: {
                Settings.data.colorSchemes.useWallpaperColors = !Settings.data.colorSchemes.useWallpaperColors;
                if (Settings.data.colorSchemes.useWallpaperColors) {
                  AppThemeService.generate();
                } else {
                  ColorSchemeService.setPredefinedScheme(Settings.data.colorSchemes.predefinedScheme);
                }
              }
            }

            NComboBox {
              id: colorSchemeComboBox
              Layout.fillWidth: false
              Layout.minimumWidth: 200

              model: Settings.data.colorSchemes.useWallpaperColors ? TemplateProcessor.schemeTypes : ColorSchemeService.schemes.map(s => ({
                "key": ColorSchemeService.getBasename(s),
                "name": ColorSchemeService.getBasename(s)
              }))
              currentKey: Settings.data.colorSchemes.useWallpaperColors ? Settings.data.colorSchemes.generationMethod : Settings.data.colorSchemes.predefinedScheme

              onSelected: key => {
                if (Settings.data.colorSchemes.useWallpaperColors) {
                  Settings.data.colorSchemes.generationMethod = key;
                  AppThemeService.generate();
                } else {
                  ColorSchemeService.setPredefinedScheme(key);
                }
              }
            }

            NComboBox {
              id: sourceComboBox
              Layout.fillWidth: false

              model: [
                { "key": "local", "name": "Local" },
                { "key": "wallhaven", "name": "Wallhaven" }
              ]
              currentKey: Settings.data.wallpaper.useWallhaven ? "wallhaven" : "local"

              onSelected: key => {
                var useWallhaven = (key === "wallhaven");
                Settings.data.wallpaper.useWallhaven = useWallhaven;
                if (useWallhaven) {
                  searchInput.text = Settings.data.wallpaper.wallhavenQuery || "";
                } else {
                  searchInput.text = panelContent.filterText || "";
                }
                if (useWallhaven && typeof WallhavenService !== "undefined") {
                  WallhavenService.categories = Settings.data.wallpaper.wallhavenCategories;
                  WallhavenService.purity = Settings.data.wallpaper.wallhavenPurity;
                  WallhavenService.sorting = Settings.data.wallpaper.wallhavenSorting;
                  WallhavenService.order = Settings.data.wallpaper.wallhavenOrder;
                  panelContent.updateWallhavenResolution();
                  if (panelContent.wallhavenView && panelContent.wallhavenView.initialized && !WallhavenService.fetching) {
                    panelContent.wallhavenView.loading = true;
                    WallhavenService.search(Settings.data.wallpaper.wallhavenQuery || "", WallhavenService.currentPage);
                  }
                }
              }
            }

            NIconButton {
              id: wallhavenSettingsButton
              icon: "settings"
              tooltipText: "Wallhaven settings"
              baseSize: Style.baseWidgetSize * 0.8
              visible: Settings.data.wallpaper.useWallhaven
              onClicked: {
                if (searchInput.inputItem) {
                  searchInput.inputItem.focus = false;
                }
                wallhavenSettingsPopup.item.showAt(wallhavenSettingsButton);
              }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Color.mSurfaceVariant
        radius: Style.radiusM

        StackLayout {
          id: contentStack
          anchors.fill: parent
          anchors.margins: Style.marginL

          currentIndex: Settings.data.wallpaper.useWallhaven ? 1 : 0

          StackLayout {
            id: screenStack
            currentIndex: panelContent.currentScreenIndex

            Repeater {
              id: screenRepeater
              model: Quickshell.screens
              delegate: wallpaperScreenViewDelegate
            }
          }

          Item {
            id: wallhavenViewContainer
            wallpaperPanelWallhavenViewComponent {
              id: wallhavenView
            }
          }
        }
      }
    }
  }

  Loader {
    id: wallhavenSettingsPopup
    source: "WallhavenSettingsPopup.qml"
    onLoaded: {
      if (item) {
        item.screen = root.pluginApi?.panelOpenScreen;
      }
    }
  }

  NColorPickerDialog {
    id: solidColorPicker
    selectedColor: Settings.data.wallpaper.solidColor
    onColorSelected: color => hyprpaperService.setSolidColor(color.toString())
  }

  Timer {
    id: searchDebounceTimer
    interval: 150
    onTriggered: {
      panelContent.filterText = searchInput.text;
      for (var i = 0; i < screenRepeater.count; i++) {
        var item = screenRepeater.itemAt(i);
        if (item && item.updateFiltered) {
          item.updateFiltered();
        }
      }
    }
  }

  Timer {
    id: wallhavenSearchDebounceTimer
    interval: 500
    onTriggered: {
      Settings.data.wallpaper.wallhavenQuery = searchInput.text;
      if (typeof WallhavenService !== "undefined") {
        panelContent.wallhavenView.loading = true;
        WallhavenService.search(searchInput.text, 1);
      }
    }
  }

  Component {
    id: wallpaperScreenViewDelegate

    Item {
      property alias gridView: wallpaperGridView

      property list<string> wallpapersList: []
      property string currentWallpaper: ""
      property var filteredItems: []
      property var directoriesList: []

      ListModel {
        id: wallpaperModel
      }

      property string currentBrowsePath: hyprpaperService.getCurrentBrowsePath(targetScreen?.name ?? "")
      property bool isBrowseMode: Settings.data.wallpaper.viewMode === "browse"
      property int _browseScanGeneration: 0

      property var targetScreen: modelData

      function sortFavoritesToTop(items) {
        var favorited = [];
        var nonFavorited = [];
        for (var i = 0; i < items.length; i++) {
          if (!items[i].isDirectory && hyprpaperService.isFavorite(items[i].path)) {
            favorited.push(items[i]);
          } else {
            nonFavorited.push(items[i]);
          }
        }
        return favorited.concat(nonFavorited);
      }

      function updateFiltered(skipSync) {
        var combinedItems = [];

        if (isBrowseMode) {
          for (var i = 0; i < directoriesList.length; i++) {
            var dirPath = directoriesList[i];
            combinedItems.push({
              "path": dirPath,
              "name": dirPath.split('/').pop(),
              "isDirectory": true
            });
          }
        }

        for (var i = 0; i < wallpapersList.length; i++) {
          combinedItems.push({
            "path": wallpapersList[i],
            "name": wallpapersList[i].split('/').pop(),
            "isDirectory": false
          });
        }

        combinedItems = sortFavoritesToTop(combinedItems);

        if (!panelContent.filterText || panelContent.filterText.trim().length === 0) {
          filteredItems = combinedItems;
          if (!skipSync) syncModel();
          return;
        }

        var searchText = panelContent.filterText.trim().toLowerCase();
        var filtered = combinedItems.filter(function(item) {
          return item.name.toLowerCase().includes(searchText);
        });
        filteredItems = sortFavoritesToTop(filtered);
        if (!skipSync) syncModel();
      }

      function syncModel() {
        wallpaperModel.clear();
        for (var i = 0; i < filteredItems.length; i++) {
          wallpaperModel.append(filteredItems[i]);
        }
        wallpaperGridView.currentIndex = -1;
        wallpaperGridView.positionViewAtBeginning();
      }

      function handleFavoriteMove(path) {
        var fromIndex = -1;
        for (var i = 0; i < wallpaperModel.count; i++) {
          if (wallpaperModel.get(i).path === path) {
            fromIndex = i;
            break;
          }
        }
        if (fromIndex === -1) return;

        var toIndex = -1;
        for (var j = 0; j < filteredItems.length; j++) {
          if (filteredItems[j].path === path) {
            toIndex = j;
            break;
          }
        }
        if (toIndex === -1 || fromIndex === toIndex) return;

        wallpaperGridView.animateMovement = true;
        wallpaperModel.move(fromIndex, toIndex, 1);
        animateMovementResetTimer.restart();
      }

      Timer {
        id: animateMovementResetTimer
        interval: Style.animationNormal + 50
        onTriggered: {
          wallpaperGridView.animateMovement = false;
          reconcileModel();
        }
      }

      function reconcileModel() {
        for (var i = 0; i < filteredItems.length; i++) {
          var currentPos = -1;
          for (var j = i; j < wallpaperModel.count; j++) {
            if (wallpaperModel.get(j).path === filteredItems[i].path) {
              currentPos = j;
              break;
            }
          }
          if (currentPos !== -1 && currentPos !== i) {
            wallpaperModel.move(currentPos, i, 1);
          }
        }
      }

      Component.onCompleted: {
        refreshWallpaperScreenData();
      }

      Connections {
        target: hyprpaperService
        function onWallpaperChanged(screenName, path) {
          if (targetScreen !== null && screenName === targetScreen.name) {
            currentWallpaper = hyprpaperService.getWallpaper(targetScreen.name);
          }
        }
        function onWallpaperDirectoryChanged(screenName, directory) {
          if (targetScreen !== null && screenName === targetScreen.name) {
            if (isBrowseMode) {
              hyprpaperService.navigateToRoot(targetScreen.name);
            }
            refreshWallpaperScreenData();
          }
        }
        function onWallpaperListChanged(screenName, count) {
          if (targetScreen !== null && screenName === targetScreen.name) {
            refreshWallpaperScreenData();
          }
        }
        function onBrowsePathChanged(screenName, path) {
          if (targetScreen !== null && screenName === targetScreen.name) {
            currentBrowsePath = path;
            refreshWallpaperScreenData();
          }
        }
        function onFavoritesChanged(path) {
          updateFiltered(true);
          handleFavoriteMove(path);
        }
      }

      function refreshWallpaperScreenData() {
        if (targetScreen === null) return;

        currentWallpaper = hyprpaperService.getWallpaper(targetScreen.name);

        if (isBrowseMode) {
          var browsePath = hyprpaperService.getCurrentBrowsePath(targetScreen.name);
          currentBrowsePath = browsePath;

          var gen = ++_browseScanGeneration;
          hyprpaperService.scanDirectoryWithDirs(targetScreen.name, browsePath, function(result) {
            if (gen !== _browseScanGeneration) return;
            wallpapersList = result.files;
            directoriesList = result.directories;
            updateFiltered();
          });
        } else {
          wallpapersList = hyprpaperService.getWallpapersList(targetScreen.name);
          directoriesList = [];
          updateFiltered();
        }
      }

      function selectItem(path, isDirectory) {
        if (isDirectory) {
          hyprpaperService.setBrowsePath(targetScreen.name, path);
        } else {
          var screen = Settings.data.wallpaper.setWallpaperOnAllMonitors ? undefined : targetScreen.name;
          hyprpaperService.changeWallpaper(path, screen);
          hyprpaperService.applyFavoriteTheme(path, screen);
        }
      }

      function cycleViewMode() {
        var mode = Settings.data.wallpaper.viewMode;
        if (mode === "single") {
          Settings.data.wallpaper.viewMode = "recursive";
        } else if (mode === "recursive") {
          Settings.data.wallpaper.viewMode = "browse";
        } else {
          Settings.data.wallpaper.viewMode = "single";
        }
      }

      function getViewModeIcon() {
        var mode = Settings.data.wallpaper.viewMode;
        if (mode === "single") return "folder";
        if (mode === "recursive") return "folders";
        return "folder-open";
      }

      ColumnLayout {
        anchors.fill: parent
        spacing: Style.marginM

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          NIconButton {
            icon: "arrow-left"
            enabled: isBrowseMode && currentBrowsePath !== hyprpaperService.getMonitorDirectory(targetScreen?.name ?? "")
            onClicked: hyprpaperService.navigateUp(targetScreen?.name ?? "")
            baseSize: Style.baseWidgetSize * 0.8
          }

          NIconButton {
            icon: "home"
            enabled: isBrowseMode && currentBrowsePath !== hyprpaperService.getMonitorDirectory(targetScreen?.name ?? "")
            onClicked: hyprpaperService.navigateToRoot(targetScreen?.name ?? "")
            baseSize: Style.baseWidgetSize * 0.8
          }

          NScrollText {
            text: isBrowseMode ? currentBrowsePath : hyprpaperService.getMonitorDirectory(targetScreen?.name ?? "")
            Layout.fillWidth: true
            scrollMode: NScrollText.ScrollMode.Hover
            gradientColor: Color.mSurfaceVariant
            cornerRadius: Style.radiusM

            NText {
              text: isBrowseMode ? currentBrowsePath : hyprpaperService.getMonitorDirectory(targetScreen?.name ?? "")
              pointSize: Style.fontSizeS
              color: Color.mOnSurfaceVariant
            }
          }

          NIconButton {
            property string sortOrder: Settings.data.wallpaper.sortOrder || "name"
            icon: {
              if (sortOrder === "date_desc") return "clock";
              if (sortOrder === "date_asc") return "history";
              if (sortOrder === "name_desc") return "sort-descending";
              if (sortOrder === "random") return "arrows-shuffle";
              return "sort-ascending";
            }
            onClicked: {
              var next = "name";
              if (sortOrder === "name") next = "date_desc";
              else if (sortOrder === "date_desc") next = "date_asc";
              else if (sortOrder === "date_asc") next = "name_desc";
              else if (sortOrder === "name_desc") next = "random";
              else next = "name";
              Settings.data.wallpaper.sortOrder = next;
            }
            baseSize: Style.baseWidgetSize * 0.8
          }

          NIconButton {
            icon: getViewModeIcon()
            onClicked: cycleViewMode()
            baseSize: Style.baseWidgetSize * 0.8
          }

          NIconButton {
            icon: Settings.data.wallpaper.hideWallpaperFilenames ? "id-off" : "id"
            onClicked: Settings.data.wallpaper.hideWallpaperFilenames = !Settings.data.wallpaper.hideWallpaperFilenames
            baseSize: Style.baseWidgetSize * 0.8
          }

          NIconButton {
            icon: Settings.data.wallpaper.showHiddenFiles ? "eye" : "eye-closed"
            onClicked: Settings.data.wallpaper.showHiddenFiles = !Settings.data.wallpaper.showHiddenFiles
            baseSize: Style.baseWidgetSize * 0.8
          }

          NIconButton {
            icon: "refresh"
            onClicked: {
              if (isBrowseMode) {
                refreshWallpaperScreenData();
              } else {
                hyprpaperService.refreshWallpapersList();
              }
            }
            baseSize: Style.baseWidgetSize * 0.8
          }
        }

        NGridView {
          id: wallpaperGridView

          Layout.fillWidth: true
          Layout.fillHeight: true

          visible: !hyprpaperService.scanning
          interactive: true
          keyNavigationEnabled: true
          keyNavigationWraps: false
          highlightFollowsCurrentItem: false
          currentIndex: -1

          model: wallpaperModel

          property int columns: 4
          property int itemSize: cellWidth

          cellWidth: Math.floor((availableWidth - leftMargin - rightMargin) / columns)
          cellHeight: Math.floor(itemSize * 0.7) + Style.marginXS + Style.fontSizeXS + Style.marginM

          leftMargin: Style.marginS
          rightMargin: Style.marginS
          topMargin: Style.marginS
          bottomMargin: Style.marginS

          delegate: Item {
            width: wallpaperGridView.cellWidth
            height: wallpaperGridView.cellHeight

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Style.marginXS
              spacing: Style.marginXS

              property string wallpaperPath: model.path ?? ""
              property bool isDirectory: model.isDirectory ?? false
              property bool isSelected: !isDirectory && (wallpaperPath === currentWallpaper)
              property bool isFavorited: !isDirectory && hyprpaperService.isFavorite(wallpaperPath)
              property string filename: model.name ?? wallpaperPath.split('/').pop()

              Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                property real imageHeight: Math.round(wallpaperGridView.itemSize * 0.67)

                Rectangle {
                  anchors.fill: parent
                  color: Color.mSurfaceVariant
                  radius: Style.radiusM
                  visible: isDirectory
                  border.color: wallpaperGridView.currentIndex === index ? Color.mHover : Color.mSurface
                  border.width: Math.max(1, Style.borderL * 1.5)

                  NIcon {
                    icon: "folder"
                    pointSize: Style.fontSizeXXXL
                    color: Color.mPrimary
                    anchors.centerIn: parent
                  }
                }

                NImageRounded {
                  id: img
                  anchors.fill: parent
                  visible: !isDirectory
                  imagePath: wallpaperItem.wallpaperPath
                  radius: Style.radiusM
                  borderColor: {
                    if (isSelected) return Color.mSecondary;
                    if (wallpaperGridView.currentIndex === index) return Color.mHover;
                    return Color.mSurface;
                  }
                  borderWidth: Math.max(1, Style.borderL * 1.5)
                  imageFillMode: Image.PreserveAspectCrop
                }

                Rectangle {
                  anchors.fill: parent
                  color: Color.mSurfaceVariant
                  radius: Style.radiusM
                  visible: !isDirectory && (img.status === Image.Loading || img.status === Image.Error)

                  NIcon {
                    icon: "image"
                    pointSize: Style.fontSizeL
                    color: Color.mOnSurfaceVariant
                    anchors.centerIn: parent
                  }
                }

                NBusyIndicator {
                  anchors.horizontalCenter: parent.horizontalCenter
                  y: (parent.height - height) / 2
                  visible: !isDirectory && img.status === Image.Loading
                  running: visible
                  size: 18
                }

                Rectangle {
                  anchors.top: parent.top
                  anchors.right: parent.top
                  anchors.margins: Style.marginS
                  width: 28
                  height: 28
                  radius: width / 2
                  color: Color.mSecondary
                  visible: isSelected

                  NIcon {
                    icon: "check"
                    pointSize: Style.fontSizeM
                    color: Color.mOnSecondary
                    anchors.centerIn: parent
                  }
                }

                Rectangle {
                  anchors.top: parent.top
                  anchors.left: parent.left
                  anchors.margins: Style.marginS
                  width: 28
                  height: 28
                  radius: width / 2
                  visible: !isDirectory && (isFavorited || starHoverHandler.hovered || wallpaperGridView.currentIndex === index)
                  color: isFavorited ? (starHoverHandler.hovered ? Color.mHover : Color.mPrimary) : (starHoverHandler.hovered ? Color.mSurfaceVariant : Color.mSurface)
                  opacity: isFavorited || starHoverHandler.hovered ? 1.0 : 0.7

                  NIcon {
                    icon: isFavorited ? "star-filled" : "star"
                    pointSize: Style.fontSizeM
                    color: isFavorited ? (starHoverHandler.hovered ? Color.mOnHover : Color.mOnPrimary) : (starHoverHandler.hovered ? Color.mOnSurface : Color.mOnSurfaceVariant)
                    anchors.centerIn: parent
                  }

                  HoverHandler {
                    id: starHoverHandler
                  }

                  TapHandler {
                    onToggled: hyprpaperService.toggleFavorite(wallpaperItem.wallpaperPath)
                  }
                }

                HoverHandler {}

                TapHandler {
                  onTapped: {
                    wallpaperGridView.forceActiveFocus();
                    wallpaperGridView.currentIndex = index;
                    selectItem(wallpaperItem.wallpaperPath, wallpaperItem.isDirectory);
                  }
                }
              }

              NText {
                text: filename
                visible: !Settings.data.wallpaper.hideWallpaperFilenames
                color: Color.mOnSurface
                pointSize: Style.fontSizeXS
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
              }
            }
          }
        }

        Rectangle {
          color: Color.mSurface
          radius: Style.radiusM
          border.color: Color.mOutline
          border.width: Style.borderS
          visible: (wallpaperModel.count === 0 && !hyprpaperService.scanning) || hyprpaperService.scanning
          Layout.fillWidth: true
          Layout.preferredHeight: 130

          ColumnLayout {
            anchors.fill: parent
            visible: hyprpaperService.scanning

            NBusyIndicator {
              Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }
          }

          ColumnLayout {
            anchors.fill: parent
            visible: !hyprpaperService.scanning

            NText {
              text: "No wallpapers found"
              color: Color.mOnSurfaceVariant
              pointSize: Style.fontSizeM
              Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }
          }
        }
      }
    }
  }

  Item {
    id: panelContent

    property alias screenRepeater: screenRepeater
    property alias wallhavenView: wallhavenView
    property int currentScreenIndex: {
      if (screen !== null) {
        for (var i = 0; i < Quickshell.screens.length; i++) {
          if (Quickshell.screens[i].name == screen.name) {
            return i;
          }
        }
      }
      return 0;
    }
    property var currentScreen: Quickshell.screens[currentScreenIndex]
    property string filterText: ""

    function updateWallhavenResolution() {
      if (typeof WallhavenService === "undefined") return;

      var width = Settings.data.wallpaper.wallhavenResolutionWidth || "";
      var height = Settings.data.wallpaper.wallhavenResolutionHeight || "";
      var mode = Settings.data.wallpaper.wallhavenResolutionMode || "atleast";

      if (width && height) {
        var resolution = width + "x" + height;
        if (mode === "atleast") {
          WallhavenService.minResolution = resolution;
          WallhavenService.resolutions = "";
        } else {
          WallhavenService.minResolution = "";
          WallhavenService.resolutions = resolution;
        }
      } else {
        WallhavenService.minResolution = "";
        WallhavenService.resolutions = "";
      }

      if (Settings.data.wallpaper.useWallhaven) {
        if (wallhavenView) {
          wallhavenView.loading = true;
        }
        WallhavenService.search(Settings.data.wallpaper.wallhavenQuery || "", 1);
      }
    }

    Component.onCompleted: {
      root.contentItem = panelContent;
    }
  }

  Component {
    id: wallpaperPanelWallhavenViewComponent

    Item {
      id: wallhavenViewRoot
      property alias gridView: wallhavenGridView
      property alias pageInput: pageInput

      property var wallpapers: []
      property bool loading: false
      property string errorMessage: ""
      property bool initialized: false
      property bool searchScheduled: false

      function submitPage() {
        var page = parseInt(pageInput.text);
        if (!isNaN(page) && page > 0) {
          WallhavenService.search(Settings.data.wallpaper.wallhavenQuery || "", page);
        }
      }

      Connections {
        target: typeof WallhavenService !== "undefined" ? WallhavenService : null
        function onSearchCompleted(results, meta) {
          wallhavenViewRoot.wallpapers = results || [];
          wallhavenViewRoot.loading = false;
          wallhavenViewRoot.errorMessage = "";
          wallhavenViewRoot.searchScheduled = false;
        }
        function onSearchFailed(error) {
          wallhavenViewRoot.loading = false;
          wallhavenViewRoot.errorMessage = error || "";
          wallhavenViewRoot.searchScheduled = false;
        }
      }

      Component.onCompleted: {
        if (typeof WallhavenService !== "undefined" && Settings.data.wallpaper.useWallhaven && !initialized) {
          initialized = true;
          WallhavenService.categories = Settings.data.wallpaper.wallhavenCategories;
          WallhavenService.purity = Settings.data.wallpaper.wallhavenPurity;
          WallhavenService.sorting = Settings.data.wallpaper.wallhavenSorting;
          WallhavenService.order = Settings.data.wallpaper.wallhavenOrder;

          var width = Settings.data.wallpaper.wallhavenResolutionWidth || "";
          var height = Settings.data.wallpaper.wallhavenResolutionHeight || "";
          var mode = Settings.data.wallpaper.wallhavenResolutionMode || "atleast";
          if (width && height) {
            var resolution = width + "x" + height;
            if (mode === "atleast") {
              WallhavenService.minResolution = resolution;
              WallhavenService.resolutions = "";
            } else {
              WallhavenService.minResolution = "";
              WallhavenService.resolutions = resolution;
            }
          }

          loading = true;
          WallhavenService.search(Settings.data.wallpaper.wallhavenQuery || "", 1);
        }
      }

      ColumnLayout {
        anchors.fill: parent
        spacing: Style.marginM

        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          NGridView {
            id: wallhavenGridView

            anchors.fill: parent

            visible: !loading && errorMessage === "" && (wallpapers && wallpapers.length > 0)
            interactive: true
            keyNavigationEnabled: true
            keyNavigationWraps: false
            highlightFollowsCurrentItem: false
            currentIndex: -1

            model: wallpapers || []

            property int columns: 4
            property int itemSize: cellWidth

            cellWidth: Math.floor((availableWidth - leftMargin - rightMargin) / columns)
            cellHeight: Math.floor(itemSize * 0.7) + Style.marginXS + Style.fontSizeXS + Style.marginM

            leftMargin: Style.marginS
            rightMargin: Style.marginS
            topMargin: Style.marginS
            bottomMargin: Style.marginS

            delegate: Item {
              width: wallhavenGridView.cellWidth
              height: wallhavenGridView.cellHeight

              ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.marginXS
                spacing: Style.marginXS

                property string thumbnailUrl: (modelData && typeof WallhavenService !== "undefined") ? WallhavenService.getThumbnailUrl(modelData, "large") : ""
                property string wallpaperId: (modelData && modelData.id) ? modelData.id : ""

                Item {
                  Layout.fillWidth: true
                  Layout.fillHeight: true

                  property real imageHeight: Math.round(wallhavenGridView.itemSize * 0.67)

                  NImageRounded {
                    id: img
                    anchors.fill: parent
                    imagePath: wallhavenItem.thumbnailUrl
                    radius: Style.radiusM
                    borderColor: wallhavenGridView.currentIndex === index ? Color.mHover : Color.mSurface
                    borderWidth: Math.max(1, Style.borderL * 1.5)
                    imageFillMode: Image.PreserveAspectCrop
                  }

                  Rectangle {
                    anchors.fill: parent
                    color: Color.mSurfaceVariant
                    radius: Style.radiusM
                    visible: img.status === Image.Loading || img.status === Image.Error || wallhavenItem.thumbnailUrl === ""

                    NIcon {
                      icon: "image"
                      pointSize: Style.fontSizeL
                      color: Color.mOnSurfaceVariant
                      anchors.centerIn: parent
                    }
                  }

                  NBusyIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: (parent.height - height) / 2
                    visible: img.status === Image.Loading
                    running: visible
                    size: 18
                  }

                  HoverHandler {}

                  TapHandler {
                    onTapped: {
                      wallhavenGridView.forceActiveFocus();
                      wallhavenGridView.currentIndex = index;
                      downloadAndApply(modelData);
                    }
                  }
                }

                NText {
                  text: wallhavenItem.wallpaperId || "Unknown"
                  visible: !Settings.data.wallpaper.hideWallpaperFilenames
                  color: Color.mOnSurface
                  pointSize: Style.fontSizeXS
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignHCenter
                  horizontalAlignment: Text.AlignHCenter
                  elide: Text.ElideRight
                }
              }
            }
          }

          Rectangle {
            anchors.fill: parent
            color: Color.mSurface
            radius: Style.radiusM
            border.color: Color.mOutline
            border.width: Style.borderS
            visible: loading || (typeof WallhavenService !== "undefined" && WallhavenService.fetching)
            z: 10

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Style.marginL

              Item { Layout.fillHeight: true }

              NBusyIndicator {
                size: Style.baseWidgetSize * 1.5
                color: Color.mPrimary
                Layout.alignment: Qt.AlignHCenter
              }

              NText {
                text: "Loading..."
                color: Color.mOnSurfaceVariant
                pointSize: Style.fontSizeM
                Layout.alignment: Qt.AlignHCenter
              }

              Item { Layout.fillHeight: true }
            }
          }

          Rectangle {
            anchors.fill: parent
            color: Color.mSurface
            radius: Style.radiusM
            border.color: Color.mOutline
            border.width: Style.borderS
            visible: errorMessage !== "" && !loading
            z: 10

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Style.marginL

              Item { Layout.fillHeight: true }

              NIcon {
                icon: "alert-circle"
                pointSize: Style.fontSizeXXL
                color: Color.mError
                Layout.alignment: Qt.AlignHCenter
              }

              NText {
                text: errorMessage
                color: Color.mOnSurface
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
              }

              Item { Layout.fillHeight: true }
            }
          }

          Rectangle {
            anchors.fill: parent
            color: Color.mSurface
            radius: Style.radiusM
            border.color: Color.mOutline
            border.width: Style.borderS
            visible: (!wallpapers || wallpapers.length === 0) && !loading && errorMessage === ""
            z: 10

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Style.marginL

              Item { Layout.fillHeight: true }

              NIcon {
                icon: "image"
                pointSize: Style.fontSizeXXL
                color: Color.mOnSurfaceVariant
                Layout.alignment: Qt.AlignHCenter
              }

              NText {
                text: "No results"
                color: Color.mOnSurface
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
              }

              Item { Layout.fillHeight: true }
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          visible: errorMessage === "" && typeof WallhavenService !== "undefined"
          spacing: Style.marginS

          Item { Layout.fillWidth: true }

          NIconButton {
            icon: "chevron-left"
            enabled: !loading && WallhavenService.currentPage > 1 && !WallhavenService.fetching
            onClicked: WallhavenService.previousPage()
          }

          RowLayout {
            spacing: Style.marginXS

            NText {
              text: "Page"
              color: Color.mOnSurface
            }

            NTextInput {
              id: pageInput
              text: "" + (typeof WallhavenService !== "undefined" ? WallhavenService.currentPage : 1)
              Layout.preferredWidth: 50
              Layout.maximumWidth: 50
              Layout.fillWidth: false
              minimumInputWidth: 50
              horizontalAlignment: Text.AlignHCenter

              onEditingFinished: submitPage()
            }

            NText {
              text: "of " + (typeof WallhavenService !== "undefined" ? WallhavenService.lastPage : 1)
              color: Color.mOnSurface
            }
          }

          NIconButton {
            icon: "chevron-right"
            enabled: !loading && typeof WallhavenService !== "undefined" && WallhavenService.currentPage < WallhavenService.lastPage && !WallhavenService.fetching
            onClicked: WallhavenService.nextPage()
          }
        }
      }

      function downloadAndApply(wallpaper) {
        if (!wallpaper) return;

        loading = true;

        WallhavenService.downloadWallpaper(wallpaper, function(success, localPath) {
          if (success && localPath) {
            var screen = Settings.data.wallpaper.setWallpaperOnAllMonitors ? undefined : panelContent.currentScreen?.name;
            hyprpaperService.changeWallpaper(localPath, screen);
          }
          loading = false;
        });
      }
    }
  }
}
