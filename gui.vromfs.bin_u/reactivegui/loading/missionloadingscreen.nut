from "%globalsDarg/darg_library.nut" import *
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { mkLoadingTip } = require("%rGui/loading/mkLoadingTip.nut")
let { locMissionName, locMissionDesc } = require("%rGui/globals/missionUtils.nut")
let { isMissionLoading } = require("%appGlobals/clientState/clientState.nut")
let { mkSpinner } = require("%rGui/components/spinner.nut")
let teamColors = require("%rGui/style/teamColors.nut")

let mapSize = hdpxi(680)
let borderSize = hdpxi(200)

let mapBgByCamp = {
  ships = "ui/images/loading/briefing_water_map.avif"
  ships_new = "ui/images/loading/briefing_water_map.avif"
}

let textParams = {
  rendObj = ROBJ_TEXT
  fontFx = FFT_GLOW
  fontFxFactor = 64
  fontFxColor = Color(0, 0, 0)
  color = Color(205, 205, 205)
}.__update(fontSmall)

let loadingHeader = {
  margin = hdpx(70)
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    textParams.__merge({
      text = loc("loading")
      color = 0xFFF0F0F0
    }, fontMedium)
    mkSpinner()
  ]
}

let mkImage = @(path, size, ovr = null) {
  size
  rendObj = ROBJ_IMAGE
  image = Picture($"{path}:{size[0]}:{size[1]}:P")
}.__update(ovr)


let textBlock = @() {
  watch = isMissionLoading
  size = const [hdpx(800), flex()]
  margin = const [hdpx(160), 0, hdpx(30), 0]
  flow = FLOW_VERTICAL
  gap = hdpx(40)
  children = isMissionLoading.get()
    ? [
        {
          size = FLEX_H
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_TOP
          text = locMissionName()
        }.__update(fontMedium)
        {
          size = FLEX_H
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_TOP
          text = locMissionDesc()
          colorTable = teamColors
        }.__update(fontSmall)
      ]
    : null
}

return @() {
  watch = curCampaign
  size = flex()
  rendObj = ROBJ_IMAGE
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  image = Picture("ui/images/loading/campaign_back.avif")
  children =
  [
    mkImage("ui/images/loading/decor2.avif", [hdpxi(300), hdpxi(150)], { pos = [pw(50), hdpxi(200)] })
    mkImage("ui/images/loading/decor3.avif", [hdpxi(300), hdpxi(600)], {
      hplace = ALIGN_RIGHT
      vplace = ALIGN_CENTER
    })
    {
      size = flex()
      children = [
         {
          vplace = ALIGN_CENTER
          size = [flex(), mapSize]
          flow = FLOW_HORIZONTAL
          halign = ALIGN_CENTER
          gap = hdpx(10)
          children = [
            mkImage("ui/images/loading/map_back.avif", [mapSize, mapSize], {
                children = [
                  curCampaign.get() not in mapBgByCamp ? null
                    : {
                        size = flex()
                        margin = const [hdpx(20), hdpx(40), hdpx(20), hdpx(42)]
                        rendObj = ROBJ_IMAGE
                        image = Picture(mapBgByCamp[curCampaign.get()])
                      }
                  {
                    margin = const [hdpx(20), hdpx(40), hdpx(20), hdpx(42)]
                    size = flex()
                    rendObj = ROBJ_TACTICAL_MAP
                  }
                ]
              })
            textBlock
          ]
        }
        {
          size = flex()
          transform = { scale = [2.5, 1] }
          rendObj = ROBJ_IMAGE
          image = Picture("ui/images/loading/briefingshade.avif:0:P")
        }
        {
          vplace = ALIGN_TOP
          size = [flex(), borderSize]
          rendObj = ROBJ_SOLID
          color = 0xFF000000
          children = loadingHeader
        }
        {
          vplace = ALIGN_BOTTOM
          size = [flex(), borderSize]
          rendObj = ROBJ_SOLID
          color = 0xFF000000
          children = mkLoadingTip({
            size = const [hdpx(1200), SIZE_TO_CONTENT]
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
          })
        }
      ]
    }
  ]
}
