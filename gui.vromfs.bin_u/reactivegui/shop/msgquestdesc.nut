from "%globalsDarg/darg_library.nut" import *
let { userlogTextColor } = require("%rGui/style/stdColors.nut")
let { campaignActiveUnlocks } = require("%rGui/unlocks/unlocks.nut")

let questsIconSize = hdpxi(50)
let questsIconSizeSmall = hdpxi(30)

let mkFlagImage = @(country, size) {
  size
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#{country}.svg:{size}:{size}:P")
  fallbackImage = Picture($"ui/gameuiskin#menu_lang.svg:{size}:{size}:P")
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  keepAspect = true
}

let getQuestLocName = @(id) loc(campaignActiveUnlocks.get()?[id].meta.lang_id ?? id)

function mkQuestDesc(currencyId, spUnlocks, goodsCountry = null) {
  let unlocks = spUnlocks?[currencyId]
  if (!unlocks)
    return null
  let res = []
  foreach (u in unlocks?[""] ?? {})
    res.append({
      flow = FLOW_HORIZONTAL
      gap = hdpx(15)
      children = [
        {
          size = questsIconSize
          rendObj = ROBJ_IMAGE
          image = Picture($"ui/gameuiskin#quests.svg:{questsIconSize}:{questsIconSize}:P")
        }
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc("shop/questProgress", { questName = colorize(userlogTextColor, getQuestLocName(u)) })
        }.__update(fontSmall)
      ]
    })
  foreach (u in unlocks?[goodsCountry] ?? {})
    res.append({
      flow = FLOW_HORIZONTAL
      gap = hdpx(15)
      children = [
        {
          children =[
            mkFlagImage(goodsCountry, hdpxi(55))
            {
              pos = [hdpx(-12), 0]
              size = questsIconSizeSmall
              rendObj = ROBJ_IMAGE
              image = Picture($"ui/gameuiskin#quests.svg:{questsIconSizeSmall}:{questsIconSizeSmall}:P")
              vplace = ALIGN_BOTTOM
            }
          ]
        }
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc("shop/questProgress", { questName = colorize(userlogTextColor, getQuestLocName(u)) })
        }.__update(fontSmall)
      ]
    })
  return res
}

return { mkQuestDesc }
