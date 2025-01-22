from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bulletsInfo, chosenBullets, bulletStep, bulletTotalSteps, bulletLeftSteps, setCurUnitBullets,
  maxBulletsCountForExtraAmmo, hasExtraBullets, bulletsSecInfo, bulletSecStep, bulletSecLeftSteps
  chosenBulletsSec, bulletSecTotalSteps, hasExtraBulletsSec, maxBulletsSecCountForExtraAmmo, BULLETS_PRIM_SLOTS
} = require("bulletsChoiceState.nut")
let { bulletsAABB } = require("respawnAnimState.nut")
let { bg, bulletsBlockWidth, headerMargin, headerText, headerSlotHeight, header, bulletsLegend,
  mkBulletHeightInfo
} = require("respawnComps.nut")
let { slider, sliderValueSound, sliderBtn, mkSliderKnob } = require("%rGui/components/slider.nut")
let mkBulletSlot = require("mkBulletSlot.nut")
let { showRespChooseWnd, openedSlot } = require("respawnChooseBulletWnd.nut")
let { mkCustomButton } = require("%rGui/components/textButton.nut")
let { selSlot, hasUnseenShellsBySlot } = require("respawnState.nut")
let { mkPriorityUnseenMarkWatch } = require("%rGui/components/unseenMark.nut")
let { unitPlatesGap } = require("%rGui/unit/components/unitPlateComp.nut")

let padding = hdpx(8)
let choiceCount = Computed(@() chosenBullets.value.len())
let choiceSecCount = Computed(@() chosenBulletsSec.get().len())
let bulletCardStyle = mkBulletHeightInfo(choiceCount, choiceSecCount)
let btnSize = evenPx(80)
let knobSize = evenPx(50)
let sliderGap = knobSize / 2 + (0.1 * btnSize).tointeger()
let sliderSize = [bulletsBlockWidth - 2 * (btnSize + sliderGap + padding), evenPx(80)]
let hoverColor = 0x8052C4E4
let arrowSize = [ hdpxi(50),hdpxi(50)]

function onHeaderClick(key, slotIdx) {
  if (slotIdx != null)
    showRespChooseWnd(slotIdx, gui_scene.getCompAABBbyKey(key), gui_scene.getCompAABBbyKey("respawnWndContent"))
}

let arrowBtnImage = @(isOpened) {
  rendObj = ROBJ_IMAGE
  size = arrowSize
  flipX = !isOpened
  image = Picture($"ui/gameuiskin#arrow_icon.svg:{arrowSize[0]}:{arrowSize[1]}:P")
}

function bulletHeader(bSlot, bSet, bInfo) {
  let fromUnitTags = Computed(@() bInfo.get()?.fromUnitTags[bSlot.get()?.name])
  let { idx = -1 } = bSlot.value
  let key = $"respBulletsHeader{idx}"
  let hasUnseenBullets = Computed(@() (bSlot.value?.idx ?? 0) > 0
    && hasUnseenShellsBySlot.value?[selSlot.value?.id ?? 0].findvalue(@(v) v) != null)
  let isSecBullet = idx >= BULLETS_PRIM_SLOTS
  return @() {
    watch = [bSet, fromUnitTags]
    onAttach = @() deferOnce(function() {
      let aabb = gui_scene.getCompAABBbyKey(key)
      if (aabb != null)
        bulletsAABB.mutate(@(v) v.__update({ [idx] = aabb }))
    })
    size = [bulletsBlockWidth, headerSlotHeight]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    children = [
      {
        key
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          @() mkBulletSlot(isSecBullet, bSet.get(), fromUnitTags.get(), {}, {}, { watch = [fromUnitTags, bSet] })
          @() {
            watch = openedSlot
            size = [flex(), headerSlotHeight]
            rendObj = ROBJ_BOX
            borderWidth = openedSlot.value < 0 || idx != openedSlot.value ? 0 : hdpxi(4)
          }
        ]
      }
      @() {
        key = $"respBulletsBtn{idx}" //for UI tutorial
        size = flex()
        watch = openedSlot
        rendObj = ROBJ_SOLID
        color = 0x99000000
        children = [
          mkCustomButton(arrowBtnImage(
            openedSlot.value < 0 || idx != openedSlot.value), @() onHeaderClick(key, idx),
            {
              ovr = {
                size = [flex(),  headerSlotHeight]
                fillColor = 0xFF0593AD
                borderColor = 0xFF236DB5
              }
              gradientOvr = { color = 0xFF16B2E9 }
            })
          mkPriorityUnseenMarkWatch(hasUnseenBullets, { margin = [hdpx(7), hdpx(7)] })
        ]
      }
    ]
  }
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

function bulletSlider(bSlot, maxCount, maxBullets, withExtraBullets, bStep, bLeftSteps) {
  let count = Computed(@() bSlot.get()?.count ?? 0)
  let minOvr = Computed(@() count.get() == 0 ? inactiveBtnOvr : {})
  let maxOvr = Computed(@() (bLeftSteps.get() == 0
    || count.get() >= (withExtraBullets.get()
        ? maxBullets.get()
        : (maxCount.get() * bStep.get())))
      ? inactiveBtnOvr
      : {})
  function onChange(value) {
    if (bSlot.get() == null)
      return
    let newVal = clamp(value, 0, !withExtraBullets.get()
      ? (count.get() + bLeftSteps.get() * bStep.get())
      : maxBullets.get())
    if (newVal == count.get())
      return
    sliderValueSound()
    let { name, idx } = bSlot.get()
    setCurUnitBullets(idx, name, newVal)
  }
  return @() bg.__merge({
    watch = [ maxCount, bStep, withExtraBullets, maxBullets, bulletCardStyle ]
    size = [ flex(), bulletCardStyle.get().slotSliderHeight ]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = sliderGap
    padding = [padding, 0]
    children = [
      sliderBtn(btnTextDec(minOvr),
        @() onChange(count.get() - bStep.get()),
        Computed(@() btnBgOvr.__merge(minOvr.get())))
      slider(count,
        {
          size = [sliderSize[0], knobSize]
          unit = withExtraBullets.get() ? maxBullets.get() : bStep.get()
          min = 0
          max = withExtraBullets.get() ? maxBullets.get() : maxCount.get() * bStep.get()
          onChange
        },
        knobCtor).__update({ vplace = ALIGN_TOP })
      sliderBtn(btnTextInc(maxOvr),
        @() onChange(count.get() + bStep.get()),
        Computed(@() btnBgOvr.__merge(maxOvr.get())))
    ]
  })
}

function mkBulletSliderSlot(idx, bInfo, bullets, bTotalSteps, bStep, maxBullets, withExtraBullets, bLeftSteps) {
  let bSlot = Computed(@() bullets.get()?[idx])
  let bSet = Computed(@() bInfo.get()?.bulletSets[bSlot.get()?.name])
  let maxCount = Computed(@() min(bTotalSteps.get(),
    bInfo.get()?.fromUnitTags[bSlot.get()?.name]?.maxCount ?? bTotalSteps.get()))
  let maxCountByStep = Computed(@() maxCount.get() * bStep.get())
  let maxBulletsWithExtraCount = Computed(@() maxBullets.get()?[idx])
  let maxCountText = Computed(@() $"{!withExtraBullets.get() ? maxCountByStep.get() : maxBulletsWithExtraCount.get()}")
  let countText = Computed(@() $"{bSlot.get()?.count ?? 0}/{maxCountText.get()}")

  return @() {
    watch = bTotalSteps
    children = [
      {
        flow = FLOW_VERTICAL
        children = [
          bulletHeader(bSlot, bSet, bInfo)
          bTotalSteps.get() <= 1 ? null
            : bulletSlider(bSlot, maxCount, maxBulletsWithExtraCount, withExtraBullets, bStep, bLeftSteps)
          bg.__merge({
            size = [flex(), bTotalSteps.get() <= 1 ? SIZE_TO_CONTENT : 0]
            children = @() {
              watch = countText
              rendObj = ROBJ_TEXT
              pos = [0, bTotalSteps.get() <= 1 ? 0 : -hdpx(40)]
              hplace = ALIGN_CENTER
              text = countText.value
              color = 0xFFFFFFFF
            }.__update(fontTiny)
          })
        ]
      }
    ]
  }
}

function respawnBullets() {
  let res = {
    watch = [bulletsInfo, bulletsSecInfo, choiceCount, choiceSecCount, bulletCardStyle]
    animations = wndSwitchAnim
  }
  let bulletSliderSlots = []
  if (bulletsInfo.get() != null)
    bulletSliderSlots.extend(array(choiceCount.get()).map(@(_, idx)
      mkBulletSliderSlot(idx, bulletsInfo, chosenBullets, bulletTotalSteps, bulletStep, maxBulletsCountForExtraAmmo,
        hasExtraBullets, bulletLeftSteps)))
  if (bulletsSecInfo.get() != null)
    bulletSliderSlots.extend(array(choiceSecCount.get()).map(@(_, idx)
      mkBulletSliderSlot(idx, bulletsSecInfo, chosenBulletsSec, bulletSecTotalSteps, bulletSecStep,
        maxBulletsSecCountForExtraAmmo, hasExtraBulletsSec, bulletSecLeftSteps)))
  return bulletSliderSlots.len() == 0 ? res : res.__update({
    flow = FLOW_HORIZONTAL
    children = [
      {
        margin = headerMargin
        flow = FLOW_VERTICAL
        gap = unitPlatesGap
        children = [
          header(headerText(loc("respawn/chooseBullets")))
          {
            flow = FLOW_VERTICAL
            gap = bulletCardStyle.get().gapHeight
            children = bulletSliderSlots
          }
        ]
      }
      bulletsLegend
    ]
  })
}

return respawnBullets
