from "%globalsDarg/darg_library.nut" import *
let { deferOnce } = require("dagor.workcycle")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bulletsInfo, chosenBullets, bulletStep, bulletTotalSteps, bulletLeftSteps, setCurUnitBullets,
  maxBulletsCountForExtraAmmo, hasExtraBullets
} = require("bulletsChoiceState.nut")
let { bulletsAABB } = require("respawnAnimState.nut")
let { bg, bulletsBlockWidth, headerMargin, headerText, header, bulletsLegend } = require("respawnComps.nut")
let { slider, sliderValueSound, sliderBtn, mkSliderKnob } = require("%rGui/components/slider.nut")
let mkBulletSlot = require("mkBulletSlot.nut")
let { showRespChooseWnd, openedSlot } = require("respawnChooseBulletWnd.nut")
let { mkCustomButton } = require("%rGui/components/textButton.nut")
let { selSlot, hasUnseenShellsBySlot } = require("respawnState.nut")
let { mkPriorityUnseenMarkWatch } = require("%rGui/components/unseenMark.nut")
let { unitPlatesGap } = require("%rGui/unit/components/unitPlateComp.nut")

let padding = hdpx(10)
let headerHeight = hdpx(108)
let choiceCount = Computed(@() chosenBullets.value.len())
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

function bulletHeader(bSlot, bInfo) {
  let fromUnitTags = Computed(@() bulletsInfo.value?.fromUnitTags[bSlot.value?.name])
  let { idx = -1 } = bSlot.value
  let key = $"respBulletsHeader{idx}"
  let hasUnseenBullets = Computed(@() (bSlot.value?.idx ?? 0) > 0
    && hasUnseenShellsBySlot.value?[selSlot.value?.id ?? 0].findvalue(@(v) v) != null)
  return @() {
    watch = [bInfo, bulletsInfo]
    onAttach = @() deferOnce(function() {
      let aabb = gui_scene.getCompAABBbyKey(key)
      if (aabb != null)
        bulletsAABB.mutate(@(v) v.__update({ [idx] = aabb }))
    })
    size = [bulletsBlockWidth, headerHeight]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    children = [
      {
        key
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          @() mkBulletSlot(bInfo.value, fromUnitTags.value, {}, {}, {
            watch = [fromUnitTags, bInfo]})
          @(){
            watch = openedSlot
            size = [flex(), headerHeight]
            rendObj = ROBJ_BOX
            borderWidth = openedSlot.value < 0 || idx != openedSlot.value ? 0 : hdpxi(4)
          }
        ]
      }
      @(){
        key = $"respBulletsBtn{idx}" //for UI tutorial
        size = flex()
        watch = openedSlot
        rendObj = ROBJ_SOLID
        color = 0x99000000
        children =[
          mkCustomButton(arrowBtnImage(
            openedSlot.value < 0 || idx != openedSlot.value), @() onHeaderClick(key, idx),
          {
            ovr = {
              size = [flex(),  headerHeight]
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

function bulletSlider(bSlot, maxCount) {
  let count = Computed(@() bSlot.get()?.count ?? 0)
  let maxBulletsWithExtraCount = Computed(@() maxBulletsCountForExtraAmmo.get()?[bSlot.get()?.idx])
  let minOvr = Computed(@() count.get() == 0 ? inactiveBtnOvr : {})
  let maxOvr = Computed(@() (bulletLeftSteps.get() == 0
    || count.get() >= (hasExtraBullets.get()
        ? maxBulletsWithExtraCount.get()
        : (maxCount.get() * bulletStep.get())))
      ? inactiveBtnOvr
      : {})
  function onChange(value) {
    if (bSlot.get() == null)
      return
    let newVal = clamp(value, 0, !hasExtraBullets.get()
      ? (count.get() + bulletLeftSteps.get() * bulletStep.get())
      : maxBulletsWithExtraCount.get())
    if (newVal == count.get())
      return
    sliderValueSound()
    let { name, idx } = bSlot.get()
    setCurUnitBullets(idx, name, newVal)
  }
  return @() bg.__merge({
    watch = [ maxCount, bulletStep, hasExtraBullets, maxBulletsWithExtraCount ]
    size = [ flex(), headerHeight ]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = sliderGap
    children = [
      sliderBtn(btnTextDec(minOvr),
        @() onChange(count.get() - bulletStep.get()),
        Computed(@() btnBgOvr.__merge(minOvr.get())))
      slider(count,
        {
          size = sliderSize
          unit = hasExtraBullets.get() ? maxBulletsWithExtraCount.get() : bulletStep.get()
          min = 0
          max = hasExtraBullets.get() ? maxBulletsWithExtraCount.get() : maxCount.get() * bulletStep.get()
          onChange
        },
        knobCtor)
      sliderBtn(btnTextInc(maxOvr),
        @() onChange(count.get() + bulletStep.get()),
        Computed(@() btnBgOvr.__merge(maxOvr.get())))
    ]
  })
}

function mkBulletSliderSlot(idx) {
  let bSlot = Computed(@() chosenBullets.value?[idx])
  let bInfo = Computed(@() bulletsInfo.value?.bulletSets[bSlot.value?.name])
  let maxCount = Computed(@() min(bulletTotalSteps.get(),
    bulletsInfo.get()?.fromUnitTags[bSlot.get()?.name]?.maxCount ?? bulletTotalSteps.get()))
  let maxCountByStep = Computed(@() maxCount.get() * bulletStep.get())
  let maxBulletsWithExtraCount = Computed(@() maxBulletsCountForExtraAmmo.get()?[idx])
  let maxCountText = Computed(@() $"{!hasExtraBullets.get() ? maxCountByStep.get() : maxBulletsWithExtraCount.get()}")
  let countText = Computed(@() $"{bSlot.get()?.count ?? 0}/{maxCountText.get()}")

  return @() {
    watch = bulletTotalSteps
    children = [
      {
        flow = FLOW_VERTICAL
        children = [
          bulletHeader(bSlot, bInfo)
          bulletTotalSteps.value > 1 ? bulletSlider(bSlot, maxCount) : null
          bg.__merge({
            size = [flex(), bulletTotalSteps.value <= 1 ? SIZE_TO_CONTENT : hdpx(10)]
            children = @(){
              watch = countText
              rendObj = ROBJ_TEXT
              pos = [0, bulletTotalSteps.value <= 1 ? 0 : -hdpx(30)]
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
  let res = { watch = [bulletsInfo, choiceCount], animations = wndSwitchAnim }
  if (bulletsInfo.value == null)
    return res
  return res.__update({
    flow = FLOW_HORIZONTAL
    children = [
      {
        margin = headerMargin
        flow = FLOW_VERTICAL
        gap = unitPlatesGap
        children = [header(headerText(loc("respawn/chooseBullets")))]
          .extend(array(choiceCount.value).map(@(_, idx) mkBulletSliderSlot(idx)))
      },
      bulletsLegend
    ]
  })
}

return respawnBullets
