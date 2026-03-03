import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import qs.Commons
import qs.Services.Theming
import qs.Services.UI
import qs.Widgets
import "./Services"

Item {
  id: root

  property var pluginApi: null

  readonly property bool allowAttach: true
  readonly property int contentPreferredWidth: 800
  readonly property int contentPreferredHeight: 600

  property var contentItem: null

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

      // Header
      Rectangle {
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

          NDivider { Layout.fillWidth: true }

          NToggle {
            label: "Apply to all monitors"
            description: "Set the same wallpaper on all screens"
            checked: Settings.data.wallpaper.setWallpaperOnAllMonitors
            onToggled: checked => Settings.data.wallpaper.setWallpaperOnAllMonitors = checked
            Layout.fillWidth: true
          }

          NTabBar {
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
                checked: panelContent.currentScreenIndex === index
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NIconButton {
              icon: "folder-open"
              tooltipText: "Change wallpaper folder"
              baseSize: Style.baseWidgetSize * 0.8
              onClicked: folderPicker.open()
            }

            NTextInput {
              id: searchInput
              placeholderText: "Search wallpapers..."
              fontSize: Style.fontSizeM
              Layout.fillWidth: true
              onTextChanged: searchDebounceTimer.restart()
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
          }
        }
      }

      // Content Area
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Color.mSurfaceVariant
        radius: Style.radiusM

        // Stack based on selected screen index
        StackLayout {
          id: screenStack
          anchors.fill: parent
          currentIndex: panelContent.currentScreenIndex

          Repeater {
            id: screenRepeater
            model: Quickshell.screens
            delegate: WallpaperScreenView {
              targetScreen: modelData
            }
          }
        }
      }
    }
  }

  // Solid Color Picker
  NColorPickerDialog {
    id: solidColorPicker
    selectedColor: Settings.data.wallpaper.solidColor
    onColorSelected: color => Hyprpaper.setSolidColor(color.toString())
  }

  // Folder Picker (Using QtQuick.Dialogs as NFilePicker might differ)
  FolderDialog {
    id: folderPicker
    title: "Select wallpaper folder"
    onAccepted: {
      var path = selectedFolder.toString().replace("file://", "");
      Settings.data.wallpaper.directory = path;
      Hyprpaper.refreshWallpapersList();
    }
  }

  Timer {
    id: searchDebounceTimer
    interval: 150
    onTriggered: {
      panelContent.filterText = searchInput.text;
      // Update all screen views
      for (var i = 0; i < screenRepeater.count; i++) {
        var item = screenRepeater.itemAt(i);
        if (item && item.updateFiltered) {
          item.updateFiltered();
        }
      }
    }
  }

  // Inline Component for Screen View
  component WallpaperScreenView: Item {
    id: screenViewRoot
    property var targetScreen
    property alias gridView: wallpaperGridView

    // State
    property list<string> wallpapersList: []
    property string currentWallpaper: ""
    property var filteredItems: []
    property var directoriesList: []

    ListModel { id: wallpaperModel }

    property string currentBrowsePath: Hyprpaper.getCurrentBrowsePath(targetScreen?.name ?? "")
    property bool isBrowseMode: Settings.data.wallpaper.viewMode === "browse"
    property int _browseScanGeneration: 0

    function sortFavoritesToTop(items) {
      var favorited = [];
      var nonFavorited = [];
      for (var i = 0; i < items.length; i++) {
        if (!items[i].isDirectory && Hyprpaper.isFavorite(items[i].path)) {
          favorited.push(items[i]);
        } else {
          nonFavorited.push(items[i]);
        }
      }
      return favorited.concat(nonFavorited);
    }

    function updateFiltered() {
      var combinedItems = [];

      if (isBrowseMode) {
        for (var i = 0; i < directoriesList.length; i++) {
          var dirPath = directoriesList[i];
          combinedItems.push({ "path": dirPath, "name": dirPath.split('/').pop(), "isDirectory": true });
        }
      }

      for (var i = 0; i < wallpapersList.length; i++) {
        combinedItems.push({ "path": wallpapersList[i], "name": wallpapersList[i].split('/').pop(), "isDirectory": false });
      }

      combinedItems = sortFavoritesToTop(combinedItems);

      if (!panelContent.filterText || panelContent.filterText.trim().length === 0) {
        filteredItems = combinedItems;
        syncModel();
        return;
      }

      var searchText = panelContent.filterText.trim().toLowerCase();
      var filtered = combinedItems.filter(item => item.name.toLowerCase().includes(searchText));
      filteredItems = sortFavoritesToTop(filtered);
      syncModel();
    }

    function syncModel() {
      wallpaperModel.clear();
      for (var i = 0; i < filteredItems.length; i++) {
        wallpaperModel.append(filteredItems[i]);
      }
      wallpaperGridView.currentIndex = -1;
      wallpaperGridView.positionViewAtBeginning();
    }

    Component.onCompleted: refreshWallpaperScreenData();

    Connections {
      target: Hyprpaper
      function onWallpaperChanged(screenName, path) {
        if (targetScreen !== null && screenName === targetScreen.name) {
          currentWallpaper = Hyprpaper.getWallpaper(targetScreen.name);
        }
      }
      function onWallpaperDirectoryChanged(screenName, directory) {
        if (targetScreen !== null && screenName === targetScreen.name) {
          if (isBrowseMode) Hyprpaper.navigateToRoot(targetScreen.name);
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
    }

    function refreshWallpaperScreenData() {
      if (targetScreen === null) return;
      currentWallpaper = Hyprpaper.getWallpaper(targetScreen.name);

      if (isBrowseMode) {
        var browsePath = Hyprpaper.getCurrentBrowsePath(targetScreen.name);
        currentBrowsePath = browsePath;
        var gen = ++_browseScanGeneration;
        Hyprpaper.scanDirectoryWithDirs(targetScreen.name, browsePath, function(result) {
          if (gen !== _browseScanGeneration) return;
          wallpapersList = result.files;
          directoriesList = result.directories;
          updateFiltered();
        });
      } else {
        wallpapersList = Hyprpaper.getWallpapersList(targetScreen.name);
        directoriesList = [];
        updateFiltered();
      }
    }

    function selectItem(path, isDir) {
      if (isDir) {
        Hyprpaper.setBrowsePath(targetScreen.name, path);
      } else {
        var screen = Settings.data.wallpaper.setWallpaperOnAllMonitors ? undefined : targetScreen.name;
        Hyprpaper.changeWallpaper(path, screen);
        Hyprpaper.applyFavoriteTheme(path, screen);
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      // Toolbar
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NIconButton {
          icon: "arrow-left"
          enabled: isBrowseMode && currentBrowsePath !== Hyprpaper.getMonitorDirectory(targetScreen?.name ?? "")
          onClicked: Hyprpaper.navigateUp(targetScreen?.name ?? "")
          baseSize: Style.baseWidgetSize * 0.8
        }

        NIconButton {
          icon: "home"
          enabled: isBrowseMode && currentBrowsePath !== Hyprpaper.getMonitorDirectory(targetScreen?.name ?? "")
          onClicked: Hyprpaper.navigateToRoot(targetScreen?.name ?? "")
          baseSize: Style.baseWidgetSize * 0.8
        }

        NScrollText {
          text: isBrowseMode ? currentBrowsePath : Hyprpaper.getMonitorDirectory(targetScreen?.name ?? "")
          Layout.fillWidth: true
          scrollMode: NScrollText.ScrollMode.Hover
          gradientColor: Color.mSurfaceVariant
          cornerRadius: Style.radiusM
          NText {
            text: isBrowseMode ? currentBrowsePath : Hyprpaper.getMonitorDirectory(targetScreen?.name ?? "")
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
          }
        }

        NIconButton {
          property string sortOrder: Settings.data.wallpaper.waSortOrder || "name"
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
            Settings.data.wallpaper.waSortOrder = next;
          }
          baseSize: Style.baseWidgetSize * 0.8
        }

        NIconButton {
          property string fitMode: Settings.data.wallpaper.fillMode || "cover"
          icon: {
            if (fitMode === "cover") return "crop-landscape";
            if (fitMode === "tile") return "layout";
            if (fitMode === "contain") return "container";
            if (fitMode === "fill") return "arrows-maximize";
            return "arrows-in";
          }
          tooltipText: "Fit mode: " + fitMode
          onClicked: {
            var next = "cover";
            if (fitMode === "cover") next = "tile";
            else if (fitMode === "tile") next = "fill";
            else if (fitMode === "fill") next = "contain";
            else if (fitMode === "contain") next = "cover";
            else next = "cover";
            Settings.data.wallpaper.fillMode = next;
          }
          baseSize: Style.baseWidgetSize * 0.8
        }

        NIconButton {
          icon: "refresh"
          onClicked: isBrowseMode ? refreshWallpaperScreenData() : Hyprpaper.refreshWallpapersList()
          baseSize: Style.baseWidgetSize * 0.8
        }
      }

      // Grid View
      NGridView {
        id: wallpaperGridView
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !Hyprpaper.scanning
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
          id: delegateItem
          width: wallpaperGridView.cellWidth
          height: wallpaperGridView.cellHeight

          // PROPERTIES MOVED HERE (Fixes ReferenceError)
          property string itemPath: model.path || ""
          property bool itemIsDir: model.isDirectory || false
          property bool itemIsSelected: !itemIsDir && (itemPath === currentWallpaper)
          property bool itemIsFavorited: !itemIsDir && Hyprpaper.isFavorite(itemPath)
          property string itemName: model.name || itemPath.split('/').pop()

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginXS
            spacing: Style.marginXS

            Item {
              Layout.fillWidth: true
              Layout.fillHeight: true
              property real imageHeight: Math.round(wallpaperGridView.itemSize * 0.67)

              Rectangle {
                anchors.fill: parent
                color: Color.mSurfaceVariant
                radius: Style.radiusM
                visible: itemIsDir
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
                visible: !itemIsDir
                imagePath: itemPath.startsWith("file://") ? itemPath : "file://" + itemPath
                radius: Style.radiusM
                borderColor: itemIsSelected ? Color.mSecondary : (wallpaperGridView.currentIndex === index ? Color.mHover : Color.mSurface)
                borderWidth: Math.max(1, Style.borderL * 1.5)
                imageFillMode: Image.PreserveAspectCrop
              }

              Rectangle {
                anchors.fill: parent
                color: Color.mSurfaceVariant
                radius: Style.radiusM
                visible: !itemIsDir && (img.status === Image.Loading || img.status === Image.Error)
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
                visible: !itemIsDir && img.status === Image.Loading
                running: visible
                size: 18
              }

              Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: Style.marginS
                width: 28
                height: 28
                radius: 14
                color: Color.mSecondary
                visible: itemIsSelected
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
                radius: 14
                visible: !itemIsDir && (itemIsFavorited || starHover.hovered || wallpaperGridView.currentIndex === index)
                color: itemIsFavorited ? (starHover.hovered ? Color.mHover : Color.mPrimary) : (starHover.hovered ? Color.mSurfaceVariant : Color.mSurface)
                opacity: itemIsFavorited || starHover.hovered ? 1.0 : 0.7
                NIcon {
                  icon: itemIsFavorited ? "star-filled" : "star"
                  pointSize: Style.fontSizeM
                  color: itemIsFavorited ? (starHover.hovered ? Color.mOnHover : Color.mOnPrimary) : (starHover.hovered ? Color.mOnSurface : Color.mOnSurfaceVariant)
                  anchors.centerIn: parent
                }
                HoverHandler { id: starHover }
                TapHandler { onTapped: Hyprpaper.toggleFavorite(itemPath) }
              }

              HoverHandler {}
              TapHandler { 
                onTapped: { 
                  wallpaperGridView.forceActiveFocus(); 
                  wallpaperGridView.currentIndex = index; 
                  selectItem(itemPath, itemIsDir); 
                } 
              }
            }

            NText {
              text: itemName
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

      // Empty / Loading State
      Rectangle {
        color: Color.mSurface
        radius: Style.radiusM
        border.color: Color.mOutline
        border.width: Style.borderS
        visible: (wallpaperModel.count === 0 && !Hyprpaper.scanning) || Hyprpaper.scanning
        Layout.fillWidth: true
        Layout.preferredHeight: 130
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        ColumnLayout {
          anchors.centerIn: parent
          visible: Hyprpaper.scanning
          NBusyIndicator { Layout.alignment: Qt.AlignHCenter }
        }

        ColumnLayout {
          anchors.centerIn: parent
          visible: !Hyprpaper.scanning
          NText {
            text: "No wallpapers found"
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeM
            Layout.alignment: Qt.AlignHCenter
          }
        }
      }
    }
  }

  Item {
    id: panelContent
    property alias screenRepeater: screenRepeater
    property int currentScreenIndex: {
      if (screen !== null) {
        for (var i = 0; i < Quickshell.screens.length; i++) {
          if (Quickshell.screens[i].name == screen.name) return i;
        }
      }
      return 0;
    }
    property var currentScreen: Quickshell.screens[currentScreenIndex]
    property string filterText: ""
    Component.onCompleted: root.contentItem = panelContent
  }
}