pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Theming
import qs.Services.UI

Singleton {
  id: root

  readonly property ListModel fillModeModel: ListModel {}
  property string defaultDirectory: ""
  readonly property string solidColorPrefix: "solid://"

  readonly property ListModel transitionsModel: ListModel {}

  property var wallpaperLists: ({})
  property int scanningCount: 0

  property var currentWallpapers: ({})
  property var alphabeticalIndices: ({})
  property var usedRandomWallpapers: ({})

  property bool isInitialized: false
  property string wallpaperCacheFile: ""

  readonly property bool scanning: (scanningCount > 0)
  property string defaultWallpaper: ""

  signal wallpaperChanged(string screenName, string path)
  signal wallpaperDirectoryChanged(string screenName, string directory)
  signal wallpaperListChanged(string screenName, int count)
  signal browsePathChanged(string screenName, string path)
  signal favoritesChanged(string path)
  signal favoriteDataUpdated(string path)

  property var currentBrowsePaths: ({})

  property var wallpaperSettings: null

  Component.onCompleted: {
    function connectSettings() {
      if (typeof Settings !== 'undefined' && Settings.data?.wallpaper) {
        wallpaperSettings = Settings.data.wallpaper;
      } else {
        Qt.callLater(connectSettings);
      }
    }
    Qt.callLater(connectSettings);
  }

  Connections {
    target: wallpaperSettings
    ignoreUnknownSignals: true
    function onDirectoryChanged() {
      root.usedRandomWallpapers = {};
      root.refreshWallpapersList();
      if (!Settings.data.wallpaper.enableMultiMonitorDirectories) {
        for (var i = 0; i < Quickshell.screens.length; i++) {
          root.wallpaperDirectoryChanged(Quickshell.screens[i].name, root.defaultDirectory);
        }
      } else {
        for (var i = 0; i < Quickshell.screens.length; i++) {
          var screenName = Quickshell.screens[i].name;
          var monitor = root.getMonitorConfig(screenName);
          if (!monitor || !monitor.directory) {
            root.wallpaperDirectoryChanged(screenName, root.defaultDirectory);
          }
        }
      }
    }
    
    function onEnableMultiMonitorDirectoriesChanged() {
      root.usedRandomWallpapers = {};
      root.refreshWallpapersList();
      for (var i = 0; i < Quickshell.screens.length; i++) {
        var screenName = Quickshell.screens[i].name;
        root.wallpaperDirectoryChanged(screenName, root.getMonitorDirectory(screenName));
      }
    }
    function onViewModeChanged() {
      root.currentBrowsePaths = {};
      root.refreshWallpapersList();
    }
    function onShowHiddenFilesChanged() {
      root.refreshWallpapersList();
    }
    function onUseSolidColorChanged() {
      if (Settings.data.wallpaper.useSolidColor) {
        var solidPath = root.createSolidColorPath(Settings.data.wallpaper.solidColor.toString());
        for (var i = 0; i < Quickshell.screens.length; i++) {
          root.wallpaperChanged(Quickshell.screens[i].name, solidPath);
        }
      } else {
        for (var i = 0; i < Quickshell.screens.length; i++) {
          var screenName = Quickshell.screens[i].name;
          root.wallpaperChanged(screenName, currentWallpapers[screenName] || root.defaultWallpaper);
        }
      }
    }
    function onSolidColorChanged() {
      if (Settings.data.wallpaper.useSolidColor) {
        var solidPath = root.createSolidColorPath(Settings.data.wallpaper.solidColor.toString());
        for (var i = 0; i < Quickshell.screens.length; i++) {
          root.wallpaperChanged(Quickshell.screens[i].name, solidPath);
        }
      }
    }
    function onWaSortOrderChanged() {
      root.refreshWallpapersList();
    }
  }

  function init() {
    Logger.i("Hyprpaper", "Service starting...")
    root.defaultWallpaper = ""
    
    function loadSettings() {
      if (typeof Settings !== 'undefined' && Settings.data && Settings.data.wallpaper) {
        if (Settings.data.wallpaper.directory) {
          root.defaultDirectory = Settings.preprocessPath(Settings.data.wallpaper.directory);
          Logger.i("Hyprpaper", "Loaded directory:", root.defaultDirectory);
        } else {
          root.defaultDirectory = "";
          Logger.w("Hyprpaper", "No directory set in settings");
        }
        
        Qt.callLater(() => {
          if (typeof Settings !== 'undefined' && Settings.cacheDir) {
            wallpaperCacheFile = Settings.cacheDir + "hyprpaper.json";
            wallpaperCacheView.path = wallpaperCacheFile;
          }
        });
        
        Qt.callLater(refreshWallpapersList);
      } else {
        Logger.w("Hyprpaper", "Settings not available, retrying in 500ms...");
        Qt.callLater(() => { Qt.callLater(loadSettings); });
      }
    }
    Qt.callLater(loadSettings);
    Qt.callLater(() => {
        if (root.isInitialized) {
            updateHyprpaperConf();
        }
    });
  }

  function isSolidColorPath(path) {
    return path && typeof path === "string" && path.startsWith(solidColorPrefix);
  }

  function getSolidColor(path) {
    if (!isSolidColorPath(path)) {
      return null;
    }
    return path.substring(solidColorPrefix.length);
  }

  function createSolidColorPath(colorString) {
    return solidColorPrefix + colorString;
  }

  function setSolidColor(colorString) {
    Settings.data.wallpaper.solidColor = colorString;
    Settings.data.wallpaper.useSolidColor = true;
  }

  function getMonitorConfig(screenName) {
    var monitors = Settings.data.wallpaper.monitorDirectories;
    if (monitors !== undefined) {
      for (var i = 0; i < monitors.length; i++) {
        if (monitors[i].name !== undefined && monitors[i].name === screenName) {
          return monitors[i];
        }
      }
    }
  }

  function getMonitorDirectory(screenName) {
    if (!Settings.data.wallpaper.enableMultiMonitorDirectories) {
      if (root.defaultDirectory) {
        return root.defaultDirectory;
      }
      if (typeof Settings !== 'undefined' && Settings.data?.wallpaper?.directory) {
        return Settings.preprocessPath(Settings.data.wallpaper.directory);
      }
      return "";
    }

    var monitor = getMonitorConfig(screenName);
    if (monitor !== undefined && monitor.directory !== undefined) {
      return Settings.preprocessPath(monitor.directory);
    }

    if (root.defaultDirectory) {
      return root.defaultDirectory;
    }
    if (typeof Settings !== 'undefined' && Settings.data?.wallpaper?.directory) {
      return Settings.preprocessPath(Settings.data.wallpaper.directory);
    }
    return "";
  }

  function setMonitorDirectory(screenName, directory) {
    var monitors = Settings.data.wallpaper.monitorDirectories || [];
    var found = false;

    var newMonitors = monitors.map(function (monitor) {
      if (monitor.name === screenName) {
        found = true;
        return {
          "name": screenName,
          "directory": directory,
          "wallpaper": monitor.wallpaper || ""
        };
      }
      return monitor;
    });

    if (!found) {
      newMonitors.push({
                         "name": screenName,
                         "directory": directory,
                         "wallpaper": ""
                       });
    }

    Settings.data.wallpaper.monitorDirectories = newMonitors.slice();
    root.wallpaperDirectoryChanged(screenName, Settings.preprocessPath(directory));
  }

  function getWallpaper(screenName) {
    if (Settings.data.wallpaper.useSolidColor) {
      return createSolidColorPath(Settings.data.wallpaper.solidColor.toString());
    }
    if (currentWallpapers[screenName]) {
      return currentWallpapers[screenName];
    }
    return root.defaultWallpaper;
  }

  function setWallpaperOnHyprland(path, screenName) {
    if (!path) return;

    const monitor = screenName || "HDMI-A-1";
    const fitMode = Settings.data.wallpaper.fillMode || "cover";
    const command = "hyprctl hyprpaper wallpaper '" + monitor + ", " + path + ", " + fitMode + "'";

    Logger.d("Hyprpaper", "Setting wallpaper:", monitor, path, "fit:", fitMode);

    const hyprlandProcess = Qt.createQmlObject(`
      import QtQuick
      import Quickshell.Io
      Process {
        command: ["bash", "-c", "${command}"]
      }
    `, root, "HyprlandSetWallpaper");

    hyprlandProcess.exited.connect(function (exitCode) {
      if (exitCode !== 0) {
        Logger.e("Hyprpaper", "Failed to set wallpaper, exit code:", exitCode);
      } else {
        Logger.i("Hyprpaper", "Wallpaper set successfully");
      }
      hyprlandProcess.destroy();
    });

    hyprlandProcess.running = true;
  }

  function changeWallpaper(path, screenName) {
    if (Settings.data.wallpaper.useSolidColor) {
      Settings.data.wallpaper.useSolidColor = false;
    }

    _saveOutgoingFavorites(path, screenName);

    if (screenName !== undefined) {
      _setWallpaper(screenName, path);
      setWallpaperOnHyprland(path, screenName);
    } else {
      var allScreenNames = new Set(Object.keys(currentWallpapers));
      for (var i = 0; i < Quickshell.screens.length; i++) {
        allScreenNames.add(Quickshell.screens[i].name);
      }
      allScreenNames.forEach(function(name) {
        _setWallpaper(name, path);
        setWallpaperOnHyprland(path, name);
      });
    }
  }

  function _saveOutgoingFavorites(newPath, screenName) {
    var outgoing = screenName !== undefined ? [currentWallpapers[screenName]] : Object.values(currentWallpapers);
    var unique = [...new Set(outgoing)];

    unique.forEach(function (path) {
      if (path && path !== newPath && isFavorite(path)) {
        updateFavoriteColorScheme(path);
      }
    });
  }

  function _setWallpaper(screenName, path) {
    if (path === "" || path === undefined) {
      return;
    }

    if (screenName === undefined) {
      Logger.w("Hyprpaper", "setWallpaper", "no screen specified");
      return;
    }

    var oldPath = currentWallpapers[screenName] || "";
    if (oldPath === path) {
      return;
    }

    currentWallpapers[screenName] = path;
    saveTimer.restart();
    root.wallpaperChanged(screenName, path);
  }

  function setRandomWallpaper() {
    Logger.d("Hyprpaper", "setRandomWallpaper");

    if (Settings.data.wallpaper.enableMultiMonitorDirectories) {
      for (var i = 0; i < Quickshell.screens.length; i++) {
        var screenName = Quickshell.screens[i].name;
        var wallpaperList = getWallpapersList(screenName);

        if (wallpaperList.length > 0) {
          var randomPath = _pickUnusedRandom(screenName, wallpaperList);
          changeWallpaper(randomPath, screenName);
        }
      }
    } else {
      var wallpaperList = getWallpapersList(Screen.name);
      if (wallpaperList.length > 0) {
        var randomPath = _pickUnusedRandom("all", wallpaperList);
        changeWallpaper(randomPath, undefined);
      }
    }
  }

  function _pickUnusedRandom(key, wallpaperList) {
    var used = usedRandomWallpapers[key] || [];

    var wallpaperSet = new Set(wallpaperList);
    used = used.filter(function (path) {
      return wallpaperSet.has(path);
    });

    var unused = wallpaperList.filter(function (path) {
      return used.indexOf(path) === -1;
    });

    if (unused.length === 0) {
      var lastUsed = used.length > 0 ? used[used.length - 1] : "";
      used = lastUsed ? [lastUsed] : [];
      unused = wallpaperList.filter(function (path) {
        return used.indexOf(path) === -1;
      });
      if (unused.length === 0) {
        unused = wallpaperList;
      }
      Logger.d("Hyprpaper", "All wallpapers used for", key, "- resetting pool");
    }

    var randomIndex = Math.floor(Math.random() * unused.length);
    var picked = unused[randomIndex];

    used.push(picked);
    usedRandomWallpapers[key] = used;

    saveTimer.restart();

    return picked;
  }

  function getWallpapersList(screenName) {
    if (screenName != undefined && wallpaperLists[screenName] != undefined) {
      return wallpaperLists[screenName];
    }
    return [];
  }

  function getCurrentBrowsePath(screenName) {
    if (currentBrowsePaths[screenName] !== undefined) {
      var stored = currentBrowsePaths[screenName];
      var rootPath = getMonitorDirectory(screenName);
      if (rootPath && stored.startsWith(rootPath)) {
        return stored;
      }
      delete currentBrowsePaths[screenName];
    }
    return getMonitorDirectory(screenName);
  }

  function setBrowsePath(screenName, path) {
    if (!screenName) return;
    currentBrowsePaths[screenName] = path;
    browsePathChanged(screenName, path);
  }

  function navigateUp(screenName) {
    if (!screenName) return;
    var currentPath = getCurrentBrowsePath(screenName);
    var rootPath = getMonitorDirectory(screenName);

    if (!rootPath || currentPath === rootPath) return;

    var parentPath = currentPath.replace(/\/[^\/]+\/?$/, "");
    if (parentPath === "") parentPath = rootPath;
    if (!parentPath.startsWith(rootPath)) parentPath = rootPath;

    setBrowsePath(screenName, parentPath);
  }

  function navigateToRoot(screenName) {
    if (!screenName) return;
    var rootPath = getMonitorDirectory(screenName);
    setBrowsePath(screenName, rootPath);
  }

  function scanDirectoryWithDirs(screenName, directory, callback) {
    if (!directory || directory === "") {
      callback({ "files": [], "directories": [] });
      return;
    }

    var result = { "files": [], "directories": [] };
    var pendingScans = 2;

    function checkComplete() {
      pendingScans--;
      if (pendingScans === 0) {
        result.directories.sort();
        callback(result);
      }
    }

    _scanDirectoryInternal(screenName, directory, false, false, function (files) {
      result.files = files;
      checkComplete();
    });

    _scanForDirectories(directory, function (dirs) {
      result.directories = dirs;
      checkComplete();
    });
  }

  function _scanForDirectories(directory, callback) {
    var findArgs = ["find", "-L", directory, "-maxdepth", "1", "-mindepth", "1", "-type", "d"];

    var processString = `
      import QtQuick
      import Quickshell.Io
      Process {
        id: process
        command: ${JSON.stringify(findArgs)}
        stdout: StdioCollector {}
        stderr: StdioCollector {}
      }
    `;

    var processObject = Qt.createQmlObject(processString, root, "DirScan");

    processObject.exited.connect(function (exitCode) {
      var dirs = [];
      if (exitCode === 0) {
        var lines = processObject.stdout.text.split('\n');
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim();
          if (line !== '') {
            var showHidden = Settings.data.wallpaper.showHiddenFiles;
            var name = line.split('/').pop();
            if (showHidden || !name.startsWith('.')) {
              dirs.push(line);
            }
          }
        }
      }
      callback(dirs);
      processObject.destroy();
    });

    processObject.running = true;
  }

  function refreshWallpapersList() {
    if (typeof Settings === 'undefined' || !Settings.data?.wallpaper) {
      Logger.w("Hyprpaper", "Settings not available for refreshWallpapersList");
      Qt.callLater(refreshWallpapersList);
      return;
    }
    
    var mode = Settings.data.wallpaper.viewMode;
    var directory = getMonitorDirectory(Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
    Logger.d("Hyprpaper", "refreshWallpapersList", "viewMode:", mode, "directory:", directory);
    scanningCount = 0;

    if (mode === "recursive") {
      for (var i = 0; i < Quickshell.screens.length; i++) {
        var screenName = Quickshell.screens[i].name;
        var directory = getMonitorDirectory(screenName);
        scanDirectoryRecursive(screenName, directory);
      }
    } else if (mode === "browse") {
      for (var i = 0; i < Quickshell.screens.length; i++) {
        var screenName = Quickshell.screens[i].name;
        var directory = getCurrentBrowsePath(screenName);
        _scanDirectoryInternal(screenName, directory, false, true, null);
      }
    } else {
      for (var i = 0; i < Quickshell.screens.length; i++) {
        var screenName = Quickshell.screens[i].name;
        var directory = getMonitorDirectory(screenName);
        _scanDirectoryInternal(screenName, directory, false, true, null);
      }
    }
  }

  function _scanDirectoryInternal(screenName, directory, recursive, updateList, callback) {
    if (!directory || directory === "") {
      Logger.w("Hyprpaper", "Empty directory for", screenName);
      if (updateList) {
        wallpaperLists[screenName] = [];
        wallpaperListChanged(screenName, 0);
      }
      if (callback) callback([]);
      return;
    }

    if (recursiveProcesses[screenName]) {
      Logger.d("Hyprpaper", "Cancelling existing scan for", screenName);
      recursiveProcesses[screenName].running = false;
      recursiveProcesses[screenName].destroy();
      delete recursiveProcesses[screenName];
      if (updateList) scanningCount--;
    }

    if (updateList) scanningCount++;
    Logger.i("Hyprpaper", "Starting scan for", screenName, "in", directory, "recursive:", recursive);

    var filters = ["*.jpg", "*.jpeg", "*.png", "*.bmp", "*.webp", "*.svg"];
    var findArgs = ["find", "-L", directory];

    if (!recursive) {
      findArgs.push("-maxdepth", "1", "-mindepth", "1");
    }

    findArgs.push("-type", "f");
    findArgs.push("(");
    for (var i = 0; i < filters.length; i++) {
      if (i > 0) findArgs.push("-o");
      findArgs.push("-iname");
      findArgs.push(filters[i]);
    }
    findArgs.push(")");
    findArgs.push("-printf", "%T@|%p\n");

    var processString = `
      import QtQuick
      import Quickshell.Io
      Process {
        id: process
        command: ${JSON.stringify(findArgs)}
        stdout: StdioCollector {}
        stderr: StdioCollector {}
      }
    `;

    var processObject = Qt.createQmlObject(processString, root, "Scan_" + screenName);

    if (updateList) {
      recursiveProcesses[screenName] = processObject;
    }

    var handler = function (exitCode) {
      if (updateList) scanningCount--;
      Logger.d("Hyprpaper", "Process exited with code", exitCode, "for", screenName);

      var files = [];
      if (exitCode === 0) {
        var lines = processObject.stdout.text.split('\n');
        var parsedFiles = [];

        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim();
          if (line !== '') {
            var parts = line.split('|');
            if (parts.length >= 2) {
              var timestamp = parseFloat(parts[0]);
              var path = parts.slice(1).join('|');

              var showHidden = Settings.data.wallpaper.showHiddenFiles;
              var name = path.split('/').pop();
              if (showHidden || !name.startsWith('.')) {
                parsedFiles.push({ "path": path, "time": timestamp, "name": name });
              }
            }
          }
        }

        var sortOrder = Settings.data.wallpaper.waSortOrder || "name";

        if (sortOrder === "random") {
          for (let i = parsedFiles.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            const temp = parsedFiles[i];
            parsedFiles[i] = parsedFiles[j];
            parsedFiles[j] = temp;
          }
        } else {
          parsedFiles.sort(function (a, b) {
            if (sortOrder === "date_desc") return b.time - a.time;
            else if (sortOrder === "date_asc") return a.time - b.time;
            else if (sortOrder === "name_desc") return b.name.localeCompare(a.name);
            else return a.name.localeCompare(b.name);
          });
        }

        files = parsedFiles.map(f => f.path);

        if (updateList) {
          wallpaperLists[screenName] = files;
          if (alphabeticalIndices[screenName] !== undefined) {
            var currentWallpaper = currentWallpapers[screenName] || "";
            var foundIndex = files.indexOf(currentWallpaper);
            alphabeticalIndices[screenName] = (foundIndex >= 0) ? foundIndex : 0;
          }
          Logger.i("Hyprpaper", "Scan completed for", screenName, "found", files.length, "files");
          wallpaperListChanged(screenName, files.length);
        }
      } else {
        Logger.w("Hyprpaper", "Scan failed for", screenName, "exit code:", exitCode);
        if (updateList) {
          wallpaperLists[screenName] = [];
          wallpaperListChanged(screenName, 0);
        }
      }

      if (updateList) {
        delete recursiveProcesses[screenName];
      }

      if (callback) callback(files);
      processObject.destroy();
    };

    processObject.exited.connect(handler);
    Logger.d("Hyprpaper", "Starting process for", screenName);
    processObject.running = true;
  }

  property var recursiveProcesses: ({})

  function scanDirectoryRecursive(screenName, directory) {
    _scanDirectoryInternal(screenName, directory, true, true, null);
  }

  readonly property int _favoriteNotFound: -1

  function _findFavoriteIndex(path) {
    var favorites = Settings.data.wallpaper.favorites;
    for (var i = 0; i < favorites.length; i++) {
      if (favorites[i].path === path) {
        return i;
      }
    }
    return _favoriteNotFound;
  }

  function _createFavoriteEntry(path) {
    return {
      "path": path,
      "colorScheme": Settings.data.colorSchemes.predefinedScheme,
      "darkMode": Settings.data.colorSchemes.darkMode,
      "useWallpaperColors": Settings.data.colorSchemes.useWallpaperColors,
      "generationMethod": Settings.data.colorSchemes.generationMethod,
      "paletteColors": [Color.mPrimary.toString(), Color.mSecondary.toString(), Color.mTertiary.toString(), Color.mError.toString()]
    };
  }

  function isFavorite(path) {
    return _findFavoriteIndex(path) !== _favoriteNotFound;
  }

  function getFavorite(path) {
    var favoriteIndex = _findFavoriteIndex(path);
    if (favoriteIndex === _favoriteNotFound) return null;
    return Settings.data.wallpaper.favorites[favoriteIndex];
  }

  function toggleFavorite(path) {
    var favorites = Settings.data.wallpaper.favorites.slice();
    var existingIndex = _findFavoriteIndex(path);

    if (existingIndex !== _favoriteNotFound) {
      favorites.splice(existingIndex, 1);
      Logger.d("Hyprpaper", "Removed favorite:", path);
    } else {
      favorites.push(_createFavoriteEntry(path));
      Logger.d("Hyprpaper", "Added favorite:", path);
    }

    Settings.data.wallpaper.favorites = favorites;
    favoritesChanged(path);
  }

  function applyFavoriteTheme(path, screenName) {
    var effectiveMonitor = Settings.data.colorSchemes.monitorForColors;
    if (effectiveMonitor === "" || effectiveMonitor === undefined) {
      effectiveMonitor = Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "";
    }
    if (screenName !== undefined && screenName !== effectiveMonitor) {
      return;
    }

    var favorite = getFavorite(path);
    if (!favorite) return;

    var generationMethodChanging = Settings.data.colorSchemes.generationMethod !== favorite.generationMethod;
    var darkModeChanging = Settings.data.colorSchemes.darkMode !== favorite.darkMode;

    Settings.data.colorSchemes.useWallpaperColors = favorite.useWallpaperColors;
    Settings.data.colorSchemes.predefinedScheme = favorite.colorScheme;
    Settings.data.colorSchemes.generationMethod = favorite.generationMethod;
    Settings.data.colorSchemes.darkMode = favorite.darkMode;

    if (!generationMethodChanging && !darkModeChanging) {
      AppThemeService.generate();
    }
  }

  function updateFavoriteColorScheme(path) {
    var existingIndex = _findFavoriteIndex(path);
    if (existingIndex === _favoriteNotFound) return;

    var favorites = Settings.data.wallpaper.favorites.slice();
    favorites[existingIndex] = _createFavoriteEntry(path);
    Settings.data.wallpaper.favorites = favorites;
    Logger.d("Hyprpaper", "Updated color scheme for favorite:", path);
    favoriteDataUpdated(path);
  }

  function updateHyprpaperConf(splash, splashOffset, splashOpacity, ipc) {
    var home = Quickshell.env("HOME");
    var confPath = home + "/.config/hypr/hyprpaper.conf";

    // Build config content
    var lines = [];
    lines.push("# Generated by Noctalia Hyprpaper Plugin");
    lines.push("# Do not edit manually - changes will be overwritten");
    lines.push("");

    // Misc Options (use passed parameters, with fallbacks)
    var useSplash = splash ?? Settings.data.wallpaper?.splash ?? true;
    var useSplashOffset = splashOffset ?? Settings.data.wallpaper?.splash_offset ?? 20;
    var useSplashOpacity = splashOpacity ?? Settings.data.wallpaper?.splash_opacity ?? 0.8;
    var useIpc = ipc ?? Settings.data.wallpaper?.ipc ?? true;

    lines.push("splash = " + (useSplash ? "true" : "false"));
    lines.push("splash_offset = " + useSplashOffset);
    lines.push("splash_opacity = " + useSplashOpacity);
    lines.push("ipc = " + (useIpc ? "true" : "false"));
    lines.push("");

    // Wallpaper blocks for each monitor
    var screens = Quickshell.screens;
    for (var i = 0; i < screens.length; i++) {
        var screenName = screens[i].name;
        var wallpaperPath = currentWallpapers[screenName];

        if (wallpaperPath && !isSolidColorPath(wallpaperPath)) {
            var fitMode = Settings.data.wallpaper.fillMode || "cover";

            lines.push("wallpaper {");
            lines.push("    monitor = " + screenName);
            lines.push("    path = " + wallpaperPath);
            lines.push("    fit_mode = " + fitMode);
            lines.push("}");
            lines.push("");
        }
    }

    var content = lines.join("\n");

    // Escape for shell
    var escapedContent = content
        .replace(/\\/g, '\\\\')
        .replace(/'/g, "'\"'\"'");

    var writeProcess = Qt.createQmlObject(`
        import QtQuick
        import Quickshell.Io
        Process {
            command: ["bash", "-c", "cat > '${confPath}' <<< '${escapedContent}'"]
        }
    `, root, "WriteHyprpaperConf");

    writeProcess.exited.connect(function(exitCode) {
        if (exitCode === 0) {
            Logger.i("Hyprpaper", "Config written to", confPath);
            
            // Restart hyprpaper to apply changes
            restartHyprpaper();
        } else {
            Logger.e("Hyprpaper", "Failed to write config, exit code:", exitCode);
        }
        writeProcess.destroy();
    });

    writeProcess.running = true;
}

function restartHyprpaper() {
    Logger.i("Hyprpaper", "Restarting hyprpaper...");
    
    var restartProcess = Qt.createQmlObject(`
        import QtQuick
        import Quickshell.Io
        Process {
            command: ["bash", "-c", "pkill -x hyprpaper; hyprpaper & disown"]
        }
    `, root, "RestartHyprpaper");

    restartProcess.exited.connect(function(exitCode) {
        Logger.i("Hyprpaper", "Hyprpaper restart initiated");
        restartProcess.destroy();
    });

    restartProcess.running = true;
}

  FileView {
    id: wallpaperCacheView
    path: root.wallpaperCacheFile
    printErrors: false
    watchChanges: false

    adapter: JsonAdapter {
      id: wallpaperCacheAdapter
      property var wallpapers: ({})
      property string defaultWallpaper: ""
      property var usedRandomWallpapers: ({})
    }

    onLoaded: {
      root.currentWallpapers = wallpaperCacheAdapter.wallpapers || {};
      root.usedRandomWallpapers = wallpaperCacheAdapter.usedRandomWallpapers || {};
      root.defaultWallpaper = wallpaperCacheAdapter.defaultWallpaper || "";
      Logger.d("Hyprpaper", "Loaded wallpapers from cache file:", Object.keys(root.currentWallpapers).length, "screens");
      root.isInitialized = true;
    }

    onLoadFailed: error => {
      root.currentWallpapers = {};
      Logger.d("Hyprpaper", "Cache file doesn't exist or failed to load, starting with empty wallpapers");
      root.isInitialized = true;
    }
  }

  Timer {
    id: saveTimer
    interval: 500
    repeat: false
    onTriggered: {
      if (!wallpaperCacheView.path) {
        Logger.w("Hyprpaper", "Cache file path not set, skipping save");
        return;
      }
      wallpaperCacheAdapter.wallpapers = root.currentWallpapers;
      wallpaperCacheAdapter.defaultWallpaper = root.defaultWallpaper;
      wallpaperCacheAdapter.usedRandomWallpapers = root.usedRandomWallpapers;
      wallpaperCacheView.writeAdapter();
      Logger.d("Hyprpaper", "Saved wallpapers to cache file");
    }
  }
}
