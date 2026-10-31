/*
 * Xenoglyph — the living sigil. Shared by the wallpaper, splash and SDDM.
 *
 * Everything slow (rings, drifting glyphs, the ichor pulse, the scan beam)
 * is a pure function of one clock `t` that ticks at `fps`. The scene only
 * redraws on a tick, so a 20 fps clock costs about a third of a 60 fps
 * animation, and the motion is so slow it reads as smooth. Only the quick
 * eye-blink runs a full-rate animation, for a quarter second.
 */
import QtQuick

Item {
    id: scene
    property url art: Qt.resolvedUrl("../art/")
    property real sigilSize: Math.min(width, height) * 0.64
    property real centerX: width * 0.5
    property real centerY: height * 0.47
    property bool running: true
    property bool motes: true
    property bool beam: true
    property real speed: 1.0          // >1 = slower, <1 = faster
    property int fps: 20
    property real assembly: 1.0       // 0..1: rings fly in one by one (splash)
    property string ringText: "XENOGLYPH  INK AND ICHOR  THE VESSEL WAKES  WE WERE WRITTEN BEFORE THE SKIN  "
    readonly property alias glyphFont: daedric.name
    readonly property color ink: "#141016"
    readonly property color ichor: "#d3122b"
    clip: true

    // ---- the clock -----------------------------------------------------------
    property real t: 0                // seconds of scene time
    Timer {
        interval: Math.round(1000 / scene.fps); repeat: true; running: scene.running
        onTriggered: scene.t += interval / 1000 / scene.speed
    }
    function turn(period) { return (scene.t / period * 360) % 360 }
    function wave(period) { return 0.5 + 0.5 * Math.sin(scene.t * 2 * Math.PI / period) }
    function grow(k) { return Math.max(0, Math.min(1, (scene.assembly - k) / 0.28)) }

    FontLoader { id: daedric; source: scene.art + "OMWAyembedt.otf" }

    Image {
        anchors.fill: parent
        source: scene.art + "background.svg"
        sourceSize: Qt.size(Math.max(1, width), Math.max(1, height))
        fillMode: Image.PreserveAspectCrop
        cache: true
    }

    // ---- drifting glyph motes -----------------------------------------------
    Repeater {
        model: scene.motes ? 24 : 0
        delegate: Text {
            id: mote
            // never exactly 0: keeps every mote on its own phase
            readonly property real seed: 0.02 + 0.98 * (index * 7919 % 1000) / 1000
            readonly property real seed2: 0.05 + 0.95 * (index * 104729 % 997) / 997
            readonly property real trip: 38 + 30 * seed                 // seconds bottom -> top
            readonly property real phase: ((scene.t / trip) + seed2) % 1  // 0 at bottom, 1 off the top
            x: scene.width * (0.03 + 0.94 * seed)
            y: scene.height * (1.04 - 1.2 * phase)
            text: "ABCDEFGHIJKLMNOPQRSTUVWXYZ".charAt(index * 11 % 26)
            font.family: daedric.name
            font.pixelSize: Math.max(10, scene.height * (0.014 + 0.022 * seed2))
            color: index % 5 == 0 ? scene.ichor : scene.ink
            // fade in from the bottom, out near the top
            opacity: (0.12 + 0.18 * seed) * Math.min(1, phase / 0.15) * Math.min(1, (1 - phase) / 0.3)
        }
    }

    // ---- the sigil -----------------------------------------------------------
    Item {
        id: sigil
        width: scene.sigilSize
        height: width
        x: scene.centerX - width / 2
        y: scene.centerY - height / 2
        scale: 1 + 0.018 * scene.wave(10.4)          // slow breath

        Image {
            anchors.centerIn: parent
            width: parent.width * 0.9; height: width
            source: scene.art + "bloom.svg"
            sourceSize: Qt.size(256, 256)
            opacity: (0.35 + 0.6 * scene.wave(4.8)) * scene.grow(0.6)
        }

        component Layer: Image {
            property real at: 0
            anchors.fill: parent
            sourceSize: Qt.size(Math.ceil(scene.sigilSize), Math.ceil(scene.sigilSize))
            smooth: true
            antialiasing: true
            opacity: scene.grow(at)
            scale: 1 + (1 - scene.grow(at)) * 0.45
        }

        Layer { at: 0.0; source: scene.art + "ring-ticks.svg"; rotation: scene.turn(240) }

        Item {   // ring of live Daedric script, counter-turning
            anchors.fill: parent
            opacity: scene.grow(0.15)
            rotation: -scene.turn(180)
            Repeater {
                model: scene.ringText.length
                delegate: Item {
                    width: sigil.width; height: sigil.height
                    rotation: index * 360 / scene.ringText.length
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height * 0.5 - parent.height * 0.418 - height / 2
                        text: scene.ringText.charAt(index)
                        font.family: daedric.name
                        font.pixelSize: Math.max(8, sigil.width * 0.026)
                        color: scene.ink
                        opacity: 0.85
                    }
                }
            }
        }

        Layer { at: 0.3; source: scene.art + "ring-blades.svg"; rotation: scene.turn(120) }
        Layer { at: 0.45; source: scene.art + "ring-ichor.svg"; rotation: -scene.turn(46) }
        Layer { at: 0.55; source: scene.art + "core.svg" }

        Item {   // the eye: it blinks
            anchors.fill: parent
            opacity: scene.grow(0.72)
            transform: Scale { id: lid; origin.x: sigil.width / 2; origin.y: sigil.height / 2; yScale: 1 }
            Layer { source: scene.art + "lens.svg"; at: -1 }
            Layer { source: scene.art + "pupil.svg"; at: -1 }
            SequentialAnimation {
                running: scene.running
                loops: Animation.Infinite
                PauseAnimation { duration: 7400 }
                NumberAnimation { target: lid; property: "yScale"; to: 0.06; duration: 90; easing.type: Easing.InQuad }
                NumberAnimation { target: lid; property: "yScale"; to: 1; duration: 190; easing.type: Easing.OutQuad }
                PauseAnimation { duration: 3100 }
                NumberAnimation { target: lid; property: "yScale"; to: 0.06; duration: 80 }
                NumberAnimation { target: lid; property: "yScale"; to: 1; duration: 150 }
            }
        }
    }

    // ---- the scanner: a red beam sweeps the skin every 30 s ------------------
    Image {
        id: beamImg
        readonly property real cycle: (scene.t % 30) / 6.5          // sweep in the first 6.5 s of each 30
        visible: scene.beam && cycle < 1
        source: scene.art + "beam.svg"
        width: Math.max(24, scene.width * 0.03)
        height: scene.height
        sourceSize: Qt.size(64, 512)
        x: -width + (scene.width + width) * (0.5 - 0.5 * Math.cos(Math.PI * Math.min(1, cycle)))
        opacity: 0.7
    }
}
