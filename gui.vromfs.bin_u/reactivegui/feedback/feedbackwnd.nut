from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { register_command } = require("console")
let { sendCustomBqEvent } = require("%appGlobals/pServer/bqClient.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { registerScene } = require("%rGui/navState.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { textButtonCommon, textButtonPrimary, buttonsHGap } = require("%rGui/components/textButton.nut")
let { textInput } = require("%rGui/components/textInput.nut")
let { isOnlineSettingsAvailable } = require("%appGlobals/loginState.nut")
let { get_local_custom_settings_blk } = require("blkGetters")
let { isOldFeedbackCompleted, isRateGameSeen } = require("%rGui/feedback/rateGameState.nut")

let feedbackTube = "user_feedback"
let pollId = "feedback_alpha"
let questions = [
  { id = "gameplay",  defVal = 0,  title = loc("feedback/rate/gameplay") }
  { id = "graphics",  defVal = 0,  title = loc("feedback/rate/graphics") }
  { id = "sound",     defVal = 0,  title = loc("feedback/rate/sound") }
  { id = "learning",  defVal = 0,  title = loc("feedback/rate/learning") }
  { id = "interface", defVal = 0,  title = loc("feedback/rate/interface") }
  { id = "wishes",    defVal = "", title = loc("feedback/message") }
].map(@(q) q.__update({ val = Watched(q.defVal) }))

const RATE_STARS_TOTAL = 5
const SAVE_ID_FEEDBACK_ANSWERS_COUNT = "feedbackAlpha"

let starIconSize = hdpxi(80)
let starIconGap = hdpx(60)

let isOpened = mkWatched(persist, "isOpened", false)

let function close() {
  isOpened(false)
  isRateGameSeen(true)
}

let questionAnswered = Watched(questions.len())
let function updateAnswersCount() {
  if (isOnlineSettingsAvailable.value)
    questionAnswered(get_local_custom_settings_blk()?[SAVE_ID_FEEDBACK_ANSWERS_COUNT] ?? 0)
}
isOnlineSettingsAvailable.subscribe(@(_) updateAnswersCount())
updateAnswersCount()

let haveQuestionsLeft = Computed(@() questionAnswered.value < questions.len())
let isQuestionLast = Computed(@() questionAnswered.value == questions.len() - 1)
let isCurQuestionRating = Computed(@() type(questions?[questionAnswered.value].val.value) == "integer")

haveQuestionsLeft.subscribe(@(v) isOldFeedbackCompleted(!v))

let hasAnswerForCurQuestion = Watched(false)
let function updateHasAnswer() {
  let q = questions?[questionAnswered.value]
  hasAnswerForCurQuestion(q != null && q.val.value != q.defVal)
}
foreach (q in questions)
  q.val.subscribe(@(_) updateHasAnswer())
questionAnswered.subscribe(@(_) updateHasAnswer())
updateHasAnswer()

let btnClose = {
  size  = [hdpx(30), hdpx(30)]
  margin = buttonsHGap
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_VECTOR_CANVAS
  commands = [
    [VECTOR_LINE, 0, 0, 100, 100],
    [VECTOR_LINE, 0, 100, 100, 0]
  ]
  color = 0xFFA0A0A0
  lineWidth = hdpx(6)
  behavior = Behaviors.Button
  onClick = close
}

let function onBtnApply() {
  let q = questions?[questionAnswered.value]
  if (q != null && q.val.value != q.defVal)
    sendCustomBqEvent(feedbackTube, {
      poll = pollId
      question = q.id
      answer = q.val.value.tostring()
    })

  questionAnswered(questionAnswered.value + 1)
  get_local_custom_settings_blk()[SAVE_ID_FEEDBACK_ANSWERS_COUNT] = questionAnswered.value
  send("saveProfile", {})

  if (!haveQuestionsLeft.value)
    close()
}

let onBtnSkip = onBtnApply

let textarea = {
  size = [ flex(), SIZE_TO_CONTENT ]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color = 0xFFFFFFFF
}.__update(fontMedium)

let mkTitle = @(text) textarea.__merge({
  text
})

let mkRateStarsRow = @(valueWatch) {
  flow = FLOW_HORIZONTAL
  gap = starIconGap
  children = array(RATE_STARS_TOTAL).map(@(_, idx) function() {
    let rating = idx + 1
    let icon = rating <= valueWatch.value ? "rate_star_filled" : "rate_star_empty"
    return {
      watch = valueWatch
      behavior = Behaviors.Button
      onClick = @() valueWatch(rating)
      rendObj = ROBJ_IMAGE
      size = [ starIconSize, starIconSize ]
      image = Picture($"ui/gameuiskin#{icon}.svg:{starIconSize}:{starIconSize}")
    }
  })
}

let mkTextInputField = @(valueWatch) @() {
  size = [ flex(), SIZE_TO_CONTENT ]
  flow = FLOW_VERTICAL
  children = textInput(valueWatch, {
    placeholder = loc("feedback/editbox/placeholder")
    onChange = @(value) valueWatch(value)
  })
}

let function mkQuestionComp(question) {
  if (question == null)
    return null
  let { title, val } = question
  let valueType = type(val.value)
  let isRating = valueType == "integer"
  let isTextInput = valueType == "string"
  return {
    size = flex()
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = buttonsHGap
    children = [
      mkTitle(title),
      isRating ? mkRateStarsRow(val)
        : isTextInput ? mkTextInputField(val)
        : null
    ]
  }
}

let feedbackWnd = bgShaded.__merge({
  key = {}
  size = flex()
  children = {
    size = [ min(saSize[0], hdpx(1650)), hdpx(866) ]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = 0xDC161B23
    children = [
      @() {
        watch = questionAnswered
        size = flex()
        flow = FLOW_VERTICAL
        padding = [ 0, buttonsHGap, buttonsHGap, buttonsHGap ]
        children = [
          mkQuestionComp(questions?[questionAnswered.value])
          {
            size = [ flex(), SIZE_TO_CONTENT ]
            children = [
              @() {
                watch = [ isQuestionLast ]
                children = !isQuestionLast.value
                  ? textButtonCommon(utf8ToUpper(loc("msgbox/btn_skip")), onBtnSkip)
                  : null
              }
              {
                hplace = ALIGN_CENTER
                vplace = ALIGN_CENTER
                rendObj = ROBJ_TEXT
                text = $"{questionAnswered.value + 1}/{questions.len()}"
                color = 0xFFFFFFFF
              }.__update(fontMedium)
              @() {
                watch = [ isQuestionLast, hasAnswerForCurQuestion, isCurQuestionRating ]
                hplace = ALIGN_RIGHT
                children = isQuestionLast.value || hasAnswerForCurQuestion.value
                  ? textButtonPrimary(
                      utf8ToUpper(loc(isCurQuestionRating.value ? "msgbox/btn_rate" : "mainmenu/btnSend")),
                      onBtnApply)
                  : null
              }
            ]
          }
        ]
      }
      btnClose
    ]
  }
})

register_command(function() {
    if (!isOpened.value) {
      isRateGameSeen(false)
      questionAnswered(0)
    }
    isOpened(!isOpened.value)
  }, "ui.debug.feedback")

isOpened.subscribe(@(v) v ? questions.each(@(q) q.val(q.defVal)) : null)
registerScene("feedbackWnd", feedbackWnd, close, isOpened)

return @() isOpened(true)
