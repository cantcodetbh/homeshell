import QtQuick
import QtQuick.Layouts
import "ShellFinder.js" as ShellFinder

Rectangle {
  id: tile
  property var shell: null

  Component.onCompleted: { if (shell === null) shell = ShellFinder.findShell(parent) }

  property string icon: ""
  property string label: ""
  property string detail: ""
  property string command: ""
  property bool confirm: true
  property bool hovered: false
  readonly property bool waiting: shell && shell.powerConfirm === label

  Layout.preferredWidth: 126
  Layout.preferredHeight: 112
  radius: shell ? shell.cornerRadius : 3
  color: Qt.rgba(
    shell ? shell.baseAlt.r : 0.14, shell ? shell.baseAlt.g : 0.11, shell ? shell.baseAlt.b : 0.09, hovered ? 0.70 : 0.46)
  border.width: shell ? shell.uiBorderWidth : 3
  border.color: waiting ? (shell ? shell.amber : "#d7a86e")
                : hovered ? (shell ? shell.accent : "#a8c5c9")
                : Qt.rgba(shell ? shell.muted.r : 0.8, shell ? shell.muted.g : 0.75, shell ? shell.muted.b : 0.71, 0.34)
  scale: hovered || waiting ? (shell ? shell.motionLift : 1.006) : 1

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 12
    spacing: 8

    MinimalText {
      Layout.fillWidth: true
      Layout.preferredHeight: 34
      text: tile.icon
      color: tile.waiting ? (shell ? shell.amber : "#d7a86e")
             : tile.hovered ? (shell ? shell.accent : "#a8c5c9")
             : (shell ? shell.textColor : "#efe4dc")
      font.pixelSize: 24
      horizontalAlignment: Text.AlignHCenter
    }

    MinimalText {
      Layout.fillWidth: true
      text: tile.label
      color: tile.waiting ? (shell ? shell.amber : "#d7a86e") : (shell ? shell.textColor : "#efe4dc")
      font.pixelSize: 12
      horizontalAlignment: Text.AlignHCenter
    }

    MinimalText {
      Layout.fillWidth: true
      text: tile.waiting ? "click again" : tile.detail
      color: tile.waiting ? (shell ? shell.amber : "#d7a86e") : (shell ? shell.muted : "#cdbeb4")
      font.pixelSize: 9
      horizontalAlignment: Text.AlignHCenter
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: tile.hovered = true
    onExited: tile.hovered = false
    onClicked: {
      if (!shell) return
      shell.powerAction(tile.label, tile.command, tile.confirm)
    }
  }

  Behavior on color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on border.color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on scale { NumberAnimation { duration: shell ? shell.motionFast : 110; easing.type: Easing.OutCubic } }
}
