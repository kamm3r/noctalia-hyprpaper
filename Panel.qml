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

            // ── Header ──────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NIcon {
                    icon: "wallpaper"
                    pointSize: Style.fontSizeXXL
                    color: Color.mPrimary
                }

                NText {
                    text: pluginApi?.tr("panel.title")
                    Layout.fillWidth: true
                    pointSize: Style.fontSizeL
                    font.weight: Font.Bold
                }

                // ── Random wallpaper button ──
                NIconButton {
                    icon: "shuffle"
                    tooltipText: pluginApi?.tr("panel.randomTooltip")
                    onClicked: {
                        const screen =
                            Settings.data.wallpaper
                                .setWallpaperOnAllMonitors
                                ? undefined
                                : Quickshell.screens[
                                      root.currentScreenIndex
                                  ].name;
                        Hyprpaper.setRandomWallpaper(screen);
                    }
                }

                NIconButton {
                    icon: "close"
                    tooltipText: pluginApi?.tr("common.close")
                    onClicked: {
                        pluginApi.closePanel(
                            pluginApi.panelOpenScreen
                        );
                    }
                }
            }

            NDivider { Layout.fillWidth: true }

            // ── Monitor toggle ──────────────────────────
            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("panel.applyAllMonitors")
                checked:
                    Settings.data.wallpaper
                        .setWallpaperOnAllMonitors
                onToggled: checked => {
                    Settings.data.wallpaper
                        .setWallpaperOnAllMonitors = checked;
                }
            }

            // ── Screen tabs (only when per-monitor) ────
            NTabBar {
                Layout.fillWidth: true
                visible:
                    !Settings.data.wallpaper
                        .setWallpaperOnAllMonitors
                currentIndex: root.currentScreenIndex
                onCurrentIndexChanged: {
                    root.currentScreenIndex = currentIndex;
                }

                Repeater {
                    model: Quickshell.screens

                    NTabButton {
                        required property int index
                        required property var modelData
                        text:
                            modelData.name ||
                            "Screen " + (index + 1)
                        checked:
                            index === root.currentScreenIndex
                    }
                }
            }

            // ── Toolbar: folder + search + fill mode ───
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NIconButton {
                    icon: "folder"
                    tooltipText: pluginApi?.tr("panel.changeFolderTooltip")
                    onClicked: folderPicker.open()
                }

                NTextInput {
                    Layout.fillWidth: true
                    placeholderText: pluginApi?.tr("panel.searchPlaceholder")
                    onTextChanged: root.filterText = text
                }
            }

            // ── Fill mode row ───────────────────────────
            RowLayout {
                id: fitModeRow
                Layout.fillWidth: true
                spacing: Style.marginXS

                property string fitMode:
                    Settings.data.wallpaper.fillMode ||
                    "cover"

                readonly property var fitModeOptions: [
                    { key: "cover", label: pluginApi?.tr("panel.fillModeCover") },
                    { key: "contain", label: pluginApi?.tr("panel.fillModeContain") },
                    { key: "tile", label: pluginApi?.tr("panel.fillModeTile") },
                    { key: "fill", label: pluginApi?.tr("panel.fillModeFill") }
                ]

                NText {
                    text: pluginApi?.tr("panel.fillMode")
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeS
                    Layout.rightMargin: Style.marginXS
                }

                Repeater {
                    model: fitModeRow.fitModeOptions

                    Rectangle {
                        required property var modelData

                        radius: Style.radiusL
                        color: fitModeRow.fitMode ===
                            modelData.key
                            ? Color.mPrimary
                            : "transparent"
                        border.width: 1
                        border.color: fitModeRow.fitMode ===
                            modelData.key
                            ? Color.mPrimary
                            : Color.mOutline

                        implicitHeight: 32
                        implicitWidth:
                            fmLabel.implicitWidth +
                            Style.marginL * 2

                        scale: fmTap.pressed ? 0.95 : 1

                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: 150 }
                        }

                        TapHandler {
                            id: fmTap
                            onTapped: {
                                Settings.data.wallpaper
                                    .fillMode =
                                    modelData.key;
                            }
                        }

                        NText {
                            id: fmLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            pointSize: Style.fontSizeS
                            color: fitModeRow.fitMode ===
                                modelData.key
                                ? Color.mOnPrimary
                                : Color.mOnSurface
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // ── Slideshow settings ──────────────────
            RowLayout {
                id: slideshowRow
                Layout.fillWidth: true
                spacing: Style.marginS

                NIcon {
                    icon: "timer"
                    pointSize: Style.fontSizeM
                    color: Color.mOnSurfaceVariant
                }

                NText {
                    text: pluginApi?.tr("panel.cycleEvery")
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeS
                }

                Rectangle {
                    implicitWidth: timeoutInput.implicitWidth + Style.marginL * 2
                    implicitHeight: 34
                    radius: Style.radiusM
                    color: Color.mSurfaceVariant
                    border.width: 1
                    border.color: timeoutInput.activeFocus
                        ? Color.mPrimary
                        : Color.mOutline

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    TextInput {
                        id: timeoutInput
                        anchors.centerIn: parent
                        width: 48

                        horizontalAlignment: TextInput.AlignHCenter
                        color: Color.mOnSurface
                        selectionColor: Color.mPrimary
                        selectedTextColor: Color.mOnPrimary

                        font.pointSize: Style.fontSizeS
                        font.weight: Font.Medium

                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator {
                            bottom: 1
                            top: 86400
                        }

                        text: Settings.data.wallpaper.timeout
                            ?? "30"

                        onEditingFinished: {
                            let val = parseInt(text);
                            if (isNaN(val) || val < 1)
                                val = 30;
                            if (val > 86400) val = 86400;
                            text = val.toString();
                            Settings.data.wallpaper.timeout =
                                val;
                        }
                    }
                }

                NText {
                    text: pluginApi?.tr("panel.seconds")
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeS
                }

                // ── Quick presets ────────────────────
                Repeater {
                    model: [
                        { label: pluginApi?.tr("panel.preset30s"), value: 30 },
                        { label: pluginApi?.tr("panel.preset5m"), value: 300 },
                        { label: pluginApi?.tr("panel.preset30m"), value: 1800 },
                        { label: pluginApi?.tr("panel.preset1h"), value: 3600 }
                    ]

                    Rectangle {
                        required property var modelData

                        readonly property bool isActive:
                            (Settings.data.wallpaper
                                .timeout ?? 30) ===
                            modelData.value

                        implicitWidth:
                            presetLabel.implicitWidth +
                            Style.marginM * 2
                        implicitHeight: 28
                        radius: Style.radiusL

                        color: isActive
                            ? Color.mSecondaryContainer
                            : "transparent"
                        border.width: isActive ? 0 : 1
                        border.color: Color.mOutline

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        scale: presetTap.pressed ? 0.95 : 1
                        Behavior on scale {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutCubic
                            }
                        }

                        TapHandler {
                            id: presetTap
                            onTapped: {
                                Settings.data.wallpaper
                                    .timeout =
                                    modelData.value;
                                timeoutInput.text =
                                    modelData.value.toString();
                            }
                        }

                        NText {
                            id: presetLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            pointSize: Style.fontSizeXS
                            color: parent.isActive
                                ? Color.mOnSecondaryContainer
                                : Color.mOnSurfaceVariant
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // ── Order toggle ─────────────────────
                Rectangle {
                    implicitWidth:
                        orderRow.implicitWidth +
                        Style.marginM * 2
                    implicitHeight: 34
                    radius: Style.radiusL
                    color: "transparent"
                    border.width: 1
                    border.color: Color.mOutline

                    property string order:
                        Settings.data.wallpaper.order ||
                        "sequential"

                    RowLayout {
                        id: orderRow
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: [
                                {
                                    key: "sequential",
                                    label: pluginApi?.tr("panel.orderSequential"),
                                    icon: "arrow-right"
                                },
                                {
                                    key: "random",
                                    label: pluginApi?.tr("panel.orderRandom"),
                                    icon: "shuffle"
                                }
                            ]

                            Rectangle {
                                required property var modelData

                                readonly property bool isActive:
                                    (Settings.data.wallpaper
                                        .order ||
                                        "sequential") ===
                                    modelData.key

                                implicitWidth:
                                    orderItemRow
                                        .implicitWidth +
                                    Style.marginM * 2
                                implicitHeight: 28
                                radius: Style.radiusM

                                color: isActive
                                    ? Color.mPrimary
                                    : "transparent"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                scale: orderTap.pressed
                                    ? 0.95
                                    : 1
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 100
                                        easing.type:
                                            Easing.OutCubic
                                    }
                                }

                                TapHandler {
                                    id: orderTap
                                    onTapped: {
                                        Settings.data
                                            .wallpaper
                                            .order =
                                            modelData.key;
                                    }
                                }

                                RowLayout {
                                    id: orderItemRow
                                    anchors.centerIn: parent
                                    spacing: Style.marginXS

                                    NIcon {
                                        icon: modelData.icon
                                        pointSize:
                                            Style.fontSizeXS
                                        color: parent.parent
                                            .isActive
                                            ? Color.mOnPrimary
                                            : Color
                                                  .mOnSurfaceVariant
                                    }

                                    NText {
                                        text: modelData.label
                                        pointSize:
                                            Style.fontSizeXS
                                        color: parent.parent
                                            .isActive
                                            ? Color.mOnPrimary
                                            : Color
                                                  .mOnSurfaceVariant
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Wallpaper grid ──────────────────────────
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
        title: pluginApi?.tr("panel.changeFolderTooltip")

        onAccepted: {
            var p = selectedFolder
                .toString()
                .replace("file://", "");
            Settings.data.wallpaper.directory = p;
            Hyprpaper.refreshWallpapersList();
        }
    }

    // ════════════════════════════════════════════════
    //  WallpaperScreen component
    // ════════════════════════════════════════════════
    component WallpaperScreen: Item {

        property var targetScreen
        property string filterText: ""
        property string currentWallpaper: ""
        property var allItems: []

        ListModel { id: wallpaperModel }

        Component.onCompleted: refresh()

        function refresh() {
            if (!targetScreen) return;

            currentWallpaper =
                Hyprpaper.getWallpaper(targetScreen.name);

            const files =
                Hyprpaper.getWallpapersList(
                    targetScreen.name
                );
            const list = [];

            for (let i = 0; i < files.length; i++) {
                const path = files[i];
                const name = path.substring(
                    path.lastIndexOf("/") + 1
                );
                list.push({
                    path: path,
                    name: name,
                    search: name.toLowerCase()
                });
            }

            allItems = list;
            applyFilter();
        }

        function applyFilter() {
            const text =
                (filterText || "").toLowerCase().trim();

            wallpaperModel.clear();

            for (let i = 0; i < allItems.length; i++) {
                const item = allItems[i];
                if (text && !item.search.includes(text))
                    continue;
                wallpaperModel.append(item);
            }
        }

        onFilterTextChanged: applyFilter()

        Connections {
            target: Hyprpaper

            function onWallpaperListChanged(screenName) {
                if (screenName === targetScreen.name)
                    refresh();
            }

            function onWallpaperChanged(screenName, path) {
                if (
                    targetScreen &&
                    screenName === targetScreen.name
                ) {
                    currentWallpaper = path;
                }
            }
        }

        // ── Empty state ─────────────────────────────
        ColumnLayout {
            anchors.centerIn: parent
            visible: wallpaperModel.count === 0
            spacing: Style.marginM
            opacity: 0.5

            NIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: "image-off"
                pointSize: Style.fontSizeXXL * 2
                color: Color.mOnSurfaceVariant
            }

            NText {
                Layout.alignment: Qt.AlignHCenter
                text: filterText
                    ? pluginApi?.tr("panel.emptyState.noResults")
                    : pluginApi?.tr("panel.emptyState.noWallpapers")
                color: Color.mOnSurfaceVariant
                pointSize: Style.fontSizeM
            }

            NText {
                Layout.alignment: Qt.AlignHCenter
                text: filterText
                    ? pluginApi?.tr("panel.emptyState.tryDifferentSearch")
                    : pluginApi?.tr("panel.emptyState.pickDirectory")
                color: Color.mOnSurfaceVariant
                pointSize: Style.fontSizeS
            }
        }

        // ── Grid ────────────────────────────────────
        NGridView {
            id: grid
            anchors.fill: parent
            anchors.margins: Style.marginS
            handleRadius: Style.radiusMss
            model: wallpaperModel

            // Responsive columns: aim for ~180-200px
            readonly property int columns: Math.max(
                2,
                Math.floor(width / (180 * Style.uiScaleRatio))
            )
            cellWidth: Math.floor(width / columns)
            cellHeight: cellWidth * 0.65

            delegate: Item {
                id: wallpaperDelegate

                width: grid.cellWidth
                height: grid.cellHeight

                required property int index
                required property string path
                required property string name

                property bool isSelected:
                    path === currentWallpaper

                HoverHandler { id: hover }
                TapHandler {
                    id: tap
                    onTapped: {
                        const screen =
                            Settings.data.wallpaper
                                .setWallpaperOnAllMonitors
                                ? undefined
                                : targetScreen.name;
                        Hyprpaper.changeWallpaper(
                            wallpaperDelegate.path,
                            screen
                        );
                    }
                }

                scale: tap.pressed ? 0.96 : 1
                Behavior on scale {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutCubic
                    }
                }

                // Padding wrapper so items have gaps
                Item {
                    anchors.fill: parent
                    anchors.margins: Style.marginXS

                    // ── Card background ─────────
                    Rectangle {
                        id: card
                        anchors.fill: parent
                        radius: Style.radiusM
                        color: Color.mSurface
                        border.width:
                            wallpaperDelegate.isSelected
                                ? 3
                                : 0
                        border.color: Color.mPrimary

                        Behavior on border.width {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    // ── Thumbnail ────────────────
                    NImageRounded {
                        anchors.fill: parent
                        radius: Style.radiusM
                        imageFillMode:
                            Image.PreserveAspectCrop

                        Component.onCompleted: {
                            Thumbnail.request(
                                wallpaperDelegate.path
                            );
                        }

                        imagePath:
                            Thumbnail.cache &&
                            Thumbnail.cache[
                                wallpaperDelegate.path
                            ]
                                ? "file://" +
                                  Thumbnail.cache[
                                      wallpaperDelegate.path
                                  ]
                                : ""

                        opacity:
                            wallpaperDelegate.isSelected ||
                            hover.hovered
                                ? 1
                                : 0.75

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    // ── Bottom gradient for text ─
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: parent.height * 0.4
                        radius: Style.radiusM

                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: "transparent"
                            }
                            GradientStop {
                                position: 1.0
                                color: "#AA000000"
                            }
                        }
                    }

                    // ── Hover overlay ────────────
                    Rectangle {
                        anchors.fill: parent
                        radius: Style.radiusM
                        color: "#18FFFFFF"
                        visible: hover.hovered
                    }

                    // ── Selection badge ──────────
                    Rectangle {
                        id: badge
                        width: 26
                        height: 26
                        radius: width / 2
                        z: 10

                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: Style.marginS

                        visible:
                            wallpaperDelegate.isSelected ||
                            hover.hovered

                        color:
                            wallpaperDelegate.isSelected
                                ? Color.mPrimary
                                : Color.mSurface
                        border.width:
                            wallpaperDelegate.isSelected
                                ? 0
                                : 1
                        border.color: Color.mOutline

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        NIcon {
                            anchors.centerIn: parent
                            icon:
                                wallpaperDelegate.isSelected
                                    ? "check"
                                    : "plus"
                            pointSize: Style.fontSizeXS
                            color:
                                wallpaperDelegate.isSelected
                                    ? Color.mOnPrimary
                                    : Color.mOnSurface
                        }
                    }

                    // ── Filename label ───────────
                    NText {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: Style.marginS

                        text: wallpaperDelegate.name
                        color: "white"
                        elide: Text.ElideRight
                        font.pointSize: Style.fontSizeXS
                    }
                }
            }
        }
    }
}
