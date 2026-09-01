from "%globalsDarg/darg_library.nut" import *
from "console" import register_command
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/loginState.nut" import isLoggedIn
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%appGlobals/pServer/pServerApi.nut" import buy_slots_exp, registerHandler, slotInProgress
from "%appGlobals/pServer/slots.nut" import curSlots
from "%rGui/attributes/attrBlockComp.nut" import mkProgressBtnContentDec, mkProgressBtnContentInc, mkProgressBtn,
  knobCtor, progressBtnSize
from "%rGui/attributes/slotAttr/slotAttrState.nut" import isOpenedSlotExpWnd, curCampSlotExpId, curCampSlotExp
from "%rGui/attributes/slotAttr/slotLevelComp.nut" import mkSlotLevel, mkSlotLevelIcon
from "%rGui/components/backButton.nut" import backButton, backButtonHeight
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/slider.nut" import slider, mkSliderOnChangeSound, sliderH
from "%rGui/components/spinner.nut" import mkSpinnerHideBlock
from "%rGui/components/textButton.nut" import textButtonPrimary
from "%rGui/navState.nut" import registerScene
from "%rGui/slotBar/slotBarState.nut" import slotLevelsCfg, slotMaxLevel
from "%rGui/style/stdAnimations.nut" import wndSwitchAnim
from "%rGui/style/stdColors.nut" import selectColor
from "%rGui/textFormatByLang.nut" import decimalFormat
from "%rGui/unit/components/unitPlateComp.nut" import bgUnit, unitPlateRatio


let slotWidth = evenPx(370)
let slotHeight = (slotWidth * unitPlateRatio).tointeger()
let slotSize = [slotWidth, slotHeight]
const gap = hdpx(20)
let levelImageSize = evenPx(30)
const priceBlockWidth = hdpx(150)
let sliderWidth = saSize[0] - slotSize[0] - 6 * gap - 2 * progressBtnSize - priceBlockWidth
const lvlProgressBorder = hdpx(2)
const lvlProgressHeight = 5 * lvlProgressBorder

const expIconSize = hdpx(30)

let chosenExp = mkWatched(persist, "chosenExp", {})
let curBalance = Computed(@() curCampSlotExp.get() - chosenExp.get().reduce(@(a, b) a + b, 0))
let isSlotInProgress = Computed(@() slotInProgress.get() != null)

let closeSlotExpWnd = @() isOpenedSlotExpWnd.set(false)

curCampSlotExp.subscribe(@(v) v == 0 ? closeSlotExpWnd() : null)

registerHandler("onBuySlotsExp", @(res) res?.error == null ? chosenExp.set({}) : null)
isLoggedIn.subscribe(@(_) chosenExp.set({}))

function buySlotsExp() {
  let expList = curSlots.get().map(@(_, i) chosenExp.get()?[i] ?? 0)
  if (expList.findindex(@(v) v > 0) != null)
    buy_slots_exp(curCampaign.get(), curCampSlotExpId.get(), expList, "onBuySlotsExp")
}

let textComp = @(text, ovr = {}) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontTiny, ovr)

let header = {
  size = [SIZE_TO_CONTENT, backButtonHeight]
  vplace = ALIGN_TOP
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    backButton(closeSlotExpWnd)
    textComp(loc("slotExp/title"), fontMedium)
  ]
}

let totalExpCount = @() {
  size = const [FLEX, SIZE_TO_CONTENT]
  padding = hdpx(20)
  rendObj = ROBJ_SOLID
  color = 0x70000000
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(50)
  children = [
    textComp(loc("slotExp/expLeft"), fontMedium)
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = hdpx(10)
      children = [
        {
          size = expIconSize
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#experience_icon.svg:{expIconSize}:{expIconSize}:P")
          color = 0xFF65BC82
        }
        @() textComp(decimalFormat(curBalance.get()),
          {
            watch = curBalance
            color = curBalance.get() < 0 ? 0xFFFF0000 : 0xFFFFFFFF
          }.__update(fontMedium))
      ]
    }
  ]
}

let mkSlotInfo = @(slot, idx) {
  size = slotSize
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  children = [
    textComp(loc("gamercard/slot/title", { idx = idx + 1 }), fontVeryTinyAccented)
    { size = FLEX }
    mkSlotLevel(slot?.level ?? 0, levelImageSize)
  ]
}

let mkSlot = @(slot, idx) {
  size = slotSize
  rendObj = ROBJ_IMAGE
  image = bgUnit
  children = [
    {
      size = slotSize
      rendObj = ROBJ_IMAGE
      keepAspect = true
      image = Picture($"ui/gameuiskin/upgrades_tank_crew_icon.avif:{slotSize[0]}:{slotSize[1]}:P")
    }
    mkSlotInfo(slot, idx)
  ]
}

let toValTxt = textComp(" >>> ", { color = selectColor })

let mkLevel = @(level, expPart, color = 0xFFFFFFFF) {
  flow = FLOW_VERTICAL
  padding = const [lvlProgressHeight, 0, 0, 0] 
  children = [
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        mkSlotLevelIcon(level, levelImageSize)
        {
          rendObj = ROBJ_TEXT
          text = level
          color
        }.__update(fontMonoTiny)
      ]
    }
    expPart <= 0 ? { size = const [FLEX, lvlProgressHeight] }
      : {
          size = const [FLEX, lvlProgressHeight]
          padding = lvlProgressBorder
          rendObj = ROBJ_SOLID
          color = 0xFF000000
          children = {
            size = [pw(100 * expPart), FLEX]
            rendObj = ROBJ_SOLID
            color = 0xFFFFFFFF
          }
        }
  ]
}


let sliderHeader = @(curLevel, curExpPart, newLevel, newExpPart) {
  size = FLEX_H
  pos = [0, -0.3 * slotHeight]
  valign = ALIGN_CENTER
  children = [
    textComp(loc("slot/level"))
    @() {
      watch = [curLevel, newLevel, curExpPart, newExpPart]
      hplace = ALIGN_RIGHT
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      children = newLevel.get() == curLevel.get() ? mkLevel(curLevel.get(), curExpPart.get())
        : [
            mkLevel(curLevel.get(), curExpPart.get())
            toValTxt
            mkLevel(newLevel.get(), newExpPart.get(), selectColor)
          ]
    }
  ]
}

function mkSlider(idx) {
  let curLevel = Computed(@() curSlots.get()?[idx].level ?? 0)
  let curExp = Computed(@() curSlots.get()?[idx].exp ?? 0)
  let expSum = Computed(function() {
    let res = array(curLevel.get(), 0)
    if (curLevel.get() >= slotMaxLevel.get())
      return res

    if ("upToLevel" not in slotLevelsCfg.get()?[0]) { 
      local sum = (slotLevelsCfg.get()?[curLevel.get()].exp ?? 0) - curExp.get()
      res.append(sum)
      let total = slotLevelsCfg.get().len()
      for (local lvl = curLevel.get() + 1; lvl < total; lvl++) {
        sum += slotLevelsCfg.get()[lvl].exp
        res.append(sum)
      }
    }
    else {
      local sum = -curExp.get()
      local fromLevel = curLevel.get()
      foreach (c in slotLevelsCfg.get()) {
        if (c.upToLevel <= fromLevel)
          continue
        for (local l = fromLevel; l < c.upToLevel; l++) {
          sum += c.exp
          res.append(sum)
        }
        fromLevel = c.upToLevel
      }
    }
    return res
  })
  let slotChosenExp = Computed(@() chosenExp.get()?[idx] ?? 0)
  let level = Computed(function() {
    let total = expSum.get().len()
    for (local lvl = curLevel.get(); lvl < total; lvl++)
      if (expSum.get()[lvl] > slotChosenExp.get())
        return lvl
    return total
  })
  let curLevelUpExp = Computed(@() ("upToLevel" not in slotLevelsCfg.get()?[0]) 
    ? (slotLevelsCfg.get()?[curLevel.get()].exp ?? 0)
    : (slotLevelsCfg.get().findvalue(@(c) c.upToLevel > curLevel.get())?.exp ?? 0)
  )
  let curExpPart = Computed(@() curLevelUpExp.get() <= 0 ? 0.0
    : curExp.get().tofloat() / curLevelUpExp.get())
  let levelFullCost = Computed(@() level.get() not in expSum.get() ? 0
    : (expSum.get()[level.get()] - (expSum.get()?[level.get() - 1] ?? 0)))
  let expPart = Computed(@() levelFullCost.get() <= 0 ? 0.0
    : (slotChosenExp.get() - (expSum.get()?[level.get() - 1] ?? 0) + (curLevel.get() == level.get() ? curExp.get() : 0)).tofloat()
        / (expSum.get()[level.get()] - (expSum.get()?[level.get() - 1] ?? 0)))

  let incCost = Computed(@() levelFullCost.get() - (level.get() == curLevel.get() ? curExp.get() : 0))
  let canDec = Computed(@() level.get() > curLevel.get())
  let canInc = Computed(@() incCost.get() > 0 && curBalance.get() > 0)

  let onChange = mkSliderOnChangeSound(function onChangeBase(newLevel) {
    local newExp = (expSum.get()?[newLevel - 1] ?? 0)
    let leftBalance = slotChosenExp.get() + curBalance.get()
    newExp = clamp(newExp, 0, max(leftBalance, 0))
    if (newExp == slotChosenExp.get())
      return false
    chosenExp.set(chosenExp.get().__merge({ [idx] = newExp }))
    return true
  })

  return {
    size = [FLEX, slotHeight]
    padding = gap
    rendObj = ROBJ_SOLID
    color = 0x70000000
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap
    children = [
      mkProgressBtn(mkProgressBtnContentDec(canDec), @() onChange(level.get() + (expPart.get() == 0 ? -1 : 0)))
      {
        size = [sliderWidth, FLEX]
        valign = ALIGN_CENTER
        children = [
          sliderHeader(curLevel, curExpPart, level, expPart)
          @() {
            watch = slotMaxLevel
            children = slider(level,
              {
                size = [sliderWidth, sliderH]
                max = slotMaxLevel.get(),
                onChange
              },
              knobCtor)
          }
        ]
      }
      mkProgressBtn(mkProgressBtnContentInc(canInc), @() onChange(level.get() + 1))
      @() {
        watch = incCost
        size = const [priceBlockWidth, FLEX]
        flow = FLOW_HORIZONTAL
        vplace = ALIGN_CENTER
        valign = ALIGN_CENTER
        halign = ALIGN_RIGHT
        gap = hdpx(5)
        children = incCost.get() == 0 ? null
          : [
              {
                size = expIconSize
                rendObj = ROBJ_IMAGE
                keepAspect = KEEP_ASPECT_FIT
                image = Picture($"ui/gameuiskin#experience_icon.svg:{expIconSize}:{expIconSize}:P")
                color = 0xFF65BC82
              }
              textComp(decimalFormat(incCost.get()), fontTiny)
            ]
      }
    ]
  }
}

let mkRow = @(slot, idx) {
  size = [FLEX, slotHeight]
  flow = FLOW_HORIZONTAL
  gap
  children = [
    mkSlot(slot, idx)
    mkSlider(idx)
  ]
}

let slots = @() {
  watch = curSlots
  size = FLEX
  flow = FLOW_VERTICAL
  gap
  children = curSlots.get().map(mkRow)
}

let navBar = @() {
  watch = [curCampSlotExp, curBalance]
  size = [ FLEX, defButtonHeight ]
  children = curCampSlotExp.get() == curBalance.get() ? null
    : mkSpinnerHideBlock(isSlotInProgress,
        textButtonPrimary(utf8ToUpper(loc("msgbox/btn_confirm")), buySlotsExp),
        {
          size = [ FLEX, defButtonHeight ]
          halign = ALIGN_RIGHT
        })
}

let slotExpWnd = {
  key = {}
  size = FLEX
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap
  children = [
    header
    {
      size = FLEX
      flow = FLOW_VERTICAL
      gap
      children = [
        totalExpCount
        slots
        navBar
      ]
    }
  ]
  animations = wndSwitchAnim
}

register_command(@() isOpenedSlotExpWnd.set(!isOpenedSlotExpWnd.get()), "ui.slot_exp_wnd")

registerScene("slotExpWnd", slotExpWnd, closeSlotExpWnd, isOpenedSlotExpWnd)
