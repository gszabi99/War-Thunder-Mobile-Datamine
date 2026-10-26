from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/tabs.nut" import mkTabs
from "%rGui/components/unseenMark.nut" import mkUnseenMark
from "%rGui/options/optionsStyle.nut" import tabW, tabH, tabPadding
from "%rGui/unseenPriority.nut" import SEEN, UNSEEN_HIGH


const iconSizeDef = hdpxi(80)

const textColor = 0xFFFFFFFF

function mkTabImage(image, imageSizeMul, imageTabOffset) {
  let h = (iconSizeDef * imageSizeMul + 0.5).tointeger()
  let w = (1.5 * h + 0.5).tointeger()
  let blockSize = max(iconSizeDef, h)
  return {
    size = blockSize
    vplace = ALIGN_CENTER
    children = {
      size = [w, h]
      pos = [h * imageTabOffset[0], h * imageTabOffset[1]]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      rendObj = ROBJ_IMAGE
      image = Picture($"{image}:{w}:{h}:P")
      color = textColor
      keepAspect = true
    }
  }
}

let mkImage = @(image, imageSizeMul, imageTabOffset) function() {
  let imageTab = image instanceof Watched ? image.get() : image
  let imageTabSizeMul = imageSizeMul instanceof Watched ? imageSizeMul.get() : imageSizeMul ?? 1
  let imageTabOffsetVal = imageTabOffset instanceof Watched ? imageTabOffset.get() : imageTabOffset ?? const [0, 0]

  local watchesList = []
  if(image instanceof Watched)
    watchesList.append(image)
  if(imageSizeMul instanceof Watched)
    watchesList.append(imageSizeMul)
  if(imageTabOffset instanceof Watched)
    watchesList.append(imageTabOffset)

  return {
    padding = const [0, hdpx(15)]
    watch = watchesList
    vplace = ALIGN_CENTER
    children = imageTab == null ? null : mkTabImage(imageTab, imageTabSizeMul, imageTabOffsetVal)
  }
}

function tabData(tab, idx, curTabIdx) {
  let { locId  = "", image = null, imageSizeMul = null, isVisible = null, unseen = null,
    tabContent = null, tabHeight = tabH, ovr = {}, imageTabOffset = null } = tab
  local unseenMark = null
  if (unseen != null) {
    let unseenExt = Computed(@() curTabIdx.get() == idx || unseen.get() == false ? SEEN
      : unseen.get() == true ? UNSEEN_HIGH
      : unseen.get())
    unseenMark = mkUnseenMark(unseenExt)
  }

  return {
    id = idx
    isVisible
    content = {
      size = [ FLEX, tabHeight ]
      padding = tabPadding
      children = [
        {
          size = FLEX
          flow = FLOW_HORIZONTAL
          gap = hdpx(10)
          children = [
            mkImage(image, imageSizeMul, imageTabOffset)
            tabContent ?? {
              size = FLEX
              rendObj = ROBJ_TEXTAREA
              behavior = [Behaviors.TextArea, Behaviors.Marquee]
              halign = ALIGN_RIGHT
              lineSpacing = -hdpx(5)
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

return @(tabs, curTabIdx, onClick = null)
  mkTabs(tabs.map(@(t, i) tabData(t, i, curTabIdx)), curTabIdx, { size = [ tabW, SIZE_TO_CONTENT ] }, onClick)
