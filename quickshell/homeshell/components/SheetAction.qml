import QtQuick
import QtQuick.Layouts

Rectangle {
  id: action
  property var shell: null

  function findShell() {
    var p = parent
    while (p) {
      if (p.shell) return p.shell
      if (typeof p.baseDir === 'string' && typeof p.drawerMode === 'string') return p
      p = p.parent
    }
    return null
  }

  Component.onCompleted: { if (shell === null) shell = findShell() }

  property string label: ""
  property string detail: ""
  property string command: ""
  property string drawer: ""
  property int keyIndex: -1
  property bool hovered: false
  property bool pressed: false
  readonly property bool keyboardSelected: keyIndex >= 0 && shell && shell.drawerKeyboardIndex === keyIndex

  Layout.fillWidth: true
  Layout.preferredHeight: 34
  radius: shell ? shell.cornerRadius : 3
  color: Qt.rgba(
    shell ? shell.base.r : 0.08, shell ? shell.base.g : 0.07, shell ? shell.base.b : 0.06, 0.62)
  border.width: shell ? shell.uiBorderWidth : 3
  border.color: action.keyboardSelected
    ? Qt.rgba(shell ? shell.accent.r : 0.66, shell ? shell.accent.g : 0.77, shell ? shell.accent.b : 0.79, 0.56)
    : Qt.rgba(shell ? shell.muted.r : 0.8, shell ? shell.muted.g : 0.75, shell ? shell.muted.b : 0.71,
              action.hovered ? 0.40 : 0.24)
  scale: action.pressed ? (shell ? shell.motionPress : 0.996)
        : action.hovered || action.keyboardSelected ? (shell ? shell.motionLift : 1.006)
        : 1

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    spacing: 10

    MinimalText {
      Layout.fillWidth: true
      text: action.label
      color: action.hovered || action.keyboardSelected
             ? (shell ? shell.accent : "#a8c5c9")
             : (shell ? shell.textColor : "#efe4dc")
      font.pixelSize: 12
      horizontalAlignment: Text.AlignLeft
    }

    MinimalText {
      Layout.maximumWidth: 150
      text: action.detail
      color: action.hovered || action.keyboardSelected
             ? (shell ? shell.accent : "#a8c5c9")
             : (shell ? shell.muted : "#cdbeb4")
      font.pixelSize: 10
      horizontalAlignment: Text.AlignRight
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: (action.command.length > 0 || action.drawer.length > 0) ? Qt.PointingHandCursor : Qt.ArrowCursor
    onEntered: {
      action.hovered = true
      if (shell && action.keyIndex >= 0) shell.drawerKeyboardIndex = action.keyIndex
    }
    onExited: {
      action.hovered = false
      action.pressed = false
    }
    onPressed: action.pressed = true
    onReleased: action.pressed = false
    onClicked: {
      if (!shell) return
      if (action.drawer.length > 0) shell.navigateDrawer(action.drawer)
      else if (action.command.length > 0) shell.run(action.command)
    }
  }

  Behavior on color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on border.color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on scale { NumberAnimation { duration: shell ? shell.motionFast : 110; easing.type: Easing.OutCubic } }
}
