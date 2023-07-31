from "%globalsDarg/darg_library.nut" import *
let logZ = log_with_prefix("[ZENDESK] ")
let { parse_json } = require("json")
let { httpRequest, HTTP_SUCCESS, HTTP_FAILED, HTTP_ABORTED } = require("dagor.http")
let { getLogFileData } = require("logFileAttachment.nut")

/*
 * This script is a replacement for this Gaijin Support request form:
 * https://support.gaijin.net/hc/en-us/requests/new?locked=1&ticket_form_id=5532303880849
 * It uses Zendesk API. More info here:
 * https://developer.zendesk.com/api-reference/ticketing/tickets/ticket-requests/
 */

let defaultRequestState = {
  isProcessing = false
  formData = null
  attachments = []
  errInfo = null
  id = null
}
let requestState = Watched(clone defaultRequestState)

let mkZendeskHttpRequestCb = @(onSuccess, onFailure) function(response) {
  let { status = -1, http_code = -1, body = null } = response
  if (status != HTTP_SUCCESS || body == null) {
    let reason = status == HTTP_FAILED ? "FAILED"
      : status == HTTP_ABORTED ? "ABORTED"
      : "UNKNOWN"
    logZ($"Request failed: {reason}", response)
    onFailure({
      errId = $"Request failed: {reason}"
      errText = loc($"http/request/status/{reason}")
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
      errText = loc("http/response/error/parsing_failed")
    })
  }
  if (http_code < 200 || 300 <= http_code || answer?.error != null) {
    let reason = " ".join([ http_code, answer?.error ], true)
    logZ($"Response is error: {reason}", response)
    onFailure({
      errId = $"Response is error: {reason}"
      errText = reason
    })
  }
  else
    onSuccess(answer)
}

let function onAttachmentUploadSuccess(answer, cb) {
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

let function onAttachmentUploadFailure(errInfo, cb) {
  logZ($"Attachment upload failed: {errInfo.errId}")
  cb()
}

let function uploadAttachment(fileData, cb) {
  if (fileData == null)
    return cb()
  let { filename, mimeType, content } = fileData
  logZ($"Uploading attachment: {filename} ({content.len()} bytes)")
  httpRequest({
    url = $"https://gaijin.zendesk.com/api/v2/uploads.json?filename={filename}"
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

let function onSendFormSuccess(answer) {
  let { id, requester_id } = answer.request
  logZ($"Request created successfully: id {id}, requester_id {requester_id}")
  requestState.mutate(@(v) v.__update({
    isProcessing = false
    id
  }))
}

let function onSendFormFailure(errInfo) {
  logZ($"Request sending failed")
  requestState.mutate(@(v) v.__update({
    isProcessing = false
    errInfo
  }))
}

let function sendFormData() {
  let { email, name, category, subject, message, locale, lang } = requestState.value.formData
  let { attachments } = requestState.value
  logZ($"Sending request from user {email}")
  let data = {
    request = {
      requester = { name, email, locale }
      ticket_form_id = 5532303880849
      subject
      comment = { body = message }
      custom_fields = [
        { id = 360000060018, value = category }
        { id = 23145413, value = name }
        { id = 23166961, value = lang }
      ]
    }
  }
  if (attachments.len())
    data.request.comment.__update({ uploads = attachments.map(@(v) v.token) })
  httpRequest({
    url = "https://gaijin.zendesk.com/api/v2/requests"
    method = "POST"
    json = data
    callback = mkZendeskHttpRequestCb(
      onSendFormSuccess,
      onSendFormFailure
    )
  })
}

let function submitSupportRequest(formData) {
  if (requestState.value.isProcessing)
    return
  requestState.mutate(@(v) v.__update({
    isProcessing = true
    formData
    errInfo = null
  }))
  if (requestState.value.attachments.len() == 0)
    uploadAttachment(getLogFileData(), sendFormData)
  else
    sendFormData()
}

let onRequestResultSeen = @() requestState.value.isProcessing
  ? null
  : requestState(clone defaultRequestState)

return {
  requestState
  submitSupportRequest
  onRequestResultSeen
}
