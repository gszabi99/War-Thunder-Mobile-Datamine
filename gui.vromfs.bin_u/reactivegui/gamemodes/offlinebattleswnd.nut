from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { deferOnce } = require("dagor.workcycle")
let { register_command } = require("console")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { mkGameModeByCampaign } = require("%appGlobals/gameModes/gameModes.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { TANK, AIR, SHIP, HELICOPTER, BOAT, SUBMARINE, SAILBOAT } = require("%appGlobals/unitConst.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let getTagsUnitName = require("%appGlobals/getTagsUnitName.nut")
let { mkToBattleButtonWithSquadManagement } = require("%rGui/mainMenu/toBattleButton.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { hangarUnitName, setHangarUnitWithSkin } = require("%rGui/unit/hangarUnit.nut")
let { defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { textButtonCommon, buttonsHGap, buttonsVGap } = require("%rGui/components/textButton.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let chooseByNameWnd = require("%rGui/debugTools/debugSkins/chooseByNameWnd.nut")
let { mkCfg, debugOfflineBattleCfg, openOfflineBattleMenu, isOfflineBattlesActive, savedUnitType, savedUnitName,
  isDebugListMapsActive, canAccessForDebug, savedMissionName, runOfflineBattle, initOfflineBattlesData,
  refreshOfflineMissionsList, savedOBDebugMissionName, skipMissionSettings, unitPresetsLevelList, savedUnit,
  savedBotsCount, savedBotsRank, defMaxBotsCount, defMaxBotsRank, NUMBER_OF_PLAYERS, savedUnitPresetLevel,
} = require("%rGui/gameModes/offlineBattlesState.nut")
let { registerScene } = require("%rGui/navState.nut")
let { verticalToggleWithLabel, horizontalToggleWithLabel } = require("%rGui/components/toggle.nut")
let { addModalWindowWithHeader, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { sliderWithButtons } = require("%rGui/components/slider.nut")
let { OCT_LIST } = require("%rGui/options/optCtrlType.nut")
let mkOption = require("%rGui/options/mkOption.nut")
let mkUnitPkgDownloadInfo = require("%rGui/unit/mkUnitPkgDownloadInfo.nut")


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
let unitTypeByCampaign = {
  air = AIR
  tanks = TANK
  ships = SHIP
}

let needShowBattleSettingsWnd = mkWatched(persist, "needShowBattleSettingsWnd", false)

let close = @() isOfflineBattlesActive.set(false)

let setHangarUnit = @() getCampaignPresentation(curCampaign.get()).campaign != campaignByUnitType?[savedUnitType.get()]
  ? savedUnitName.set(serverConfigs.get()?.allUnits.findindex(@(unit) unit.unitType == savedUnitType.get()))
  : savedUnitName.set(getTagsUnitName(curUnit.get()?.name))

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
  let gmCfg = mkGameModeByCampaign(getCampaignPresentation(campaign).campaign)
  let isCommonUnit = Computed(function() {
    let unit = allUnits.get()?[savedUnitName.get()] ?? allUnits.get()?[$"{savedUnitName.get()}_nc"] ?? {}
    let { isPremium = false, isHidden = false } = unit
    return !isPremium && !isHidden
  })

  let maxBotsCount = Computed(function() {
    let maxBotsByCfg = gmCfg.get()?.mission_decl.maxBots
    let maxBotSlots = maxBotsByCfg != null ? maxBotsByCfg : defMaxBotsCount
    return maxBotSlots - NUMBER_OF_PLAYERS
  })

  let maxBotsRank = Computed(function() {
    local res = 1
    foreach (unit in allUnits.get())
      if (getCampaignPresentation(unit.campaign).campaign == campaign)
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
    visible = isCommonUnit
    valToString = @(v) loc($"mainmenu/offlineBattles/unitPreset/{v}")
  }

  return {
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    padding = hdpx(40)
    gap = hdpx(40)
    function onAttach() {
      let selectedUnit = allUnits.get()?[savedUnitName.get()] ?? allUnits.get()?[$"{savedUnitName.get()}_nc"] ?? {}
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

let setParamsAndRunBattle = @() skipMissionSettings.get()
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
  size = FLEX_H
  valign = ALIGN_TOP
  flow = FLOW_HORIZONTAL
  gap = buttonsHGap
  children = [
    backButton(close)
    {
      rendObj = ROBJ_TEXT
      size = FLEX_H
      text = loc("mainmenu/offlineBattles")
    }.__update(fontBig)
    {
      flow = FLOW_VERTICAL
      gap = buttonsVGap
      children
    }
  ]
}

let wndFooter = @() {
  watch = canAccessForDebug
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  valign = ALIGN_BOTTOM
  gap = buttonsHGap
  children = [
    !canAccessForDebug.get() ? null
      : {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = buttonsHGap
          children = [
            textButtonCommon(utf8ToUpper(loc("mainmenu/offlineBattles/debug/useHangarUnit")), setHangarUnit)
            horizontalToggleWithLabel(skipMissionSettings, loc("mainmenu/offlineBattles/settings/skipMissionSettings"),
              {
                maxWidth = defButtonMinWidth
                behavior = Behaviors.Marquee
              })
          ]
        }
    {
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = buttonsVGap
      halign = ALIGN_RIGHT
      children = [
        toBattleHint(loc("mainmenu/btnSingleLocalMission"))
        mkToBattleButtonWithSquadManagement(setParamsAndRunBattle)
      ]
    }
  ]
}

let mkSelector = @(curValue, allValues, setValue, mkLoc, mkValues, title = "") @() {
  watch = curValue
  children = textButtonCommon(utf8ToUpper(mkLoc(curValue.get())),
    @(event) chooseByNameWnd(event.targetRect,
      title
      mkValues(allValues?.get() ?? allValues, mkLoc),
      curValue.get(),
      setValue))
}

let mkMisContent = @(cfg, allMissions, curMissionName, curUnitType) @() {
  watch = allMissions
  children = allMissions.get().len() == 0
    ? textButtonCommon(utf8ToUpper(loc("options/mislist/empty")), @() null)
    : mkSelector(curMissionName,
        allMissions,
        @(value) savedMissionName.set(value),
        @(id) cfg.get()?.missions[curUnitType.get()][id] || id,
        @(allValues, mkLoc) allValues.keys().sort().map(@(value) { text = mkLoc(value), value }),
        loc("options/mislist"))
}

function mkDebugMisContent(curUnitType) {
  let cfg = debugOfflineBattleCfg()
  let allDebugMissions = Computed(@() cfg.get()?[curUnitType.get()] ?? {})
  let curDebugMissionName = Computed(@() savedOBDebugMissionName.get() in allDebugMissions.get()
    ? savedOBDebugMissionName.get()
    : allDebugMissions.get().findindex(@(_) true))

  savedUnitType.subscribe(@(_) savedOBDebugMissionName.set(curDebugMissionName.get()))

  return @() {
    watch = allDebugMissions
    children = allDebugMissions.get().len() == 0
      ? textButtonCommon(utf8ToUpper(loc("options/mislist/empty")), @() null)
      : mkSelector(curDebugMissionName,
          allDebugMissions,
          @(value) savedOBDebugMissionName.set(value),
          @(id) cfg.get()?[curUnitType.get()][id] || id,
          @(allValues, mkLoc) allValues.keys().sort().map(@(value) { text = mkLoc(value), value }),
          loc("options/mislist"))
  }
}

function mkContent() {
  let cfg = mkCfg()
  let allUnitTypes = Computed(@() cfg.get().unitTypes.keys().sort())
  let curUnitType = Computed(function() {
    let curTypeByCampaign = unitTypeByCampaign?[getCampaignPresentation(curCampaign.get()).campaign]
    return allUnitTypes.get().contains(savedUnitType.get()) ? savedUnitType.get()
      : curTypeByCampaign != null ? curTypeByCampaign
      : allUnitTypes.get()?[0]
  })
  let unitsByType = Computed(@() cfg.get()?.allUnits[curUnitType.get()] ?? {})
  let allMissions = Computed(@() cfg.get()?.missions[curUnitType.get()] ?? {})

  let curData = Computed(function() {
    local name = getTagsUnitName(savedUnitName.get() ?? hangarUnitName.get())
    local mission = savedMissionName.get()
    local units = unitsByType.get()
    name = name in units ? name : getTagsUnitName(units.findindex(@(_) true) ?? "")
    mission = mission in allMissions.get() ? mission : allMissions.get().findindex(@(_) true)
    return { name, units, mission }
  })
  let curUnitName = Computed(@() curData.get().name)
  let curMissionName = Computed(@() curData.get().mission)

  let onUnitChange = @(name) name != null
    ? setHangarUnitWithSkin(name, "")
    : null

  let initMissionName = @(mission) (mission != null && !isDebugListMapsActive.get())
    ? savedMissionName.set(mission)
    : null

  function onUnitTypeChange(_unitType) {
    savedUnitName.set(getTagsUnitName(curUnitName.get() ?? hangarUnitName.get()))
    savedMissionName.set(curMissionName.get() ?? allMissions.get().findindex(@(_) true) ?? "")
  }

  return @() {
    watch = [cfg, isDebugListMapsActive, canAccessForDebug, initOfflineBattlesData]
    key = onUnitChange
    size = flex()
    flow = FLOW_VERTICAL
    gap = hdpx(30)
    function onAttach() {
      refreshOfflineMissionsList()

      if (initOfflineBattlesData.get() != null) {
        let { unitType, unitName, missionName } = initOfflineBattlesData.get()
        savedUnitType.set(unitType)
        savedUnitName.set(unitName)
        savedMissionName.set(missionName)
      } else {
        savedUnitType.set(getUnitType(hangarUnitName.get()))
        setHangarUnit()
        savedMissionName.set(curMissionName.get() ?? allMissions.get().findindex(@(_) true) ?? "")
      }

      curUnitName.subscribe(onUnitChange)
      savedUnitType.subscribe(onUnitTypeChange)

      deferOnce(function() {
        onUnitChange(curUnitName.get())
        initMissionName(curMissionName.get())
      })
    }
    function onDetach() {
      curUnitName.unsubscribe(onUnitChange)
      savedUnitType.unsubscribe(onUnitTypeChange)
    }
    children = [
      {
        size = flex()
        flow = FLOW_VERTICAL
        gap = hdpx(30)
        children = [
          wndHeader([
            mkSelector(curUnitType,
              allUnitTypes,
              @(value) savedUnitType.set(value),
              @(name) loc($"campaign/{campaignByUnitType?[name] ?? "tanks"}"),
              @(allValues, mkLoc) allValues.map(@(value) { text = mkLoc(value), value }),
              loc("changeCampaignShort"))
            mkSelector(curUnitName,
              Computed(@() curData.get().units),
              @(value) savedUnitName.set(value),
              @(name) loc(getUnitLocId(name ?? "")),
              @(allValues, mkLoc) allValues.keys().sort().filter(@(v) v != "dummy_plane").map(@(value) { text = mkLoc(value), value }),
              loc("slotbar/selectUnit"))
            isDebugListMapsActive.get() && canAccessForDebug.get()
              ? mkDebugMisContent(curUnitType)
              : mkMisContent(cfg, allMissions, curMissionName, curUnitType)
            !canAccessForDebug.get() ? null
              : verticalToggleWithLabel(isDebugListMapsActive, loc("mainmenu/offlineBattles/debug/maps"))
          ])
        ]
      }
      { size = flex() }
      mkUnitPkgDownloadInfo(savedUnit, true, { halign = ALIGN_LEFT, hplace = ALIGN_LEFT })
      wndFooter
    ]
  }
}

let offlineBattlesWnd = {
  key = {}
  size = flex()
  padding = saBordersRv
  behavior = HangarCameraControl
  touchMarginPriority = TOUCH_BACKGROUND
  animations = wndSwitchAnim
  children = mkContent()
}

registerScene("offlineBattlesWnd", offlineBattlesWnd, close, isOfflineBattlesActive)

register_command(openOfflineBattleMenu, "ui.debug.offlineBattlesWnd")
