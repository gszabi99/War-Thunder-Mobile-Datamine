from "%globalsDarg/darg_library.nut" import *
let { eventbus_send } = require("eventbus")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { debugModes } = require("%rGui/gameModes/gameModeState.nut")
let listButton = require("%rGui/components/listButton.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { closeButton } = require("%rGui/components/debugWnd.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")
let { textButtonCommon } = require("%rGui/components/textButton.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let tryOpenQueuePenaltyWnd = require("%rGui/queue/queuePenaltyWnd.nut")

let wndUid = "debugGameModes"
let close = @() removeModalWindow(wndUid)

let gap = hdpx(10)
let selectedCampaign = mkWatched(persist, "selectedCampaign", curCampaign.get())

let specialTabs = [
  { id = "dev",       contain = ["qa_", "testflight", "test_flight", "vidteam_"] }
  { id = "newbie",    contain = ["new_players"] }
  { id = "dev_event", contain = ["limited_"] }
]

let isModeFitToTab = @(t, m) t.contain.findvalue(@(p) m.name.indexof(p) != null) != null

let noGameModes = {
  size = const [ hdpx(500), SIZE_TO_CONTENT ]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color = 0xFFFFFFFF
  text = "No debug game modes at this moment"
}.__update(fontMedium)

function gameModesList() {
  let res = {
    watch = [debugModes, selectedCampaign]
    size = FLEX_H
    padding = gap
    children = noGameModes
  }

  let sel = selectedCampaign.get()
  let specialTab = specialTabs.findvalue(@(t) t.id == sel)
  let modes = debugModes.get().values()
    .filter(@(m) specialTab != null
      ? isModeFitToTab(specialTab, m)
      : specialTabs.findvalue(@(t) isModeFitToTab(t, m)) == null && m?.campaign == sel)
    .sort(@(a, b) (a?.name ?? "") <=> (b?.name ?? ""))
    .map(@(m) textButtonCommon(m?.name ?? m?.gameModeId ?? "!!!ERROR!!!",
      function() {
        close()
        let modeId = m?.gameModeId
        let campaign = m?.campaign ?? selectedCampaign.get()
        if (tryOpenQueuePenaltyWnd(campaign, m, { id = "queueToGameMode", modeId }))
          return
        eventbus_send("queueToGameMode", { modeId })
      },
      { ovr = { size = const [flex(), hdpx(100)] }, useFlexText = true }))

  if (modes.len() == 0)
    return res

  let rows = arrayByRows(modes, 2)
  if (rows.top().len() < 2)
    rows.top().resize(2, { size = flex() })

  return res.__update({
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap
    children = rows.map(@(children) {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap
      children
    })
  })
}

function getDefaultCampaign(campaigns) {
  local camp = curCampaign.get()
  if (campaigns.contains(camp))
    return camp
  camp = getCampaignPresentation(camp).campaign
  return campaigns.contains(camp) ? camp : campaigns[0]
}

function gameModesTabs() {
  let allModes = debugModes.get().values()
  let campaigns = allModes
    .filter(@(m) specialTabs.findvalue(@(t) isModeFitToTab(t, m)) == null)
    .reduce(@(res, m) res.$rawset(m?.campaign ?? "", true), {})
    .keys()
    .sort()
  local tabs = campaigns
  foreach (t in specialTabs)
    if (allModes.findvalue(@(m) isModeFitToTab(t, m)) != null)
      tabs.append(t.id)
  let res = { watch = [ selectedCampaign, debugModes ]}
  return tabs.len() == 0 ? res
    : res.__update({
      flow = FLOW_HORIZONTAL
      gap = hdpx(20)
      onAttach = @() selectedCampaign.set(getDefaultCampaign(campaigns))
      children = tabs.map(@(c) listButton(c, Computed(@() selectedCampaign.get() == c), @() selectedCampaign.set(c), { size = const [hdpx(200), SIZE_TO_CONTENT] }))
    })
}

return @() addModalWindow({
  key = wndUid
  size = flex()
  stopHotkeys = true
  hotkeys = [[btnBEscUp, { action = close }]]
  children = {
    size = const [hdpx(1500), sh(90)]
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
        valign = ALIGN_CENTER
        padding = gap
        children = [
          {
            rendObj = ROBJ_TEXT
            text = "Debug game modes"
          }.__update(fontSmall)
          { size = flex() }
          closeButton(close)
        ]
      }
      gameModesTabs
      makeVertScroll(
        gameModesList,
        { rootBase = { behavior = Behaviors.Pannable } })
    ]
  }
})
