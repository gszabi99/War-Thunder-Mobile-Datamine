from "%darg/ui_imports.nut" import *
from "dagor.workcycle" import defer

function mkMsgbox(id, defStyling = require("msgbox.style.nut")){
  let widgets = persist($"{id}_widgets", @() [])
  let msgboxGeneration = persist($"{id}_msgboxGeneration", @() Watched(0))
  let hasMsgBoxes = Computed(@() msgboxGeneration.value >= 0 && widgets.len() > 0)

  function getCurMsgbox(){
    if (widgets.len()==0)
      return null
    return widgets.top()
  }

  

  function addWidget(w) {
    widgets.append(w)
    defer(@() msgboxGeneration(msgboxGeneration.value+1))
  }

  function removeWidget(w, uid=null) {
    let idx = widgets.indexof(w) ?? (uid!=null ? widgets.findindex(@(v) v?.uid == uid) : null)
    if (idx == null)
      return
    widgets.remove(idx)
    msgboxGeneration(msgboxGeneration.value+1)
  }

  function removeAllMsgboxes() {
    widgets.clear()
    msgboxGeneration(msgboxGeneration.value+1)
  }

  function updateWidget(w, uid){
    let idx = widgets.findindex(@(wd) wd.uid == uid)
    if (idx == null)
      addWidget(w)
    else {
      widgets.remove(idx)
      addWidget(w)
    }
  }

  function removeMsgboxByUid(uid) {
    let idx = widgets.findindex(@(w) w.uid == uid)
    if (idx == null)
      return false
    widgets.remove(idx)
    msgboxGeneration(msgboxGeneration.value+1)
    return true
  }

  function isMsgboxInList(uid) {
    return widgets.findindex(@(w) w.uid == uid) != null
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  

  let skip = {skip=true}
  let skpdescr = {description = skip}
  let defaultButtons = [{text="OK" customStyle={hotkeys=[["^Esc | Enter", skpdescr]]}}]


  function show(params, styling=defStyling) {
    log($"[MSGBOX] show: text = '{params?.text}'")
    let self = {v = null}
    let uid = params?.uid ?? {}

    function doClose() {
      removeWidget(self.v, uid)
      if ("onClose" in params && params.onClose)
        params.onClose()

      log($"[MSGBOX] closed: text = '{params?.text}'")
    }

    function handleButton(button_action) {
      if (button_action) {
        if (button_action?.getfuncinfos?().parameters.len()==2) {
          
          button_action({doClose})
          return 
        }

        button_action()
      }

      doClose()
    }

    local btnsDesc = params?.buttons ?? defaultButtons
    if (!(isObservable(btnsDesc)))
      btnsDesc = Watched(btnsDesc, FRP_DONT_CHECK_NESTED)

    local defCancel = null
    local initialBtnIdx = 0

    foreach (idx, bd in btnsDesc.value) {
      if (bd?.isCurrent)
        initialBtnIdx = idx
      if (bd?.isCancel)
        defCancel = bd
    }

    let curBtnIdx = Watched(initialBtnIdx)

    function moveBtnFocus(dir) {
      curBtnIdx.update((curBtnIdx.value + dir + btnsDesc.value.len()) % btnsDesc.value.len())
    }

    function activateCurBtn() {
      log($"[MSGBOX] handling active '{btnsDesc.value[curBtnIdx.value]?.text}' button: text = '{params?.text}'")
      handleButton(btnsDesc.value[curBtnIdx.value]?.action)
    }

    let buttonsBlockKey = {}

    function buttonsBlock() {
      return @() {
        watch = [curBtnIdx, btnsDesc]
        key = buttonsBlockKey
        size = SIZE_TO_CONTENT
        flow = FLOW_HORIZONTAL
        gap = hdpx(40)

        children = btnsDesc.value.map(function(desc, idx) {
          let conHover = desc?.onHover
          function onHover(on){
            if (!on)
              return
            curBtnIdx.update(idx)
            conHover?()
          }
          let onAttach = (initialBtnIdx==idx && styling?.moveMouseCursor.value)
            ? @(elem) move_mouse_cursor(elem)
            : null
          local behavior = desc?.customStyle?.behavior ?? desc?.customStyle?.behavior
          behavior = type(behavior) == "array" ? behavior : [behavior]
          behavior.append(Behaviors.Button)
          let customStyle = (desc?.customStyle ?? {}).__merge({
            onHover
            behavior
            onAttach
          })
          function onClick() {
            log($"[MSGBOX] clicked '{desc?.text}' button: text = '{params?.text}'")
            handleButton(desc?.action)
          }
          return styling.button(desc.__merge({customStyle, key=desc}), onClick)
        })

        hotkeys = [
          [styling?.closeKeys ?? "Esc", {action= @() handleButton(params?.onCancel ?? defCancel?.action), description = styling?.closeTxt}],
          [styling?.rightKeys ?? "Right | Tab", {action = @() moveBtnFocus(1) description = skip}],
          [styling?.leftKeys ?? "Left", {action = @() moveBtnFocus(-1) description = skip}],
          [styling?.activateKeys ?? "Space | Enter", {action= activateCurBtn, description= skip}],
          [styling?.maskKeys ?? "", {action = @() null, description = skip}]
        ]
      }
    }

    let root = styling.Root.__merge({
      key = uid
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      children = [
        styling.messageText(params.__merge({ handleButton = handleButton }))
        buttonsBlock()
      ]
    })

    self.v = styling.BgOverlay.__merge({
      uid
      cursor = styling.cursor
      stopMouse = true
      children = [styling.BgOverlay?.children, root]
    })

    updateWidget(self.v, uid)

    return self
  }
  let msgboxComponent = @(){watch=msgboxGeneration children = getCurMsgbox()}

  return {
    show
    showMsgbox = show
    getCurMsgbox
    msgboxGeneration
    removeAllMsgboxes
    isMsgboxInList
    removeMsgboxByUid
    msgboxComponent
    styling = defStyling
    hasMsgBoxes
  }
}
return mkMsgbox