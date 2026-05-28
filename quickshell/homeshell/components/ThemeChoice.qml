import QtQuick
import QtQuick.Layouts

Rectangle {
  id: choice
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

  property string choiceId: ""
  property string label: "source"
  property string primary: "#a8c5c9"
  property string secondary: "#7fa8a2"
  property string tertiary: "#d7a86e"
  property string surface: "#15110f"
  property string textTone: "#efe4dc"
  property string variant: ""
  property bool selected: false
  property int keyIndex: -1
  property bool hovered: false
  readonly property bool wildcard: variant === "wildcard" || choiceId.indexOf("wild/") === 0
  readonly property bool keyboardSelected: keyIndex >= 0 && shell && shell.drawerKeyboardIndex === keyIndex

  Layout.fillWidth: true
  Layout.preferredHeight: 46
  radius: shell ? shell.cornerRadius : 3
  color: Qt.rgba(shell ? shell.base.r : 0.08, shell ? shell.base.g : 0.07, shell ? shell.base.b : 0.06, hovered ? 0.72 : 0.56)
  border.width: shell ? shell.uiBorderWidth : 3
  border.color: selected
    ? Qt.rgba(shell ? shell.borderAccent.r : 0.66, shell ? shell.borderAccent.g : 0.77, shell ? shell.borderAccent.b : 0.79, 0.87)
    : Qt.rgba(shell ? shell.muted.r : 0.8, shell ? shell.muted.g : 0.75, shell ? shell.muted.b : 0.71, hovered ? 0.38 : 0.22)
  scale: hovered || keyboardSelected ? (shell ? shell.motionLift : 1.006) : 1

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    spacing: 10

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 4

      MinimalText {
        Layout.fillWidth: true
        text: choice.label
        color: choice.wildcard
               ? choice.primary
               : choice.selected || choice.hovered || choice.keyboardSelected
               ? (shell ? shell.accent : "#a8c5c9")
               : (shell ? shell.textColor : "#efe4dc")
        font.pixelSize: 12
        horizontalAlignment: Text.AlignLeft
      }

      MinimalText {
        Layout.fillWidth: true
        text: choice.primary + "  " + choice.secondary + "  " + choice.tertiary
        color: choice.wildcard ? (shell ? shell.textColor : "#efe4dc") : (shell ? shell.muted : "#cdbeb4")
        font.pixelSize: 9
        horizontalAlignment: Text.AlignLeft
      }
    }

    Row {
      Layout.preferredWidth: 96
      Layout.preferredHeight: 20
      spacing: 3

      Repeater {
        model: [choice.primary, choice.secondary, choice.tertiary, choice.surface]
        delegate: Rectangle {
          width: 21
          height: 20
          radius: shell ? shell.cornerRadius : 3
          color: modelData
          border.width: 1
          border.color: Qt.rgba(shell ? shell.textColor.r : 0.94, shell ? shell.textColor.g : 0.89, shell ? shell.textColor.b : 0.86, 0.22)
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: {
      choice.hovered = true
      if (shell && choice.keyIndex >= 0) shell.drawerKeyboardIndex = choice.keyIndex
    }
    onExited: choice.hovered = false
    onClicked: {
      if (!shell) return
      shell.run(shell.baseDir + "/scripts/theme-colour set-index " + choice.choiceId)
    }
  }

  Behavior on color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on border.color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on scale { NumberAnimation { duration: shell ? shell.motionFast : 110; easing.type: Easing.OutCubic } }
}
