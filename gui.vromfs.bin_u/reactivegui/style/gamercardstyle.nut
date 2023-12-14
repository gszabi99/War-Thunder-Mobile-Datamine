from "%globalsDarg/darg_library.nut" import *

let avatarSize       = hdpx(96)
let profileGap       = hdpx(45)
let levelHolderSize  = hdpx(60)

return {
  avatarSize
  profileGap
  levelHolderSize
  levelHolderPlace   = avatarSize - levelHolderSize / 2
  gamercardHeight    = avatarSize + levelHolderSize / 2
}