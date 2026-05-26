import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.VectorImage
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "components"

ShellRoot {
  id: root

  property string baseDir: Quickshell.shellPath("../..")
  property string preferredScreenName: "HDMI-A-1"
  property var primaryScreen: choosePrimaryScreen()
  property string drawerMode: ""
  property var drawerHistory: []
	  property int drawerKeyboardIndex: 0
	  property bool drawerLayerVisible: false
	  property bool drawerPanelOpen: false
	  property bool drawerClosing: false
  property bool drawerOpening: false
  property bool drawerTransitioning: false
  property string drawerTransitionTarget: ""
	  readonly property bool drawerOpen: drawerMode.length > 0
  property bool shellRaised: false
  property string shellRaisedSide: ""
  property bool calendarTriggerHovered: false
  property int calendarMonthOffset: 0
	  property bool notificationsDnd: false
	  property string powerConfirm: ""
	  property int selectedWorkspaceId: 1
	  readonly property int motionInstant: 90
	  readonly property int motionFast: 110
	  readonly property int motionBase: 400
	  readonly property int motionSlow: 400
	  readonly property int drawerMotionFast: 220
	  readonly property int drawerMotionBase: 360
	  readonly property int drawerMotionSlow: 460
  readonly property int drawerOpenSurface: 220
  readonly property int drawerOpenContent: 400
  readonly property int drawerOpenTotal: 420
  readonly property int drawerCloseContent: 160
  readonly property int drawerCloseSurface: 280
  readonly property int drawerCloseTotal: 440
  readonly property real motionLift: 1.006
  readonly property real motionPress: 0.996
  readonly property int leftBarX: 18
  readonly property int leftBarWidth: 220
  readonly property int leftBarBottom: 18
  readonly property int leftBarHeight: 86
  readonly property int rightBarRight: 18
  readonly property int rightBarWidth: 326
  readonly property int rightBarBottom: 18
  readonly property int rightBarHeight: 44
  readonly property int drawerAttachOverlap: 0
  readonly property int drawerBridgeHeight: 18
  property var status: ({
    "time": "--:--",
    "window": "HomeShell",
    "workspaces": [
      {"id": 1, "name": "1", "windows": 0, "active": true, "urgent": false},
      {"id": 2, "name": "2", "windows": 0, "active": false, "urgent": false},
      {"id": 3, "name": "3", "windows": 0, "active": false, "urgent": false},
      {"id": 4, "name": "4", "windows": 0, "active": false, "urgent": false},
      {"id": 5, "name": "5", "windows": 0, "active": false, "urgent": false}
    ],
    "audio": {"text": "Vol --%", "muted": false},
    "network": {"text": "Net", "detail": ""},
    "clipboard": {"count": 0, "items": []},
    "transfer": {"rx_text": "0B/s", "tx_text": "0B/s", "downloads": []},
    "calendar": {"month": "", "today": "", "weeks": []},
    "processes": {"items": []},
    "power_profile": {"profile": "unknown", "profiles": []},
    "screenshots": {"count": 0, "items": []},
    "hardware": {"cpu": 0, "memory": 0, "disk": 0},
    "weather": {"text": ""},
    "updates": {"text": "0", "available": false},
    "wallpaper": {"current": "", "count": 0, "items": []},
    "theme": {"colors": {"base": "#15110f", "base_alt": "#241b18", "text": "#efe4dc", "muted": "#cdbeb4", "accent": "#a8c5c9", "amber": "#d7a86e", "red": "#b85f4d", "teal": "#7fa8a2"}}
  })

  readonly property var colors: status.theme && status.theme.colors ? status.theme.colors : ({})
  readonly property color base: colors.base || "#15110f"
  readonly property color baseAlt: colors.base_alt || "#241b18"
  readonly property color textColor: colors.text || "#efe4dc"
  readonly property color muted: colors.muted || "#cdbeb4"
  readonly property color accent: colors.accent || "#a8c5c9"
  readonly property color borderAccent: colors.border_accent || accent
  readonly property color amber: colors.amber || "#d7a86e"
  readonly property color red: colors.red || "#b85f4d"
  readonly property color teal: colors.teal || "#7fa8a2"
  readonly property string colorPickerCommand: "command -v hyprpicker >/dev/null && hyprpicker -a"
  readonly property string updateCommand: "if command -v yay >/dev/null; then kitty -e yay -Syu; elif command -v paru >/dev/null; then kitty -e paru -Syu; else kitty -e sudo pacman -Syu; fi"
  readonly property string screenshotCommand: "mkdir -p \"$HOME/Pictures/Screenshots\"; grim -g \"$(slurp)\" \"$HOME/Pictures/Screenshots/shot-$(date +%Y%m%d-%H%M%S).png\""
  readonly property string cliphistCommand: "cliphist list | rofi -dmenu | cliphist decode | wl-copy"
  readonly property string hyprexposeCommand: "command -v hyprexpose-toggle >/dev/null && hyprexpose-toggle"
  readonly property int uiBorderWidth: 3
  readonly property int cornerRadius: 3
  readonly property int hyprFocusedWorkspaceId: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id ? Hyprland.focusedWorkspace.id : 0

		  function choosePrimaryScreen() {
	    var fallback = null
	    for (var i = 0; i < Quickshell.screens.length; i++) {
	      var candidate = Quickshell.screens[i]
	      if (candidate.name === root.preferredScreenName) return candidate
	      if (fallback === null || candidate.width * candidate.height > fallback.width * fallback.height) fallback = candidate
	    }
	    return fallback
	  }

	  function run(command) {
    actionProc.exec(["sh", "-lc", command])
    quickRefresh.restart()
  }

  function activeWorkspaceId() {
    if (root.hyprFocusedWorkspaceId > 0) return root.hyprFocusedWorkspaceId
    if (root.status && root.status.workspaces) {
      for (var i = 0; i < root.status.workspaces.length; i++) {
        var workspace = root.status.workspaces[i] || {}
        if (workspace.active) return workspace.id || 0
      }
    }
    return 0
  }

  function workspaceIsActive(workspace) {
    if (!workspace) return false
    var wid = workspace.id || 0
    if (wid <= 0) return false
    var focused = root.hyprFocusedWorkspaceId
    if (focused > 0) return wid === focused
    return workspace.active === true || wid === root.activeWorkspaceId()
  }

  function runVolume(command) {
    if (!volumeProc.running) volumeProc.exec(["sh", "-lc", command])
  }

  function enterShellSurface(side) {
    shellDemoteTimer.stop()
    shellHideTimer.stop()
    shellRaised = true
    if (side && side.length > 0) shellRaisedSide = side
  }

  function leaveShellSurface() {
    shellHideTimer.restart()
  }

  function hideShellSurfaces() {
    if (drawerOpening) return
    if (drawerMode.length > 0 || drawerClosing) {
      closeDrawer()
      shellDemoteTimer.restart()
    } else {
      shellRaised = false
      shellRaisedSide = ""
    }
  }

  function toggleDrawer(mode) {
    if (drawerMode === mode) {
      closeDrawer()
    } else {
      openDrawer(mode, false)
    }
  }

  function navigateDrawer(mode) {
    if (drawerMode === mode) return
    var history = drawerHistory ? drawerHistory.slice() : []
    if (drawerMode.length > 0) history.push(drawerMode)
    drawerHistory = history
    drawerTransitioning = true
    drawerTransitionTarget = mode
    drawerClosing = true
    drawerPanelOpen = false
    drawerKeyboardIndex = 0
    powerConfirm = ""
    drawerTransitionTimer.restart()
  }

  function goBack() {
    var history = drawerHistory ? drawerHistory.slice() : []
    if (history.length === 0) return
    openDrawer(history.pop(), true)
    drawerHistory = history
    drawerKeyboardIndex = 0
    powerConfirm = ""
  }

	  function openDrawer(mode, keepHistory) {
    enterShellSurface(drawerSide(mode))
    drawerCloseTimer.stop()
    drawerTransitionTimer.stop()
    drawerClosing = false
    drawerOpening = true
    drawerTransitioning = false
    drawerTransitionTarget = ""
    drawerMode = mode
    drawerLayerVisible = mode !== "power"
    drawerPanelOpen = false
    if (!keepHistory) drawerHistory = []
    drawerKeyboardIndex = 0
    powerConfirm = ""
    drawerOpenTimer.restart()
  }

  function closeDrawer() {
    drawerOpenTimer.stop()
    drawerCloseTimer.stop()
    drawerTransitionTimer.stop()
    drawerOpening = false
    drawerClosing = true
    drawerTransitioning = false
    drawerTransitionTarget = ""
    drawerPanelOpen = false
    drawerKeyboardIndex = 0
    powerConfirm = ""
    drawerCloseTimer.restart()
  }

  function recoverDrawerLayer() {
    drawerOpenTimer.stop()
    drawerCloseTimer.stop()
    drawerTransitionTimer.stop()
    drawerOpenResetTimer.stop()
    drawerMode = ""
    drawerHistory = []
    drawerLayerVisible = false
    drawerPanelOpen = false
    drawerClosing = false
    drawerOpening = false
    drawerTransitioning = false
    drawerTransitionTarget = ""
    drawerKeyboardIndex = 0
    powerConfirm = ""
  }

	  function drawerClosedScale(mode) {
	    return 0.78
	  }

	  function drawerContentClosedScale(mode) {
	    return root.drawerClosedScale(mode)
	  }

	  function drawerContentClosedRotation(mode) {
	    return root.drawerClosedRotation(mode)
	  }

	  function drawerContentClosedXOffset(mode) {
	    return 58
	  }

	  function drawerContentClosedYOffset(mode) {
	    return 54
	  }

  function drawerClosedXOffset(mode) {
    var sideSign = root.drawerSide(mode) === "left" ? -1 : 1
    return sideSign * 36
  }

  function drawerClosedBottomOffset(mode) {
    return 44
  }

  function drawerClosedRotation(mode) {
    return 5
  }

  function drawerMotionDuration(mode) {
    return root.drawerMotionBase
  }

  function drawerOpacityDuration(mode) {
    return root.drawerMotionFast
  }

  function drawerEasing(mode) {
    return Easing.OutCubic
  }

  function drawerEasingAmplitude(mode) {
    return 1.0
  }

  function drawerEasingOvershoot(mode) {
    return 1.70158
  }

  function drawerKeyboardCount() {
    if (drawerMode === "control") return 5
    if (drawerMode === "launch") return 6
    if (drawerMode === "overview") return root.allClients().length
    if (drawerMode === "wallpaper") return 5 + (((root.status.wallpaper && root.status.wallpaper.items) ? root.status.wallpaper.items.length : 0))
    if (drawerMode === "theme") return 3 + (((root.status.theme && root.status.theme.candidates) ? root.status.theme.candidates.length : 0))
    if (drawerMode === "audio") return 5
    if (drawerMode === "system") return 7
    if (drawerMode === "transfers") return 3 + (((root.status.transfer && root.status.transfer.downloads) ? root.status.transfer.downloads.length : 0))
    if (drawerMode === "processes") return ((root.status.processes && root.status.processes.items) ? root.status.processes.items.length : 0)
    if (drawerMode === "profiles") return 2 + (((root.status.power_profile && root.status.power_profile.profiles) ? root.status.power_profile.profiles.length : 0))
    if (drawerMode === "screenshots") return 1 + (((root.status.screenshots && root.status.screenshots.items) ? root.status.screenshots.items.length : 0))
    if (drawerMode === "network") return 6 + (((root.status.network && root.status.network.vpn) ? root.status.network.vpn.length : 0))
    if (drawerMode === "clipboard") return 1 + (((root.status.clipboard && root.status.clipboard.items) ? root.status.clipboard.items.length : 0))
    if (drawerMode === "workspace") return 1 + ((root.selectedWorkspace().clients) ? root.selectedWorkspace().clients.length : 0)
    if (drawerMode === "weather") return 0
    if (drawerMode === "notifications") return 3
    return 0
  }

  function moveDrawerSelection(delta) {
    var count = drawerKeyboardCount()
    if (count <= 0) return
    drawerKeyboardIndex = (drawerKeyboardIndex + delta + count) % count
  }

  function activateDrawerSelection() {
    var idx = drawerKeyboardIndex
    if (drawerMode === "control") {
      var controlCommands = [
        "",
        "",
        "",
        root.baseDir + "/scripts/stop && " + root.baseDir + "/scripts/launch",
        ""
      ]
      if (idx < controlCommands.length) root.run(controlCommands[idx])
    } else if (drawerMode === "launch") {
      var launchCommands = ["rofi -show drun", "", "", "", root.colorPickerCommand, ""]
      var launchDrawers = ["", "clipboard", "screenshots", "transfers", "", ""]
      if (launchDrawers[idx]) root.navigateDrawer(launchDrawers[idx])
      else if (launchCommands[idx]) root.run(launchCommands[idx])
    } else if (drawerMode === "overview") {
      var overviewClients = root.allClients()
      if (overviewClients[idx]) root.focusClient(overviewClients[idx])
    } else if (drawerMode === "wallpaper") {
      if (idx === 0) root.run(root.baseDir + "/scripts/wallpaper pick")
      else if (idx === 1) root.run(root.baseDir + "/scripts/wallpaper next")
      else if (idx === 2) root.run(root.baseDir + "/scripts/wallpaper random")
      else if (idx === 3) root.navigateDrawer("theme")
      else if (idx >= 5) {
        var walls = (root.status.wallpaper && root.status.wallpaper.items) ? root.status.wallpaper.items : []
        var wall = walls[idx - 5]
        if (wall) root.run(root.baseDir + "/scripts/wallpaper set '" + String(wall).replace(/'/g, "'\\''") + "'")
      }
    } else if (drawerMode === "theme") {
      var candidates = (root.status.theme && root.status.theme.candidates) ? root.status.theme.candidates : []
      if (idx > 0 && idx <= candidates.length) root.run(root.baseDir + "/scripts/theme-colour set-index " + candidates[idx - 1].index)
      else if (idx === candidates.length + 1) root.run(root.baseDir + "/scripts/theme-colour breed")
      else if (idx === candidates.length + 2) root.run(root.baseDir + "/scripts/theme-colour clear")
    } else if (drawerMode === "audio") {
      var audioCommands = ["pavucontrol", "pactl set-sink-mute @DEFAULT_SINK@ toggle", "pactl set-sink-volume @DEFAULT_SINK@ +5%", "pactl set-sink-volume @DEFAULT_SINK@ -5%", "pactl set-source-mute @DEFAULT_SOURCE@ toggle"]
      if (idx < audioCommands.length) root.run(audioCommands[idx])
    } else if (drawerMode === "system") {
      var systemDrawers = ["", "", "", "network", "processes", "profiles", ""]
      if (systemDrawers[idx]) root.navigateDrawer(systemDrawers[idx])
      else if (idx === 6) root.run(root.updateCommand)
    } else if (drawerMode === "transfers") {
      if (idx === 2) root.run("xdg-open ~/Downloads")
      else if (idx >= 3) {
        var downloads = (root.status.transfer && root.status.transfer.downloads) ? root.status.transfer.downloads : []
        var download = downloads[idx - 3]
        if (download) root.run("xdg-open '" + String(download.path).replace(/'/g, "'\\''") + "'")
      }
    } else if (drawerMode === "processes") {
      var processes = (root.status.processes && root.status.processes.items) ? root.status.processes.items : []
      var process = processes[idx]
      if (process) root.run("kitty --title Process -- sh -lc 'ps -p " + process.pid + " -f; read -r _'")
    } else if (drawerMode === "profiles") {
      var profiles = (root.status.power_profile && root.status.power_profile.profiles) ? root.status.power_profile.profiles : []
      if (idx >= 2 && profiles[idx - 2]) root.run("powerprofilesctl set " + profiles[idx - 2])
    } else if (drawerMode === "screenshots") {
      if (idx === 0) root.run(root.screenshotCommand)
      else {
        var shots = (root.status.screenshots && root.status.screenshots.items) ? root.status.screenshots.items : []
        var shot = shots[idx - 1]
        if (shot) root.run("xdg-open '" + String(shot.path).replace(/'/g, "'\\''") + "'")
      }
    } else if (drawerMode === "network") {
      if (idx === 2) root.run("printf '%s' '" + ((root.status.network && root.status.network.ip) || "") + "' | wl-copy")
      else if (idx === 5) root.run("kitty --title Network -- nmtui")
    } else if (drawerMode === "clipboard") {
      if (idx === 0) root.run(root.cliphistCommand)
      else {
        var clips = (root.status.clipboard && root.status.clipboard.items) ? root.status.clipboard.items : []
        var clip = clips[idx - 1]
        if (clip) root.run("cliphist decode " + clip.id + " | wl-copy")
      }
    } else if (drawerMode === "workspace") {
      if (idx === 0) root.run("hyprctl dispatch workspace " + root.selectedWorkspaceId)
      else {
        var clients = root.selectedWorkspace().clients || []
        var client = clients[idx - 1]
        if (client) root.run("hyprctl dispatch focuswindow address:" + client.address)
      }
    } else if (drawerMode === "notifications") {
      if (idx === 1) root.notificationsDnd = !root.notificationsDnd
      else if (idx === 2) root.dismissAllNotifications()
    }
  }

  function basename(path) {
    var parts = String(path || "").split("/")
    return parts.length ? parts[parts.length - 1] : ""
  }

  function selectedWorkspace() {
    var items = root.status.workspaces || []
    for (var i = 0; i < items.length; i++) {
      if (items[i].id === root.selectedWorkspaceId) return items[i]
    }
    return {"id": root.selectedWorkspaceId, "name": String(root.selectedWorkspaceId), "windows": 0, "clients": []}
  }

  function updatesBadgeText() {
    var text = String((root.status.updates && root.status.updates.text) || "0")
    return text !== "0" && text.length > 0 ? text : ""
  }

  function drawerTitle() {
    if (drawerMode === "launch") return "open"
    if (drawerMode === "overview") return "workspace overview"
    if (drawerMode === "wallpaper") return "wallpaper"
    if (drawerMode === "theme") return "theme colour"
    if (drawerMode === "audio") return "audio"
    if (drawerMode === "system") return "system health"
    if (drawerMode === "network") return "network"
    if (drawerMode === "clipboard") return "clipboard"
    if (drawerMode === "workspace") return "workspace " + root.selectedWorkspaceId
    if (drawerMode === "transfers") return "transfers"
    if (drawerMode === "calendar") return "calendar"
    if (drawerMode === "processes") return "processes"
    if (drawerMode === "profiles") return "power profile"
    if (drawerMode === "screenshots") return "screenshots"
    if (drawerMode === "weather") return "weather"
    if (drawerMode === "notifications") return "notifications"
    if (drawerMode === "power") return "power"
    return "control"
  }

  function drawerSide(mode) {
    if (mode === "weather" || mode === "workspace" || mode === "calendar" || mode === "overview") return "left"
    return "right"
  }

  function drawerOrigin(mode) {
    var side = root.drawerSide(mode)
    if (side === "left") return Item.BottomLeft
    return Item.BottomRight
  }

  function drawerBottomMargin(mode) {
    if (root.drawerSide(mode) === "left") return root.leftBarBottom + root.leftBarHeight - root.drawerAttachOverlap
    return root.rightBarBottom + root.rightBarHeight - root.drawerAttachOverlap
  }

  function drawerBridgeX(mode, panelWidth, parentWidth) {
    if (root.drawerSide(mode) === "left") return root.leftBarX - root.uiBorderWidth
    return parentWidth - root.rightBarRight - root.rightBarWidth - root.uiBorderWidth
  }

  function drawerBridgeWidth(mode, panelWidth) {
    if (root.drawerSide(mode) === "left") return Math.min(panelWidth, root.leftBarWidth + root.uiBorderWidth * 2)
    return Math.min(panelWidth, root.rightBarWidth + root.uiBorderWidth * 2)
  }

  function drawerBridgeBottomMargin(mode) {
    return Math.max(0, root.drawerBottomMargin(mode) - root.drawerBridgeHeight + root.drawerAttachOverlap + root.uiBorderWidth)
  }

  function calendarDate() {
    var now = new Date()
    return new Date(now.getFullYear(), now.getMonth() + calendarMonthOffset, 1)
  }

  function calendarMonthTitle() {
    var date = calendarDate()
    return date.toLocaleDateString(Qt.locale(), "MMMM yyyy").toLowerCase()
  }

  function calendarWeeks() {
    var now = new Date()
    var date = calendarDate()
    var year = date.getFullYear()
    var month = date.getMonth()
    var first = new Date(year, month, 1)
    var days = new Date(year, month + 1, 0).getDate()
    var lead = (first.getDay() + 6) % 7
    var cells = []
    for (var i = 0; i < lead; i++) cells.push({"day": 0, "today": false})
    for (var day = 1; day <= days; day++) {
      cells.push({
        "day": day,
        "today": calendarMonthOffset === 0 && day === now.getDate()
      })
    }
    while (cells.length % 7 !== 0) cells.push({"day": 0, "today": false})
    var weeks = []
    for (var offset = 0; offset < cells.length; offset += 7) weeks.push(cells.slice(offset, offset + 7))
    return weeks
  }

  function moveCalendarMonth(delta) {
    calendarMonthOffset = Math.max(-24, Math.min(24, calendarMonthOffset + delta))
  }

  function weatherIcon() {
    var text = ((root.status.weather && root.status.weather.text) || "") + " " + ((root.status.weather && root.status.weather.tooltip) || "") + " " + ((root.status.weather && root.status.weather.class) || "")
    text = text.toLowerCase()
    if (text.indexOf("thunder") >= 0 || text.indexOf("storm") >= 0) return ""
    if (text.indexOf("snow") >= 0 || text.indexOf("sleet") >= 0 || text.indexOf("ice") >= 0) return ""
    if (text.indexOf("heavy rain") >= 0 || text.indexOf("rain") >= 0 || text.indexOf("shower") >= 0) return ""
    if (text.indexOf("drizzle") >= 0) return ""
    if (text.indexOf("fog") >= 0 || text.indexOf("mist") >= 0) return ""
    if (text.indexOf("cloud") >= 0 || text.indexOf("overcast") >= 0) return "☁"
    if (text.indexOf("clear") >= 0 || text.indexOf("sun") >= 0) return "☀"
    return ""
  }

  function shortWeatherSummary() {
    if (!root.status.weather) return "Weather unavailable"
    var tooltip = root.status.weather.tooltip || ""
    var lines = tooltip.split("\n")
    var place = lines.length > 0 ? lines[0] : ""
    var condition = lines.length > 1 ? lines[1] : "Weather"
    var feels = lines.length > 2 ? lines[2].replace("Feels like ", "feels ") : ""
    var temp = root.status.weather.text || "--"
    var bits = [condition, temp]
    if (feels.length > 0) bits.push(feels)
    return bits.join(" | ")
  }

  function weatherIconUrl(path, active) {
    if (!path || String(path).length === 0) return ""
    var iconPath = active ? String(path).replace(".svg", "-active.svg") : String(path)
    var theme = root.status.theme || {}
    var colors = theme.colors || {}
    var version = String(theme.wallpaper || "") + "-" + String(colors.muted || "") + "-" + String(colors.accent || "")
    return "file://" + iconPath + "?v=" + encodeURIComponent(version)
  }

  function lowerText(value) {
    return String(value || "").toLowerCase()
  }

  function notificationsSummary() {
    var count = qsNotifications.trackedNotifications.values.length
    var groups = root.notificationGroups().length
    var dnd = root.notificationsDnd ? "DND on" : "DND off"
    if (count > 0) return String(count) + " unread / " + String(groups) + " apps | " + dnd
    return "No unread | " + dnd
  }

  function allClients() {
    var result = []
    var workspaces = root.status.workspaces || []
    for (var i = 0; i < workspaces.length; i++) {
      var workspace = workspaces[i] || {}
      var clients = workspace.clients || []
      for (var j = 0; j < clients.length; j++) {
        var client = clients[j] || {}
        result.push({
          "title": client.title || "untitled",
          "class": client.class || "app",
          "address": client.address || "",
          "active": !!client.active,
          "workspaceId": workspace.id || 0,
          "workspaceName": workspace.name || String(workspace.id || ""),
          "x": client.x || 0,
          "y": client.y || 0,
          "w": client.w || 640,
          "h": client.h || 360,
          "floating": !!client.floating,
          "fullscreen": !!client.fullscreen,
        })
      }
    }
    result.sort(function(a, b) {
      if (a.active !== b.active) return a.active ? -1 : 1
      if (a.workspaceId !== b.workspaceId) return a.workspaceId - b.workspaceId
      return String(a.class).localeCompare(String(b.class))
    })
    return result
  }

  function focusClient(client) {
    if (!client || !client.address) return
    root.closeDrawer()
    root.run("hyprctl dispatch focuswindow address:" + client.address)
  }

  function focusWorkspace(workspace) {
    if (!workspace || !workspace.id) return
    root.closeDrawer()
    root.run("hyprctl dispatch workspace " + workspace.id)
  }

  function workspaceClientBounds(clients) {
    var items = clients || []
    if (items.length === 0) return {"x": 0, "y": 0, "w": 1920, "h": 1080}
    var minX = 999999
    var minY = 999999
    var maxX = -999999
    var maxY = -999999
    for (var i = 0; i < items.length; i++) {
      var client = items[i] || {}
      var x = Number(client.x || 0)
      var y = Number(client.y || 0)
      var w = Math.max(1, Number(client.w || 640))
      var h = Math.max(1, Number(client.h || 360))
      minX = Math.min(minX, x)
      minY = Math.min(minY, y)
      maxX = Math.max(maxX, x + w)
      maxY = Math.max(maxY, y + h)
    }
    return {"x": minX, "y": minY, "w": Math.max(1, maxX - minX), "h": Math.max(1, maxY - minY)}
  }

  function previewRect(client, clients, width, height) {
    var bounds = root.workspaceClientBounds(clients)
    var pad = 10
    var scale = Math.min((width - pad * 2) / bounds.w, (height - pad * 2) / bounds.h)
    if (!isFinite(scale) || scale <= 0) scale = 1
    var usedW = bounds.w * scale
    var usedH = bounds.h * scale
    var ox = (width - usedW) / 2
    var oy = (height - usedH) / 2
    return {
      "x": ox + (Number(client.x || 0) - bounds.x) * scale,
      "y": oy + (Number(client.y || 0) - bounds.y) * scale,
      "w": Math.max(42, Number(client.w || 640) * scale),
      "h": Math.max(30, Number(client.h || 360) * scale),
    }
  }

  function hyprToplevelForAddress(address) {
    var needle = String(address || "").toLowerCase()
    if (needle.length === 0 || !Hyprland.toplevels || !Hyprland.toplevels.values) return null
    var items = Hyprland.toplevels.values
    for (var i = 0; i < items.length; i++) {
      var item = items[i]
      if (String(item.address || "").toLowerCase() === needle) return item
    }
    return null
  }

  function waylandToplevelForAddress(address) {
    var item = root.hyprToplevelForAddress(address)
    return item && item.wayland ? item.wayland : null
  }

  function clientSubtitle(client) {
    if (!client) return ""
    var workspace = client.workspaceName || String(client.workspaceId || "")
    return "workspace " + workspace + " | " + (client.class || "app")
  }

  function appInitial(name) {
    var clean = String(name || "app").replace(/^[^A-Za-z0-9]+/, "")
    return clean.length > 0 ? clean.charAt(0).toUpperCase() : "A"
  }

  function notificationGroups() {
    var values = qsNotifications.trackedNotifications.values || []
    var map = {}
    var order = []
    for (var i = 0; i < values.length; i++) {
      var notification = values[i]
      var app = root.cleanNotificationText(notification ? (notification.appName || "notification") : "notification") || "notification"
      if (!map[app]) {
        map[app] = {"app": app, "items": [], "critical": 0}
        order.push(app)
      }
      map[app].items.push(notification)
      if (notification && notification.urgency === NotificationUrgency.Critical) map[app].critical += 1
    }
    var result = []
    for (var j = 0; j < order.length; j++) result.push(map[order[j]])
    result.sort(function(a, b) {
      if (a.critical !== b.critical) return b.critical - a.critical
      if (a.items.length !== b.items.length) return b.items.length - a.items.length
      return a.app.localeCompare(b.app)
    })
    return result
  }

  function cleanNotificationText(text) {
    return String(text || "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim()
  }

  function notificationIcon(notification) {
    var urgency = notification && notification.urgency
    if (urgency === NotificationUrgency.Critical) return ""
    return ""
  }

  function notificationUrgencyText(notification) {
    var urgency = notification && notification.urgency
    if (urgency === NotificationUrgency.Critical) return "critical"
    if (urgency === NotificationUrgency.Low) return "low"
    return "normal"
  }

  function dismissAllNotifications() {
    var items = qsNotifications.trackedNotifications.values.slice()
    for (var i = 0; i < items.length; i++) items[i].dismiss()
    quickRefresh.restart()
  }

  function powerAction(label, command, confirm) {
    if (confirm && powerConfirm !== label) {
      powerConfirm = label
      return
    }
    powerConfirm = ""
    closeDrawer()
    root.run(command)
  }

  property int pollCycle: -1

  function refreshStatus() {
    if (statusProc.running) return
    pollCycle = pollCycle + 1
    if (pollCycle % 8 === 0) {
      statusProc.exec(["python3", root.baseDir + "/scripts/qs-status.py"])
    } else {
      statusProc.exec(["python3", root.baseDir + "/scripts/qs-status.py", "--fast"])
    }
  }

  Process { id: actionProc }

  IpcHandler {
    target: "overview"

    function toggle(): void {
      root.toggleDrawer("overview")
    }

    function open(): void {
      root.openDrawer("overview", false)
    }

    function close(): void {
      root.closeDrawer()
    }
  }

  IpcHandler {
    target: "shell"

    function closeDrawer(): void {
      root.closeDrawer()
    }

    function openDrawer(mode: string): void {
      root.openDrawer(mode, false)
    }

    function toggleDrawer(mode: string): void {
      root.toggleDrawer(mode)
    }

    function refresh(): void {
      quickRefresh.restart()
    }

    function recover(): void {
      root.recoverDrawerLayer()
    }
  }

  Process {
    id: volumeProc
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var payload = this.text.trim()
          if (payload.length > 0) {
            var next = JSON.parse(JSON.stringify(root.status))
            next.audio = JSON.parse(payload)
            root.status = next
          }
        } catch (error) {
          console.log("volume parse failed: " + error)
          quickRefresh.restart()
	      }
	    }
	  }
	}

	Scope {
	  NotificationServer {
	    id: qsNotifications
	    keepOnReload: true
	    persistenceSupported: true
	    bodySupported: true
	    bodyMarkupSupported: true
	    actionsSupported: true
	    actionIconsSupported: true
	    imageSupported: true
	    onNotification: function(notification) {
	      if (root.notificationsDnd) {
	        notification.dismiss()
	        return
	      }
	      notification.tracked = true
	    }
	  }
	}

	Process {
    id: statusProc
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var payload = this.text.trim()
          if (payload.length > 0) {
            var incoming = JSON.parse(payload)
            var oldStatus = root.status
            var merged = {}
            for (var k in oldStatus) merged[k] = oldStatus[k]
            for (var k in incoming) merged[k] = incoming[k]
            root.status = merged
          }
        } catch (error) {
          console.log("status parse failed: " + error)
	      }
	    }
	  }
	}

	Timer {
    interval: 250
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshStatus()
  }

  Timer {
    id: quickRefresh
    interval: 120
    repeat: false
    onTriggered: root.refreshStatus()
  }

  Timer {
    id: drawerOpenTimer
    interval: 16
    repeat: false
    onTriggered: {
      root.drawerPanelOpen = true
      drawerOpenResetTimer.restart()
    }
  }

  Timer {
    id: drawerOpenResetTimer
    interval: root.drawerOpenTotal
    repeat: false
    onTriggered: root.drawerOpening = false
  }

  Timer {
    id: drawerCloseTimer
    interval: root.drawerCloseTotal
    repeat: false
    onTriggered: {
      root.drawerMode = ""
      root.drawerHistory = []
      root.drawerLayerVisible = false
      root.drawerPanelOpen = false
      root.drawerClosing = false
      root.drawerOpening = false
    }
  }

  Timer {
    id: drawerTransitionTimer
    interval: root.drawerCloseContent
    repeat: false
    onTriggered: {
      root.drawerMode = root.drawerTransitionTarget
      root.drawerTransitionTarget = ""
      root.drawerTransitioning = false
      root.drawerClosing = false
      root.drawerOpening = true
      root.drawerPanelOpen = false
      root.drawerKeyboardIndex = 0
      root.powerConfirm = ""
      drawerOpenTimer.restart()
    }
  }

  Timer {
    id: shellHideTimer
    interval: 450
    repeat: false
    onTriggered: root.hideShellSurfaces()
  }

  Timer {
    id: shellDemoteTimer
    interval: root.drawerCloseTotal
    repeat: false
    onTriggered: {
      root.shellRaised = false
      root.shellRaisedSide = ""
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      property var modelData
      screen: modelData
      WlrLayershell.namespace: "quickshell-bar"
      implicitWidth: 360
      implicitHeight: 132
      color: "transparent"
      aboveWindows: root.shellRaised && root.shellRaisedSide === "left"
      exclusiveZone: 0

      anchors {
        left: true
        bottom: true
      }

      margins {
        left: 18
        bottom: 18
      }

      Rectangle {
        width: root.leftBarWidth
        height: 86
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        radius: root.cornerRadius
        antialiasing: true
        color: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.74)
        border.width: root.uiBorderWidth
        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.42)
        opacity: root.drawerPanelOpen && root.drawerSide(root.drawerMode) === "left" ? 0 : 1
        transformOrigin: Item.BottomLeft
        scale: 1
        transform: Translate {
          x: 0
          y: 0
        }

        Behavior on color { ColorAnimation { duration: root.motionBase } }
        Behavior on border.color { ColorAnimation { duration: root.motionBase } }
        Behavior on opacity { NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic } }

        HoverHandler {
          onHoveredChanged: hovered ? root.enterShellSurface("left") : root.leaveShellSurface()
        }

        ColumnLayout {
          z: 10
          anchors.fill: parent
          anchors.margins: 10
          anchors.rightMargin: 78
          spacing: 9

          RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 10
            spacing: 5
            Repeater {
              model: root.status.workspaces
              delegate: WorkspaceMark { shell: root;
                wid: modelData.id
                label: modelData.name || String(modelData.id)
                active: root.workspaceIsActive(modelData)
                urgent: modelData.urgent
                windows: modelData.windows || 0
              }
            }
          }

          MinimalText { shell: root;
            id: timeText
            Layout.fillWidth: true
            Layout.preferredHeight: 18
            text: root.status.time || "--:--"
            color: root.calendarTriggerHovered || root.drawerMode === "calendar" ? root.accent : root.textColor
            font.pixelSize: 16
            horizontalAlignment: Text.AlignLeft
          }

          MinimalText { shell: root;
            id: dayText
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            text: root.status.window || "HomeShell"
            color: root.muted
            font.pixelSize: 9
            horizontalAlignment: Text.AlignLeft
          }
        }

        MouseArea {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.margins: 10
          anchors.rightMargin: 78
          anchors.topMargin: 38
          anchors.bottomMargin: 24
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: root.calendarTriggerHovered = true
          onExited: root.calendarTriggerHovered = false
          onClicked: root.toggleDrawer("calendar")
        }

        AmbientButton {
          shell: root
          z: 1
          anchors.right: parent.right
          anchors.rightMargin: 2
          anchors.verticalCenter: parent.verticalCenter
          buttonWidth: 88
          buttonHeight: 88
          imagePath: (root.status.weather && root.status.weather.icon_path) || ""
          label: root.weatherIcon()
          iconSize: 74
          iconOffsetY: -4
          iconClipBottom: 11
          drawer: "weather"
          active: root.drawerMode === "weather"
          tooltip: root.shortWeatherSummary()
          tooltipAnchor: "center"
          tooltipBottomMargin: 3
          activeBorder: false
        }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      property var modelData
      screen: modelData
      WlrLayershell.namespace: "quickshell-bar"
      implicitWidth: 430
      implicitHeight: 78
      color: "transparent"
      aboveWindows: root.shellRaised && root.shellRaisedSide === "right"
      exclusiveZone: 0

      anchors {
        right: true
        bottom: true
      }

      margins {
        right: -34
        bottom: 18
      }

      Item {
        anchors.fill: parent

        Rectangle {
        width: root.rightBarWidth
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        height: 44
        radius: root.cornerRadius
        color: root.drawerOpen && root.drawerSide(root.drawerMode) === "right" ? Qt.rgba(root.base.r, root.base.g, root.base.b, 0.74) : Qt.rgba(root.baseAlt.r, root.baseAlt.g, root.baseAlt.b, 0.74)
        border.width: root.uiBorderWidth
        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.42)
        opacity: root.drawerPanelOpen && root.drawerSide(root.drawerMode) === "right" ? 0 : 1
        transformOrigin: Item.BottomRight
        scale: 1
        transform: Translate {
          x: 0
          y: 0
        }

        Behavior on color { ColorAnimation { duration: root.motionBase } }
        Behavior on border.color { ColorAnimation { duration: root.motionBase } }
        Behavior on opacity { NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic } }

        HoverHandler {
          onHoveredChanged: hovered ? root.enterShellSurface("right") : root.leaveShellSurface()
        }

        Row {
          anchors.centerIn: parent
          spacing: 4

          AmbientButton {
            shell: root
            label: ""
            iconSize: 17
            drawer: "notifications"
            tooltip: root.notificationsSummary()
            tooltipAnchor: "left"
            active: qsNotifications.trackedNotifications.values.length > 0
            activeBorder: false
          }
          AmbientButton { shell: root; label: ""; iconSize: 17; drawer: "launch"; tooltip: "Launch apps and tools" }
          AmbientButton { shell: root; label: ""; iconSize: 17; drawer: "wallpaper"; tooltip: "Wallpaper controls" }
          AmbientButton { shell: root; label: ""; iconSize: 17; drawer: "system"; badgeText: root.updatesBadgeText(); tooltip: "CPU " + String(root.status.hardware.cpu || 0) + "% | RAM " + String(root.status.hardware.memory || 0) + "% | Disk " + String(root.status.hardware.disk || 0) + "%" }
          AmbientButton {
            shell: root
            label: (root.status.audio && root.status.audio.icon) || ""
            iconSize: 17
            drawer: "audio"
            active: root.status.audio && root.status.audio.muted
            activeBorder: false
            iconSlash: root.status.audio && root.status.audio.muted
            tooltip: (root.status.audio && root.status.audio.text) || "Audio"
            scrollUpCommand: root.baseDir + "/scripts/audio-volume up 5"
            scrollDownCommand: root.baseDir + "/scripts/audio-volume down 5"
          }
          AmbientButton { shell: root; label: ""; iconSize: 17; drawer: "control"; tooltip: "Shell controls" }
          AmbientButton { shell: root; label: "⏻"; iconSize: 17; drawer: "power"; tooltip: "Power menu"; tooltipAnchor: "right" }
        }
        }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      property var modelData
      screen: modelData
      WlrLayershell.namespace: "quickshell-left-hotcorner"
      implicitWidth: 12
      implicitHeight: 12
      color: "transparent"
      aboveWindows: true
      exclusiveZone: 0

      anchors {
        left: true
        bottom: true
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.enterShellSurface("left")
        onExited: root.leaveShellSurface()
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      property var modelData
      screen: modelData
      WlrLayershell.namespace: "quickshell-right-hotcorner"
      implicitWidth: 12
      implicitHeight: 12
      color: "transparent"
      aboveWindows: true
      exclusiveZone: 0

      anchors {
        right: true
        bottom: true
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.enterShellSurface("right")
        onExited: root.leaveShellSurface()
      }
    }
  }

  PanelWindow {
    id: drawer
    screen: root.primaryScreen
    WlrLayershell.namespace: "quickshell-drawer"
    visible: root.drawerLayerVisible && root.drawerMode !== "power" && root.drawerMode !== "overview"
    implicitWidth: root.primaryScreen ? root.primaryScreen.width : 1920
    implicitHeight: root.primaryScreen ? root.primaryScreen.height : 1080
    color: "transparent"
    aboveWindows: root.shellRaised
    focusable: true
    exclusiveZone: 0

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    margins {
      left: 0
      right: 0
      top: 0
      bottom: 0
    }

    Item {
      id: drawerBackdrop
      anchors.fill: parent
      readonly property int panelWidth: root.drawerMode === "calendar" ? 292 : root.drawerMode === "notifications" ? 560 : 420
      readonly property int panelHeight: root.drawerMode === "calendar" ? 356 : (root.drawerMode === "theme" || root.drawerMode === "weather" || root.drawerMode === "clipboard" || root.drawerMode === "notifications") ? 540 : 430
      focus: true
      Keys.onEscapePressed: {
        root.closeDrawer()
      }
      Keys.onUpPressed: root.moveDrawerSelection(-1)
      Keys.onDownPressed: root.moveDrawerSelection(1)
      Keys.onReturnPressed: root.activateDrawerSelection()
      Keys.onEnterPressed: root.activateDrawerSelection()
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Backspace) {
          root.goBack()
          event.accepted = true
        } else if (root.drawerMode === "calendar" && event.key === Qt.Key_Left) {
          root.moveCalendarMonth(-1)
          event.accepted = true
        } else if (root.drawerMode === "calendar" && event.key === Qt.Key_Right) {
          root.moveCalendarMonth(1)
          event.accepted = true
        }
      }

      onVisibleChanged: if (visible) forceActiveFocus()

      MouseArea {
        anchors.fill: parent
        onClicked: root.closeDrawer()
      }

      readonly property real safeX: Math.min(drawerPanel.x, drawerAttachedBar.x)
      readonly property real safeY: Math.min(drawerPanel.y, drawerAttachedBar.y)
      readonly property real safeRight: Math.max(drawerPanel.x + drawerPanel.width, drawerAttachedBar.x + drawerAttachedBar.width)
      readonly property real safeBottom: Math.max(drawerPanel.y + drawerPanel.height, drawerAttachedBar.y + drawerAttachedBar.height)

      MouseArea {
        z: 0.5
        x: 0
        y: 0
        width: parent.width
        height: Math.max(0, drawerBackdrop.safeY)
        hoverEnabled: true
        onEntered: root.leaveShellSurface()
      }

      MouseArea {
        z: 0.5
        x: 0
        y: drawerBackdrop.safeBottom
        width: parent.width
        height: Math.max(0, parent.height - drawerBackdrop.safeBottom)
        hoverEnabled: true
        onEntered: root.leaveShellSurface()
      }

      MouseArea {
        z: 0.5
        x: 0
        y: drawerBackdrop.safeY
        width: Math.max(0, drawerBackdrop.safeX)
        height: Math.max(0, drawerBackdrop.safeBottom - drawerBackdrop.safeY)
        hoverEnabled: true
        onEntered: root.leaveShellSurface()
      }

      MouseArea {
        z: 0.5
        x: drawerBackdrop.safeRight
        y: drawerBackdrop.safeY
        width: Math.max(0, parent.width - drawerBackdrop.safeRight)
        height: Math.max(0, drawerBackdrop.safeBottom - drawerBackdrop.safeY)
        hoverEnabled: true
        onEntered: root.leaveShellSurface()
      }



      Rectangle {
        id: drawerBridge
        visible: false
        z: 4
        width: root.drawerBridgeWidth(root.drawerMode, drawerPanel.width)
        height: root.drawerBridgeHeight
        x: root.drawerBridgeX(root.drawerMode, drawerPanel.width, parent.width)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.drawerBridgeBottomMargin(root.drawerMode)
        radius: root.cornerRadius
        color: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.74)
        opacity: root.drawerPanelOpen ? 1 : 0
        transformOrigin: root.drawerOrigin(root.drawerMode)
        scale: root.drawerPanelOpen ? 1 : root.motionPress

        Behavior on scale { NumberAnimation { duration: root.motionBase; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: root.motionBase } }
      }

      Shape {
        id: drawerSurface
        visible: true
        z: 1
        anchors.fill: parent
        opacity: root.drawerPanelOpen ? 1 : 0
        transform: Scale {
          id: drawerSurfaceScale
          origin.x: drawerSurface.leftSide ? drawerSurface.barX : drawerSurface.barX + drawerSurface.barW
          origin.y: drawerSurface.barBottom
          xScale: root.drawerPanelOpen ? 1 : 0
          yScale: root.drawerPanelOpen ? 1 : 0

          Behavior on yScale { NumberAnimation { duration: root.drawerOpening ? root.drawerOpenSurface : root.drawerClosing ? root.drawerCloseSurface : root.drawerMotionBase; easing.type: root.drawerOpening ? Easing.OutCubic : root.drawerClosing ? Easing.InCubic : Easing.OutCubic } }
          Behavior on xScale { NumberAnimation { duration: root.drawerOpening ? root.drawerOpenSurface : root.drawerClosing ? root.drawerCloseSurface : root.drawerMotionBase; easing.type: root.drawerOpening ? Easing.OutCubic : root.drawerClosing ? Easing.InCubic : Easing.OutCubic } }
        }

        readonly property bool leftSide: root.drawerSide(root.drawerMode) === "left"
        readonly property real panelX: drawerPanel.x
        readonly property real panelY: drawerPanel.y
        readonly property real panelRight: drawerPanel.x + drawerPanel.width
        readonly property real panelBottom: drawerPanel.y + drawerPanel.height
        readonly property real barX: leftSide ? root.leftBarX : parent.width - root.rightBarRight - root.rightBarWidth
        readonly property real barW: leftSide ? root.leftBarWidth : root.rightBarWidth
        readonly property real barH: leftSide ? root.leftBarHeight : root.rightBarHeight
        readonly property real barBottomMargin: leftSide ? root.leftBarBottom : root.rightBarBottom
        readonly property real barBottom: parent.height - barBottomMargin
        readonly property real barY: barBottom - barH

        ShapePath {
          strokeWidth: root.uiBorderWidth
          strokeColor: Qt.rgba(root.borderAccent.r, root.borderAccent.g, root.borderAccent.b, 0.87)
          fillColor: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.74)
          joinStyle: ShapePath.RoundJoin
          capStyle: ShapePath.RoundCap
          startX: drawerSurface.panelX
          startY: drawerSurface.panelY

          PathLine { x: drawerSurface.panelRight; y: drawerSurface.panelY }
          PathLine { x: drawerSurface.panelRight; y: drawerSurface.leftSide ? drawerSurface.panelBottom : drawerSurface.barBottom }
          PathLine { x: drawerSurface.leftSide ? drawerSurface.barX + drawerSurface.barW : drawerSurface.barX; y: drawerSurface.leftSide ? drawerSurface.panelBottom : drawerSurface.barBottom }
          PathLine { x: drawerSurface.leftSide ? drawerSurface.barX + drawerSurface.barW : drawerSurface.barX; y: drawerSurface.leftSide ? drawerSurface.barBottom : drawerSurface.panelBottom }
          PathLine { x: drawerSurface.leftSide ? drawerSurface.barX : drawerSurface.panelX; y: drawerSurface.leftSide ? drawerSurface.barBottom : drawerSurface.panelBottom }
          PathLine { x: drawerSurface.panelX; y: drawerSurface.panelY }
        }        Behavior on opacity { NumberAnimation { duration: root.drawerOpening ? root.drawerOpenSurface : root.drawerClosing ? root.drawerCloseSurface : root.drawerMotionFast; easing.type: root.drawerOpening ? Easing.OutCubic : root.drawerClosing ? Easing.InCubic : Easing.OutCubic } }
      }

      Rectangle {
        id: drawerPanel
        z: 2
        width: drawerBackdrop.panelWidth
        height: drawerBackdrop.panelHeight
        x: root.drawerSide(root.drawerMode) === "left" ? root.leftBarX : parent.width - root.rightBarRight - width
        y: parent.height - root.drawerBottomMargin(root.drawerMode) - height
        radius: root.cornerRadius
        color: "transparent"
        border.width: 0
        border.color: "transparent"
        transformOrigin: root.drawerOrigin(root.drawerMode)
        opacity: 1

        Behavior on color { ColorAnimation { duration: root.drawerMotionBase } }
        Behavior on border.color { ColorAnimation { duration: root.drawerMotionBase } }

        HoverHandler {
          onHoveredChanged: if (hovered) root.enterShellSurface(root.drawerSide(root.drawerMode))
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons
          hoverEnabled: true
          onEntered: root.enterShellSurface(root.drawerSide(root.drawerMode))
          onClicked: mouse.accepted = true
        }

      ColumnLayout {
        id: drawerContent
        anchors.fill: parent
        anchors.margins: 14
        spacing: 9

        opacity: root.drawerPanelOpen ? 1 : 0
        transformOrigin: Item.BottomRight
        transform: Translate {
          id: drawerContentTranslate
          x: root.drawerPanelOpen ? 0 : root.drawerContentClosedXOffset(root.drawerMode)
          y: root.drawerPanelOpen ? 0 : root.drawerContentClosedYOffset(root.drawerMode)

          Behavior on x { NumberAnimation { duration: root.drawerOpening ? root.drawerOpenContent : root.drawerClosing ? root.drawerCloseContent : root.drawerMotionDuration(root.drawerMode); easing.type: root.drawerOpening ? Easing.OutCubic : root.drawerClosing ? Easing.InBack : root.drawerEasing(root.drawerMode); easing.amplitude: root.drawerClosing ? 1.0 : root.drawerEasingAmplitude(root.drawerMode); easing.overshoot: root.drawerClosing ? 0.4 : root.drawerEasingOvershoot(root.drawerMode) } }
          Behavior on y { NumberAnimation { duration: root.drawerOpening ? root.drawerOpenContent : root.drawerClosing ? root.drawerCloseContent : root.drawerMotionDuration(root.drawerMode); easing.type: root.drawerOpening ? Easing.OutCubic : root.drawerClosing ? Easing.InBack : root.drawerEasing(root.drawerMode); easing.amplitude: root.drawerClosing ? 1.0 : root.drawerEasingAmplitude(root.drawerMode); easing.overshoot: root.drawerClosing ? 0.4 : root.drawerEasingOvershoot(root.drawerMode) } }
        }
        scale: root.drawerPanelOpen ? 1 : root.drawerContentClosedScale(root.drawerMode)
        rotation: root.drawerPanelOpen ? 0 : root.drawerContentClosedRotation(root.drawerMode)

        Behavior on rotation { NumberAnimation { duration: root.drawerOpening ? root.drawerOpenContent : root.drawerClosing ? root.drawerCloseContent : root.drawerMotionDuration(root.drawerMode); easing.type: root.drawerOpening ? Easing.OutCubic : root.drawerClosing ? Easing.InCubic : root.drawerEasing(root.drawerMode); easing.overshoot: root.drawerClosing ? 0 : root.drawerEasingOvershoot(root.drawerMode) } }
        Behavior on scale { NumberAnimation { duration: root.drawerOpening ? root.drawerOpenContent : root.drawerClosing ? root.drawerCloseContent : root.drawerMotionDuration(root.drawerMode); easing.type: root.drawerOpening ? Easing.OutCubic : root.drawerClosing ? Easing.InBack : root.drawerEasing(root.drawerMode); easing.overshoot: root.drawerClosing ? 0.4 : root.drawerEasingOvershoot(root.drawerMode) } }
        Behavior on opacity { NumberAnimation { duration: root.drawerOpening ? root.drawerOpenContent : root.drawerClosing ? root.drawerCloseContent : root.drawerOpacityDuration(root.drawerMode); easing.type: root.drawerOpening ? Easing.OutCubic : root.drawerClosing ? Easing.InCubic : Easing.OutCubic } }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: 30
          spacing: 10

          MinimalText { shell: root;
            Layout.fillWidth: true
            text: root.drawerTitle()
            color: root.textColor
            font.pixelSize: 18
            horizontalAlignment: Text.AlignLeft
          }

          AmbientButton { shell: root;
            visible: root.drawerHistory && root.drawerHistory.length > 0
            Layout.preferredWidth: 28
            Layout.preferredHeight: 26
            label: ""
            iconSize: 14
            backButton: true
          }

          AmbientButton { shell: root;
            visible: root.drawerMode === "weather"
            Layout.preferredWidth: 28
            Layout.preferredHeight: 26
            label: ""
            iconSize: 13
            command: root.baseDir + "/scripts/qs-status.py >/dev/null"
            tooltip: "refresh weather"
            tooltipAnchor: "right"
          }

          AmbientButton { shell: root;
            Layout.preferredWidth: 28
            Layout.preferredHeight: 26
            label: ""
            drawer: root.drawerMode
          }
        }

        ColumnLayout {
          visible: root.drawerMode === "control"
          Layout.fillWidth: true
          spacing: 7
          SheetAction { shell: root; keyIndex: 0; label: "theme studio"; detail: "not configured"; command: "" }
          SheetAction { shell: root; keyIndex: 1; label: "keybindings"; detail: "not configured"; command: "" }
          SheetAction { shell: root; keyIndex: 2; label: "model cockpit"; detail: "not configured"; command: "" }
          SheetAction { shell: root; keyIndex: 3; label: "restart shell"; detail: "quickshell"; command: root.baseDir + "/scripts/stop && " + root.baseDir + "/scripts/launch" }
          SheetAction { shell: root; keyIndex: 4; label: "stop shell"; detail: "quickshell"; command: root.baseDir + "/scripts/stop" }
        }

        ColumnLayout {
          visible: root.drawerMode === "launch"
          Layout.fillWidth: true
          spacing: 7
          SheetAction { shell: root; keyIndex: 0; label: "applications"; detail: "rofi"; command: "rofi -show drun" }
          SheetAction { shell: root; keyIndex: 1; label: "clipboard"; detail: String((root.status.clipboard && root.status.clipboard.count) || 0) + " recent"; drawer: "clipboard" }
          SheetAction { shell: root; keyIndex: 2; label: "screenshots"; detail: String((root.status.screenshots && root.status.screenshots.count) || 0) + " recent"; drawer: "screenshots" }
          SheetAction { shell: root; keyIndex: 3; label: "transfers"; detail: "down " + ((root.status.transfer && root.status.transfer.rx_text) || "0B/s"); drawer: "transfers" }
          SheetAction { shell: root; keyIndex: 4; label: "colour picker"; detail: "sample"; command: root.colorPickerCommand }
          SheetAction { shell: root; keyIndex: 5; label: "ai assistant"; detail: "not configured"; command: "" }
        }

        ColumnLayout {
          visible: root.drawerMode === "overview"
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 12

          Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: overviewContent.implicitHeight
            interactive: contentHeight > height

            GridLayout {
              id: overviewContent
              width: parent.width
              columns: width > 1500 ? 3 : width > 900 ? 2 : 1
              columnSpacing: 12
              rowSpacing: 12
              property real cellHeight: Math.max(245, Math.min(360, (drawerPanel.height - 94) / 2))

              MinimalText { shell: root;
                visible: (root.status.workspaces || []).length === 0
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                text: "No workspaces"
                color: root.muted
                font.pixelSize: 13
              }

              Repeater {
                model: root.status.workspaces || []
                delegate: WorkspaceOverviewCard { shell: root;
                  workspace: modelData
                  cardHeight: overviewContent.cellHeight
                }
              }

              Item { width: 1; height: 8 }
            }
          }
        }

        ColumnLayout {
          visible: root.drawerMode === "wallpaper"
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 7
          SheetAction { shell: root; keyIndex: 0; label: "pick wallpaper"; detail: String(root.status.wallpaper.count || 0) + " files"; command: root.baseDir + "/scripts/wallpaper pick" }
          SheetAction { shell: root; keyIndex: 1; label: "next wallpaper"; detail: "avoid repeats"; command: root.baseDir + "/scripts/wallpaper next" }
          SheetAction { shell: root; keyIndex: 2; label: "random wallpaper"; detail: "contrast pick"; command: root.baseDir + "/scripts/wallpaper random" }
          SheetAction { shell: root; keyIndex: 3; label: "theme colour"; detail: "current wallpaper"; drawer: "theme" }

          Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentHeight: wallList.implicitHeight
            interactive: contentHeight > height

            ColumnLayout {
              id: wallList
              width: parent.width
              spacing: 7

              SheetAction { shell: root; keyIndex: 4; label: "current"; detail: root.basename(root.status.wallpaper.current) }
              SheetAction { shell: root; label: "why this one"; detail: (root.status.wallpaper && root.status.wallpaper.intelligence && root.status.wallpaper.intelligence.reason) ? root.status.wallpaper.intelligence.reason : "analysed" }

              Repeater {
                model: (root.status.wallpaper && root.status.wallpaper.items) ? root.status.wallpaper.items : []
                delegate: SheetAction { shell: root;
                  keyIndex: 5 + index
                  label: root.basename(modelData)
                  detail: "set"
                  command: root.baseDir + "/scripts/wallpaper set '" + String(modelData).replace(/'/g, "'\\''") + "'"
                }
              }

              Item { width: 1; height: 8 }
            }
          }
        }

        Flickable {
          visible: root.drawerMode === "theme"
          Layout.fillWidth: true
          Layout.preferredHeight: 424
          Layout.maximumHeight: 424
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          contentWidth: width
          contentHeight: themeScrollContent.implicitHeight
          interactive: contentHeight > height

          ColumnLayout {
            id: themeScrollContent
            width: parent.width
            spacing: 7

            SheetAction { shell: root;
              keyIndex: 0
              label: "current"
              detail: root.status.theme && root.status.theme.colors ? root.status.theme.colors.accent : ""
            }
            SheetAction { shell: root;
              label: "why this palette"
              detail: (root.status.theme && root.status.theme.selected_reason) ? root.status.theme.selected_reason : "wallpaper match"
            }

            RowLayout {
              Layout.fillWidth: true
              Layout.preferredHeight: 42
              spacing: 7

              Rectangle {
                Layout.preferredWidth: 84
                Layout.fillHeight: true
                radius: root.cornerRadius
                color: root.accent
                border.width: root.uiBorderWidth
                border.color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.18)
              }

              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: root.cornerRadius
                color: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.56)
                border.width: root.uiBorderWidth
                border.color: Qt.rgba(root.borderAccent.r, root.borderAccent.g, root.borderAccent.b, 0.87)

                MinimalText { shell: root;
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  text: "border " + ((root.status.theme && root.status.theme.colors && root.status.theme.colors.border_accent) ? root.status.theme.colors.border_accent : "")
                  color: root.textColor
                  horizontalAlignment: Text.AlignLeft
                  font.pixelSize: 10
                }
              }
            }

            Repeater {
              model: (root.status.theme && root.status.theme.candidates) ? root.status.theme.candidates : []
              delegate: ThemeChoice { shell: root;
                keyIndex: index + 1
                sourceIndex: modelData.index
                primary: modelData.primary
                secondary: modelData.secondary
                tertiary: modelData.tertiary
                surface: modelData.surface
                textTone: modelData.text
                selected: root.status.theme && root.status.theme.selected_index === modelData.index
              }
            }

            SheetAction { shell: root;
              keyIndex: ((root.status.theme && root.status.theme.candidates) ? root.status.theme.candidates.length : 0) + 1
              label: "breed palette"
              detail: "select two parents"
              command: root.baseDir + "/scripts/theme-colour breed"
            }

            SheetAction { shell: root;
              keyIndex: ((root.status.theme && root.status.theme.candidates) ? root.status.theme.candidates.length : 0) + 2
              label: "clear override"
              detail: "return to auto"
              command: root.baseDir + "/scripts/theme-colour clear"
            }

            Item { width: 1; height: 8 }
          }
        }

        ColumnLayout {
          visible: root.drawerMode === "audio"
          Layout.fillWidth: true
          spacing: 7
          SheetAction { shell: root; keyIndex: 0; label: "mixer"; detail: root.status.audio.text || "volume"; command: "pavucontrol" }
          SheetAction { shell: root; keyIndex: 1; label: "mute output"; detail: "toggle"; command: "pactl set-sink-mute @DEFAULT_SINK@ toggle" }
          SheetAction { shell: root; keyIndex: 2; label: "volume up"; detail: "+5%"; command: "pactl set-sink-volume @DEFAULT_SINK@ +5%" }
          SheetAction { shell: root; keyIndex: 3; label: "volume down"; detail: "-5%"; command: "pactl set-sink-volume @DEFAULT_SINK@ -5%" }
          SheetAction { shell: root; keyIndex: 4; label: "mute mic"; detail: "toggle"; command: "pactl set-source-mute @DEFAULT_SOURCE@ toggle" }
        }

        ColumnLayout {
          visible: root.drawerMode === "system"
          Layout.fillWidth: true
          spacing: 7
          SheetAction { shell: root; keyIndex: 0; label: "cpu"; detail: String(root.status.hardware.cpu || 0) + "%" }
          SheetAction { shell: root; keyIndex: 1; label: "memory"; detail: String(root.status.hardware.memory || 0) + "%" }
          SheetAction { shell: root; keyIndex: 2; label: "disk"; detail: String(root.status.hardware.disk || 0) + "%" }
          SheetAction { shell: root; keyIndex: 3; label: "network"; detail: root.status.network.text || "net"; drawer: "network" }
          SheetAction { shell: root; keyIndex: 4; label: "processes"; detail: "top cpu"; drawer: "processes" }
          SheetAction { shell: root; keyIndex: 5; label: "power profile"; detail: (root.status.power_profile && root.status.power_profile.profile) || "unknown"; drawer: "profiles" }
          SheetAction { shell: root; keyIndex: 6; label: "updates"; detail: (root.status.updates && root.status.updates.text) || "0"; command: root.updateCommand }
        }

        ColumnLayout {
          visible: root.drawerMode === "transfers"
          Layout.fillWidth: true
          spacing: 7
          SheetAction { shell: root; keyIndex: 0; label: "download"; detail: (root.status.transfer && root.status.transfer.rx_text) || "0B/s" }
          SheetAction { shell: root; keyIndex: 1; label: "upload"; detail: (root.status.transfer && root.status.transfer.tx_text) || "0B/s" }
          SheetAction { shell: root; keyIndex: 2; label: "open downloads"; detail: "folder"; command: "xdg-open ~/Downloads" }
          Repeater {
            model: (root.status.transfer && root.status.transfer.downloads) ? root.status.transfer.downloads : []
            delegate: SheetAction { shell: root;
              keyIndex: index + 3
              label: modelData.name
              detail: modelData.age
              command: "xdg-open '" + String(modelData.path).replace(/'/g, "'\\''") + "'"
            }
          }
        }

        ColumnLayout {
          visible: root.drawerMode === "calendar"
          Layout.fillWidth: true
          spacing: 6

          RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            spacing: 6

            Rectangle {
              Layout.preferredWidth: 24
              Layout.preferredHeight: 22
              radius: root.cornerRadius
              color: prevMonthArea.containsMouse ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14) : "transparent"
              scale: prevMonthArea.containsPress ? root.motionPress : prevMonthArea.containsMouse ? root.motionLift : 1

              MinimalText { shell: root;
                anchors.centerIn: parent
                text: ""
                color: prevMonthArea.containsMouse ? root.accent : root.muted
                font.pixelSize: 10
              }

              MouseArea {
                id: prevMonthArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.moveCalendarMonth(-1)
              }

              Behavior on color { ColorAnimation { duration: root.motionFast } }
              Behavior on scale { NumberAnimation { duration: root.motionInstant; easing.type: Easing.OutCubic } }
            }

            MinimalText { shell: root;
              Layout.fillWidth: true
              text: root.calendarMonthTitle()
              color: root.textColor
              font.pixelSize: 13
              horizontalAlignment: Text.AlignLeft
            }

            Rectangle {
              Layout.preferredWidth: 24
              Layout.preferredHeight: 22
              radius: root.cornerRadius
              color: nextMonthArea.containsMouse ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14) : "transparent"
              scale: nextMonthArea.containsPress ? root.motionPress : nextMonthArea.containsMouse ? root.motionLift : 1

              MinimalText { shell: root;
                anchors.centerIn: parent
                text: ""
                color: nextMonthArea.containsMouse ? root.accent : root.muted
                font.pixelSize: 10
              }

              MouseArea {
                id: nextMonthArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.moveCalendarMonth(1)
              }

              Behavior on color { ColorAnimation { duration: root.motionFast } }
              Behavior on scale { NumberAnimation { duration: root.motionInstant; easing.type: Easing.OutCubic } }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 18
            spacing: 4
            Repeater {
              model: ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
              delegate: MinimalText { shell: root;
                Layout.fillWidth: true
                text: modelData
                color: root.muted
                font.pixelSize: 9
              }
            }
          }

          Repeater {
            model: root.calendarWeeks()
            delegate: RowLayout {
              property bool activeWeek: modelData.some(function(d) { return d.today })
              Layout.fillWidth: true
              Layout.preferredHeight: 27
              spacing: 4

              Repeater {
                model: modelData
                delegate: CalendarDay { shell: root;
                  day: modelData.day
                  today: modelData.today
                  activeWeek: parent.activeWeek
        }
      }

    }
  }
        }

        ColumnLayout {
          visible: root.drawerMode === "processes"
          Layout.fillWidth: true
          spacing: 7
          Repeater {
            model: (root.status.processes && root.status.processes.items) ? root.status.processes.items : []
            delegate: SheetAction { shell: root;
              keyIndex: index
              label: modelData.name
              detail: "cpu " + modelData.cpu + "% mem " + modelData.mem + "%"
              command: "kitty --title Process -- sh -lc 'ps -p " + modelData.pid + " -f; read -r _'"
            }
          }
        }

        ColumnLayout {
          visible: root.drawerMode === "profiles"
          Layout.fillWidth: true
          spacing: 7
          SheetAction { shell: root; keyIndex: 0; label: "current"; detail: (root.status.power_profile && root.status.power_profile.profile) || "unknown" }
          SheetAction { shell: root; keyIndex: 1; label: "governor"; detail: (root.status.power_profile && root.status.power_profile.governor) || "--" }
          Repeater {
            model: (root.status.power_profile && root.status.power_profile.profiles) ? root.status.power_profile.profiles : []
            delegate: SheetAction { shell: root;
              keyIndex: index + 2
              label: modelData
              detail: "set"
              command: "powerprofilesctl set " + modelData
            }
          }
        }

        Flickable {
          visible: root.drawerMode === "screenshots"
          Layout.fillWidth: true
          Layout.preferredHeight: 424
          Layout.maximumHeight: 424
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          contentWidth: width
          contentHeight: screenshotContent.implicitHeight
          interactive: contentHeight > height

          ColumnLayout {
            id: screenshotContent
            width: parent.width
            spacing: 7
            SheetAction { shell: root; keyIndex: 0; label: "capture"; detail: "new"; command: root.screenshotCommand }
            Repeater {
              model: (root.status.screenshots && root.status.screenshots.items) ? root.status.screenshots.items : []
              delegate: SheetAction { shell: root;
                keyIndex: index + 1
                label: modelData.name
                detail: modelData.time
                command: "xdg-open '" + String(modelData.path).replace(/'/g, "'\\''") + "'"
              }
            }
          }
        }

        ColumnLayout {
          visible: root.drawerMode === "network"
          Layout.fillWidth: true
          spacing: 7
          SheetAction { shell: root; keyIndex: 0; label: "connection"; detail: (root.status.network && root.status.network.connection) || "--" }
          SheetAction { shell: root; keyIndex: 1; label: "device"; detail: ((root.status.network && root.status.network.device) || "--") + " " + ((root.status.network && root.status.network.kind) || "") }
          SheetAction { shell: root; keyIndex: 2; label: "ip address"; detail: (root.status.network && root.status.network.ip) || "--"; command: "printf '%s' '" + ((root.status.network && root.status.network.ip) || "") + "' | wl-copy" }
          SheetAction { shell: root; keyIndex: 3; label: "gateway"; detail: (root.status.network && root.status.network.gateway) || "--" }
          SheetAction { shell: root; keyIndex: 4; label: "dns"; detail: (root.status.network && root.status.network.dns) || "--" }
          SheetAction { shell: root; keyIndex: 5; label: "nmtui"; detail: "manage"; command: "kitty --title Network -- nmtui" }

          Repeater {
            model: (root.status.network && root.status.network.vpn) ? root.status.network.vpn : []
            delegate: SheetAction { shell: root;
              keyIndex: index + 6
              label: modelData.device
              detail: modelData.kind + " " + modelData.state
            }
          }
        }

        Flickable {
          visible: root.drawerMode === "clipboard"
          Layout.fillWidth: true
          Layout.preferredHeight: 458
          Layout.maximumHeight: 458
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          contentWidth: width
          contentHeight: clipboardContent.implicitHeight
          interactive: contentHeight > height

          ColumnLayout {
            id: clipboardContent
            width: parent.width
            spacing: 7

            SheetAction { shell: root; keyIndex: 0; label: "open cliphist"; detail: "full history"; command: root.cliphistCommand }

            Repeater {
              model: (root.status.clipboard && root.status.clipboard.items) ? root.status.clipboard.items : []
              delegate: SheetAction { shell: root;
                keyIndex: index + 1
                label: modelData.preview
                detail: "copy"
                command: "cliphist decode " + modelData.id + " | wl-copy"
              }
            }

            Item { width: 1; height: 8 }
          }
        }

        ColumnLayout {
          visible: root.drawerMode === "workspace"
          Layout.fillWidth: true
          spacing: 7
          SheetAction { shell: root;
            keyIndex: 0
            label: "go to workspace"
            detail: String(root.selectedWorkspace().windows || 0) + " windows"
            command: "hyprctl dispatch workspace " + root.selectedWorkspaceId
          }

          Repeater {
            model: root.selectedWorkspace().clients || []
            delegate: SheetAction { shell: root;
              keyIndex: index + 1
              label: modelData.title
              detail: modelData.class + (modelData.active ? " active" : "")
              command: "hyprctl dispatch focuswindow address:" + modelData.address
            }
          }

          MinimalText { shell: root;
            visible: !root.selectedWorkspace().clients || root.selectedWorkspace().clients.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            text: "No windows on this workspace"
            color: root.muted
            horizontalAlignment: Text.AlignLeft
          }
        }

        ColumnLayout {
          visible: root.drawerMode === "weather"
          Layout.fillWidth: true
          spacing: 7
          RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            spacing: 8

            VectorImage {
              Layout.preferredWidth: 38
              Layout.preferredHeight: 38
              fillMode: VectorImage.PreserveAspectFit
              assumeTrustedSource: true
              source: root.weatherIconUrl((root.status.weather && root.status.weather.icon_path) || "", false)
              animations.loops: -1
              animations.paused: false
              onSourceChanged: animations.restart()
            }

            SheetAction { shell: root; Layout.fillWidth: true; label: "now"; detail: root.lowerText((root.status.weather && root.status.weather.text) || "--") }
          }
          SheetAction { shell: root; label: "condition"; detail: root.lowerText((root.status.weather && root.status.weather.condition) || "weather") }
          RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            spacing: 8

            VectorImage {
              Layout.preferredWidth: 38
              Layout.preferredHeight: 38
              fillMode: VectorImage.PreserveAspectFit
              assumeTrustedSource: true
              source: root.weatherIconUrl((root.status.weather && root.status.weather.moon && root.status.weather.moon.icon_path) || "", false)
              animations.loops: -1
              animations.paused: false
              onSourceChanged: animations.restart()
            }

            SheetAction { shell: root;
              Layout.fillWidth: true
              label: "moon"
              detail: root.lowerText(((root.status.weather && root.status.weather.moon && root.status.weather.moon.phase) ? root.status.weather.moon.phase : "--") + ((root.status.weather && root.status.weather.moon && root.status.weather.moon.illumination) ? " " + root.status.weather.moon.illumination + "%" : ""))
            }
          }
          SheetAction { shell: root; label: "sunrise"; detail: root.lowerText((root.status.weather && root.status.weather.sun && root.status.weather.sun.rise) || "--") }
          SheetAction { shell: root; label: "sunset"; detail: root.lowerText((root.status.weather && root.status.weather.sun && root.status.weather.sun.set) || "--") }
          Item { Layout.fillWidth: true; Layout.preferredHeight: 6 }
          MinimalText { shell: root;
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            text: root.lowerText((root.status.weather && root.status.weather.detail) || ((root.status.weather && root.status.weather.tooltip) || "no weather data yet"))
            color: root.textColor
            font.pixelSize: 11
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignTop
            wrapMode: Text.WordWrap
          }
        }

        ColumnLayout {
          visible: root.drawerMode === "notifications"
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 7

          RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 7

            SheetAction { shell: root;
              keyIndex: 0
              Layout.fillWidth: true
              label: "timeline"
              detail: String(qsNotifications.trackedNotifications.values.length) + " in " + String(root.notificationGroups().length) + " apps"
            }

            SheetAction { shell: root;
              keyIndex: 1
              Layout.preferredWidth: 112
              Layout.fillWidth: false
              label: "dnd"
              detail: root.notificationsDnd ? "on" : "off"
              command: ""
              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: parent.hovered = true
                onExited: parent.hovered = false
                onClicked: root.notificationsDnd = !root.notificationsDnd
              }
            }
          }

          Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentHeight: notificationList.implicitHeight
            interactive: contentHeight > height

            ColumnLayout {
              id: notificationList
              width: parent.width
              spacing: 7

              MinimalText { shell: root;
                visible: qsNotifications.trackedNotifications.values.length === 0
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                text: root.notificationsDnd ? "Do not disturb is on" : "No notifications"
                color: root.muted
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
              }

              Repeater {
                model: root.notificationGroups()
                delegate: NotificationGroup { shell: root; groupData: modelData }
              }
            }
          }

          SheetAction { shell: root; keyIndex: 2; label: "clear all"; detail: "dismiss"; command: ""; MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: parent.hovered = true; onExited: parent.hovered = false; onClicked: root.dismissAllNotifications() } }
        }

        ColumnLayout {
          visible: root.drawerMode === "power"
          Layout.fillWidth: true
          spacing: 7

          SheetAction { shell: root;
            label: "lock"
            detail: "screen"
            command: ""
            MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: parent.hovered = true; onExited: parent.hovered = false; onClicked: root.powerAction("lock", "loginctl lock-session", false) }
          }

          SheetAction { shell: root;
            label: "suspend"
            detail: root.powerConfirm === "suspend" ? "click again" : "sleep"
            command: ""
            MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: parent.hovered = true; onExited: parent.hovered = false; onClicked: root.powerAction("suspend", "systemctl suspend", true) }
          }

          SheetAction { shell: root;
            label: "logout"
            detail: root.powerConfirm === "logout" ? "click again" : "hyprland"
            command: ""
            MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: parent.hovered = true; onExited: parent.hovered = false; onClicked: root.powerAction("logout", "hyprctl dispatch exit", true) }
          }

          SheetAction { shell: root;
            label: "reboot"
            detail: root.powerConfirm === "reboot" ? "click again" : "system"
            command: ""
            MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: parent.hovered = true; onExited: parent.hovered = false; onClicked: root.powerAction("reboot", "systemctl reboot", true) }
          }

          SheetAction { shell: root;
            label: "shutdown"
            detail: root.powerConfirm === "shutdown" ? "click again" : "power off"
            command: ""
            MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: parent.hovered = true; onExited: parent.hovered = false; onClicked: root.powerAction("shutdown", "systemctl poweroff", true) }
          }
        }

        Item { Layout.fillHeight: true }

      }

      }

      Item {
        id: drawerAttachedBar
        visible: root.drawerMode.length > 0
        z: 3
        x: root.drawerSide(root.drawerMode) === "left" ? root.leftBarX : parent.width - root.rightBarRight - root.rightBarWidth
        y: parent.height - (root.drawerSide(root.drawerMode) === "left" ? root.leftBarBottom + root.leftBarHeight : root.rightBarBottom + root.rightBarHeight)
        width: root.drawerSide(root.drawerMode) === "left" ? root.leftBarWidth : root.rightBarWidth
        height: root.drawerSide(root.drawerMode) === "left" ? root.leftBarHeight : root.rightBarHeight
        opacity: root.drawerPanelOpen ? 1 : 0

        HoverHandler {
          onHoveredChanged: if (hovered) root.enterShellSurface(root.drawerSide(root.drawerMode))
        }

        Item {
          visible: root.drawerSide(root.drawerMode) === "left"
          anchors.fill: parent

          ColumnLayout {
            z: 10
            anchors.fill: parent
            anchors.margins: 10
            anchors.rightMargin: 78
            spacing: 9

            RowLayout {
              Layout.fillWidth: true
              Layout.preferredHeight: 10
              spacing: 5
              Repeater {
                model: root.status.workspaces
                delegate: WorkspaceMark { shell: root;
                  wid: modelData.id
                  label: modelData.name || String(modelData.id)
                  active: root.workspaceIsActive(modelData)
                  urgent: modelData.urgent
                  windows: modelData.windows || 0
                }
              }
            }

            MinimalText { shell: root;
              Layout.fillWidth: true
              Layout.preferredHeight: 18
              text: root.status.time || "--:--"
              color: root.calendarTriggerHovered || root.drawerMode === "calendar" ? root.accent : root.textColor
              font.pixelSize: 16
              horizontalAlignment: Text.AlignLeft
            }

            MinimalText { shell: root;
              Layout.fillWidth: true
              Layout.preferredHeight: 14
              text: root.status.window || "HomeShell"
              color: root.muted
              font.pixelSize: 9
              horizontalAlignment: Text.AlignLeft
            }
          }

          MouseArea {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 10
            anchors.rightMargin: 78
            anchors.topMargin: 38
            anchors.bottomMargin: 24
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.calendarTriggerHovered = true
            onExited: root.calendarTriggerHovered = false
            onClicked: root.toggleDrawer("calendar")
          }

          AmbientButton {
            shell: root
            z: 1
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            buttonWidth: 88
            buttonHeight: 88
            imagePath: (root.status.weather && root.status.weather.icon_path) || ""
            label: root.weatherIcon()
            iconSize: 74
            iconOffsetY: -4
            iconClipBottom: 11
            drawer: "weather"
            active: root.drawerMode === "weather"
            tooltip: root.shortWeatherSummary()
            tooltipAnchor: "center"
            tooltipBottomMargin: 3
            activeBorder: false
          }
        }

        Row {
          visible: root.drawerSide(root.drawerMode) !== "left"
          anchors.centerIn: parent
          spacing: 4

          AmbientButton {
            shell: root
            label: ""
            iconSize: 17
            drawer: "notifications"
            tooltip: root.notificationsSummary()
            tooltipAnchor: "left"
            active: qsNotifications.trackedNotifications.values.length > 0
            activeBorder: false
          }
          AmbientButton { shell: root; label: ""; iconSize: 17; drawer: "launch"; tooltip: "Launch apps and tools" }
          AmbientButton { shell: root; label: ""; iconSize: 17; drawer: "wallpaper"; tooltip: "Wallpaper controls" }
          AmbientButton { shell: root; label: ""; iconSize: 17; drawer: "system"; badgeText: root.updatesBadgeText(); tooltip: "CPU " + String(root.status.hardware.cpu || 0) + "% | RAM " + String(root.status.hardware.memory || 0) + "% | Disk " + String(root.status.hardware.disk || 0) + "%" }
          AmbientButton {
            shell: root
            label: (root.status.audio && root.status.audio.icon) || ""
            iconSize: 17
            drawer: "audio"
            active: root.status.audio && root.status.audio.muted
            activeBorder: false
            iconSlash: root.status.audio && root.status.audio.muted
            tooltip: (root.status.audio && root.status.audio.text) || "Audio"
            scrollUpCommand: root.baseDir + "/scripts/audio-volume up 5"
            scrollDownCommand: root.baseDir + "/scripts/audio-volume down 5"
          }
          AmbientButton { shell: root; label: ""; iconSize: 17; drawer: "control"; tooltip: "Shell controls" }
          AmbientButton { shell: root; label: "⏻"; iconSize: 17; drawer: "power"; tooltip: "Power menu"; tooltipAnchor: "right" }
        }

        Behavior on opacity { NumberAnimation { duration: root.motionFast; easing.type: Easing.OutCubic } }
      }
    }
  }

  PanelWindow {
    id: overviewOverlay
    screen: root.primaryScreen
    WlrLayershell.namespace: "quickshell-overview"
    visible: root.drawerMode === "overview"
    implicitWidth: root.primaryScreen ? root.primaryScreen.width : 1920
    implicitHeight: root.primaryScreen ? root.primaryScreen.height : 1080
    color: "transparent"
    aboveWindows: root.shellRaised
    focusable: true
    exclusiveZone: 0

    anchors {
      left: true
      right: true
      top: true
      bottom: true
    }

    Rectangle {
      id: overviewBackdrop
      anchors.fill: parent
      focus: true
      color: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.52)
      opacity: root.drawerPanelOpen ? 1 : 0
      Keys.onEscapePressed: root.closeDrawer()
      Keys.onUpPressed: root.moveDrawerSelection(-1)
      Keys.onDownPressed: root.moveDrawerSelection(1)
      Keys.onReturnPressed: root.activateDrawerSelection()
      Keys.onEnterPressed: root.activateDrawerSelection()

      Behavior on color { ColorAnimation { duration: root.motionSlow } }
      Behavior on opacity { NumberAnimation { duration: root.drawerMotionSlow; easing.type: Easing.OutCubic } }

      onVisibleChanged: if (visible) forceActiveFocus()

      MouseArea {
        anchors.fill: parent
        onClicked: root.closeDrawer()
      }

      ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.drawerPanelOpen ? 0 : 18
        width: Math.min(parent.width - 96, 1520)
        height: Math.min(parent.height - 96, 920)
        spacing: 22
        transformOrigin: Item.BottomRight
        scale: root.drawerPanelOpen ? 1 : 0.94
        rotation: root.drawerPanelOpen ? 0 : 1.2
        opacity: root.drawerPanelOpen ? 1 : 0

        HoverHandler {
          onHoveredChanged: hovered ? root.enterShellSurface("right") : root.leaveShellSurface()
        }

        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: root.drawerMotionBase; easing.type: Easing.OutCubic } }
        Behavior on rotation { NumberAnimation { duration: root.drawerMotionBase; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.drawerMotionBase; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: root.drawerMotionFast; easing.type: Easing.OutCubic } }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: 34
          spacing: 10

          MinimalText { shell: root;
            Layout.fillWidth: true
            text: "workspace overview"
            color: root.textColor
            font.pixelSize: 18
            horizontalAlignment: Text.AlignLeft
          }

          MinimalText { shell: root;
            Layout.preferredWidth: 180
            text: String(root.allClients().length) + (root.allClients().length === 1 ? " window" : " windows")
            color: root.muted
            font.pixelSize: 11
            horizontalAlignment: Text.AlignRight
          }

          AmbientButton { shell: root;
            Layout.preferredWidth: 30
            Layout.preferredHeight: 28
            label: ""
            drawer: "overview"
          }
        }

        Flickable {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          contentWidth: width
          contentHeight: overviewOverlayContent.implicitHeight
          interactive: contentHeight > height

          GridLayout {
            id: overviewOverlayContent
            width: parent.width
            columns: width > 1500 ? 3 : width > 900 ? 2 : 1
            columnSpacing: 12
            rowSpacing: 12
            property real cellHeight: Math.max(250, Math.min(360, (parent.height - 12) / 2))

            Repeater {
              model: root.status.workspaces || []
              delegate: WorkspaceOverviewCard { shell: root;
                workspace: modelData
                cardHeight: overviewOverlayContent.cellHeight
              }
            }
          }
        }
      }
    }
  }

  PanelWindow {
    id: powerOverlay
    screen: root.primaryScreen
    WlrLayershell.namespace: "quickshell-power"
    visible: root.drawerMode === "power"
    implicitWidth: root.primaryScreen ? root.primaryScreen.width : 1920
    implicitHeight: root.primaryScreen ? root.primaryScreen.height : 1080
    color: "transparent"
    aboveWindows: root.shellRaised
    focusable: true
    exclusiveZone: 0

    anchors {
      left: true
      right: true
      top: true
      bottom: true
    }

    Rectangle {
      id: powerBackdrop
      anchors.fill: parent
      focus: true
      color: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.52)
      opacity: root.drawerPanelOpen ? 1 : 0
      Keys.onEscapePressed: root.closeDrawer()

      Behavior on color { ColorAnimation { duration: root.motionSlow } }
	      Behavior on opacity { NumberAnimation { duration: root.drawerMotionSlow; easing.type: Easing.OutCubic } }

      onVisibleChanged: if (visible) forceActiveFocus()

      MouseArea {
        anchors.fill: parent
        onClicked: root.closeDrawer()
      }

	      ColumnLayout {
	        anchors.centerIn: parent
	        anchors.verticalCenterOffset: root.drawerPanelOpen ? 0 : 18
	        width: 760
	        spacing: 22
	        transformOrigin: Item.BottomRight
	        scale: root.drawerPanelOpen ? 1 : 0.94
	        rotation: root.drawerPanelOpen ? 0 : 1.2
	        opacity: root.drawerPanelOpen ? 1 : 0

	        HoverHandler {
	          onHoveredChanged: hovered ? root.enterShellSurface("right") : root.leaveShellSurface()
	        }

	        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: root.drawerMotionBase; easing.type: Easing.OutCubic } }
	        Behavior on rotation { NumberAnimation { duration: root.drawerMotionBase; easing.type: Easing.OutCubic } }
	        Behavior on scale { NumberAnimation { duration: root.drawerMotionBase; easing.type: Easing.OutCubic } }
	        Behavior on opacity { NumberAnimation { duration: root.drawerMotionFast; easing.type: Easing.OutCubic } }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: 34

          MinimalText { shell: root;
            Layout.fillWidth: true
            text: "power"
            color: root.textColor
            font.pixelSize: 18
            horizontalAlignment: Text.AlignLeft
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          PowerTile { shell: root;
            icon: ""
            label: "lock"
            detail: "screen"
            confirm: false
            command: "loginctl lock-session"
          }

          PowerTile { shell: root;
            icon: "⏾"
            label: "suspend"
            detail: "sleep"
            command: "systemctl suspend"
          }

          PowerTile { shell: root;
            icon: "󰍃"
            label: "logout"
            detail: "hyprland"
            command: "hyprctl dispatch exit"
          }

          PowerTile { shell: root;
            icon: ""
            label: "reboot"
            detail: "system"
            command: "systemctl reboot"
          }

          PowerTile { shell: root;
            icon: "⏻"
            label: "shutdown"
            detail: "power off"
            command: "systemctl poweroff"
          }
        }

        MinimalText { shell: root;
          Layout.fillWidth: true
          text: root.powerConfirm.length > 0 ? "confirm " + root.powerConfirm : ""
          color: root.amber
          font.pixelSize: 11
          horizontalAlignment: Text.AlignHCenter
          }
        }
      }
      }
    }
