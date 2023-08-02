from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bulletsInfo, chosenBullets, bulletStep, bulletTotalSteps, bulletLeftSteps, setCurUnitBullets
} = require("bulletsChoiceState.nut")
let { bulletsAABB } = require("respawnAnimState.nut")
let { bg, bulletsBlockWidth, bulletsBlockMargin, headerText, header, gap, bulletsLegend } = require("respawnComps.nut")
let { slider, sliderValueSound, sliderBtn, mkSliderKnob } = require("%rGui/components/slider.nut")
let mkBulletSlot = require("mkBulletSlot.nut")
let respawnChooseBulletWnd = require("respawnChooseBulletWnd.nut")
let { getAmmoNameShortText } = require("%rGui/weaponry/weaponsVisual.nut")

let padding = hdpx(10)
let headerHeight = hdpx(105)
let choiceCount = Computed(@() chosenBullets.value.len())
let btnSize = evenPx(80)
let knobSize = evenPx(50)
let sliderGap = knobSize / 2 + (0.1 * btnSize).tointeger()
let sliderSize = [bulletsBlockWidth - 2 * (btnSize + sliderGap + padding), evenPx(80)]
let hoverColor = 0x8052C4E4

let curSlotName = Watched(-1)

let mkText = @(ovr) {
  rendObj = ROBJ_TEXT
  color = 0xFFFFFFFF
}.__update(fontTiny, ovr)

let function onHeaderClick(key, slotIdx) {
  if (slotIdx != null)
    respawnChooseBulletWnd(slotIdx, gui_scene.getCompAABBbyKey(key), gui_scene.getCompAABBbyKey("respawnWndContent"))
}

let function bulletHeader(bSlot, bInfo, maxCount) {
  let fromUnitTags = Computed(@() bulletsInfo.value?.fromUnitTags[bSlot.value?.name])
  let countText = Computed(@() $"{bSlot.value?.count ?? 0}/{bulletStep.value * maxCount.value}")
  let nameText = Computed(@() getAmmoNameShortText(bInfo.value))
  let { idx = -1 } = bSlot.value
  let key = $"respBulletsHeader{idx}"
  return @() bg.__merge({
    watch = [bInfo, bulletsInfo]
    key
    onAttach = @() deferOnce(function() {
      let aabb = gui_scene.getCompAABBbyKey(key)
      if (aabb != null)
        bulletsAABB.mutate(@(v) v.__update({ [idx] = aabb }))
    })
    size = [flex(), headerHeight]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick = function(){
      curSlotName(idx)
      onHeaderClick(key, bSlot.value?.idx)
    }
    children = [
      @() mkBulletSlot(bInfo.value, fromUnitTags.value, {
        watch = [fromUnitTags, bInfo]
      })
      {
        padding
        flow = FLOW_VERTICAL
        valign = ALIGN_CENTER
        halign = ALIGN_LEFT
        gap = { size = flex() }
        children = [
          @() mkText({ watch = nameText, text = nameText.value })
          @() mkText({ watch = countText, text = countText.value })
        ]
      }
    ]
  })
}

let btnBgOvr = { size = [btnSize, btnSize] }
let inactiveBtnOvr = { color = 0x30303030 }

let mkBtnTextCtor = @(override) @(ovrW) @(sf) @() {
  watch = ovrW
  rendObj = ROBJ_TEXT
  color = sf & S_HOVER ? hoverColor : 0xFFFFFFFF
}.__update(fontMedium, override, ovrW.value)
let btnTextDec = mkBtnTextCtor({ text = "-", pos = [0, -hdpx(4)] })
let btnTextInc = mkBtnTextCtor({ text = "+" })

let knobCtor = @(relValue, stateFlags, fullW)
  mkSliderKnob(relValue, stateFlags, fullW, { size = [knobSize, knobSize] })

let function bulletSlider(bSlot, maxCount) {
  let count = Computed(@() bSlot.value?.count ?? 0)
  let minOvr = Computed(@() count.value == 0 ? inactiveBtnOvr : {})
  let maxOvr = Computed(@() (bulletLeftSteps.value == 0
    || count.value >= maxCount.value * bulletStep.value)
      ? inactiveBtnOvr
      : {})
  let function onChange(value) {
    if (bSlot.value == null)
      return
    let newVal = clamp(value, 0, count.value + bulletLeftSteps.value * bulletStep.value)
    if (newVal == count.value)
      return
    sliderValueSound()
    let { name, idx } = bSlot.value
    setCurUnitBullets(idx, name, newVal)
  }
  return @() bg.__merge({
    watch = [maxCount, bulletStep]
    size = [flex(), headerHeight]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = sliderGap
    children = [
      sliderBtn(btnTextDec(minOvr),
        @() onChange(count.value - bulletStep.value),
        Computed(@() btnBgOvr.__merge(minOvr.value)))
      slider(count,
        {
          size = sliderSize
          unit = bulletStep.value
          min = 0
          max = maxCount.value * bulletStep.value
          onChange
        },
        knobCtor)
      sliderBtn(btnTextInc(maxOvr),
        @() onChange(count.value + bulletStep.value),
        Computed(@() btnBgOvr.__merge(maxOvr.value)))
    ]
  })
}

let function mkBulletSliderSlot(idx) {
  let bSlot = Computed(@() chosenBullets.value?[idx])
  let bInfo = Computed(@() bulletsInfo.value?.bulletSets[bSlot.value?.name])
  let maxCount = Computed(@() min(bulletTotalSteps.value,
    bulletsInfo.value?.fromUnitTags[bSlot.value?.name]?.maxCount ?? bulletTotalSteps.value))
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      bulletHeader(bSlot, bInfo, maxCount)
      bulletSlider(bSlot, maxCount)
    ]
  }
}

let function respawnBullets() {
  let res = { watch = [bulletsInfo, choiceCount], animations = wndSwitchAnim }
  if (bulletsInfo.value == null)
    return res
  let { caliber = 0.0, isBulletBelt = false } = bulletsInfo.value.bulletSets.findvalue(@(_) true)
  return res.__update({
    flow = FLOW_HORIZONTAL
    children = [
      {
        size = [bulletsBlockWidth, SIZE_TO_CONTENT]
        margin = [0, hdpx(20), 0, bulletsBlockMargin]
        flow = FLOW_VERTICAL
        gap
        children = [header(headerText(loc(isBulletBelt ? "machinegun/caliber" : "gun/caliber", { caliber })))]
          .extend(array(choiceCount.value).map(@(_, idx) mkBulletSliderSlot(idx)))
      },
      bulletsLegend
    ]
  })
}

return respawnBullets
