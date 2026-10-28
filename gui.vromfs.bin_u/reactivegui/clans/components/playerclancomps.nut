from "%globalsDarg/darg_library.nut" import *
from "%rGui/clans/clanState.nut" import getClanDisplayName
from "%rGui/clans/components/clanBadge.nut" import mkClanBadgeImage
from "%rGui/clans/clanPublicInfo.nut" import getUserClan


const defIconSize = hdpxi(32)
const clanNameMaxWidth = hdpx(300)

function mkByUserId(userId, ctor) {
  let userClan = getUserClan(userId)
  return function() {
    let clan = userClan.get()
    return {
      watch = userClan
      children = clan == null ? null : ctor(clan)
    }
  }
}

let mkPlayerClanIcon = @(userId) mkByUserId(userId, @(clan) mkClanBadgeImage(clan.badge, defIconSize))

let mkPlayerClanRow = @(userId, iconSize, textStyle) mkByUserId(userId, @(clan) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(10)
  children = [
    mkClanBadgeImage(clan.badge, iconSize)
    {
      maxWidth = clanNameMaxWidth
      rendObj = ROBJ_TEXT
      behavior = Behaviors.Marquee
      delay = defMarqueeDelay
      text = getClanDisplayName(clan.name)
      ...textStyle
    }
  ]
})

return {
  mkPlayerClanIcon
  mkPlayerClanRow
}
