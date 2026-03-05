pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string cacheDir:
        Quickshell.env("HOME") +
        "/.cache/noctalia/wallpaper_thumbnails/"

    property var cache: ({})
    property var _status: ({})
    property var _queue: []

    property int workers: 0
    property int maxWorkers: 4

    function ensureDir() {
        var proc = Qt.createQmlObject(`
            import QtQuick
            import Quickshell.Io
            Process {
                command: ["bash","-c",
                "mkdir -p '${cacheDir}'"]
            }
        `, root)
        proc.running = true
    }

    function thumbPathFor(filePath) {
        var safe = filePath
            .replace(/\.[^/.]+$/, "")
            .replace(/\//g,"_")
            .replace(/[^a-zA-Z0-9_\-]/g,"")

        return cacheDir + safe + ".jpg"
    }

    function request(filePath) {
        if (!filePath)
            return ""

        if (cache[filePath])
            return cache[filePath]

        if (_status[filePath])
            return ""

        _status[filePath] = "queued"
        _queue.push(filePath)
        process()

        return ""
    }

    function process() {
        if (workers >= maxWorkers)
            return

        if (_queue.length === 0)
            return

        var filePath = _queue.shift()
        workers++
        _status[filePath] = "pending"

        var thumb = thumbPathFor(filePath)

        var proc = Qt.createQmlObject(`
            import QtQuick
            import Quickshell.Io
            Process {
                command: ["bash","-c",
                "[ -f '${thumb}' ] || \
                ffmpeg -loglevel quiet -y \
                -i '${filePath}' \
                -vf scale=320:-1 \
                -frames:v 1 '${thumb}'"]
            }
        `, root)

        proc.exited.connect(function(code){

            if (code === 0) {
                cache[filePath] = thumb
                root.cache = Object.assign({}, cache)
                _status[filePath] = "ready"
            } else {
                delete _status[filePath]
            }

            workers--
            proc.destroy()
            process()
        })

        proc.running = true
        process()
    }

    Component.onCompleted: ensureDir()
}