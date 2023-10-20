from "%globalsDarg/darg_library.nut" import *
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { registerScene } = require("%rGui/navState.nut")
let { shortcutsByUnitTypes, pages } = require("controlsCfg.nut")
let { hangarUnitName } = require("%rGui/unit/hangarUnit.nut")
let { isInBattle } = require("%appGlobals/clientState/clientState.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { unitType } = require("%rGui/hudState.nut")
let mkControlsHelpXone = require("mkControlsHelpXone.nut")
let mkControlsHelpSony = require("mkControlsHelpSony.nut")
let mkControlsHelpNintendo = require("mkControlsHelpNintendo.nut")
let { gamepadShortcuts, gamepadAxes } = require("%rGui/controls/shortcutsMap.nut")
let { axisToHotkey } = require("%rGui/controls/axisToHotkey.nut")
let listButton = require("%rGui/components/listButton.nut")
let { gamepadPreset } = require("%rGui/controlsMenu/gamepadVendor.nut")

let typeGamepad = {
  xone = mkControlsHelpXone
  sony = mkControlsHelpSony
  nintendo = mkControlsHelpNintendo
}
let mkControlsHelp = typeGamepad?[gamepadPreset] ?? mkControlsHelpXone

let isOpened = mkWatched(persist, "isOpened", false)
let curUnitType = mkWatched(persist, "curUnitType", null)
let close = @() isOpened(false)
let backBtn = backButton(close)

isOpened.subscribe(function(v) {
  if (!v)
    return
  let uType = isInBattle.value ? unitType.value
    : hangarUnitName.value != "" ? getUnitType(hangarUnitName.value)
    : null
  curUnitType(pages.contains(uType) ? uType : pages[0])
})

let function appendScText(textLists, key, value) {
  if (key not in textLists)
    textLists[key] <- [value]
  else if (!textLists[key].contains(value))
    textLists[key].append(value)
}

let function content() {
  let { shortcuts = [], axes = [] } = shortcutsByUnitTypes?[curUnitType.value]
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

  let texts = textLists.map(@(l) "\n".join(l))

  return {
    watch = curUnitType
    size = flex()
    children = mkControlsHelp(texts)
  }
}

let togglePage = @(diff)
  curUnitType(pages[clamp((pages.indexof(curUnitType.value) ?? -1) + diff, 0, pages.len() - 1)])

let header = {
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  children = [
    backBtn
    {
      hplace = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = hdpx(20)
      children = pages.map(@(t)
        listButton(loc($"mainmenu/type_{t}"), Computed(@() t == curUnitType.value), @() curUnitType(t),
          { size = SIZE_TO_CONTENT, minWidth = hdpx(300) }))
      hotkeys = [
        ["J:LB", @() togglePage(-1), loc("mainmenu/btnPagePrev")],
        ["J:RB", @() togglePage(1), loc("mainmenu/btnPageNext")],
      ]
    }
  ]
}

let scene = bgShaded.__merge({
  key = {}
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = hdpx(50)
  children = [
    header
    content
  ]
  animations = wndSwitchAnim
})

registerScene("controlsHelpWnd", scene, close, isOpened)

return @() isOpened(true)
