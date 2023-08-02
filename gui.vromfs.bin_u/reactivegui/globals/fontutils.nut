from "daRg" import *

let function getTextCompFullWidthPx(textOrTextareaComp) {
  let textComp = textOrTextareaComp.__merge({ size = SIZE_TO_CONTENT })
  return calc_comp_size(textComp)[0]
}

/**
 * Returns scale prop value N which should be set as textOrTextareaComp.transform.scale = [N, N],
 * to make textOrTextareaComp fit into maxWidthPx width. This text scaling method is a good compromise,
 * it is NOT pixel-perfect, but it looks good enough, and it is cheap.
 * @param {table} textOrTextareaComp - Text or TextArea comp table with initial fontSize value.
 * @param {integer} maxWidthPx - Maximum text width in pixels.
 * @return {float} - scale.
 */
let getTextScaleToFitWidth = @(textOrTextareaComp, maxWidthPx)
  min(1.0, maxWidthPx / getTextCompFullWidthPx(textOrTextareaComp))

/**
 * Returns fontSize prop value which should be set to textOrTextareaComp,
 * to make it fit into maxWidthPx width. This text scaling method is PIXEL-PERFECT,
 * but it is the MOST EXPENSIVE (it adds glypths of non-standard size to atlas).
 * @param {table} textOrTextareaComp - Text or TextArea comp table with initial fontSize value.
 * @param {integer} maxWidthPx - Maximum text width in pixels.
 * @param {integer} minFontSize - Minimum fontSize value to return.
 * @return {integer} - fontSize.
 */
let function getFontSizeToFitWidth(textOrTextareaComp, maxWidthPx, minFontSize) {
  let w = getTextCompFullWidthPx(textOrTextareaComp)
  return w <= maxWidthPx
    ? textOrTextareaComp.fontSize
    : max(minFontSize, (textOrTextareaComp.fontSize * (maxWidthPx / w)).tointeger())
}

/**
 * Selects a font style (font props table) from orderedFontsList, which should be merged
 * to textOrTextareaComp, to make it fit into maxWidthPx width.
 * @param {table} textOrTextareaComp - Text or TextArea comp with initial fontSize value.
 * @param {integer} maxWidthPx - Maximum text width in pixels.
 * @param {array} orderedFontsList - Non-emply list of font style tables, ordered by fontSize.
 * from lesser to bigger (like fontsLists.common from fontsStyle.nut).
 * @return {table} - font style (font props table).
 */
let function getFontToFitWidth(textOrTextareaComp, maxWidthPx, orderedFontsList) {
  let preciseFontSize = getFontSizeToFitWidth(textOrTextareaComp, maxWidthPx, orderedFontsList[0].fontSize)
  for (local i = orderedFontsList.len() - 1; i >= 0; i--)
    if (i == 0 || orderedFontsList[i].fontSize <= preciseFontSize)
      return  orderedFontsList[i]
  return {}
}

return {
  getTextScaleToFitWidth
  getFontSizeToFitWidth
  getFontToFitWidth
}
