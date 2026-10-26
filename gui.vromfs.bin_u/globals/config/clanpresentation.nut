from "%sqstd/functools.nut" import memoize
from "%sqstd/string.nut" import isStringInteger
from "%appGlobals/clanConsts.nut" import GRADE_MEMBER, GRADE_OFFICER, GRADE_DEPUTY, GRADE_FOUNDER, GRADE_LEADER
from "%rGui/style/gradients.nut" import mkColoredGradientY


const defaultGradeIcon = "ui/gameuiskin#icon_clan_member.svg"
let gradeIcons = {
  [GRADE_LEADER] = "ui/gameuiskin#icon_clan_owner.svg",
  [GRADE_FOUNDER] = "ui/gameuiskin#icon_clan_founder.svg",
  [GRADE_DEPUTY] = "ui/gameuiskin#icon_clan_senior_officer.svg",
  [GRADE_OFFICER] = "ui/gameuiskin#icon_clan_officer.svg",
  [GRADE_MEMBER] = "ui/gameuiskin#icon_clan_member.svg"
}

let getGradeIcon = @(grade) gradeIcons?[grade] ?? defaultGradeIcon

let gradeLocIds = {
  [GRADE_LEADER] = "clans/grade/LEADER",
  [GRADE_DEPUTY] = "clans/grade/DEPUTY"
}

let getGradeLocId = @(grade) gradeLocIds?[grade] ?? $"clans/grade/{grade}"

let badgeColors = [
  0xFF000000,  
  0xFFFFFFFF,  
  0xFFFF2121,  
  0xFFFF8800,  
  0xFFFFE100,  
  0xFF00FFAE,  
  0xFF00F6FF,  
  0xFF0066FF,  
  0xFFAE00FF   
]

let badgeBgOrder = [
  "greyY",
  "defaultBgColor",
  "redY",
  "orangeY",
  "yellowY",
  "greenY",
  "cyanY",
  "blueY",
  "purpleY"
]

let defaultBgColor = mkColoredGradientY(0xFFEDEAEA, 0xFFAAAAAA)

let gradientBgConfig = {
  greyY   = @() mkColoredGradientY(0xFF4B4B4B, 0xFF141313)
  redY    = @() mkColoredGradientY(0xFFE20707, 0xFF8D0404)
  orangeY = @() mkColoredGradientY(0xFFE66E04, 0xFFA83C02)
  yellowY = @() mkColoredGradientY(0xFFFFBB00, 0xFFA86802)
  greenY  = @() mkColoredGradientY(0xFF07E57D, 0xFF078244)
  cyanY   = @() mkColoredGradientY(0xFF05DADA, 0xFF098F8F)
  blueY   = @() mkColoredGradientY(0xFF054ADF, 0xFF071F82)
  purpleY = @() mkColoredGradientY(0xFF8B00E8, 0xFF550782)
}

let getClanBg = memoize(@(bgColorName) gradientBgConfig?[bgColorName]()
  ?? defaultBgColor)

let badgeIcons = {
  clan_avatar_icon_01 = "clan_avatar_icon_01"
  clan_avatar_icon_02 = "clan_avatar_icon_02"
  clan_avatar_icon_03 = "clan_avatar_icon_03"
  clan_avatar_icon_04 = "clan_avatar_icon_04"
  clan_avatar_icon_05 = "clan_avatar_icon_05"
  clan_avatar_icon_06 = "clan_avatar_icon_06"
  clan_avatar_icon_07 = "clan_avatar_icon_07"
  clan_avatar_icon_08 = "clan_avatar_icon_08"
  clan_avatar_icon_09 = "clan_avatar_icon_09"
  clan_avatar_icon_10 = "clan_avatar_icon_10"
  clan_avatar_icon_11 = "clan_avatar_icon_11"
  clan_avatar_icon_12 = "clan_avatar_icon_12"
  clan_avatar_icon_13 = "clan_avatar_icon_13"
  clan_avatar_icon_14 = "clan_avatar_icon_14"
  clan_avatar_icon_15 = "clan_avatar_icon_15"
  clan_avatar_icon_16 = "clan_avatar_icon_16"
  clan_avatar_icon_17 = "clan_avatar_icon_17"
}
let badgeFrames = {
  clan_slot_border_01 = "clan_slot_border_01"
  clan_slot_border_02 = "clan_slot_border_02"
  clan_slot_border_03 = "clan_slot_border_03"
  clan_slot_border_04 = "clan_slot_border_04"
  clan_slot_border_05 = "clan_slot_border_05"
  clan_slot_border_06 = "clan_slot_border_06"
  clan_slot_border_07 = "clan_slot_border_07"
}

let badgeValidValues = {
  badge_icon        = badgeIcons
  badge_frame       = badgeFrames
  badge_bg_color    = gradientBgConfig
}

let defBadgeIcon = {
  badge_icon_color = badgeColors[0]
  badge_icon = badgeIcons.clan_avatar_icon_01
  badge_frame = badgeFrames.clan_slot_border_01
  badge_frame_color = badgeColors[2]
  badge_bg_color = "defaultBgColor"
}

function validate(id, val, def) {
  if (typeof def == "integer") {
    let v = isStringInteger(val) ? val.tointeger() : def
    return v
  }

  return (val != null && val != "" && val in badgeValidValues[id]) ? val : def
}

function [pure, nodiscard] mkClanBadge(tf) {
  if (tf == null)
    return defBadgeIcon
  return defBadgeIcon.map(@(v, id) validate(id, tf?[id], v))
}

return {
  getGradeIcon
  getGradeLocId
  mkClanBadge
  badgeIcons = badgeIcons.values().sort()
  badgeFrames = badgeFrames.values().sort()
  badgeColors
  badgeBgOrder
  defBadgeIcon

  getClanBg
}
