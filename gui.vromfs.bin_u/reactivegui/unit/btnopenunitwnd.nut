from "%globalsDarg/darg_library.nut" import *
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let { unseenUnits} = require("%rGui/unit/unseenUnits.nut")
let unitsWnd = require("%rGui/unit/unitsWnd.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { getCampaignPresentation } = require("%appGlobals/config/campaignPresentation.nut")
let { openLvlUpWndIfCan } = require("%rGui/levelUp/levelUpState.nut")
let { hoverColor } = require("%rGui/style/stdColors.nut")

let hasUnseen = Computed(@() unseenUnits.value.len() > 0 )
let curCampPresentation = Computed(@() getCampaignPresentation(curCampaign.value))

let mkBgAnim = @(duration, colorFrom, colorTo) [
  { prop = AnimProp.fillColor, from = colorFrom, to = colorTo, duration,
    play = true, loop = true, easing = CosineFull }
]

let mkAvailNewUnit = @(sf) {
  size  = [hdpx(62), hdpx(62)]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = {
    size = [hdpx(44), hdpx(44)]
    rendObj = ROBJ_BOX
    borderWidth = hdpx(2)
    fillColor = 0xBFBF8908
    borderColor = sf & S_HOVER ? hoverColor : 0xFFA0A0A0
    transform = { rotate = 45 }
    animations = mkBgAnim(1.0, 0xFFFFB70B, 0xA5A57607)
  }
}

let statusMark = @(sf) {
  size = [0, 0]
  hplace = ALIGN_RIGHT
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = mkAvailNewUnit(sf)
}

return @(){
  watch = [curCampPresentation, hasUnseen]
  children = translucentButton(curCampPresentation.value.icon,
    loc(curCampPresentation.value.unitsLocId),
    function() {
      unitsWnd()
      openLvlUpWndIfCan()
    },
    hasUnseen.value ? statusMark : null
  )
}

