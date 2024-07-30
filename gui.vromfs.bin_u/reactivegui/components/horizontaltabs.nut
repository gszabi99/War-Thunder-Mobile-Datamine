from "%globalsDarg/darg_library.nut" import *
let { mkBitmapPictureLazy } = require("%darg/helpers/bitmap.nut")
let { gradTexSize, mkGradientCtorRadial, simpleHorGradInv } = require("%rGui/style/gradients.nut")
let { selectedLineHorSolid, opacityTransition } = require("%rGui/components/selectedLine.nut")

let iconSizeDef = hdpxi(60)
let tabHeight = hdpx(120)

let textColor = 0xFFFFFFFF
let bgColor = 0x990C1113
let activeBgColor = 0xFF52C4E4

let bgGradient = mkBitmapPictureLazy(gradTexSize, gradTexSize / 4,
  mkGradientCtorRadial(activeBgColor, 0, gradTexSize / 4, gradTexSize / 3, gradTexSize / 2, -(gradTexSize / 6)))

let mkTabContent = @(content, isActive, isHover) {
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    {
      size = flex()
      rendObj = ROBJ_IMAGE
      image = simpleHorGradInv
      color = bgColor
      transitions = opacityTransition
    }
    @() {
      watch = [isActive, isHover]
      size = flex()
      rendObj = ROBJ_IMAGE
      image = bgGradient()
      opacity = isActive.get() ? 0.7
        : isHover.get() ? 0.5
        : 0
      transitions = opacityTransition
    }
  ].append(content)
}

function mkTabImage(image, imageSizeMul) {
  let size = (iconSizeDef * imageSizeMul + 0.5).tointeger()
  let blockSize = max(iconSizeDef, size)
  return {
    size = [blockSize, blockSize]
    vplace = ALIGN_CENTER
    children = {
      size = [size, size]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = Picture($"{image}:{size}:{size}:P")
      color = textColor
      keepAspect = KEEP_ASPECT_FIT
    }
  }
}

function tabData(tab, idx) {
  let { locId  = "", image = null } = tab
  return {
    id = idx
    content = {
      size = [flex(), tabHeight]
      padding = [hdpx(10), hdpx(20)]
      children = [
        {
          size = flex()
          flow = FLOW_HORIZONTAL
          gap = hdpx(10)
          children = [
            image == null ? null
              : image instanceof Watched ? @() mkTabImage(image.get(), 1.0).__update({ watch = image })
              : mkTabImage(image, 1.0)
            {
              size = flex()
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              valign = ALIGN_CENTER
              halign = ALIGN_CENTER
              color = textColor
              text = loc(locId)
            }.__update(fontTinyAccented)
          ]
        }
      ]
    }
  }
}

function mkTab(data, curTabIdx) {
  let stateFlags = Watched(0)
  let isActive = Computed (@() curTabIdx.get() == data.id || (stateFlags.get() & S_ACTIVE) != 0)
  let isHover = Computed (@() stateFlags.get() & S_HOVER)

  return {
    size = [flex(), SIZE_TO_CONTENT]
    behavior = Behaviors.Button
    onElemState = @(v) stateFlags.set(v)
    clickableInfo = loc("mainmenu/btnSelect")
    onClick = @() curTabIdx.set(data.id)
    sound = { click = "choose" }
    children = [
      mkTabContent(data.content, isActive, isHover)
      selectedLineHorSolid(isActive)
    ]
  }
}

let mkHorizontalTabs = @(tabs, curTabIdx) {
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = tabs.map(@(tab, idx) mkTab(tabData(tab, idx), curTabIdx))
}

return { mkHorizontalTabs }