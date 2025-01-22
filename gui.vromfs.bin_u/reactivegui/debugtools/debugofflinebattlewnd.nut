from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { deferOnce } = require("dagor.workcycle")
let { register_command } = require("console")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { mkToBattleButtonWithSquadManagement } = require("%rGui/mainMenu/toBattleButton.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { hangarUnitName, setHangarUnitWithSkin } = require("%rGui/unit/hangarUnit.nut")
let { defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let chooseByNameWnd = require("debugSkins/chooseByNameWnd.nut")
let { mkCfg, openOfflineBattleMenu, isOpened, savedUnitType, savedUnitName,
  savedMissionName, runOfflineBattle, refreshOfflineMissionsList } = require("debugOfflineBattleState.nut")
let { registerScene } = require("%rGui/navState.nut")

let close = @() isOpened.set(false)

function initUnitWnd() {
  savedUnitType(getUnitType(hangarUnitName.get()))
  savedUnitName(hangarUnitName.get())
}

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
    mkToBattleButtonWithSquadManagement(@() runOfflineBattle())
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

function mkOfflineBattleMenuWnd() {
  let cfg = mkCfg
  let allUnitTypes = cfg.get().unitTypes.keys().sort()
  let curUnitType = Computed(@() allUnitTypes.contains(savedUnitType.get()) ? savedUnitType.get() : allUnitTypes?[0])
  let unitsByType = Computed(@() cfg.get()?.allUnits[curUnitType.get()] ?? {})
  let allMissions = Computed(@() cfg.get()?.missions[curUnitType.get()] ?? {})

  let curData = Computed(function() {
    local name = savedUnitName.get()
    local mission = savedMissionName.get()
    local units = unitsByType.get()
    name = name in units ? name : units.findindex(@(_) true)
    mission = mission in allMissions.get() ? mission : allMissions.get().findindex(@(_) true)
    return { name, units, mission }
  })
  let curUnitName = Computed(@() curData.get().name)
  let curMissionName = Computed(@() curData.get().mission)
  if (savedMissionName.get() == null)
    savedMissionName.set(curMissionName.get())

  function onUnitChange() {
    if (curUnitName.get() != null)
      setHangarUnitWithSkin(curUnitName.get(), "")
  }
  curUnitName.subscribe(@(_) deferOnce(onUnitChange))
  savedUnitType.subscribe(function(_) {
    savedUnitName.set(curUnitName.get())
    savedMissionName.set(curMissionName.get())
  })

  return {
    watch = cfg
    key = isOpened
    size = flex()
    padding = saBordersRv
    behavior = HangarCameraControl
    touchMarginPriority = TOUCH_BACKGROUND
    flow = FLOW_VERTICAL
    gap = hdpx(30)
    function onAttach() {
      refreshOfflineMissionsList()
      initUnitWnd()
      onUnitChange()
    }
    children = [
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
          @(name) loc(getUnitLocId(name)),
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
      {
        size = flex()
      }
      wndFooter
    ]
    animations = wndSwitchAnim
  }
}

registerScene("debugOfflineBattleWnd", mkOfflineBattleMenuWnd, close, isOpened)

register_command(openOfflineBattleMenu, "ui.debug.offlineBattleMenu")
