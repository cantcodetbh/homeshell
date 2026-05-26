import QtQuick
import QtQuick.Layouts

Rectangle {
  id: overviewCard
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

  property var client
  property int keyIndex: -1
  property bool hovered: false
  readonly property bool keyboardSelected: keyIndex >= 0 && shell && shell.drawerKeyboardIndex === keyIndex
  readonly property bool activeClient: client && client.active

  Layout.fillWidth: true
  Layout.preferredHeight: 76
  radius: shell ? shell.cornerRadius : 3
  color: shell ? Qt.rgba(shell.base.r, shell.base.g, shell.base.b, hovered || keyboardSelected ? 0.78 : 0.56) : Qt.rgba(0.08, 0.07, 0.06, hovered || keyboardSelected ? 0.78 : 0.56)
  border.width: shell ? shell.uiBorderWidth : 3
  border.color: activeClient
    ? (shell ? Qt.rgba(shell.borderAccent.r, shell.borderAccent.g, shell.borderAccent.b, 0.88) : Qt.rgba(0.66, 0.77, 0.79, 0.88))
    : (shell ? Qt.rgba(shell.muted.r, shell.muted.g, shell.muted.b, hovered || keyboardSelected ? 0.44 : 0.22) : Qt.rgba(0.8, 0.75, 0.71, hovered || keyboardSelected ? 0.44 : 0.22))
  scale: hovered || keyboardSelected ? (shell ? shell.motionLift : 1.006) : 1

  RowLayout {
    anchors.fill: parent
    anchors.margins: 10
    spacing: 10

    Rectangle {
      Layout.preferredWidth: 42
      Layout.preferredHeight: 42
      radius: shell ? shell.cornerRadius : 3
      antialiasing: true
      color: activeClient
        ? (shell ? Qt.rgba(shell.accent.r, shell.accent.g, shell.accent.b, 0.22) : Qt.rgba(0.66, 0.77, 0.79, 0.22))
        : (shell ? Qt.rgba(shell.baseAlt.r, shell.baseAlt.g, shell.baseAlt.b, 0.62) : Qt.rgba(0.14, 0.11, 0.09, 0.62))
      border.width: 1
      border.color: activeClient ? (shell ? shell.accent : "#a8c5c9") : (shell ? Qt.rgba(shell.muted.r, shell.muted.g, shell.muted.b, 0.28) : Qt.rgba(0.8, 0.75, 0.71, 0.28))

      MinimalText {
        anchors.fill: parent
        text: shell ? shell.appInitial(overviewCard.client ? overviewCard.client.class : "") : "A"
        color: activeClient ? (shell ? shell.accent : "#a8c5c9") : (shell ? shell.textColor : "#efe4dc")
        font.pixelSize: 16
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 5

      MinimalText {
        Layout.fillWidth: true
        text: overviewCard.client ? overviewCard.client.title : "untitled"
        color: hovered || keyboardSelected || activeClient ? (shell ? shell.accent : "#a8c5c9") : (shell ? shell.textColor : "#efe4dc")
        horizontalAlignment: Text.AlignLeft
        font.pixelSize: 12
      }

      MinimalText {
        Layout.fillWidth: true
        text: shell ? shell.clientSubtitle(overviewCard.client) : ""
        color: shell ? shell.muted : "#cdbeb4"
        horizontalAlignment: Text.AlignLeft
        font.pixelSize: 10
      }
    }

    MinimalText {
      Layout.preferredWidth: 54
      text: activeClient ? "active" : "focus"
      color: activeClient ? (shell ? shell.accent : "#a8c5c9") : (shell ? shell.muted : "#cdbeb4")
      font.pixelSize: 10
      horizontalAlignment: Text.AlignRight
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: {
      overviewCard.hovered = true
      if (shell && overviewCard.keyIndex >= 0) shell.drawerKeyboardIndex = overviewCard.keyIndex
    }
    onExited: overviewCard.hovered = false
    onClicked: if (shell) shell.focusClient(overviewCard.client)
  }

  Behavior on color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on border.color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on scale { NumberAnimation { duration: shell ? shell.motionFast : 110; easing.type: Easing.OutCubic } }
}
