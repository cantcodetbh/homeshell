import QtQuick
import QtQuick.Layouts

Rectangle {
  id: mark
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

  property int wid: 1
  property string label: "1"
  property bool active: false
  property bool urgent: false
  property int windows: 0
  property bool hovered: false

  Layout.preferredWidth: 25
  Layout.preferredHeight: 5
  radius: shell ? shell.cornerRadius : 3
  color: urgent ? (shell ? shell.red : "#b85f4d")
                : active ? (shell ? shell.accent : "#a8c5c9")
                : windows > 0 ? (shell ? shell.muted : "#cdbeb4")
                : Qt.rgba(shell ? shell.muted.r : 0.8, shell ? shell.muted.g : 0.75, shell ? shell.muted.b : 0.71, 0.28)
  border.width: active ? 1 : 0
  border.color: active ? (shell ? shell.textColor : "#efe4dc") : "transparent"

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onEntered: mark.hovered = true
    onExited: mark.hovered = false
    onClicked: function(mouse) {
      if (!shell) return
      if (mouse.button === Qt.RightButton) {
        shell.selectedWorkspaceId = mark.wid
        shell.toggleDrawer("workspace")
      } else if (mouse.button === Qt.MiddleButton) {
        shell.selectedWorkspaceId = mark.wid
        shell.run(shell.hyprexposeCommand)
      } else {
        shell.run("hyprctl dispatch workspace " + mark.wid)
      }
    }
  }

  opacity: hovered || active ? 1 : 0.86
  scale: 1

  Behavior on Layout.preferredWidth { NumberAnimation { duration: shell ? shell.motionFast : 110; easing.type: Easing.OutCubic } }
  Behavior on Layout.preferredHeight { NumberAnimation { duration: shell ? shell.motionFast : 110; easing.type: Easing.OutCubic } }
  Behavior on color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on border.color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on opacity { NumberAnimation { duration: shell ? shell.motionFast : 110 } }
}
