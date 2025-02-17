from "%globalsDarg/darg_library.nut" import *
let { tabW, tabH } = require("optionsStyle.nut")
let { mkTabs } = require("%rGui/components/tabs.nut")
let { mkUnseenMark, unseenSize } = require("%rGui/components/unseenMark.nut")
let { SEEN } = require("%rGui/unseenPriority.nut")

let iconSizeDef = hdpxi(80)

let textColor = 0xFFFFFFFF

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

let mkImage = @(image, imageSizeMul) function() {
  let imageTab = image instanceof Watched ? image.get() : image
  let imageTabSizeMul = imageSizeMul instanceof Watched ? imageSizeMul.get() : imageSizeMul ?? 1

  local watchesList = []
  if(image instanceof Watched)
    watchesList.append(image)
  if(imageSizeMul instanceof Watched)
    watchesList.append(imageSizeMul)

  return {
    watch = watchesList
    vplace = ALIGN_CENTER
    children = imageTab == null ? null : mkTabImage(imageTab, imageTabSizeMul)
  }
}

function tabData(tab, idx, curTabIdx) {
  let { locId  = "", image = null, imageSizeMul = null, isVisible = null, unseen = null,
    tabContent = null, tabHeight = tabH, ovr = {} } = tab
  let padding = [hdpx(10), hdpx(20)]
  let unseenMarkPos = [padding[1] + unseenSize[1] / 5, -padding[0] - unseenSize[1] / 5]
  local unseenMark = null
  if (unseen != null) {
    let unseenExt = Computed(@() curTabIdx.value == idx ? SEEN : unseen.value)
    unseenMark = mkUnseenMark(unseenExt, { vplace = ALIGN_TOP, hplace = ALIGN_RIGHT, pos = unseenMarkPos })
  }

  return {
    id = idx
    isVisible
    content = {
      size = [ flex(), tabHeight ]
      padding
      children = [
        {
          size = flex()
          flow = FLOW_HORIZONTAL
          gap = hdpx(10)
          children = [
            mkImage(image, imageSizeMul)
            tabContent ?? {
              size = flex()
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              halign = ALIGN_RIGHT
              color = textColor
              text = loc(locId)
            }.__update(fontTinyAccented)
          ]
        }
        unseenMark
      ]
    }.__update(ovr)
  }
}

return @(tabs, curTabIdx)
  mkTabs(tabs.map(@(t, i) tabData(t, i, curTabIdx)), curTabIdx, { size = [ tabW, SIZE_TO_CONTENT ] })
