from "%globalsDarg/darg_library.nut" import *
from "console" import command, setObjPrintFunc
from "dagor.clipboard" import set_clipboard_text
from "dagor.debug" import register_logerr_monitor, unregister_logerr_interceptor
from "dagor.workcycle" import defer
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/debugWnd.nut" import closeButton
from "%rGui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%rGui/components/scrollbar.nut" import makeVertScroll
from "%rGui/components/textButton.nut" import textButtonPrimary, textButtonCommon
from "%rGui/components/textInput.nut" import textInput
from "%rGui/controlsMenu/gpActBtn.nut" import btnBEscUp
from "%rGui/style/stdColors.nut" import textColor, badTextColor


const MAX_CONSOLE_TEXTS = 100
const CMD_VM_DARG  = "darg.exec"


let defaultObjPrintFunc = debugTableData

const wndUid = "debugConsoleWnd"
let close = @() removeModalWindow(wndUid)

const commandColor = 0xFF0099FF

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

function toggleConsoleCmdResultHandler(isEnable) {
  setObjPrintFunc(isEnable ? printCmdResultToConsole : defaultObjPrintFunc)
  if (isEnable)
    register_logerr_monitor([""], printErrorToConsole)
  else
    unregister_logerr_interceptor(printErrorToConsole)
}

let wrapCommand = @(cmd) cmd.startswith(CMD_VM_DARG) ? cmd : $"{CMD_VM_DARG} {cmd}"

function consoleExecute() {
  let rawCmd = consoleInputText.get().strip()
  if (rawCmd == "")
    return
  let cmd = wrapCommand(rawCmd)

  consolePrint(commandColor, $"> {cmd}")
  toggleConsoleCmdResultHandler(true)
  defer(function() {
    
    try {
      command(cmd)
    }
    catch (e)
      consolePrint(badTextColor, e)
    toggleConsoleCmdResultHandler(false)
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
    { size = const [FLEX, 0] }
    textButtonPrimary("COPY", consoleLogCopy)
  ]
}

return @() addModalWindow({
  key = wndUid
  size = FLEX
  stopHotkeys = true
  hotkeys = [[btnBEscUp, { action = close, description = loc("Cancel") }]]
  children = {
    size = const [hdpx(1500), sh(90)]
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
          { size = FLEX }
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
