from "%globalsDarg/darg_library.nut" import *
let { command, setObjPrintFunc } = require("console")
let { eventbus_send_foreign, eventbus_subscribe } = require("eventbus")
let { register_logerr_monitor, unregister_logerr_interceptor } = require("dagor.debug")
let { defer } = require("dagor.workcycle")
let { set_clipboard_text } = require("dagor.clipboard")
let { textColor, badTextColor } = require("%rGui/style/stdColors.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { textInput } = require("%rGui/components/textInput.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { textButtonPrimary, textButtonCommon } = require("%rGui/components/textButton.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { closeButton } = require("%rGui/components/debugWnd.nut")

let MAX_CONSOLE_TEXTS = 100
let CMD_VM_DARG  = "darg.exec"
let CMD_VM_DAGUI = "dagui.exec"

let defaultObjPrintFunc = debugTableData

let wndUid = "debugConsoleWnd"
let close = @() removeModalWindow(wndUid)

let commandColor = 0xFF0099FF

let consoleInputText = Watched("")
let consoleInputClear = @() consoleInputText.set("")

let consoleLog = Watched([])
let consoleLogClear = @() consoleLog.mutate(@(v) v.clear())
let consoleLogCopy = @() set_clipboard_text("\r\n".join(consoleLog.get().map(@(v) v.txt)))

let consolePrint = @(color, txt) consoleLog.mutate(function(v) {
  if (v.len() > MAX_CONSOLE_TEXTS)
    v.remove(0)
  v.append({ color, txt })
})

let printErrorToConsole = @(_tag, logstring, _timestamp) consolePrint(badTextColor, logstring)

let objPrintFuncParams = { printFn = @(txt) consolePrint(textColor, txt) }

function printCmdResultToConsole(result, params) {
  defaultObjPrintFunc(result, objPrintFuncParams)
  defaultObjPrintFunc(result, params)
}

function toggleConsoleCmdResultHandler(isDaRG, isEnable) {
  if (isDaRG) {
    setObjPrintFunc(isEnable ? printCmdResultToConsole : defaultObjPrintFunc)
    if (isEnable)
      register_logerr_monitor([""], printErrorToConsole)
    else
      unregister_logerr_interceptor(printErrorToConsole)
  }
  else
    eventbus_send_foreign("toggleConsoleCmdResultHandler", { isEnable })
}

eventbus_subscribe("daguiConsoleCmdResult", @(p) consolePrint(p.isError ? badTextColor : textColor, p.txt))

let wrapCommand = @(cmd) [ CMD_VM_DARG, CMD_VM_DAGUI ].findindex(@(v) cmd.startswith(v)) != null
    ? cmd
  : cmd.contains("require(\"%scripts/")
    ? $"{CMD_VM_DAGUI} {cmd}"
  : $"{CMD_VM_DARG} {cmd}"

function consoleExecute() {
  let rawCmd = consoleInputText.get().strip()
  if (rawCmd == "")
    return
  let cmd = wrapCommand(rawCmd)
  let isDaRG = cmd.startswith(CMD_VM_DARG)
  consolePrint(commandColor, $"> {cmd}")
  toggleConsoleCmdResultHandler(isDaRG, true)
  defer(function() {
    command(cmd)
    toggleConsoleCmdResultHandler(isDaRG, false)
  })
}

let consoleTextInput = {
  size = FLEX_H
  padding = const [0, 0, hdpx(50), 0]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    textInput(consoleInputText, {
      placeholder = loc("Enter Quirrel code here")
      onChange = @(v) consoleInputText.set(v)
      onReturn = consoleExecute
    })
    textButtonCommon("CLR", consoleInputClear,
      { ovr = { minWidth = hdpx(150), size = [hdpx(150), defButtonHeight] } })
    textButtonPrimary("RUN", consoleExecute,
      { ovr = { minWidth = hdpx(150), size = [hdpx(150), defButtonHeight] } })
  ]
}

let logScrollHandler = ScrollHandler()
let scrollToLogBottom = @() logScrollHandler.scrollToY(max(0,
  (logScrollHandler.elem?.getContentHeight() ?? 0) - (logScrollHandler.elem?.getHeight() ?? 0)))
consoleLog.subscribe(@(_) defer(scrollToLogBottom))

let consoleLogArea = @() {
  watch = consoleLog
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = 0xFFFFFFFF
  preformatted = FMT_KEEP_SPACES | FMT_NO_WRAP
  onAttach = scrollToLogBottom
  text = "\n".join(consoleLog.get().map(@(v) colorize(v.color, v.txt)))
}.__update(fontTiny)

let footerBtns = {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  children = [
    textButtonCommon("CLEAR", consoleLogClear)
    { size = const [flex(), 0] }
    textButtonPrimary("COPY", consoleLogCopy)
  ]
}

return @() addModalWindow({
  key = wndUid
  size = flex()
  stopHotkeys = true
  hotkeys = [[btnBEscUp, { action = close, description = loc("Cancel") }]]
  children = {
    size = const [sh(130), sh(90)]
    padding = hdpx(10)
    stopMouse = true
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = Color(30, 30, 30, 240)
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = [
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        valign = ALIGN_TOP
        children = [
          {
            rendObj = ROBJ_TEXT
            text = "Quirrel Console"
          }.__update(fontSmall)
          { size = flex() }
          closeButton(close)
        ]
      }
      consoleTextInput
      makeVertScroll(
        consoleLogArea,
        { rootBase = { behavior = Behaviors.Pannable }, scrollHandler = logScrollHandler })
      footerBtns
    ]
  }
})
