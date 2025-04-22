from "%globalsDarg/darg_library.nut" import *
let { round } = require("math")
let { eventbus_send } = require("eventbus")
let { register_command } = require("console")
let { deferOnce } = require("dagor.workcycle")
let { object_to_json_string } = require("json")
let io = require("io")
let { get_settings_blk } = require("blkGetters")
let { HangarCameraControl } = require("wt.behaviors")
let { arrayByRows, deep_clone } = require("%sqstd/underscore.nut")
let { registerScene } = require("%rGui/navState.nut")
let { getUnitType } = require("%appGlobals/unitTags.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { hangarUnitName, hangarUnitSkin, setHangarUnitWithSkin } = require("%rGui/unit/hangarUnit.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { textButtonCommon, textButtonPrimary } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let chooseSkinsUnitTypeWnd = require("chooseSkinsUnitTypeWnd.nut")
let chooseByNameWnd = require("chooseByNameWnd.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let { imageBtn, framedImageBtn } = require("%rGui/components/imageButton.nut")
let { unitSkinView, unknownSkinPreset } = require("%appGlobals/config/skinPresentation.nut")
let skinViewPresets = require("%appGlobals/config/skins/skinViewPresets.nut")
let { makeVertScroll } = require("%rGui/components/scrollbar.nut")


const SAVE_PATH = "../../skyquake/prog/scripts/wtm/globals/config/skins/unitSkinView.nut"
let isEditAllowed = get_settings_blk()?.debug.useAddonVromSrc ?? false

let isOpened = mkWatched(persist, "isOpened", false)
let savedUnitType = mkWatched(persist, "savedUnitType", null)
let savedUnitName = mkWatched(persist, "savedUnitName", null)
let savedUnitSkin = mkWatched(persist, "savedUnitSkin", "")
let isUnitNameFirst = mkWatched(persist, "isUnitNameFirst", true)
let selTag = Watched(null)
let selPreset = Watched(null)
let hasViewChanges = Watched(false) 

let wndHeaderHeight = hdpx(60)
let presetColumns = 5
let presetSize = hdpxi(110)
let presetBorderSize = round(presetSize*0.2).tointeger()
let presetGap = hdpx(20)
let selectedColor = 0x8052C4E4
let checkSize = [hdpxi(50), hdpxi(25)]
let underlineSize = hdpx(5)

let close = @() isOpened(false)

function initSkinsWnd() {
  savedUnitType(getUnitType(hangarUnitName.get()))
  savedUnitName(hangarUnitName.get())
  savedUnitSkin(hangarUnitSkin.get())
}

isOpened.subscribe(function(v) {
  if (!v && hasViewChanges.get())
    eventbus_send("reloadDargVM", { msg = "debug skins apply" })
})

function saveSkinView(view) {
  hasViewChanges(true)
  let saveTbl = view.map(@(mainList)
    mainList.map(@(list)
      list.map(@(v) v.id)))

  let file = io.file(SAVE_PATH, "wt+")
  file.writestring("return ")
  file.writestring(object_to_json_string(saveTbl, true))
  file.close()
  dlog("Saved to: wtm/globals/config/skins/unitSkinView.nut") 
}

function setPresetForAllUnits(skinsView, preset, curUnitName, curUnitSkin) {
  if (curUnitName.get() == null)
    return
  let unitType = getUnitType(curUnitName.get())
  let skin = curUnitSkin.get()
  if (skinsView.get().byUnitType?[unitType][skin].id == preset.id)
    return
  skinsView.mutate(function(v) {
    v.byUnitType[unitType] <- (v.byUnitType?[unitType] ?? {})
      .__merge({ [skin] = preset })
  })
}

function setPresetForOneUnit(skinsView, preset, curUnitName, curUnitSkin) {
  let name = curUnitName.get()
  if (name == null)
    return
  let skin = curUnitSkin.get()
  if (skinsView.get().byUnit?[name][skin].id == preset.id)
    return
  skinsView.mutate(function(v) {
    v.byUnit[name] <- (v.byUnit?[name] ?? {})
      .__merge({ [skin] = preset })
  })
}

let wndHeader = @(children) {
  size = [flex(), wndHeaderHeight]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(15)
  children = [
    backButton(close)
    {
      rendObj = ROBJ_TEXT
      size = [flex(), SIZE_TO_CONTENT]
      text = "ui.debug.skins"
    }.__update(fontBig)
  ].extend(children)
}

let unitTypeSelector = @(curUnitType, allUnitTypes) @() {
  watch = curUnitType
  children = textButtonPrimary(loc($"mainmenu/type_{curUnitType.get()}"),
    @(event) chooseSkinsUnitTypeWnd(event.targetRect, allUnitTypes.get(), curUnitType.get(), @(ut) savedUnitType(ut)))
}

let toggleBtn = @(isLeft, onClick, isActive) framedImageBtn(
  "ui/gameuiskin#spinnerListBox_arrow_up.svg",
  onClick,
  {
    size = [hdpx(70), hdpx(70)]
    opacity = isActive ? 1.0 : 0.3
    transform = { rotate = isLeft ? -90 : 90 }
  })

function withToggles(mainButton, curValue, allValues, setValue) {
  let order = Computed(@() allValues.get().keys().sort())
  let isFirst = Computed(@() order.get()?[0] == curValue.get())
  let isLast = Computed(@() order.get()?[order.get().len() - 1] == curValue.get())
  function toPrev() {
    let idx = order.get().indexof(curValue.get()) ?? -1
    if (idx > 0)
      setValue(order.get()[idx - 1])
  }
  function toNext() {
    let idx = order.get().indexof(curValue.get())
    if (idx != null && idx < order.get().len() - 1)
      setValue(order.get()[idx + 1])
  }
  return {
    size = [SIZE_TO_CONTENT, defButtonHeight]
    children = [
      mainButton
      @() {
        watch = [isFirst, isLast]
        pos = [0, defButtonHeight + hdpx(10)]
        hplace = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = hdpx(10)
        children = [
          toggleBtn(true, toPrev, !isFirst.get())
          toggleBtn(false, toNext, !isLast.get())
        ]
      }
    ]
  }
}

let getSkinName = @(skin) skin == "" ? "default" : skin
let unitSkinSelector = @(curUnitSkin, allAvailableSkins) withToggles(
  @() {
    watch = curUnitSkin
    children = textButtonPrimary(getSkinName(curUnitSkin.get()),
      @(event) chooseByNameWnd(event.targetRect,
        isUnitNameFirst.get() ? "Choose skin for unit" : "Choose skin for unit type"
        allAvailableSkins.get().keys().sort().map(@(value) { text = getSkinName(value), value }),
        curUnitSkin.get(),
        @(value) savedUnitSkin.set(value)))
  },
  curUnitSkin,
  allAvailableSkins,
  @(value) savedUnitSkin.set(value))

let unitSelector = @(curUnitName, allAvailableUnits) withToggles(
  @() {
    watch = curUnitName
    children = textButtonPrimary(loc(getUnitLocId(curUnitName.get())),
      @(event) chooseByNameWnd(event.targetRect,
        isUnitNameFirst.get() ? "Choose unit for unit type" : "Choose unit for skin"
        allAvailableUnits.get().keys().sort().map(@(value) { text = loc(getUnitLocId(value)), value }),
        curUnitName.get(),
        @(value) savedUnitName.set(value)))
  },
  curUnitName,
  allAvailableUnits,
  @(value) savedUnitName.set(value))

let swapButton = @(curUnitName, curUnitSkin) imageBtn("ui/gameuiskin#decor_change_icon.svg",
  function() {
    savedUnitName.set(curUnitName.get())
    savedUnitSkin.set(curUnitSkin.get())
    isUnitNameFirst.set(!isUnitNameFirst.get())
  })

function mkTagButton(tag) {
  let stateFlags = Watched(0)
  let isSelected = Computed(@() selTag.get() == tag)
  let underline = @() {
    watch = [isSelected, stateFlags]
    size = [flex(), underlineSize]
    pos = [0, underlineSize]
    vplace = ALIGN_BOTTOM
    rendObj = ROBJ_SOLID
    color = isSelected.get() ? 0xFFFFFFFF : 0
  }
  return @() {
    watch = [stateFlags, isSelected]
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick = @() selTag.set(tag)
    rendObj = ROBJ_TEXT
    text = tag
    color = isSelected.get() ? 0xFFFFFFFF : 0xFFC0C0C0
    transform = { scale = stateFlags.get() & S_ACTIVE ? [0.95, 0.95] : [1, 1] }
    transitions = [{ prop = AnimProp.scale, duration = 0.2, easing = InOutQuad }]

    children = underline
  }.__update(fontSmall)
}

function tagsList() {
  let tags = skinViewPresets
    .reduce(@(res, p) res.$rawset(p.tag, true), {})
    .keys()
    .sort()
  return {
    flow = FLOW_HORIZONTAL
    padding = hdpx(20)
    rendObj = ROBJ_SOLID
    color = 0x40000000
    gap = hdpx(20)
    children = tags.map(mkTagButton)
  }
}

let currentForUnitMark = @(isCurrentForUnit) @()
  !isCurrentForUnit.get() ? { watch = isCurrentForUnit }
    : {
        watch = isCurrentForUnit
        size = checkSize
        margin = hdpx(7)
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#check.svg:{checkSize[0]}:{checkSize[1]}:P")
        imageHalign = ALIGN_LEFT
        keepAspect = true
        color = 0xFFFFFFFF
      }

let defaultForSkinMark = @(isDefaultForSkin) @()
  !isDefaultForSkin.get() ? { watch = isDefaultForSkin }
    : {
        watch = isDefaultForSkin
        size = checkSize
        margin = hdpx(7)
        hplace = ALIGN_RIGHT
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#lobby_social_icon.svg:{checkSize[0]}:{checkSize[1]}:P")
        imagehalign = ALIGN_RIGHT
        keepAspect = true
        color = 0xFFFFFFFF
      }

let function presetBtn(preset, isCurrentForUnit, isDefaultForSkin) {
  let stateFlags = Watched(0)
  let { id, image } = preset
  let isSelected = Computed(@() selPreset.get()?.id == id)
  return @() {
    watch = stateFlags
    key = preset
    size = [presetSize, presetSize]
    rendObj = ROBJ_BOX
    fillColor = 0xFFFFFFFF
    borderRadius = presetBorderSize
    image = Picture($"ui/gameuiskin#{image}:{presetSize}:{presetSize}:P")
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick = @() selPreset.set(preset)
    transform = { scale = (stateFlags.get() & S_ACTIVE) != 0 ? [0.95, 0.95] : [1, 1] }
    children = [
      @() {
        watch = [isSelected, stateFlags]
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#slot_border.svg:{presetSize}:{presetSize}:P")
        color = isSelected.get() ? selectedColor : 0
      }
      currentForUnitMark(isCurrentForUnit)
      defaultForSkinMark(isDefaultForSkin)
    ]
  }
}


let presetsList = @(curSkinUnitPreset, curSkinDefaultPreset) function() {
  let tag = selTag.get()
  let presets = skinViewPresets.filter(@(p) p.tag == tag)
    .values()
    .sort(@(a, b) a.id <=> b.id)
    .map(@(p) presetBtn(p,
        Computed(@() curSkinUnitPreset.get()?.id == p.id),
        Computed(@() curSkinDefaultPreset.get()?.id == p.id)
      ))
  return {
    watch = selTag
    size = [SIZE_TO_CONTENT, flex()]
    children = makeVertScroll(
      {
        padding = [0, presetGap, 0, 0]
        flow = FLOW_VERTICAL
        gap = presetGap
        children = arrayByRows(presets, presetColumns).map(@(column) {
          flow = FLOW_HORIZONTAL
          gap = presetGap
          children = column
        })
      }
      { size = [SIZE_TO_CONTENT, flex()] })
  }
}

let function presetView(preset, curSkinUnitPreset, curSkinDefaultPreset) {
  let { id, image } = preset
  let isCurrentForUnit = Computed(@() curSkinUnitPreset.get()?.id == id)
  let isDefaultForSkin = Computed(@() curSkinDefaultPreset.get()?.id == id)
  return {
    size = [presetSize, presetSize]
    rendObj = ROBJ_BOX
    fillColor = 0xFFFFFFFF
    borderRadius = presetBorderSize
    image = Picture($"ui/gameuiskin#{image}:{presetSize}:{presetSize}:P")
    children = [
      {
        size = [presetSize, presetSize]
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#{image}:{presetSize}:{presetSize}:P")
      }
      currentForUnitMark(isCurrentForUnit)
      defaultForSkinMark(isDefaultForSkin)
    ]
  }
}

let framedText = @(text) {
  padding = [hdpx(10), hdpx(20)]
  rendObj = ROBJ_SOLID
  color = 0x40000000
  children = {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    maxWidth = hdpx(800)
    text
    color = 0xFFC0C0C0
  }.__update(fontSmall)
}

let buttonsBlock = @(skinsView, curSkinUnitPreset, curSkinDefaultPreset, curUnitName, curUnitSkin) function() {
  let preset = selPreset.get()
  let { id = null } = preset
  return {
    watch = selPreset
    vplace = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    gap = hdpx(15)
    children = [
      preset == null ? null : presetView(preset, curSkinUnitPreset, curSkinDefaultPreset)
      framedText(id ?? "")
      @() {
        watch = [curSkinUnitPreset, curSkinDefaultPreset]
        flow = FLOW_HORIZONTAL
        gap = hdpx(15)
        children = id == null ? null
          : !isEditAllowed ? framedText($"To edit skins you must set\ndebug/<color={0xFFFFFFFF}>useAddonVromSrc</color>:b=yes\nin the config.blk")
          : [
              (curSkinDefaultPreset.get()?.id == id ? textButtonCommon : textButtonPrimary)(
                "Select for all units", @() setPresetForAllUnits(skinsView, preset, curUnitName, curUnitSkin)),
              (curSkinUnitPreset.get()?.id == id ? textButtonCommon : textButtonPrimary)(
                "Select for one unit", @() setPresetForOneUnit(skinsView, preset, curUnitName, curUnitSkin)),
            ]
      }
    ]
  }
}

function addToLists(res, keysToAdd, value) {
  foreach(k, _ in keysToAdd) {
    if (k not in res)
      res[k] <- {}
    res[k][value] <- true
  }
}

let mkCfg = @() Computed(function() {
  let skinsByUnitByType = {}
  let unitsBySkinByType = {}
  let unitTypes = {}
  function addSkins(name, skins) {
    let unitType = getUnitType(name)
    if (unitType not in unitTypes) {
      unitTypes[unitType] <- true
      skinsByUnitByType[unitType] <- {}
      unitsBySkinByType[unitType] <- {}
    }
    skinsByUnitByType[unitType][name] <- skins
    addToLists(unitsBySkinByType[unitType], skins, name)
  }
  foreach(unitName, unit in serverConfigs.get()?.allUnits ?? {}) {
    let skins = { [""] = true }.__merge(unit?.skins ?? {})
    let { platoonUnits = [] } = unit
    addSkins(unitName, skins)
    foreach(p in platoonUnits)
      addSkins(p.name, skins)
  }
  return { skinsByUnitByType, unitsBySkinByType, unitTypes }
})

function mkSkinView() {
  let res = Watched(deep_clone(unitSkinView))
  res.subscribe(saveSkinView)
  return res
}

function mkDebugTuneSkinsWnd() {
  let skinsView = mkSkinView()
  let cfg = mkCfg()
  let allUnitTypes = Computed(@() cfg.get().unitTypes.keys().sort())
  let curUnitType = Computed(@() allUnitTypes.get().contains(savedUnitType.get()) ? savedUnitType.get() : allUnitTypes.get()?[0])
  let unitsBySkin = Computed(@() cfg.get()?.unitsBySkinByType[curUnitType.get()] ?? {})
  let skinsByUnit = Computed(@() cfg.get()?.skinsByUnitByType[curUnitType.get()] ?? {})
  let curData = Computed(function() {
    local name = savedUnitName.get()
    local skin = savedUnitSkin.get()
    local skinChoice = unitsBySkin.get()
    local unitChoice = skinsByUnit.get()
    if (isUnitNameFirst.get()) {
      name = name in unitChoice ? name : unitChoice.findindex(@(_) true)
      skinChoice = unitChoice?[name] ?? {}
      skin = skin in skinChoice ? skin : skinChoice.findindex(@(_) true) ?? ""
    }
    else {
      skin = skin in skinChoice ? skin : skinChoice.findindex(@(_) true)
      unitChoice = skinChoice?[skin] ?? {}
      name = name in unitChoice ? name : unitChoice.findindex(@(_) true)
    }
    return { name, skin, skinChoice, unitChoice }
  })
  let curUnitName = Computed(@() curData.get().name)
  let curUnitSkin = Computed(@() curData.get().skin)

  let curSkinDefaultPreset = Computed(@() skinsView.get().byUnitType?[curUnitType.get()][curUnitSkin.get()]
    ?? unknownSkinPreset)
  let curSkinUnitPreset = Computed(@() skinsView.get().byUnit?[curUnitName.get()][curUnitSkin.get()]
    ?? curSkinDefaultPreset.get())

  function onUnitOrSkinChange() {
    if (curUnitName.get() != null)
      setHangarUnitWithSkin(curUnitName.get(), curUnitSkin.get())

    let preset = curSkinUnitPreset.get()
    if (preset != unknownSkinPreset) {
      selTag.set(preset.tag)
      selPreset.set(preset)
    }
  }
  curUnitName.subscribe(@(_) deferOnce(onUnitOrSkinChange))
  curUnitSkin.subscribe(@(_) deferOnce(onUnitOrSkinChange))

  let unitSkinSelectors = [
    unitSelector(curUnitName, Computed(@() curData.get().unitChoice))
    swapButton(curUnitName, curUnitSkin)
    unitSkinSelector(curUnitSkin, Computed(@() curData.get().skinChoice))
  ]
  let unitSkinSelectorsRev = (clone unitSkinSelectors).reverse()

  return {
    key = isOpened
    size = flex()
    padding = saBordersRv
    flow = FLOW_VERTICAL
    behavior = HangarCameraControl
    touchMarginPriority = TOUCH_BACKGROUND
    function onAttach() {
      initSkinsWnd()
      onUnitOrSkinChange()
    }
    gap = hdpx(40)
    children = [
      wndHeader([
        unitTypeSelector(curUnitType, allUnitTypes)
        @() {
          watch = isUnitNameFirst
          valign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = hdpx(5)
          children = isUnitNameFirst.get() ? unitSkinSelectors : unitSkinSelectorsRev
        }
      ])
      tagsList
      {
        size = flex()
        flow = FLOW_HORIZONTAL
        gap = presetGap
        children = [
          presetsList(curSkinUnitPreset, curSkinDefaultPreset)
          buttonsBlock(skinsView, curSkinUnitPreset, curSkinDefaultPreset, curUnitName, curUnitSkin)
        ]
      }
    ]
    animations = wndSwitchAnim
  }
}

registerScene("debugTuneSkinsWnd", mkDebugTuneSkinsWnd, close, isOpened)

register_command(@() isOpened(true), "ui.debug.skins")
