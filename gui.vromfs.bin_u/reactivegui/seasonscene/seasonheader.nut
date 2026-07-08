from "%globalsDarg/darg_library.nut" import *
let { GOLD } = require("%appGlobals/currenciesState.nut")
let { mkCurrenciesBtns } = require("%rGui/mainMenu/gamercard.nut")
let { curTabParams } = require("%rGui/quests/questsState.nut")
let { curEventCurrencies } = require("%rGui/event/eventState.nut")
let { bpSeasonName, bpSeasonEndTime } = require("%rGui/battlePass/battlePassState.nut")
let { opSeasonEndTime, opSeasonName } = require("%rGui/battlePass/operationPassState.nut")
let { epSeasonEndTime, eventTitle } = require("%rGui/battlePass/eventPassState.nut")
let { passPageId, BATTLE_PASS, OPERATION_PASS } = require("%rGui/battlePass/passState.nut")
let { secondsToHoursLoc } = require("%appGlobals/timeToText.nut")
let { serverTime } = require("%appGlobals/userstats/serverTime.nut")
let { headerGradientBg } = require("%rGui/components/gradientDefComps.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { PASS_SCENE, QUESTS_TAB, LOOTBOX_TAB, seasonPageId } = require("%rGui/seasonScene/seasonSceneState.nut")

let defSeasonName = bpSeasonName
let defSeasonEndTime = bpSeasonEndTime

let seasonNameByPage = {
  [PASS_SCENE] = Computed(@() passPageId.get() == BATTLE_PASS ? bpSeasonName.get()
    : passPageId.get() == OPERATION_PASS ? opSeasonName.get()
    : loc(eventTitle.get())
  ),
}

let seasonEndTimeByPage = {
  [PASS_SCENE] = Computed(@() passPageId.get() == BATTLE_PASS ? bpSeasonEndTime.get()
    : passPageId.get() == OPERATION_PASS ? opSeasonEndTime.get()
    : epSeasonEndTime.get()
  ),
}

let currenciesByPage = {
  [PASS_SCENE] = Computed(@() passPageId.get() == BATTLE_PASS || passPageId.get() == OPERATION_PASS
    ? [GOLD]
    : curEventCurrencies.get()),
  [QUESTS_TAB] = Computed(@() curTabParams.get()?.currencies),
  [LOOTBOX_TAB] = curEventCurrencies
}

let mkHeaderChildren = @(seasonName, seasonEndTime) [
  @() {
    watch = seasonName
    rendObj = ROBJ_TEXT
    text = seasonName.get()
  }.__update(fontBig)
  @() {
    key = "battle_pass_time" 
    watch = [seasonEndTime, serverTime]
    rendObj = ROBJ_TEXT
    text = !seasonEndTime.get() || (seasonEndTime.get() - serverTime.get() < 0) ? null
      : loc("battlepass/endsin", { time = secondsToHoursLoc(seasonEndTime.get() - serverTime.get()) }  )
  }.__update(fontTinyAccented)
]

function headerCurrencies() {
  let currencies = currenciesByPage?[seasonPageId.get()]
  return currencies == null ? { watch = seasonPageId }
    : {
        watch = [seasonPageId, currencies]
        children = mkCurrenciesBtns(currencies.get())
      }
}

return @(close) {
  size = FLEX_H
  vplace = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    headerGradientBg([
      backButton(close)
      @() {
        watch = seasonPageId
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = hdpx(5)
        children = mkHeaderChildren(
          seasonNameByPage?[seasonPageId.get()] ?? defSeasonName,
          seasonEndTimeByPage?[seasonPageId.get()] ?? defSeasonEndTime)
      }
    ])
    { size = FLEX }
    headerCurrencies
  ]
}
