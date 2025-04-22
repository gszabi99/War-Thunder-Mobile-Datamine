from "math" import min, max
from "daRg" import *

function getTextCompFullWidthPx(textOrTextareaComp) {
  let textComp = textOrTextareaComp.__merge({ size = SIZE_TO_CONTENT })
  return calc_comp_size(textComp)[0]
}









let getTextScaleToFitWidth = @(textOrTextareaComp, maxWidthPx)
  min(1.0, maxWidthPx / getTextCompFullWidthPx(textOrTextareaComp))










function getFontSizeToFitWidth(textOrTextareaComp, maxWidthPx, minFontSize) {
  let w = getTextCompFullWidthPx(textOrTextareaComp)
  return w <= maxWidthPx
    ? textOrTextareaComp.fontSize
    : max(minFontSize, (textOrTextareaComp.fontSize * (maxWidthPx / w)).tointeger())
}










function getFontToFitWidth(textOrTextareaComp, maxWidthPx, orderedFontsList) {
  let preciseFontSize = getFontSizeToFitWidth(textOrTextareaComp, maxWidthPx, orderedFontsList[0].fontSize)
  for (local i = orderedFontsList.len() - 1; i >= 0; i--)
    if (i == 0 || orderedFontsList[i].fontSize <= preciseFontSize)
      return  orderedFontsList[i]
  return {}
}









function getFontToFitHeight(maxHeightPx, orderedFontsList) {
  let listLen = orderedFontsList.len()
  local res = orderedFontsList[listLen - 1]
  for (local i = 0; i < listLen; i++)
    if (orderedFontsList[i].fontSize <= maxHeightPx)
      res = orderedFontsList[i]
    else
      break
  return res
}

return {
  getTextScaleToFitWidth
  getFontSizeToFitWidth
  getFontToFitWidth
  getFontToFitHeight
}
