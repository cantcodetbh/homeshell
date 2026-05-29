import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "ShellFinder.js" as ShellFinder

Rectangle {
  id: card
  property var shell: null

  Component.onCompleted: { if (shell === null) shell = ShellFinder.findShell(parent) }

  property var notification
  property bool hovered: false
  property bool pressed: false

  Layout.fillWidth: true
  implicitHeight: Math.max(78, content.implicitHeight + 18)
  radius: shell ? shell.cornerRadius : 3
  color: shell ? Qt.rgba(shell.base.r, shell.base.g, shell.base.b, hovered ? 0.76 : 0.58) : Qt.rgba(0.08, 0.07, 0.06, hovered ? 0.76 : 0.58)
  border.width: shell ? shell.uiBorderWidth : 3
  border.color: notification && notification.urgency === NotificationUrgency.Critical
                ? (shell ? Qt.rgba(shell.red.r, shell.red.g, shell.red.b, 0.74) : Qt.rgba(0.72, 0.37, 0.30, 0.74))
                : (shell ? Qt.rgba(shell.muted.r, shell.muted.g, shell.muted.b, hovered ? 0.42 : 0.22) : Qt.rgba(0.8, 0.75, 0.71, hovered ? 0.42 : 0.22))
  scale: pressed ? (shell ? shell.motionPress : 0.996) : hovered ? (shell ? shell.motionLift : 1.006) : 1

  ColumnLayout {
    id: content
    anchors.fill: parent
    anchors.margins: 9
    spacing: 6

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      MinimalText {
        Layout.preferredWidth: 20
        text: shell ? shell.notificationIcon(card.notification) : ""
        color: card.notification && card.notification.urgency === NotificationUrgency.Critical
               ? (shell ? shell.red : "#b85f4d")
               : (shell ? shell.accent : "#a8c5c9")
        font.pixelSize: 13
      }

      MinimalText {
        Layout.fillWidth: true
        text: shell ? shell.cleanNotificationText(card.notification ? (card.notification.appName || "notification") : "notification") : "notification"
        color: shell ? shell.muted : "#cdbeb4"
        font.pixelSize: 9
        horizontalAlignment: Text.AlignLeft
      }

      MinimalText {
        text: shell ? shell.notificationUrgencyText(card.notification) : "normal"
        color: shell ? shell.muted : "#cdbeb4"
        font.pixelSize: 9
        horizontalAlignment: Text.AlignRight
      }

      Rectangle {
        Layout.preferredWidth: 22
        Layout.preferredHeight: 22
        radius: shell ? shell.cornerRadius : 3
        color: closeArea.containsMouse ? (shell ? Qt.rgba(shell.red.r, shell.red.g, shell.red.b, 0.20) : Qt.rgba(0.72, 0.37, 0.30, 0.20)) : "transparent"
        scale: closeArea.containsPress ? (shell ? shell.motionPress : 0.996) : closeArea.containsMouse ? (shell ? shell.motionLift : 1.006) : 1

        MinimalText {
          anchors.centerIn: parent
          text: ""
          color: closeArea.containsMouse ? (shell ? shell.red : "#b85f4d") : (shell ? shell.muted : "#cdbeb4")
          font.pixelSize: 11
        }

        MouseArea {
          id: closeArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: if (card.notification) card.notification.dismiss()
        }

        Behavior on color { ColorAnimation { duration: shell ? shell.motionFast : 110 } }
        Behavior on scale { NumberAnimation { duration: shell ? shell.motionInstant : 90; easing.type: Easing.OutCubic } }
      }
    }

    MinimalText {
      Layout.fillWidth: true
      text: shell ? shell.cleanNotificationText(card.notification ? card.notification.summary : "") : ""
      color: shell ? shell.textColor : "#efe4dc"
      font.pixelSize: 12
      horizontalAlignment: Text.AlignLeft
      wrapMode: Text.WordWrap
    }

    MinimalText {
      visible: text.length > 0
      Layout.fillWidth: true
      Layout.maximumHeight: 44
      text: shell ? shell.cleanNotificationText(card.notification ? card.notification.body : "") : ""
      color: shell ? shell.muted : "#cdbeb4"
      font.pixelSize: 10
      horizontalAlignment: Text.AlignLeft
      verticalAlignment: Text.AlignTop
      wrapMode: Text.WordWrap
      elide: Text.ElideRight
    }

    RowLayout {
      visible: card.notification && card.notification.actions && card.notification.actions.length > 0
      Layout.fillWidth: true
      spacing: 6

      Repeater {
        model: card.notification && card.notification.actions ? card.notification.actions : []
        delegate: Rectangle {
          Layout.preferredHeight: 24
          Layout.minimumWidth: 72
          Layout.fillWidth: true
          radius: shell ? shell.cornerRadius : 3
          color: actionArea.containsMouse
            ? (shell ? Qt.rgba(shell.accent.r, shell.accent.g, shell.accent.b, 0.20) : Qt.rgba(0.66, 0.77, 0.79, 0.20))
            : (shell ? Qt.rgba(shell.baseAlt.r, shell.baseAlt.g, shell.baseAlt.b, 0.54) : Qt.rgba(0.14, 0.11, 0.09, 0.54))
          border.width: shell ? shell.uiBorderWidth : 3
          border.color: shell ? Qt.rgba(shell.accent.r, shell.accent.g, shell.accent.b, 0.28) : Qt.rgba(0.66, 0.77, 0.79, 0.28)
          scale: actionArea.containsPress ? (shell ? shell.motionPress : 0.996) : actionArea.containsMouse ? (shell ? shell.motionLift : 1.006) : 1

          MinimalText {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            text: modelData.text || "action"
            color: actionArea.containsMouse ? (shell ? shell.accent : "#a8c5c9") : (shell ? shell.textColor : "#efe4dc")
            font.pixelSize: 10
          }

          MouseArea {
            id: actionArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: modelData.invoke()
          }

          Behavior on color { ColorAnimation { duration: shell ? shell.motionFast : 110 } }
          Behavior on border.color { ColorAnimation { duration: shell ? shell.motionFast : 110 } }
          Behavior on scale { NumberAnimation { duration: shell ? shell.motionInstant : 90; easing.type: Easing.OutCubic } }
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
    onEntered: card.hovered = true
    onExited: {
      card.hovered = false
      card.pressed = false
    }
  }

  Behavior on color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on border.color { ColorAnimation { duration: shell ? shell.motionBase : 170 } }
  Behavior on scale { NumberAnimation { duration: shell ? shell.motionFast : 110; easing.type: Easing.OutCubic } }
}
