import QtQuick
import QtQuick.Layouts
import "ShellFinder.js" as ShellFinder

Rectangle {
  id: dayCell
  property var shell: null

  Component.onCompleted: { if (shell === null) shell = ShellFinder.findShell(parent) }

  property int day: 0
  property bool today: false
  property bool activeWeek: false

  Layout.fillWidth: true
  Layout.preferredHeight: 27
  radius: shell ? shell.cornerRadius : 3
  color: "transparent"
  scale: today ? (shell ? shell.motionLift : 1.006) : 1

  MinimalText {
    anchors.fill: parent
    text: dayCell.day > 0 ? (dayCell.today ? "[" + String(dayCell.day).padStart(2, " ") + "]" : String(dayCell.day)) : ""
    color: dayCell.activeWeek ? (shell ? shell.accent : "#a8c5c9") : (shell ? shell.textColor : "#efe4dc")
    font.pixelSize: 12
    horizontalAlignment: Text.AlignHCenter
  }

  Behavior on scale { NumberAnimation { duration: shell ? shell.motionBase : 170; easing.type: Easing.OutCubic } }
}
