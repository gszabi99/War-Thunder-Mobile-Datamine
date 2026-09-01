from "%globalsDarg/darg_library.nut" import *

const avatarSize       = hdpx(96)
const profileGap       = hdpx(45)
const levelHolderSize  = hdpx(60)

return {
  avatarSize
  profileGap
  levelHolderSize
  levelHolderPlace   = avatarSize - levelHolderSize / 2
  gamercardHeight    = avatarSize + levelHolderSize / 2
}