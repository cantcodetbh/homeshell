import QtQuick
import Quickshell.Wayland

Rectangle {
  id: miniWindow
  property var shell: null

  function findShell() {
    var p = parent
    while (p) {
      if (p.shell) return p.shell
      if (p && typeof p.baseDir !== "undefined" && typeof p.drawerMode !== "undefined") return p
      p = p.parent
    }
    return null
  }

  Component.onCompleted: { if (shell === null) shell = findShell() }

  property var client
  property var clients: []
  property real previewWidth: 1
  property real previewHeight: 1
  property bool hovered: false
  readonly property var rect: shell ? shell.previewRect(client, clients, previewWidth, previewHeight) : ({"x": 0, "y": 0, "w": 1, "h": 1})

  x: rect.x
  y: rect.y
  z: 2
  width: Math.min(rect.w, previewWidth - x)
  height: Math.min(rect.h, previewHeight - y)
  radius: shell ? shell.cornerRadius : 3
  color: shell ? Qt.rgba(shell.base.r, shell.base.g, shell.base.b, hovered || (client && client.active) ? 0.88 : 0.70) : Qt.rgba(0.08, 0.07, 0.06, hovered || (client && client.active) ? 0.88 : 0.70)
  border.width: client && client.active ? (shell ? shell.uiBorderWidth : 3) : 1
  border.color: client && client.active ? (shell ? shell.accent : "#a8c5c9") : (shell ? Qt.rgba(shell.muted.r, shell.muted.g, shell.muted.b, hovered ? 0.62 : 0.34) : Qt.rgba(0.8, 0.75, 0.71, hovered ? 0.62 : 0.34))
  clip: true

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: 18
    color: client && client.active
      ? (shell ? Qt.rgba(shell.accent.r, shell.accent.g, shell.accent.b, 0.26) : Qt.rgba(0.66, 0.77, 0.79, 0.26))
      : (shell ? Qt.rgba(shell.baseAlt.r, shell.baseAlt.g, shell.baseAlt.b, 0.70) : Qt.rgba(0.14, 0.11, 0.09, 0.70))

    MinimalText {
      anchors.fill: parent
      anchors.leftMargin: 6
      anchors.rightMargin: 6
      text: client ? (client.class || "app") : "app"
      color: client && client.active ? (shell ? shell.accent : "#a8c5c9") : (shell ? shell.muted : "#cdbeb4")
      horizontalAlignment: Text.AlignLeft
      font.pixelSize: 9
    }
  }

  ScreencopyView {
    id: livePreview
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: 18
    captureSource: client ? (shell ? shell.waylandToplevelForAddress(client.address) : null) : null
    live: shell && shell.drawerMode === "overview" && captureSource !== null
    paintCursor: false
    constraintSize: Qt.size(width, height)
    opacity: hasContent ? 1 : 0
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 34
    visible: livePreview.hasContent
    color: shell ? Qt.rgba(shell.base.r, shell.base.g, shell.base.b, 0.62) : Qt.rgba(0.08, 0.07, 0.06, 0.62)
  }

  MinimalText {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.margins: 7
    anchors.topMargin: 22
    text: client ? (client.title || "untitled") : "untitled"
    color: shell ? shell.textColor : "#efe4dc"
    horizontalAlignment: Text.AlignLeft
    verticalAlignment: livePreview.hasContent ? Text.AlignBottom : Text.AlignTop
    wrapMode: Text.Wrap
    maximumLineCount: livePreview.hasContent ? 1 : 3
    font.pixelSize: 10
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: miniWindow.hovered = true
    onExited: miniWindow.hovered = false
    onClicked: if (shell) shell.focusClient(miniWindow.client)
  }

  Behavior on color { ColorAnimation { duration: shell ? shell.motionFast : 110 } }
  Behavior on border.color { ColorAnimation { duration: shell ? shell.motionFast : 110 } }
}
