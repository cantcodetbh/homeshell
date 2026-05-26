import QtQuick
import QtQuick.Layouts
import QtQuick.VectorImage

Rectangle {
  id: button
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
  property string value: ""
  property string command: ""
  property string drawer: ""
  property string scrollUpCommand: ""
  property string scrollDownCommand: ""
  property string tooltip: ""
  property string tooltipAnchor: "center"
  property string badgeText: ""
  property string imagePath: ""
  property int iconSize: 15
  property int iconOffsetX: 0
  property int iconOffsetY: 0
  property int iconClipBottom: 0
  property int tooltipBottomMargin: 13
  property int buttonWidth: 34
  property int buttonHeight: 28
  property bool active: false
  property bool activeBorder: true
  property bool backButton: false
  property bool iconSlash: false
  property bool hovered: false
  property bool pressed: false
  property bool rippleRunning: false
  property int rippleX: 0
  property int rippleY: 0
  readonly property bool visualActive: button.active || (button.drawer.length > 0 && shell && shell.drawerMode === button.drawer)

  width: button.buttonWidth
  height: button.buttonHeight
  Layout.preferredWidth: width
  Layout.preferredHeight: height
  radius: shell ? shell.cornerRadius : 3
  color: "transparent"
  border.width: visualActive && activeBorder ? (shell ? shell.uiBorderWidth : 3) : 0
  border.color: visualActive ? (shell ? shell.accent : "#a8c5c9") : (shell ? shell.muted : "#cdbeb4")
  scale: pressed ? (shell ? shell.motionPress : 0.996) : hovered || visualActive ? (shell ? shell.motionLift : 1.006) : 1

  Rectangle {
    id: buttonRipple
    visible: button.rippleRunning
    x: button.rippleX - width / 2
    y: button.rippleY - height / 2
    z: -1
    width: 4
    height: 4
    radius: width / 2
    color: shell ? Qt.rgba(shell.accent.r, shell.accent.g, shell.accent.b, 0.0) : Qt.rgba(0.66, 0.77, 0.79, 0.0)
    border.width: 0

    ParallelAnimation {
      id: rippleAnim
      running: button.rippleRunning
      onStopped: button.rippleRunning = false

      NumberAnimation {
        target: buttonRipple; property: "width"; from: 4; to: Math.max(button.width, button.height) * 2.8
        duration: (shell ? shell.motionBase : 170) + 120; easing.type: Easing.OutCubic
      }
      NumberAnimation {
        target: buttonRipple; property: "height"; from: 4; to: Math.max(button.width, button.height) * 2.8
        duration: (shell ? shell.motionBase : 170) + 120; easing.type: Easing.OutCubic
      }
      NumberAnimation {
        target: buttonRipple; property: "opacity"; from: 0.32; to: 0
        duration: (shell ? shell.motionBase : 170) + 120; easing.type: Easing.OutCubic
      }
      NumberAnimation {
        target: buttonRipple; property: "radius"; from: 2; to: Math.max(button.width, button.height) * 1.4
        duration: (shell ? shell.motionBase : 170) + 120; easing.type: Easing.OutCubic
      }
    }
  }

  MinimalText {
    shell: button.shell
    visible: button.imagePath.length === 0
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: button.iconOffsetX
    anchors.verticalCenterOffset: button.iconOffsetY
    text: button.label
    font.pixelSize: button.iconSize
    color: button.hovered || button.visualActive ? (shell ? shell.accent : "#a8c5c9") : (shell ? shell.muted : "#cdbeb4")
  }

  Rectangle {
    visible: button.iconSlash && button.imagePath.length === 0
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: 3
    anchors.verticalCenterOffset: -1
    width: 2
    height: Math.max(18, button.iconSize + 7)
    radius: 1
    rotation: 45
    color: button.hovered || button.visualActive ? (shell ? shell.accent : "#a8c5c9") : (shell ? shell.muted : "#cdbeb4")
  }

  Rectangle {
    visible: button.iconSlash && button.imagePath.length === 0
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: 3
    anchors.verticalCenterOffset: -1
    width: 2
    height: Math.max(18, button.iconSize + 7)
    radius: 1
    rotation: -45
    color: button.hovered || button.visualActive ? (shell ? shell.accent : "#a8c5c9") : (shell ? shell.muted : "#cdbeb4")
  }

  Rectangle {
    visible: button.badgeText.length > 0
    width: Math.max(12, badgeLabel.implicitWidth + 6)
    height: 12
    radius: shell ? shell.cornerRadius : 3
    anchors.right: parent.right
    anchors.top: parent.top
    color: shell ? shell.red : "#b85f4d"

    MinimalText {
      id: badgeLabel
      shell: button.shell
      anchors.centerIn: parent
      text: button.badgeText
      color: shell ? shell.base : "#15110f"
      font.pixelSize: 8
    }
  }

  Item {
    visible: button.imagePath.length > 0
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: button.iconOffsetX
    anchors.verticalCenterOffset: button.iconOffsetY
    width: button.iconSize + 5
    height: Math.max(1, button.iconSize + 5 - button.iconClipBottom)
    clip: button.iconClipBottom > 0

    VectorImage {
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width
      height: button.iconSize + 5
      fillMode: VectorImage.PreserveAspectFit
      assumeTrustedSource: true
      source: shell ? shell.weatherIconUrl(button.imagePath, false) : ""
      opacity: 1
      animations.loops: -1
      animations.paused: false
      onSourceChanged: animations.restart()
    }

    VectorImage {
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width
      height: button.iconSize + 5
      fillMode: VectorImage.PreserveAspectFit
      assumeTrustedSource: true
      source: shell ? shell.weatherIconUrl(button.imagePath, true) : ""
      opacity: button.hovered || button.visualActive ? 1 : 0
      animations.loops: -1
      animations.paused: false
      onSourceChanged: animations.restart()

      Behavior on opacity { NumberAnimation { duration: shell ? shell.motionFast : 110; easing.type: Easing.OutCubic } }
    }
  }

  Rectangle {
    visible: button.tooltip.length > 0
    z: 20
    width: Math.min(286, Math.max(86, tooltipText.implicitWidth + 18))
    height: 26
    x: button.tooltipAnchor === "left" ? 0 : button.tooltipAnchor === "right" ? button.width - width : (button.width - width) / 2
    radius: shell ? shell.cornerRadius : 3
    color: shell ? Qt.rgba(shell.base.r, shell.base.g, shell.base.b, 0.92) : Qt.rgba(0.08, 0.07, 0.06, 0.92)
    border.width: shell ? shell.uiBorderWidth : 3
    border.color: shell ? Qt.rgba(shell.accent.r, shell.accent.g, shell.accent.b, 0.58) : Qt.rgba(0.66, 0.77, 0.79, 0.58)
    opacity: button.hovered ? 1 : 0
    scale: button.hovered ? 1 : (shell ? shell.motionPress : 0.996)
    anchors.bottom: parent.top
    anchors.bottomMargin: button.tooltipBottomMargin

    MinimalText {
      id: tooltipText
      shell: button.shell
      anchors.fill: parent
      anchors.leftMargin: 9
      anchors.rightMargin: 9
      text: button.tooltip
      color: shell ? shell.textColor : "#efe4dc"
      font.pixelSize: 10
      horizontalAlignment: Text.AlignHCenter
    }

    Behavior on opacity { NumberAnimation { duration: shell ? shell.motionFast : 110; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: shell ? shell.motionFast : 110; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: shell ? shell.motionFast : 110 } }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: (button.backButton || button.command.length > 0 || button.drawer.length > 0) ? Qt.PointingHandCursor : Qt.ArrowCursor
    onEntered: button.hovered = true
    onExited: {
      button.hovered = false
      button.pressed = false
    }
    onPressed: button.pressed = true
    onReleased: button.pressed = false
    onWheel: function(wheel) {
      if (shell && wheel.angleDelta.y > 0 && button.scrollUpCommand.length > 0) {
        shell.runVolume(button.scrollUpCommand)
        wheel.accepted = true
      } else if (shell && wheel.angleDelta.y < 0 && button.scrollDownCommand.length > 0) {
        shell.runVolume(button.scrollDownCommand)
        wheel.accepted = true
      }
    }
    onClicked: {
      button.rippleX = mouse.x
      button.rippleY = mouse.y
      rippleAnim.restart()
      if (shell) {
        if (button.backButton) shell.goBack()
        else if (button.drawer.length > 0) shell.toggleDrawer(button.drawer)
        else if (button.command.length > 0) shell.run(button.command)
      }
    }
  }

  Behavior on color { ColorAnimation { duration: shell ? shell.motionFast : 110 } }
  Behavior on scale { NumberAnimation { duration: shell ? shell.motionFast : 110; easing.type: Easing.OutCubic } }
  Behavior on border.width { NumberAnimation { duration: shell ? shell.motionFast : 110; easing.type: Easing.OutCubic } }
  Behavior on border.color { ColorAnimation { duration: shell ? shell.motionFast : 110 } }
}
