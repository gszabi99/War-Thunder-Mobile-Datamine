from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { registerScene } = require("%rGui/navState.nut")
let { shortcutsByUnitTypes, pages } = require("%rGui/controls/help/controlsCfg.nut")
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { unitType } = require("%rGui/hudState.nut")
let mkControlsHelpXone = require("%rGui/controls/help/mkControlsHelpXone.nut")
let mkControlsHelpSony = require("%rGui/controls/help/mkControlsHelpSony.nut")
let mkControlsHelpNintendo = require("%rGui/controls/help/mkControlsHelpNintendo.nut")
let { gamepadShortcuts, gamepadAxes } = require("%rGui/controls/shortcutsMap.nut")
let { axisToHotkey } = require("%rGui/controls/axisToHotkey.nut")
let listButton = require("%rGui/components/listButton.nut")
let { gamepadPreset } = require("%rGui/controlsMenu/gamepadVendor.nut")
let { hudWhiteColor } = require("%rGui/style/hudColors.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")
let { mkGradientCtorRadial, gradTexSize } = require("%rGui/style/gradients.nut")

let typeGamepad = {
  xone = mkControlsHelpXone
  sony = mkControlsHelpSony
  nintendo = mkControlsHelpNintendo
}
let mkControlsHelp = typeGamepad?[gamepadPreset] ?? mkControlsHelpXone

let isOpened = mkWatched(persist, "isOpened", false)
let curUnitType = mkWatched(persist, "curUnitType", null)
let close = @() isOpened.set(false)
let backBtn = backButton(close)
let showCombo = Watched(false)
let toggleShowCombo = @() showCombo.set(!showCombo.get())

let tabHighlight = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(0xFFFFFFFF, 0, 10, 30, 31,-22))

isOpened.subscribe(function(v) {
  if (!v)
    return
  let uType = isInBattle.get() ? unitType.get()
    : hangarUnitName.get() != "" ? getUnitType(hangarUnitName.get())
    : null
  curUnitType.set(pages.contains(uType) ? uType : pages[0])
})

let combinationBtnToggle = {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  halign = ALIGN_CENTER
  margin = hdpx(20)
  children = [
    listButton(loc("controls/base"), Computed(@() !showCombo.get()), toggleShowCombo,
      { size = SIZE_TO_CONTENT, minWidth = hdpx(350), padding = 0 })
    listButton(loc("controls/combo"), showCombo, toggleShowCombo,
      { size = SIZE_TO_CONTENT, minWidth = hdpx(350) })
  ]
}

function appendScText(textLists, key, value) {
  if (key not in textLists)
    textLists[key] <- [value]
  else if (!textLists[key].contains(value))
    textLists[key].append(value)
}

function content() {
  let { shortcuts = [], axes = [] } = shortcutsByUnitTypes?[curUnitType.get()]
  let textLists = {}
  foreach (a in axes) {
    let h = axisToHotkey(gamepadAxes?[a?.value ?? a])
    if (h != null)
      appendScText(textLists, h, loc(a?.locId ?? $"controls/{a}"))
  }

  foreach (scCfg in shortcuts) {
    let sc = gamepadShortcuts?[scCfg?.value ?? scCfg]
    if (sc != null)
      appendScText(textLists, sc, loc(scCfg?.locId ?? $"hotkeys/{scCfg}"))
  }

  let texts = textLists.map(@(l) ", ".join(l))

  return {
    watch = [curUnitType, showCombo]
    size = FLEX
    children = [
      combinationBtnToggle
      mkControlsHelp(texts.filter(function(_, k) {
        if (k == gamepadShortcuts["ID_COMBINATION"])
          return true
        let hasCombination = k.contains(gamepadShortcuts["ID_COMBINATION"])
        return hasCombination == showCombo.get()
      }))
    ]
  }
}

let togglePage = @(diff)
  curUnitType.set(pages[clamp((pages.indexof(curUnitType.get()) ?? -1) + diff, 0, pages.len() - 1)])

let pageTitle = {
  hplace = ALIGN_CENTER
  size = SIZE_TO_CONTENT
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = hudWhiteColor
  text = loc("flightmenu/btnControlsHelp")
}.__update(fontBig)

let header = {
  size = FLEX_H
  valign = ALIGN_CENTER
  children = [
    backBtn
    pageTitle
  ]
}

function mkTab(uType) {
  let isActive = Computed(@() curUnitType.get() == uType)

  return @() {
    watch = isActive
    size = FLEX
    rendObj = ROBJ_IMAGE
    image = tabHighlight()
    behavior = Behaviors.Button
    onClick = @() curUnitType.set(uType)
    color = isActive.get() ? selectColor : 0
    halign = ALIGN_CENTER
    valign = ALIGN_TOP
    padding = const [hdpx(10), 0, 0, 0]
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc($"mainmenu/type_{uType}")
      }.__update(fontSmallShaded)
    ]
  }
}

let footer = {
  size = [FLEX, saBorders[1] + hdpx(60)]
  rendObj = ROBJ_SOLID
  color = 0xDD22262E
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  valign = ALIGN_CENTER
  children = pages.map(@(uType) mkTab(uType))
  hotkeys = [
    ["J:LB", @() togglePage(-1), loc("mainmenu/btnPagePrev")],
    ["J:RB", @() togglePage(1), loc("mainmenu/btnPageNext")],
  ]
}

let scene = bgShaded.__merge({
  key = {}
  size = FLEX
  flow = FLOW_VERTICAL
  children = [
    {
      size = FLEX
      flow = FLOW_VERTICAL
      padding = [saBorders[1], saBorders[0], 0]
      children = [
        header
        content
      ]
    }
    footer
  ]
  animations = wndSwitchAnim
})

registerScene("controlsHelpWnd", scene, close, isOpened)

return @() isOpened.set(true)
