from "%globalsDarg/darg_library.nut" import *
let { screenlog } = require("dagor.debug")
let { set_clipboard_text } = require("dagor.clipboard")
let { object_to_json_string } = require("json")
let { tostring_r } = require("%sqstd/string.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")
let { set_purch_player_type, check_new_offer, debug_offer_generation_stats, shift_all_offers_time,
  generate_fixed_type_offer, registerHandler, debug_offer_possible_units
} = require("%appGlobals/pServer/pServerApi.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let servProfile = require("%appGlobals/pServer/servProfile.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { closeButton } = require("%rGui/components/debugWnd.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { openMsgBox, msgBoxText } = require("%rGui/components/msgBox.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")


let wndWidth = sh(130)
let gap = hdpx(10)

let wndUid = "debugOffersWnd"
let close = @() removeModalWindow(wndUid)

registerHandler("closeOfferWndOnSuccess",
  function closeOnSuccess(res) {
    screenlog(res?.error == null ? "SUCCESS!" : "ERROR")
    if (res?.error == null)
      close()
  })

registerHandler("onDebugShiftOffer", @(_) check_new_offer(curCampaign.get(), "closeOfferWndOnSuccess"))

let mkBtn = @(label, func) textButtonCommon(label, func, { ovr = { size = const [flex(), hdpx(100)] }, useFlexText = true })
let infoTextOvr = {
  size = FLEX_H
  halign = ALIGN_LEFT,
  preformatted = FMT_KEEP_SPACES | FMT_NO_WRAP
}.__update(fontTiny)

registerHandler("onDebugOfferStats",
  function(res) {
    let data = clone res
    data?.$rawdelete("isCustom")
    openMsgBox({
      text = msgBoxText(tostring_r(data), infoTextOvr)
      wndOvr = { size = const [hdpx(1100), hdpx(1000)] }
    })
  })

let mkUnitsTexts = @(texts) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  children = texts.map(function(cfg) {
    let { campaign, units } = cfg
    let unitsText = "\n".join(units)
    return msgBoxText($"{campaign.toupper()}\n\n{unitsText}", infoTextOvr)
  })
}

let unitsSort = @(a, b) a.rank <=> b.rank
  || a.mRank <=> b.mRank
  || a.name <=> b.name

registerHandler("onDebugOfferUnits",
  function(res, context) {
    let { units = null } = res
    if (units == null) {
      openMsgBox({ text = tostring_r(res) })
      return
    }

    let { isOnlyOwn = false } = context
    let { allUnits = {} } = serverConfigs.get()
    let myUnits = servProfile.get()?.units ?? {}
    let unitsByCamp = {}
    let unknown = []
    foreach(unitName in units) {
      if (isOnlyOwn && unitName in myUnits)
        continue
      let unitCfg = allUnits?[unitName]
      if (unitCfg == null) {
        unknown.append(unitName)
        continue
      }
      let { campaign } = unitCfg
      if (campaign not in unitsByCamp)
        unitsByCamp[campaign] <- []
      unitsByCamp[campaign].append(unitCfg)
    }

    let textsByCamp = []
    foreach(campaign, cUnits in unitsByCamp)
      textsByCamp.append({
        campaign
        units = cUnits.sort(unitsSort)  
          .map(@(u) $"{u.rank} {getRomanNumeral(u.mRank)} {u.name}")
      })

    let cur = curCampaign.get()
    textsByCamp.sort(@(a, b) (b.campaign == cur) <=> (a.campaign == cur)
      || a.campaign <=> b.campaign)

    if (unknown.len() > 0)
      textsByCamp.append({ campaign = "unknown", units = unknown })

    let columns = saSize[0] / hdpxi(650)
    openMsgBox({
      title = isOnlyOwn ? "My offer allowed units" : "All offer allowed units"
      text = makeVertScroll(
        {
          size = FLEX_H
          flow = FLOW_VERTICAL
          gap = hdpx(80)
          children = arrayByRows(textsByCamp, columns)
            .map(@(row) mkUnitsTexts(row))
        },
        { rootBase = { behavior = Behaviors.Pannable } })
      wndOvr = { size = [hdpx(max(1100, 650 * columns)), hdpx(1000)] }
      buttons = [
        { text = "COPY", cb = @() set_clipboard_text(object_to_json_string(textsByCamp, true)) }
        { id = "ok", styleId = "PRIMARY", isDefault = true }
      ]
    })
  })

let commandsList = [
  { label = "gen_next_day_offer",
    func = @() shift_all_offers_time(86400, "onDebugShiftOffer")
  }
  { label = "debug_offer_generation_stats",
    func = @() debug_offer_generation_stats(curCampaign.get(), "onDebugOfferStats")
  }
  {
    label = "debug_offer_possible_units_my"
    func = @() debug_offer_possible_units({ id = "onDebugOfferUnits", isOnlyOwn = true })
  }
  {
    label = "debug_offer_possible_units_all"
    func = @() debug_offer_possible_units("onDebugOfferUnits")
  }
]

let offersList = ["start", "gold", "collection", "sidegrade", "upgrade", "whale", "blueprint",
  "branch", "premUnit", "blueprintUpgraded"
]

foreach (ot in offersList) {
  let offerType = ot
  commandsList.append({
    label = $"generate {offerType}",
    func = @() generate_fixed_type_offer(curCampaign.get(), offerType, "closeOfferWndOnSuccess")
  })
}

let pPlayerTypes = {
  newbie = ""
  standard = "standard"
  whale = "whale"
}
pPlayerTypes.each(@(pType, id) commandsList.append({
  label = $"set purch type {id}",
  func = @() set_purch_player_type(pType, "sceenlogResult")
}))

function mkCommandsList() {
  let list = commandsList.map(@(c) mkBtn(c.label, c.func))
  let rows = arrayByRows(list, 2)
  if (rows.top().len() < 2)
    rows.top().resize(2, { size = flex() })

  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    padding = gap
    gap
    children = rows.map(@(children) {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap
      children
    })
  }
}

return @() addModalWindow({
  key = wndUid
  size = flex()
  stopHotkeys = true
  hotkeys = [[btnBEscUp, { action = close, description = loc("Cancel") }]]
  children = {
    size = [wndWidth + 2 * gap, sh(90)]
    stopMouse = true
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = Color(30, 30, 30, 240)
    flow = FLOW_VERTICAL
    children = [
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        valign = ALIGN_TOP
        padding = gap
        children = [
          {
            rendObj = ROBJ_TEXT
            text = "Debug offers"
          }.__update(fontSmall)
          { size = flex() }
          closeButton(close)
        ]
      }
      makeVertScroll(
        mkCommandsList(),
        { rootBase = { behavior = Behaviors.Pannable } })
    ]
  }
})
