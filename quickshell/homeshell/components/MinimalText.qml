import QtQuick
import "ShellFinder.js" as ShellFinder

Text {
  id: component
  property var shell: null

  Component.onCompleted: { if (shell === null) shell = ShellFinder.findShell(parent) }

  color: shell ? shell.textColor : "#efe4dc"
  font.family: "JetBrainsMono Nerd Font"
  font.pixelSize: 12
  font.contextFontMerging: true
  verticalAlignment: Text.AlignVCenter
  horizontalAlignment: Text.AlignHCenter
  elide: Text.ElideRight

  Behavior on color { ColorAnimation { duration: shell ? shell.motionFast : 110 } }
}
