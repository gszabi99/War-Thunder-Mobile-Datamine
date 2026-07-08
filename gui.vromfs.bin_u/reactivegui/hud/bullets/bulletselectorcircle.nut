from "%globalsDarg/darg_library.nut" import *
let { PI, cos, sin } = require("%sqstd/math.nut")
let { hudPearlGrayColor, hudVeilGrayColorFade } = require("%rGui/style/hudColors.nut")
let { scaleArr } = require("%globalsDarg/screenMath.nut")
let { buttonSize, mkCircleGroundSecondaryGun, mkCircleBtnEditView } = require("%rGui/hud/buttons/circleTouchHudButtons.nut")
let { mkNextBulletArrow } = require("%rGui/hud/bullets/bulletNextArrow.nut")


let colorActive = hudPearlGrayColor
let colorInactive = hudVeilGrayColorFade

let DEG_TO_RAD = PI / 180.0
let MAIN_ANGLE_DEG = 180.0

let DEFAULT_ORIENTATION = false
let ORIENTATION_ANGLES = {
  [false] = { main = 180.0, extra = 226.0 },  
  [true] = { main = 0.0, extra = 314.0 }  
}

let sectorGap = hdpx(10)

let calcSectorPos = @(angleDeg, radius, size, center) [
  (center + cos(angleDeg * DEG_TO_RAD) * radius - size[0] / 2).tointeger(),
  (center + sin(angleDeg * DEG_TO_RAD) * radius - size[1] / 2).tointeger()
]
let calcSectorRotate = @(angleDeg) angleDeg - MAIN_ANGLE_DEG

function getBulletSelectorIcon(id, isBulletBelt, bulletsInfoW) {
  let raw = bulletsInfoW.get()?.fromUnitTags[id]?.icon
  return raw != null ? $"{raw}.svg"
    : isBulletBelt ? "hud_ammo_bullet_ap.svg"
    : "hud_ammo_ap1_he1.svg"
}

function mkSectorButton(isActive, onClick, size, icon, count, rotateDeg, ovr = {}, countOvr = {},
    behaviorSize = null, behaviorPosOvr = [0, 0]) {

  let stateFlags = Watched(0)
  let imgSize = scaleArr(size, 0.7)

  return {
    size
    children = [
      {
        size = behaviorSize ?? size
        pos = behaviorPosOvr
        behavior = Behaviors.Button
        cameraControl = true
        onClick
        onElemState = @(v) stateFlags.set(v)
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
      }
      @() {
        watch = stateFlags
        size
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#hud_ammo_sector_bg.svg:{size[0]}:{size[1]}:P")
        color = ((stateFlags.get() & S_ACTIVE) || isActive) ? colorActive : colorInactive
        transform = { pivot = [0.5, 0.5], rotate = rotateDeg }
      }
      {
        size = imgSize
        rendObj = ROBJ_IMAGE
        image = Picture($"ui/gameuiskin#{icon}:{imgSize[0]}:{imgSize[1]}:P")
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        keepAspect = true
        color = isActive ? colorActive : colorInactive
      }
      {
        rendObj = ROBJ_TEXT
        text = count
      }.__update(fontTinyShaded, countOvr)
    ]
  }.__update(ovr)
}

function bulletSelectorArc(mainInfo, mainCount, extraInfo, extraCount, bulletsInfoW, curNameW, nextNameW,
    mainFn, extraFn, innerR, sectorDepth, scale = 1.0, isRightW = Watched(DEFAULT_ORIENTATION)) {

  let scaledInnerR = (innerR * scale).tointeger()
  let scaledSectorDepth = (sectorDepth * scale).tointeger()
  let scaledGap = (sectorGap * scale).tointeger()

  let outerR = scaledInnerR + scaledGap + scaledSectorDepth
  let compSize = outerR * 2
  let midR = scaledInnerR + scaledGap + scaledSectorDepth / 2.0
  let sectorSize = [scaledSectorDepth, (scaledSectorDepth * 100 / 73).tointeger()]
  let arcOffset = scaledGap + scaledSectorDepth
  let arrowSz = (scaledSectorDepth * 0.55).tointeger()
  let arrowR = outerR + arrowSz / 2

  let mainCountOvrLeft = { pos = [(-sectorSize[0] * 0.3).tointeger(), (-sectorSize[1] * 0.2).tointeger()] }
  let mainCountOvrRight = { hplace = ALIGN_RIGHT, pos = [(sectorSize[0] * 0.3).tointeger(), (-sectorSize[1] * 0.2).tointeger()] }
  let extraCountOvr = { hplace = ALIGN_CENTER, pos = [0, (-sectorSize[1] * 0.35).tointeger()] }

  let touchMarginSizeMain = [sectorSize[0], (sectorSize[1] * 0.9).tointeger()]
  let touchMarginSizeExtra = [(sectorSize[0] * 1.2).tointeger(), (sectorSize[1] * 0.8).tointeger()]
  let touchMarginPosOvrExtraLeft = [-hdpxi(10.0 * scale), -hdpxi(10.0 * scale)]
  let touchMarginPosOvrExtraRight = [ hdpxi(10.0 * scale), -hdpxi(10.0 * scale)]

  let idMain = Computed(@() mainInfo.get()?.id ?? "")
  let idExtra = Computed(@() extraInfo.get()?.id ?? "")
  let beltMain = Computed(@() mainInfo.get()?.isBulletBelt ?? false)
  let beltExtra = Computed(@() extraInfo.get()?.isBulletBelt ?? false)
  let iconMain = Computed(@() getBulletSelectorIcon(idMain.get(), beltMain.get(), bulletsInfoW))
  let iconExtra = Computed(@() getBulletSelectorIcon(idExtra.get(), beltExtra.get(), bulletsInfoW))
  let isCurExtra = Computed(@() idExtra.get() == curNameW.get())
  let isNextMain = Computed(@() isCurExtra.get() && idMain.get() == nextNameW.get())
  let isNextExtra = Computed(@() !isCurExtra.get() && idExtra.get() == nextNameW.get())
  let hasExtra = Computed(@() extraInfo.get() != null)

  let mkArrowAtAngle = @(angleDeg) mkNextBulletArrow(arrowSz, angleDeg - 90, {
    hplace = ALIGN_LEFT
    vplace = ALIGN_TOP
    pos = [
      (outerR + cos(angleDeg * DEG_TO_RAD) * arrowR - arrowSz / 2).tointeger(),
      (outerR + sin(angleDeg * DEG_TO_RAD) * arrowR - arrowSz / 2).tointeger()
    ]
  })

  return function() {
    let isRight = isRightW.get()
    let angles = ORIENTATION_ANGLES[isRight]
    let mainAngle = angles.main
    let extraAngle = angles.extra
    let mainCountOvr = isRight ? mainCountOvrRight : mainCountOvrLeft
    let touchMarginPosOvrExtra = isRight ? touchMarginPosOvrExtraRight : touchMarginPosOvrExtraLeft
    return {
      watch = [hasExtra, isCurExtra, isNextMain, isNextExtra, mainCount, extraCount, iconMain, iconExtra, isRightW]
      pos = [-arcOffset, -arcOffset]
      size = compSize
      children = (!hasExtra.get() || mainCount.get() == 0 || extraCount.get() == 0) ? null
        : [
            mkSectorButton(!isCurExtra.get(), mainFn, sectorSize, iconMain.get(), mainCount.get(), calcSectorRotate(mainAngle),
              { pos = calcSectorPos(mainAngle, midR, sectorSize, outerR) }, mainCountOvr, touchMarginSizeMain)
            mkSectorButton(isCurExtra.get(), extraFn, sectorSize, iconExtra.get(), extraCount.get(), calcSectorRotate(extraAngle),
              { pos = calcSectorPos(extraAngle, midR, sectorSize, outerR) }, extraCountOvr, touchMarginSizeExtra,
              touchMarginPosOvrExtra)
            isNextMain.get() ? mkArrowAtAngle(mainAngle) : null
            isNextExtra.get() ? mkArrowAtAngle(extraAngle) : null
          ]
    }
  }
}

function mkSecGunWithBullets(shortcutId, aType, img, mainInfo, extraInfo, mainCount, extraCount, bulletsInfoW, curNameW, nextNameW,
    mainFn, extraFn, hasDoubleChoiceW, isRightW = Watched(DEFAULT_ORIENTATION)) {

  let innerCtorSectorsLeft = mkCircleGroundSecondaryGun(shortcutId, aType, img, ALIGN_RIGHT)
  let innerCtorSectorsRight = mkCircleGroundSecondaryGun(shortcutId, aType, img, ALIGN_LEFT)
  let innerR = buttonSize / 2
  let sectorDepth = (innerR * 1.2).tointeger()

  return @(actionItem, scale) {
    size = scaleEven(buttonSize, scale)
    children = [
      @() {
        watch = hasDoubleChoiceW
        children = !hasDoubleChoiceW.get() ? null
          : bulletSelectorArc(mainInfo, mainCount, extraInfo, extraCount, bulletsInfoW, curNameW, nextNameW,
              mainFn, extraFn, innerR, sectorDepth, scale, isRightW)
      }
      @() {
        watch = isRightW
        children = (isRightW.get() ? innerCtorSectorsRight : innerCtorSectorsLeft)(actionItem, scale)
      }
    ]
  }
}

let mkStaticSector = @(rotateDeg, sectorSize, sectorPos) {
  size = sectorSize
  pos = sectorPos
  children = {
    size = sectorSize
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/gameuiskin#hud_ammo_sector_bg.svg:{sectorSize[0]}:{sectorSize[1]}:P")
    color = colorInactive
    transform = { pivot = [0.5, 0.5], rotate = rotateDeg }
  }
}

function mkSecGunWithBulletsEditView(img, isRight = DEFAULT_ORIENTATION) {
  let innerR = buttonSize / 2
  let sectorDepth = (innerR * 1.2).tointeger()
  let arcOffset = (sectorGap + sectorDepth).tointeger()
  let outerR = innerR + sectorGap + sectorDepth
  let compSize = (outerR * 2).tointeger()
  let midR = innerR + sectorGap + sectorDepth / 2.0
  let sectorSize = [sectorDepth, (sectorDepth * 100 / 73).tointeger()]
  let editViewSize = arcOffset + buttonSize

  let angles = ORIENTATION_ANGLES[isRight]
  let mainAngle = angles.main
  let extraAngle = angles.extra

  let sectorPosX = isRight ? -arcOffset : 0
  let gunPosX = isRight ? 0 : arcOffset

  return {
    size = editViewSize
    clipChildren = true
    children = [
      {
        size = compSize
        pos = [sectorPosX, 0]
        children = [
          mkStaticSector(calcSectorRotate(mainAngle),  sectorSize, calcSectorPos(mainAngle,  midR, sectorSize, outerR))
          mkStaticSector(calcSectorRotate(extraAngle), sectorSize, calcSectorPos(extraAngle, midR, sectorSize, outerR))
        ]
      }
      {
        pos = [gunPosX, arcOffset]
        children = mkCircleBtnEditView(img)
      }
    ]
  }
}

return {
  mkSecGunWithBullets
  mkSecGunWithBulletsEditView
  bulletSelectorArc
}
