from "%globalsDarg/darg_library.nut" import *
let { utf8ToUpper } = require("%sqstd/string.nut")
let { registerScene } = require("%rGui/navState.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { textButtonCommon, buttonStyles, mergeStyles, mkCustomButton, buttonsHGap
} = require("%rGui/components/textButton.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { mkPieMenu, defaultPieMenuParams, mkPieMenuItemIcon, mkPieMenuItemText } = require("%rGui/hud/pieMenu.nut")
let { voiceMsgCfg, voiceMsgPieOrder, voiceMsgPieHidden, mkVoiceMsgCfgItem,
  resetVoiceMsgPieUserConfig, saveVoiceMsgPieUserConfig
} = require("%rGui/hud/voiceMsg/voiceMsgState.nut")
let { pieRadius, pieIconSizeMul } = defaultPieMenuParams

let rowHeight = hdpx(80)
let DISABLED_OPACITY = 0.5

let isOpened = mkWatched(persist, "isOpened", false)
let onClose = @() isOpened.set(false)

let selItemId = mkWatched(persist, "selItemId", null)

isOpened.subscribe(@(v) v
  ? selItemId.set(voiceMsgPieOrder.get()?[0])
  : saveVoiceMsgPieUserConfig())

function moveItem(id, isUp) {
  let items = voiceMsgPieOrder.get()
  let idx = items.findindex(@(v) v == id)
  if (idx == null)
    return
  let total = items.len()
  let newIdx = (total + idx + (isUp ? -1 : 1)) % total
  voiceMsgPieOrder.mutate(@(v) v.insert(newIdx, v.remove(idx)))
}
let onBtnUp = @() moveItem(selItemId.get(), true)
let onBtnDown = @() moveItem(selItemId.get(), false)

let selectItem = @(idx) selItemId.set(voiceMsgPieOrder.get()[idx])

let toggleItemVisibility = @(id) voiceMsgPieHidden.mutate(function(v) {
  let idx = v.findindex(@(hId) hId == id)
  if (idx == null)
    v.append(id).sort()
  else
    v.remove(idx)
})
let onBtnVisibility = @() toggleItemVisibility(selItemId.get())

let header = {
  size = FLEX_H
  valign = ALIGN_CENTER
  children = [
    backButton(onClose)
    {
      hplace = ALIGN_CENTER
      size = SIZE_TO_CONTENT
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = 0xFFFFFFFF
      text = loc("radio_messages_menu/editor")
    }.__update(fontBig)
  ]
}

let itemHiddenMarkSize = (rowHeight * 0.67).tointeger()
let itemHiddenMarkLMargin = (rowHeight - itemHiddenMarkSize) / 2
let mkHiddenMark = @(isVisible) @() isVisible.get() ? { watch = isVisible } : {
  watch = isVisible
  size = [itemHiddenMarkSize, itemHiddenMarkSize]
  margin = [0, itemHiddenMarkLMargin, 0, 0]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#btn_trash.svg:{itemHiddenMarkSize}:{itemHiddenMarkSize}:P")
  keepAspect = true
  opacity = DISABLED_OPACITY
}

function mkItemRow(idx) {
  let item = Computed(@() mkVoiceMsgCfgItem(voiceMsgPieOrder.get()[idx]))
  let isSelected = Computed(@() item.get().id == selItemId.get())
  let isVisible = Computed(@() !voiceMsgPieHidden.get().contains(item.get().id))
  let stateFlags = Watched(0)
  let isHovered = Computed(@() stateFlags.get() & S_HOVER)
  return @() {
    watch = stateFlags
    size = [flex(), rowHeight]

    behavior = Behaviors.Button
    onClick = @() selectItem(idx)
    onElemState = @(v) stateFlags(v)
    clickableInfo = loc("mainmenu/btnSelect")
    sound = { click  = "choose" }
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.98, 0.98] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.14, easing = Linear }]

    children = [
      @() {
        watch = [isSelected, isHovered]
        size = flex()
        rendObj = ROBJ_SOLID
        color = isSelected.get() || isHovered.get() ? 0x80296272 : 0
        opacity = isSelected.get() ? 1 : 0.5
      }
      @() {
        watch = [isVisible, item]
        size = flex()
        margin = hdpx(20)
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(30)
        opacity = isVisible.get() ? 1 : DISABLED_OPACITY
        children = [
          mkPieMenuItemIcon(item.get(), pieRadius, pieIconSizeMul)
          mkPieMenuItemText(item.get())
        ]
      }
      mkHiddenMark(isVisible)
    ]
  }
}

let itemsList = @() {
  watch = voiceMsgPieOrder
  size = FLEX_H
  rendObj = ROBJ_SOLID
  color = 0x80000000
  flow = FLOW_VERTICAL
  children = voiceMsgPieOrder.get().map(@(_, idx) mkItemRow(idx))
}

let { COMMON, defButtonHeight } = buttonStyles
let icoBtnStyle = mergeStyles(COMMON, { ovr = { minWidth = defButtonHeight * 2 } })
let btnIconSize = (defButtonHeight * 0.6).tointeger()

let mkIcoBtnContent = @(icon, needUpsideDown = false) {
  size = [btnIconSize, btnIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{icon}:{btnIconSize}:{btnIconSize}:P")
  keepAspect = true
  transform = needUpsideDown ? { rotate = 180 } : {}
}

let footer = @() {
  watch = [voiceMsgPieHidden, selItemId]
  size = FLEX_H
  vplace = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  gap = buttonsHGap
  children = [
    textButtonCommon(utf8ToUpper(loc("msgbox/btn_reset")), resetVoiceMsgPieUserConfig, { hotkeys = ["^J:X"] })
    { size = flex() }
    mkCustomButton(
      mkIcoBtnContent(voiceMsgPieHidden.get().contains(selItemId.get()) ? "btn_trash_return.svg" : "btn_trash.svg"),
      onBtnVisibility,
      icoBtnStyle.__merge({hotkeys = ["^J:Y"]})
    )
    mkCustomButton(mkIcoBtnContent("roulette_pointer.svg", true), onBtnUp, icoBtnStyle.__merge({ hotkeys = ["^J:LT"] }))
    mkCustomButton(mkIcoBtnContent("roulette_pointer.svg"), onBtnDown, icoBtnStyle.__merge({ hotkeys = ["^J:RT"] }))
  ]
}

let voiceMsgPieEditorWnd = bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  children = [
    header
    {
      size = flex()
      vplace = ALIGN_CENTER
      padding = const [0, 0, hdpx(20), 0]
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = saBorders[0]
      children = [
        @() {
          watch = voiceMsgCfg
          children = mkPieMenu(voiceMsgCfg, Watched(-1), defaultPieMenuParams.__merge({ piePosOffset = [0, 0] }))
        }
        itemsList
      ]
    }
    footer
  ]
  animations = wndSwitchAnim
})

registerScene("voiceMsgPieEditorWnd", voiceMsgPieEditorWnd, onClose, isOpened)

return {
  openVoiceMsgPieEditor = @() isOpened.set(true)
}
