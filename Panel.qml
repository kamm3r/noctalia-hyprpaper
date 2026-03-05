import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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

readonly property var geometryPlaceholder: panelContainer
readonly property bool allowAttach: true

property real contentPreferredWidth: 800 * Style.uiScaleRatio
property real contentPreferredHeight: 600 * Style.uiScaleRatio

anchors.fill: parent

property int currentScreenIndex: 0
property string filterText: ""

Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: Color.mSurface
    radius: Style.radiusL

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginM

        RowLayout {
            Layout.fillWidth: true

            NIcon {
                icon: "wallpaper"
                pointSize: Style.fontSizeXXL
                color: Color.mPrimary
            }

            NText {
                text: "Wallpaper"
                Layout.fillWidth: true
                pointSize: Style.fontSizeL
                font.weight: Font.Bold
            }

            NIconButton {
                icon: "close"
                onClicked: pluginApi.closePanel(pluginApi.panelOpenScreen)
            }
        }

        NDivider { Layout.fillWidth: true }

        NToggle {
          Layout.fillWidth: true
          label: "Apply to all monitors"
          checked: Settings.data.wallpaper.setWallpaperOnAllMonitors
          onToggled: checked =>Settings.data.wallpaper.setWallpaperOnAllMonitors = checked
        }

        NTabBar {
            Layout.fillWidth: true
            visible: !Settings.data.wallpaper.setWallpaperOnAllMonitors
            currentIndex: root.currentScreenIndex
            onCurrentIndexChanged: root.currentScreenIndex = currentIndex

            Repeater {
                model: Quickshell.screens

                NTabButton {
                    required property int index
                    required property var modelData
                    text: modelData.name || ("Screen " + (index + 1))
                    checked: index === root.currentScreenIndex
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NIconButton {
                icon: "folder"
                tooltipText: "Change folder"
                onClicked: folderPicker.open()
            }

            NTextInput {
                Layout.fillWidth: true
                placeholderText: "Search wallpapers"
                onTextChanged: root.filterText = text
            }
        }

 RowLayout {
    id: fitModeRow
    Layout.fillWidth: true
    spacing: Style.marginS

    property string fitMode:
        Settings.data.wallpaper.fillMode || "cover"

    readonly property var fitModeOptions: [
        { key: "cover", label: "Cover" },
        { key: "contain", label: "Contain" },
        { key: "tile", label: "Tile" },
        { key: "fill", label: "Fill" }
    ]

    NText {
        text: "Fill mode"
        color: Color.mOnSurfaceVariant
        pointSize: Style.fontSizeS
    }

    Repeater {
        model: fitModeRow.fitModeOptions

        Rectangle {
            required property var modelData

            radius: Style.radiusL
            color: fitModeRow.fitMode === modelData.key
                ? Color.mPrimary
                : Color.mSurface
            border.width: 1
            border.color: fitModeRow.fitMode === modelData.key
                ? Color.mPrimary
                : Color.mOutline

            implicitHeight: 34
            implicitWidth: label.implicitWidth + Style.marginL * 2
            TapHandler {
        id: tap
                onTapped: {
                    Settings.data.wallpaper.fillMode =
                        modelData.key;

                    // Keep this if the backend now reads fillMode.
                    Settings.data.wallpaper.fillMode =
                        modelData.key === "stretch"
                        ? "fill"
                        : modelData.key;
                }
            }
scale: tap.pressed ? 0.97 : 1


Behavior on scale {
    NumberAnimation {
        duration: 120
        easing.type: Easing.OutCubic
    }
}
            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: 120
                }
            }

            NText {
                id: label
                anchors.centerIn: parent
                text: modelData.label
                pointSize: Style.fontSizeS
                color: fitModeRow.fitMode === modelData.key
                    ? Color.mOnPrimary
                    : Color.mOnSurface
            }


        }
    }

    Item {
        Layout.fillWidth: true
    }
}

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Color.mSurfaceVariant
            radius: Style.radiusM

            StackLayout {
                anchors.fill: parent
                currentIndex: root.currentScreenIndex

                Repeater {
                    model: Quickshell.screens

                    WallpaperScreen {
                        targetScreen: modelData
                        filterText: root.filterText
                    }
                }
            }
        }
    }
}

FolderDialog {
    id: folderPicker
    title: "Select wallpaper folder"

    onAccepted: {
        var p = selectedFolder.toString().replace("file://", "")
        Settings.data.wallpaper.directory = p
        Hyprpaper.refreshWallpapersList()
    }
}

component WallpaperScreen: Item {

    property var targetScreen
    property string filterText: ""

    property string currentWallpaper: ""
    property var allItems: []

    ListModel { id: model }

    Component.onCompleted: refresh()

    function refresh() {

        if (!targetScreen)
            return

        currentWallpaper =
            Hyprpaper.getWallpaper(targetScreen.name)

        const files =
            Hyprpaper.getWallpapersList(targetScreen.name)

        const list = []

        for (let i = 0; i < files.length; i++) {

            const path = files[i]
            const name =
                path.substring(path.lastIndexOf("/") + 1)

            list.push({
                path: path,
                name: name,
                search: name.toLowerCase()
            })
        }

        allItems = list
        applyFilter()
    }

    function applyFilter() {

        const text =
            (filterText || "").toLowerCase().trim()

        model.clear()

        for (let i = 0; i < allItems.length; i++) {

            const item = allItems[i]

            if (text && !item.search.includes(text))
                continue

            model.append(item)
        }
    }

    onFilterTextChanged: applyFilter()

    Connections {
        target: Hyprpaper

        function onWallpaperListChanged(screenName) {
            if (screenName === targetScreen.name)
                refresh()
        }
    }
    Connections {
    target: Hyprpaper

    function onWallpaperChanged(screenName, path) {
        if (targetScreen && screenName === targetScreen.name) {
            currentWallpaper = path
        }
    }
}

    NGridView {

        id: grid

        anchors.fill: parent
        anchors.margins: Style.marginS
        handleRadius: Style.radiusMss
        // clip: true
        // boundsBehavior: Flickable.StopAtBounds
        model: model

        cellWidth: Math.floor((width - Style.marginS * 2) / 4)
        cellHeight: cellWidth * 0.7

        delegate: Item {

            width: grid.cellWidth
            height: grid.cellHeight

             property string itemPath: model.path ?? ""
    property string itemName: model.name ?? ""
    property bool itemIsDir: model.isDirectory ?? false
    property bool itemIsSelected: itemPath === currentWallpaper

            HoverHandler { id: hover }
            opacity: itemIsSelected || hover.hovered ? 1 : 0.7

Behavior on opacity {
    NumberAnimation { duration: 120 }
}
  TapHandler {
        id: tap
        onTapped: {
            const screen =
                Settings.data.wallpaper.setWallpaperOnAllMonitors
                ? undefined
                : targetScreen.name;

            Hyprpaper.changeWallpaper(itemPath, screen);
        }
    }

scale: tap.pressed ? 0.97 : 1

Behavior on scale {
    NumberAnimation {
        duration: 120
        easing.type: Easing.OutCubic
    }
}

Rectangle {
    id: selectIndicator

    width: 28
    height: 28
    radius: width / 2

    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: Style.marginS

    visible: itemIsSelected || hover.hovered

    color: Color.mSurface
    border.width: 1
    border.color: Color.mOutline

    opacity: itemIsSelected ? 1 : (hover.hovered ? 1 : 0)

    Behavior on opacity {
        NumberAnimation { duration: 120 }
    }
    z: 10

    NIcon {
        anchors.centerIn: parent
        icon: itemIsSelected ? "check" : "plus"
        pointSize: Style.fontSizeS
        color: Color.mOnSurface
    }
}

            Rectangle {
                anchors.fill: parent
                radius: Style.radiusM
                color: Color.mSurface

                border.width: itemIsSelected ? 3 : 0
                border.color: Color.mPrimary
            }

            NImageRounded {

                anchors.fill: parent
                radius: Style.radiusM

                imageFillMode:
                    Image.PreserveAspectCrop

                Component.onCompleted:
                    Thumbnail.request(path)

                imagePath:
                    Thumbnail.cache &&
                    Thumbnail.cache[path]
                    ? "file://" + Thumbnail.cache[path]
                    : ""
            }

            Rectangle {
                anchors.fill: parent
                color: "#22000000"
                visible: hover.hovered
                radius: Style.radiusM
            }

            NText {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Style.marginM

                text: name
                color: "white"
                elide: Text.ElideRight
                font.pointSize: Style.fontSizeS
            }

            TapHandler {
                onTapped: {

                    const screen =
                        Settings.data.wallpaper
                        .setWallpaperOnAllMonitors
                        ? undefined
                        : targetScreen.name

                    Hyprpaper.changeWallpaper(itemPath, screen)
                }
            }
        }
    }
}
}