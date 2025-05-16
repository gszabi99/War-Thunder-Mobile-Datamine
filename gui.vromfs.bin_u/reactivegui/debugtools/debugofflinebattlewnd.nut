from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { register_command } = require("console")
let { mkGameModeByCampaign } = require("%appGlobals/gameModes/gameModes.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { TANK, AIR, SHIP, HELICOPTER, BOAT, SUBMARINE, SAILBOAT } = require("%appGlobals/unitConst.nut")
let { curCampaign, getCampaignStatsId } = require("%appGlobals/pServer/campaign.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { mkToBattleButtonWithSquadManagement } = require("%rGui/mainMenu/toBattleButton.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { hangarUnitName, setHangarUnitWithSkin } = require("%rGui/unit/hangarUnit.nut")
let { defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let chooseByNameWnd = require("debugSkins/chooseByNameWnd.nut")
let { mkCfg, debugOfflineBattleCfg, openOfflineBattleMenu, isOpened, savedUnitType, savedUnitName,
  isOfflineBattleDModeActive, canUseOfflineBattleDMode, savedMissionName, runOfflineBattle,
  refreshOfflineMissionsList, savedOBDebugUnitType, savedOBDebugMissionName, savedOBDebugUnitName,
  savedBotsCount, savedBotsRank, defMaxBotsCount, defMaxBotsRank, NUMBER_OF_PLAYERS, savedUnitPresetLevel,
  unitPresetsLevelList
} = require("debugOfflineBattleState.nut")
let { registerScene } = require("%rGui/navState.nut")
let { toggleWithLabel } = require("%rGui/components/toggle.nut")
let { addModalWindowWithHeader, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { sliderWithButtons } = require("%rGui/components/slider.nut")
let { OCT_LIST } = require("%rGui/options/optCtrlType.nut")
let mkOption = require("%rGui/options/mkOption.nut")


let SET_MIS_BLK_PARAMS_WND = "setMisBlkParamsWnd"
let campaignByUnitType = {
  [SUBMARINE] = "ships",
  [SAILBOAT] = "ships",
  [SHIP] = "ships",
  [BOAT] = "ships",
  [HELICOPTER] = "air",
  [AIR] = "air",
  [TANK] = "tanks"
}

let needShowBattleSettingsWnd = mkWatched(persist, "needShowBattleSettingsWnd", false)

let close = @() isOpened.set(false)

function mkSliderOpt(opt) {
  let { value = null, ctrlOverride = {}, locId = "" } = opt
  if (value == null) {
    logerr($"Options: Missing value for option {opt?.locId}")
    return null
  }
  return sliderWithButtons(value, loc(locId), ctrlOverride)
}

let mkBotOpt = @(value, locId, maxValue) {
  locId
  value
  ctrlOverride = {
    min = 1
    max = maxValue
    unit = 1
  }
}

function setMisBlkParamsContent(campaign) {
  let allUnits = Computed(@() serverConfigs.get()?.allUnits ?? {})
  let gmCfg = mkGameModeByCampaign(getCampaignStatsId(campaign))

  let maxBotsCount = Computed(function() {
    let maxBotsByCfg = gmCfg.get()?.mission_decl.maxBots
    let maxBotSlots = maxBotsByCfg != null ? maxBotsByCfg : defMaxBotsCount
    return maxBotSlots - NUMBER_OF_PLAYERS
  })

  let maxBotsRank = Computed(function() {
    local res = 1
    foreach (unit in allUnits.get())
      if (unit.campaign == campaign)
        res = max(unit.mRank, res)
    return res
  })

  let optMaxBotsCount = mkBotOpt(savedBotsCount, "mainmenu/offlineBattles/settings/botsCount", maxBotsCount.get())
  let optMaxBotsRank = mkBotOpt(savedBotsRank, "mainmenu/offlineBattles/settings/botsRank", maxBotsRank.get())
  let optUnitPresetLevel = {
    locId = "mainmenu/offlineBattles/settings/unitLevel"
    ctrlType = OCT_LIST
    value = savedUnitPresetLevel
    list = unitPresetsLevelList
    valToString = @(v) loc($"mainmenu/offlineBattles/unitPreset/{v}")
  }

  return {
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    padding = hdpx(40)
    gap = hdpx(40)
    function onAttach() {
      let selectedUnit = allUnits.get()?[savedUnitName.get()] ?? {}
      savedBotsCount.set(maxBotsCount.get())
      savedBotsRank.set(selectedUnit?.mRank ?? defMaxBotsRank)
    }
    onDetach = @() needShowBattleSettingsWnd.set(false)
    children = [
      mkSliderOpt(optMaxBotsCount)
      mkSliderOpt(optMaxBotsRank)
      mkOption(optUnitPresetLevel)
      mkToBattleButtonWithSquadManagement(function() {
        needShowBattleSettingsWnd.set(false)
        runOfflineBattle()
      })
    ]
  }
}

let openBattleSettingsModal = @() addModalWindowWithHeader(SET_MIS_BLK_PARAMS_WND,
  loc("mainmenu/offlineBattles/settings/modalTitle"),
  setMisBlkParamsContent(campaignByUnitType[savedUnitType.get()]))

needShowBattleSettingsWnd.subscribe(@(v) v
  ? openBattleSettingsModal()
  : removeModalWindow(SET_MIS_BLK_PARAMS_WND))
if (needShowBattleSettingsWnd.get())
  openBattleSettingsModal()

let setParamsAndRunBattle = @() isOfflineBattleDModeActive.get()
  ? runOfflineBattle()
  : needShowBattleSettingsWnd.set(true)

let toBattleHint = @(text) {
  hplace = ALIGN_RIGHT
  pos = [saBorders[0] * 0.5, 0]
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  padding = [saBorders[0] * 0.2, saBorders[0] * 0.5]
  texOffs = [0, gradDoubleTexOffset]
  screenOffs = [0, saBorders[0]]
  color = 0x70000000
  children = {
    size = [defButtonMinWidth, SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text
  }.__update(fontTinyAccented)
}

let wndHeader = @(children) {
  size = [flex(), hdpx(60)]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(15)
  children = [
    backButton(close)
    {
      rendObj = ROBJ_TEXT
      size = [flex(), SIZE_TO_CONTENT]
      text = loc("mainmenu/offlineBattles")
    }.__update(fontBig)
  ].extend(children)
}

let wndContent = @(children) {
  hplace = ALIGN_LEFT
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children
}

let wndFooter = {
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  halign = ALIGN_RIGHT
  valign = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = hdpx(10)
  children = [
    toBattleHint(loc("mainmenu/btnSingleLocalMission"))
    @() {
      watch = canUseOfflineBattleDMode
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = hdpx(30)
      children = [
        canUseOfflineBattleDMode.get() ? toggleWithLabel(isOfflineBattleDModeActive, loc("mainmenu/debugOfflineBattles")) : null
        mkToBattleButtonWithSquadManagement(setParamsAndRunBattle)
      ]
    }
  ]
}

let mkSelector = @(curValue, allValues, setValue, mkLoc, mkValues, title = "") @() {
  watch = curValue
  children = textButtonPrimary(mkLoc(curValue.get()),
    @(event) chooseByNameWnd(event.targetRect,
      title
      mkValues(allValues?.get() ?? allValues, mkLoc),
      curValue.get(),
      setValue))
}

function mkDebugContent() {
  let cfg = debugOfflineBattleCfg()
  let allDebugUnitTypes = cfg.get()?.keys().sort()
  let curDebugUnitType = Computed(@() allDebugUnitTypes?.contains(savedUnitType.get())
    ? savedOBDebugUnitType.get()
    : allDebugUnitTypes?[0])
  let allDebugMissions = Computed(@() cfg.get()?[curDebugUnitType.get()] ?? {})
  let curDebugMissionName = Computed(@() savedOBDebugMissionName.get() in allDebugMissions.get()
    ? savedOBDebugMissionName.get()
    : allDebugMissions.get().findindex(@(_) true))

  function onUnitChange() {
    if (curCampaign.get() != campaignByUnitType?[savedOBDebugUnitType.get()])
      savedOBDebugUnitName.set(serverConfigs.get()?.allUnits.findindex(@(unit) unit.unitType == savedOBDebugUnitType.get()))
    else
      savedOBDebugUnitName.set(curUnit.get()?.name)
  }

  savedOBDebugUnitType.subscribe(function(v) {
    if (v != null)
      onUnitChange()
    setHangarUnitWithSkin(savedOBDebugUnitName.get() ?? savedUnitName.get() ?? curUnit.get()?.name, "")
    savedOBDebugMissionName.set(curDebugMissionName.get())
  })

  return [
    wndHeader([
      mkSelector(curDebugUnitType,
        allDebugUnitTypes,
        @(value) savedOBDebugUnitType.set(value),
        @(name) loc($"mainmenu/type_{name}"),
        @(allValues, mkLoc) allValues.map(@(value) { text = mkLoc(value), value }),
        loc("hudTuning/chooseUnitType"))
    ])
    wndContent([
      mkSelector(curDebugMissionName,
        allDebugMissions,
        @(value) savedOBDebugMissionName.set(value),
        @(id) cfg.get()?[curDebugUnitType.get()][id] || id,
        @(allValues, mkLoc) allValues.keys().sort().map(@(value) { text = mkLoc(value), value }),
        loc("options/mislist"))
    ])
  ]
}

function mkOfflineBattleMenuWnd() {
  let cfg = mkCfg()
  let allUnitTypes = cfg.get().unitTypes.keys().sort()
  let curUnitType = Computed(@() allUnitTypes.contains(savedUnitType.get()) ? savedUnitType.get() : allUnitTypes?[0])
  let unitsByType = Computed(@() cfg.get()?.allUnits[curUnitType.get()] ?? {})
  let allMissions = Computed(@() cfg.get()?.missions[curUnitType.get()] ?? {})

  let curData = Computed(function() {
    local name = savedUnitName.get() ?? hangarUnitName.get()
    local mission = savedMissionName.get()
    local units = unitsByType.get()
    name = name in units ? name : units.findindex(@(_) true)
    mission = mission in allMissions.get() ? mission : allMissions.get().findindex(@(_) true)
    return { name, units, mission }
  })
  let curUnitName = Computed(@() curData.get().name)
  let curMissionName = Computed(@() curData.get().mission)

  let onUnitChange = @() (curUnitName.get() != null && !isOfflineBattleDModeActive.get())
    ? setHangarUnitWithSkin(curUnitName.get(), "")
    : null

  let initMissionName = @() (curMissionName.get() != null && !isOfflineBattleDModeActive.get())
    ? savedMissionName.set(curMissionName.get())
    : null

  function onUnitTypeChange() {
    savedUnitName.set(curUnitName.get() ?? hangarUnitName.get())
    savedMissionName.set(curMissionName.get() ?? allMissions.get().findindex(@(_) true))
  }
  onUnitChange()
  initMissionName()
  curUnitName.subscribe(@(_) onUnitChange())
  savedUnitType.subscribe(@(_) onUnitTypeChange())

  return {
    watch = [cfg, isOfflineBattleDModeActive]
    key = isOpened
    size = flex()
    padding = saBordersRv
    behavior = HangarCameraControl
    touchMarginPriority = TOUCH_BACKGROUND
    flow = FLOW_VERTICAL
    gap = hdpx(30)
    function onAttach() {
      refreshOfflineMissionsList()
      savedUnitType.set(getUnitType(hangarUnitName.get()))
      onUnitTypeChange()
    }
    animations = wndSwitchAnim
    children = [
      {
        size = flex()
        flow = FLOW_VERTICAL
        gap = hdpx(30)
        children = isOfflineBattleDModeActive.get()
          ? mkDebugContent()
          : [
              wndHeader([
                mkSelector(curUnitType,
                  allUnitTypes,
                  @(value) savedUnitType.set(value),
                  @(name) loc($"mainmenu/type_{name}"),
                  @(allValues, mkLoc) allValues.map(@(value) { text = mkLoc(value), value }),
                  loc("hudTuning/chooseUnitType"))
                mkSelector(curUnitName,
                  Computed(@() curData.get().units),
                  @(value) savedUnitName.set(value),
                  @(name) loc(getUnitLocId(name ?? "")),
                  @(allValues, mkLoc) allValues.keys().sort().filter(@(v) v != "dummy_plane").map(@(value) { text = mkLoc(value), value }),
                  loc("slotbar/selectUnit"))
              ])
              wndContent([
                mkSelector(curMissionName,
                  allMissions,
                  @(value) savedMissionName.set(value),
                  @(id) cfg.get()?.missions[curUnitType.get()][id] || id,
                  @(allValues, mkLoc) allValues.keys().sort().map(@(value) { text = mkLoc(value), value }),
                  loc("options/mislist"))
              ])
            ]
      }
      { size = flex() }
      wndFooter
    ]
  }
}

registerScene("debugOfflineBattleWnd", mkOfflineBattleMenuWnd, close, isOpened)

register_command(openOfflineBattleMenu, "ui.debug.offlineBattleMenu")
