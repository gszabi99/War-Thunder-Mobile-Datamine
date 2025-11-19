from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { slotExpTanks, SLOT_EXP_TANKS } = require("%appGlobals/currenciesState.nut")
let { curSlots } = require("%appGlobals/pServer/slots.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { buy_slots_exp, registerHandler, slotInProgress } = require("%appGlobals/pServer/pServerApi.nut")
let { isLoggedIn } = require("%appGlobals/loginState.nut")
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { backButton, backButtonHeight } = require("%rGui/components/backButton.nut")
let { slider, sliderValueSound, sliderH } = require("%rGui/components/slider.nut")
let { textButtonPrimary } = require("%rGui/components/textButton.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { mkSpinnerHideBlock } = require("%rGui/components/spinner.nut")
let { selectColor } = require("%rGui/style/stdColors.nut")
let { mkSlotLevel, mkSlotLevelIcon } = require("%rGui/attributes/slotAttr/slotLevelComp.nut")
let { mkProgressBtnContentDec, mkProgressBtnContentInc, mkProgressBtn, knobCtor,
  progressBtnSize
} = require("%rGui/attributes/attrBlockComp.nut")
let { isOpenedSlotExpWnd } = require("%rGui/attributes/slotAttr/slotAttrState.nut")
let { bgUnit, unitPlateRatio } = require("%rGui/unit/components/unitPlateComp.nut")
let { maxSlotLevels } = require("%rGui/slotBar/slotBarState.nut")
let { decimalFormat } = require("%rGui/textFormatByLang.nut")


let slotWidth = evenPx(370)
let slotHeight = (slotWidth * unitPlateRatio).tointeger()
let slotSize = [slotWidth, slotHeight]
let gap = hdpx(20)
let levelImageSize = evenPx(30)
let priceBlockWidth = hdpx(150)
let sliderWidth = saSize[0] - slotSize[0] - 6 * gap - 2 * progressBtnSize - priceBlockWidth
let lvlProgressBorder = hdpx(2)
let lvlProgressHeight = 5 * lvlProgressBorder

let expIconSize = hdpx(30)

let chosenExp = mkWatched(persist, "chosenExp", {})
let curBalance = Computed(@() slotExpTanks.get() - chosenExp.get().reduce(@(a, b) a + b, 0))

let closeSlotExpWnd = @() isOpenedSlotExpWnd.set(false)

slotExpTanks.subscribe(@(v) v == 0 ? closeSlotExpWnd() : null)

registerHandler("onBuySlotsExp", @(res) res?.error == null ? chosenExp.set({}) : null)
isLoggedIn.subscribe(@(_) chosenExp.set({}))

function buySlotsExp() {
  let expList = curSlots.get().map(@(_, i) chosenExp.get()?[i] ?? 0)
  if (expList.findindex(@(v) v > 0) != null)
    buy_slots_exp(curCampaign.get(), SLOT_EXP_TANKS, expList, "onBuySlotsExp")
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
  size = [flex(), SIZE_TO_CONTENT]
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
    { size = flex() }
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
  padding = [lvlProgressHeight, 0, 0, 0] 
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
    expPart <= 0 ? { size = [flex(), lvlProgressHeight] }
      : {
          size = [flex(), lvlProgressHeight]
          padding = lvlProgressBorder
          rendObj = ROBJ_SOLID
          color = 0xFF000000
          children = {
            size = [pw(100 * expPart), flex()]
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
    if (curLevel.get() >= maxSlotLevels.get().len())
      return res
    local sum = (maxSlotLevels.get()?[curLevel.get()].exp ?? 0) - curExp.get()
    res.append(sum)
    let total = maxSlotLevels.get().len()
    for (local lvl = curLevel.get() + 1; lvl < total; lvl++) {
      sum += maxSlotLevels.get()[lvl].exp
      res.append(sum)
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
  let curExpPart = Computed(@() curLevel.get() not in maxSlotLevels.get() ? 0.0
    : curExp.get().tofloat() / maxSlotLevels.get()[curLevel.get()].exp)
  let expPart = Computed(@() level.get() not in maxSlotLevels.get() ? 0.0
    : (slotChosenExp.get() - (expSum.get()?[level.get() - 1] ?? 0) + (curLevel.get() == level.get() ? curExp.get() : 0)).tofloat()
        / maxSlotLevels.get()[level.get()].exp)

  let incCost = Computed(@() (maxSlotLevels.get()?[level.get()].exp ?? 0) - (level.get() == curLevel.get() ? curExp.get() : 0))
  let canDec = Computed(@() level.get() > curLevel.get())
  let canInc = Computed(@() incCost.get() > 0 && curBalance.get() > 0)

  function onChange(newLevel) {
    local newExp = (expSum.get()?[newLevel - 1] ?? 0)
    let leftBalance = slotChosenExp.get() + curBalance.get()
    newExp = clamp(newExp, 0, max(leftBalance, 0))
    if (newExp == slotChosenExp.get())
      return
    sliderValueSound()
    chosenExp.set(chosenExp.get().__merge({ [idx] = newExp }))
  }

  return {
    size = [flex(), slotHeight]
    padding = gap
    rendObj = ROBJ_SOLID
    color = 0x70000000
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap
    children = [
      mkProgressBtn(mkProgressBtnContentDec(canDec), @() onChange(level.get() + (expPart.get() == 0 ? -1 : 0)))
      {
        size = [sliderWidth, flex()]
        valign = ALIGN_CENTER
        children = [
          sliderHeader(curLevel, curExpPart, level, expPart)
          @() {
            watch = maxSlotLevels
            children = slider(level,
              {
                size = [sliderWidth, sliderH]
                max = maxSlotLevels.get()?.len() ?? 0,
                onChange
              },
              knobCtor)
          }
        ]
      }
      mkProgressBtn(mkProgressBtnContentInc(canInc), @() onChange(level.get() + 1))
      @() {
        watch = incCost
        size = [priceBlockWidth, flex()]
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
  size = [flex(), slotHeight]
  flow = FLOW_HORIZONTAL
  gap
  children = [
    mkSlot(slot, idx)
    mkSlider(idx)
  ]
}

let slots = @() {
  watch = curSlots
  size = flex()
  flow = FLOW_VERTICAL
  gap
  children = curSlots.get().map(mkRow)
}

let navBar = @() {
  watch = [slotExpTanks, curBalance]
  size = [ flex(), defButtonHeight ]
  children = slotExpTanks.get() == curBalance.get() ? null
    : mkSpinnerHideBlock(Computed(@() slotInProgress.get() != null),
        textButtonPrimary(utf8ToUpper(loc("msgbox/btn_confirm")), buySlotsExp),
        {
          size = [ flex(), defButtonHeight ]
          halign = ALIGN_RIGHT
        })
}

let slotExpWnd = {
  key = {}
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap
  children = [
    header
    {
      size = flex()
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
