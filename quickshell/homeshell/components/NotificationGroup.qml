import QtQuick
import QtQuick.Layouts

Rectangle {
  id: group
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

  property var groupData
  property bool hovered: false
  readonly property var items: groupData && groupData.items ? groupData.items : []
  readonly property bool critical: groupData && groupData.critical > 0

  Layout.fillWidth: true
  implicitHeight: groupContent.implicitHeight + 18
  radius: shell ? shell.cornerRadius : 3
  color: shell ? Qt.rgba(shell.base.r, shell.base.g, shell.base.b, hovered ? 0.72 : 0.54) : Qt.rgba(0.08, 0.07, 0.06, hovered ? 0.72 : 0.54)
  border.width: shell ? shell.uiBorderWidth : 3
  border.color: critical
    ? (shell ? Qt.rgba(shell.red.r, shell.red.g, shell.red.b, 0.70) : Qt.rgba(0.72, 0.37, 0.30, 0.70))
    : (shell ? Qt.rgba(shell.muted.r, shell.muted.g, shell.muted.b, hovered ? 0.42 : 0.22) : Qt.rgba(0.8, 0.75, 0.71, hovered ? 0.42 : 0.22))
  scale: hovered ? (shell ? shell.motionLift : 1.006) : 1

  ColumnLayout {
    id: groupContent
    anchors.fill: parent
    anchors.margins: 9
    spacing: 7

    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: 28
      spacing: 8

      Rectangle {
        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
        radius: shell ? shell.cornerRadius : 3
        color: critical
          ? (shell ? Qt.rgba(shell.red.r, shell.red.g, shell.red.b, 0.20) : Qt.rgba(0.72, 0.37, 0.30, 0.20))
          : (shell ? Qt.rgba(shell.accent.r, shell.accent.g, shell.accent.b, 0.18) : Qt.rgba(0.66, 0.77, 0.79, 0.18))

        MinimalText {
          anchors.fill: parent
          text: shell ? shell.appInitial(group.groupData ? group.groupData.app : "") : "N"
          color: critical ? (shell ? shell.red : "#b85f4d") : (shell ? shell.accent : "#a8c5c9")
          font.pixelSize: 12
        }
      }

      MinimalText {
        Layout.fillWidth: true
        text: group.groupData ? group.groupData.app : "notification"
        color: shell ? shell.textColor : "#efe4dc"
        horizontalAlignment: Text.AlignLeft
        font.pixelSize: 12
      }

      MinimalText {
        text: String(group.items.length)
        color: critical ? (shell ? shell.red : "#b85f4d") : (shell ? shell.muted : "#cdbeb4")
        font.pixelSize: 10
      }

      Rectangle {
        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
        radius: shell ? shell.cornerRadius : 3
        color: clearGroupArea.containsMouse ? (shell ? Qt.rgba(shell.red.r, shell.red.g, shell.red.b, 0.20) : Qt.rgba(0.72, 0.37, 0.30, 0.20)) : "transparent"
        scale: clearGroupArea.containsPress ? (shell ? shell.motionPress : 0.996) : clearGroupArea.containsMouse ? (shell ? shell.motionLift : 1.006) : 1

        MinimalText {
          anchors.centerIn: parent
          text: ""
          color: clearGroupArea.containsMouse ? (shell ? shell.red : "#b85f4d") : (shell ? shell.muted : "#cdbeb4")
          font.pixelSize: 10
        }

        MouseArea {
          id: clearGroupArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            for (var i = 0; i < group.items.length; i++) group.items[i].dismiss()
          }
        }

        Behavior on color { ColorAnimation { duration: shell ? shell.motionFast : 110 } }
        Behavior on scale { NumberAnimation { duration: shell ? shell.motionInstant : 90; easing.type: Easing.OutCubic } }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      color: shell ? Qt.rgba(shell.muted.r, shell.muted.g, shell.muted.b, 0.18) : Qt.rgba(0.8, 0.75, 0.71, 0.18)
    }

    Repeater {
      model: group.items
      delegate: NotificationCard {
        shell: group.shell
        notification: modelData
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
    onEntered: group.hovered = true
    onExited: group.hovered = false
  }

  Behavior on color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on border.color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on scale { NumberAnimation { duration: shell ? shell.motionFast : 110; easing.type: Easing.OutCubic } }
}
