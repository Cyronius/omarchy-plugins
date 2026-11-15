import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Bar label naming the active workspace on this bar's monitor. Click it (or
// `omarchy-shell cyrus.workspace-title toggle`) to rename; Enter saves, Esc
// cancels, saving an empty name clears it. Right-click cycles what is shown
// (auto / both / name / window); middle-click clears the name.
// Names persist per workspace id in
// ~/.local/state/omarchy/workspace-titles.json, shared by every monitor's bar.
Panel {
  id: root
  moduleName: "cyrus.workspace-title"
  ipcTarget: "cyrus.workspace-title"

  readonly property int maxLabelWidth: Number(setting("maxWidth", 240))
  readonly property int maxNameLength: 80

  readonly property var monitor: {
    var window = root.QsWindow.window
    var screen = window ? window.screen : null
    return screen ? Hyprland.monitorFor(screen) : Hyprland.focusedMonitor
  }
  readonly property int workspaceId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : -1
  // Omarchy numbers each monitor's workspaces in blocks of ten; show 1-10.
  readonly property int workspaceSlot: workspaceId > 0 ? (workspaceId - 1) % 10 + 1 : workspaceId

  property var titles: ({})
  property int editingId: -1
  readonly property string title: titles[String(workspaceId)] || ""

  // Fallback for unnamed workspaces: the focused window's title when it is on
  // this workspace, else the last window focused there, else any window on it.
  property var lastWindowTitles: ({})
  readonly property var activeToplevel: Hyprland.activeToplevel
  // Hyprland's own title can be empty until its IPC data is refreshed, so
  // prefer the Wayland handle's live title.
  function titleOf(t) {
    if (!t) return ""
    if (t.wayland && t.wayland.title) return String(t.wayland.title)
    if (t.title) return String(t.title)
    var ipc = t.lastIpcObject
    return ipc && ipc.title ? String(ipc.title) : ""
  }
  readonly property string activeToplevelTitle: titleOf(activeToplevel)
  readonly property int activeToplevelWorkspace: activeToplevel && activeToplevel.workspace ? activeToplevel.workspace.id : -1

  function rememberWindowTitle() {
    if (activeToplevelWorkspace === -1 || activeToplevelTitle === "") return
    var next = Object.assign({}, lastWindowTitles)
    next[String(activeToplevelWorkspace)] = activeToplevelTitle
    lastWindowTitles = next
  }
  onActiveToplevelTitleChanged: rememberWindowTitle()
  onActiveToplevelWorkspaceChanged: rememberWindowTitle()

  readonly property string windowTitle: {
    if (activeToplevelWorkspace === workspaceId && activeToplevelTitle !== "") return activeToplevelTitle
    var all = Hyprland.toplevels ? Hyprland.toplevels.values : []
    var titles = []
    for (var i = 0; i < all.length; i++) {
      if (!all[i].workspace || all[i].workspace.id !== workspaceId) continue
      var t = titleOf(all[i])
      if (t !== "") titles.push(t)
    }
    var remembered = lastWindowTitles[String(workspaceId)] || ""
    if (remembered !== "" && titles.indexOf(remembered) !== -1) return remembered
    return titles.length > 0 ? titles[0] : ""
  }

  Component.onCompleted: {
    Hyprland.refreshToplevels()
    rememberWindowTitle()
  }

  // Display mode, cycled with right-click and kept in this widget's shell.json
  // entry: "auto" (name, else window title), "both" (name · window title),
  // "name", or "window".
  readonly property var modes: ["auto", "both", "name", "window"]
  readonly property string mode: modes.indexOf(setting("display", "auto")) !== -1 ? setting("display", "auto") : "auto"
  readonly property bool showName: title !== "" && mode !== "window"
  readonly property bool showWindow: windowTitle !== "" && (mode === "window" || mode === "both" || (mode === "auto" && title === ""))

  function cycleMode() {
    var next = modes[(modes.indexOf(mode) + 1) % modes.length]
    root.settings = Object.assign({}, root.settings, { display: next })
    if (root.bar && root.bar.shell) root.bar.shell.updateEntryInline(root.moduleName, root.settings)
    if (root.bar) root.bar.showTooltip(button, "Show: " + next)
  }

  function readTitles(text) {
    var next = {}
    try {
      var parsed = JSON.parse(String(text || "{}"))
      if (parsed && typeof parsed === "object") {
        for (var key in parsed) {
          if (/^-?\d+$/.test(key) && typeof parsed[key] === "string" && parsed[key] !== "")
            next[key] = parsed[key].slice(0, root.maxNameLength)
        }
      }
    } catch (e) {}
    root.titles = next
  }

  function saveTitle(id, name) {
    if (id === -1) return
    var clean = String(name || "").replace(/[\r\n\t]+/g, " ").trim().slice(0, root.maxNameLength)
    var next = Object.assign({}, root.titles)
    if (clean === "") delete next[String(id)]
    else next[String(id)] = clean
    root.titles = next
    titlesFile.setText(JSON.stringify(next, null, 2) + "\n")
  }

  FileView {
    id: titlesFile
    path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/omarchy/workspace-titles.json"
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.readTitles(text())
    onLoadFailed: root.readTitles("")
  }

  onOpenedChanged: {
    if (opened) {
      root.editingId = root.workspaceId
      if (panel.loadedContent) panel.loadedContent.reset(root.title)
    }
  }

  // Switching workspace mid-edit would rename the wrong one; just cancel.
  onWorkspaceIdChanged: if (opened && workspaceId !== editingId) close()

  visible: !vertical
  implicitWidth: visible ? Math.min(maxLabelWidth, labelRow.implicitWidth) + Style.spacing.controlPaddingX * 2 : 0
  implicitHeight: barSize

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : Style.bar.sizeHorizontal

  Behavior on implicitWidth {
    NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic }
  }

  Item {
    id: button
    anchors.fill: parent

    Item {
      anchors.fill: parent
      anchors.leftMargin: Style.spacing.controlPaddingX
      anchors.rightMargin: Style.spacing.controlPaddingX
      clip: true

      // Name bright and never elided; window title dimmed and elided first.
      Row {
        id: labelRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: Style.space(6)
        readonly property real available: Math.max(0, root.maxLabelWidth)

        Text {
          id: nameText
          visible: root.showName || !root.showWindow
          textFormat: Text.PlainText
          text: root.showName ? root.title : "untitled"
          width: Math.min(implicitWidth, labelRow.available)
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          font.italic: !root.showName
          elide: Text.ElideRight
          opacity: !root.showName ? 0.45 : (mouse.containsMouse || root.opened ? 1 : 0.85)
        }

        Text {
          id: separator
          visible: root.showName && root.showWindow
          textFormat: Text.PlainText
          text: "·"
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          opacity: 0.35
        }

        Text {
          id: windowText
          visible: root.showWindow
          textFormat: Text.PlainText
          text: root.windowTitle
          width: Math.max(0, Math.min(implicitWidth, labelRow.available
            - (nameText.visible ? nameText.width + labelRow.spacing : 0)
            - (separator.visible ? separator.implicitWidth + labelRow.spacing : 0)))
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
          opacity: mouse.containsMouse ? 0.8 : 0.55
        }
      }
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: function(event) {
        if (event.button === Qt.MiddleButton) root.saveTitle(root.workspaceId, "")
        else if (event.button === Qt.RightButton) root.cycleMode()
        else root.toggle()
      }
      onExited: if (root.bar) root.bar.hideTooltip(button)
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent ? panel.loadedContent.field : null
    contentWidth: panel.fittedContentWidth(Style.space(260))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight)

    content: FocusScope {
      id: editor
      property alias field: field
      anchors.fill: parent
      implicitHeight: column.implicitHeight

      function reset(value) {
        field.text = value
        field.selectAll()
      }

      Component.onCompleted: reset(root.title)

      Column {
        id: column
        width: parent.width
        spacing: Style.space(6)

        Text {
          textFormat: Text.PlainText
          text: "Workspace " + root.workspaceSlot
          color: Commons.Color.foreground
          opacity: 0.6
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }

        TextField {
          id: field
          width: parent.width
          focus: true
          maximumLength: root.maxNameLength
          placeholderText: "Name this workspace"
          onAccepted: {
            root.saveTitle(root.editingId, text)
            root.close()
          }
          Keys.onEscapePressed: root.close()
        }
      }
    }
  }
}
