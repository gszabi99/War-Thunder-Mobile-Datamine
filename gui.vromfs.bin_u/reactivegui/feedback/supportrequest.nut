from "%globalsDarg/darg_library.nut" import *
let logZ = log_with_prefix("[ZENDESK] ")
let { parse_json } = require("json")
let { register_command } = require("console")
let { screenlog } = require("dagor.debug")
let { httpRequest, HTTP_SUCCESS, HTTP_FAILED, HTTP_ABORTED } = require("dagor.http")
let { zendeskApiUploadsUrl, zendeskApiRequestsUrl } = require("supportState.nut")
let { getLogFileData } = require("logFileAttachment.nut")








let isDebug = mkWatched(persist, "isDebug", false)

let defaultRequestState = {
  isProcessing = false
  formData = null
  attachments = []
  errInfo = null
  id = null
}
let requestState = Watched(clone defaultRequestState)

let mkErrText = @(txtReason, txtAdvice = "")
  "\n".join([ $"{loc("msgbox/appearError")}{colon}", txtReason, txtAdvice ], true)

let mkZendeskHttpRequestCb = @(onSuccess, onFailure) function(response) {
  let { status = -1, http_code = -1, body = null } = response
  if (status != HTTP_SUCCESS || body == null) {
    let reason = status == HTTP_FAILED ? "FAILED"
      : status == HTTP_ABORTED ? "ABORTED"
      : "UNKNOWN"
    let logResponse = response?.body == null ? response : response.__merge({ body = response.body.as_string() })
    logZ($"Request network connection error: {reason}", logResponse)
    onFailure({
      errId = $"Request network connection error: {reason}"
      errText = mkErrText(loc($"network_connection/error/{reason}"), loc("network_connection/advice"))
      needSendBQ = false
    })
    return
  }
  local answer = null
  try {
    answer = parse_json(body.as_string())
  }
  catch(e) {
    logZ($"Response parsing failed: {e}", response)
    onFailure({
      errId = $"Response parsing failed: {e}"
      errText = mkErrText(loc("http/response/error/parsing_failed"))
      needSendBQ = true
    })
  }
  if (http_code < 200 || 300 <= http_code || answer?.error != null) {
    let reason = " ".join([ http_code, answer?.error ], true)
    let logResponse = response?.body == null ? response : response.__merge({ body = response.body.as_string() })
    logZ($"Response is error: {reason}", logResponse)
    onFailure({
      errId = $"Response is error: {reason}"
      errText = mkErrText(reason)
      needSendBQ = true
    })
  }
  else {
    if (isDebug.get()) {
      let logResponse = response?.body == null ? response : response.__merge({ body = response.body.as_string() })
      logZ($"Response is successful", logResponse)
    }
    onSuccess(answer)
  }
}

function onAttachmentUploadSuccess(answer, cb) {
  let { token, attachment } = answer.upload
  let { file_name, content_url } = attachment
  let data = {
    token
    file_name
  }
  requestState.mutate(function(v) {
    let attachments = clone v.attachments
    attachments.append(data)
    v.attachments <- attachments
  })
  logZ($"Attachment uploaded successfully (token {token}): {content_url}")
  cb()
}

function onAttachmentUploadFailure(errInfo, cb) {
  logZ($"Attachment upload failed: {errInfo.errId}")
  cb()
}

function uploadAttachment(fileData, cb) {
  if (fileData == null)
    return cb()
  let { filename, mimeType, content } = fileData
  logZ($"Uploading attachment: {filename} ({content.len()} bytes)")
  httpRequest({
    url = zendeskApiUploadsUrl.get().subst(filename)
    method = "POST"
    headers = {
      ["Content-Type"] = mimeType,
    }
    data = content
    callback = mkZendeskHttpRequestCb(
      @(answer) onAttachmentUploadSuccess(answer, cb),
      @(errInfo) onAttachmentUploadFailure(errInfo, cb)
    )
  })
}

function onSendFormSuccess(answer) {
  let { id, requester_id } = answer.request
  logZ($"Request created successfully: id {id}, requester_id {requester_id}")
  requestState.mutate(@(v) v.__update({
    isProcessing = false
    id
  }))
}

function onSendFormFailure(errInfo) {
  logZ($"Request sending failed")
  requestState.mutate(@(v) v.__update({
    isProcessing = false
    errInfo
  }))
}

function sendFormData() {
  let { email, userId, name, category, subject, message, locale, lang, needAttachLogFile } = requestState.get().formData
  let { attachments } = requestState.value
  logZ($"Sending request from user {email}")
  let data = {
    request = {
      requester = { name, email, locale }
      ticket_form_id = 5532303880849
      subject
      comment = { body = message }
      custom_fields = [
        { id = 23973816368914, value = category }
        { id = 21445500020242, value = userId }
        { id = 23145413, value = name }
        { id = 23166961, value = lang }
      ]
    }
  }
  if (needAttachLogFile && attachments.len())
    data.request.comment.__update({ uploads = attachments.map(@(v) v.token) })
  if (isDebug.get())
    logZ(data)
  httpRequest({
    url = zendeskApiRequestsUrl.get()
    method = "POST"
    json = data
    callback = mkZendeskHttpRequestCb(
      onSendFormSuccess,
      onSendFormFailure
    )
  })
}

function submitSupportRequest(formData) {
  if (requestState.value.isProcessing)
    return
  requestState.mutate(@(v) v.__update({
    isProcessing = true
    formData
    errInfo = null
  }))
  if (formData.needAttachLogFile && requestState.get().attachments.len() == 0)
    uploadAttachment(getLogFileData(), sendFormData)
  else
    sendFormData()
}

let onRequestResultSeen = @() requestState.value.isProcessing
  ? null
  : requestState(clone defaultRequestState)

register_command(function() {
  isDebug.set(!isDebug.get())
  let res = $"ui.debug.zendesk {isDebug.get()}"
  screenlog(res) 
  console_print(res) 
}, "ui.debug.zendesk")

return {
  requestState
  submitSupportRequest
  onRequestResultSeen
}
