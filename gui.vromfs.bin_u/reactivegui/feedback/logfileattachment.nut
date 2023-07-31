from "%globalsDarg/darg_library.nut" import *
let logL = log_with_prefix("[LOGFILE] ")
let { file } = require("io")
let { DBGLEVEL } = require("dagor.system")
let { get_log_filename = @() "" } = require("dagor.debug")

let xorMask = [
  0x82, 0x87, 0x97, 0x40, 0x8D, 0x8B, 0x46, 0x0b, 0xBB, 0x73, 0x94, 0x03, 0xE5, 0xB3, 0x83, 0x53,
  0x69, 0x6B, 0x83, 0xDA, 0x95, 0xAF, 0x4a, 0x23, 0x87, 0xE5, 0x97, 0xAC, 0x24, 0x58, 0xAF, 0x36,
  0x4E, 0xE1, 0x5A, 0xF9, 0xF1, 0x01, 0x4b, 0xb1, 0xAD, 0xB6, 0x4C, 0x4C, 0xFA, 0x74, 0x28, 0x69,
  0xC2, 0x8B, 0x11, 0x17, 0xD5, 0xB6, 0x47, 0xce, 0xB3, 0xB7, 0xCD, 0x55, 0xFE, 0xF9, 0xC1, 0x24,
  0xFF, 0xAE, 0x90, 0x2E, 0x49, 0x6C, 0x4e, 0x09, 0x92, 0x81, 0x4E, 0x67, 0xBC, 0x6B, 0x9C, 0xDE,
  0xB1, 0x0F, 0x68, 0xBA, 0x8B, 0x80, 0x44, 0x05, 0x87, 0x5E, 0xF3, 0x4E, 0xFE, 0x09, 0x97, 0x32,
  0xC0, 0xAD, 0x9F, 0xE9, 0xBB, 0xFD, 0x4d, 0x06, 0x91, 0x50, 0x89, 0x6E, 0xE0, 0xE8, 0xEE, 0x99,
  0x53, 0x00, 0x3C, 0xA6, 0xB8, 0x22, 0x41, 0x32, 0xB1, 0xBD, 0xF5, 0x28, 0x50, 0xE0, 0x72, 0xAE,
]

let LOG_XOR_BLOCK_SIZE = xorMask.len()
let LOG_START_BLOCKS = 8192
let LOG_END_BLOCKS = 16384

let function applyXorMask(contentBlob) {
  local maskIdx = 0
  for (local i = 0; i < contentBlob.len(); i++) {
    contentBlob[i] = contentBlob[i] ^ xorMask[maskIdx]
    maskIdx = (maskIdx + 1) & 0x7F
  }
}

let hasLogFile = @() get_log_filename() != ""

let function getLogFileData() {
  local content = null
  try {
    let fn = get_log_filename()
    if (fn == "") {
      logL("No log file")
      return null
    }
    local fp = file(fn, "rb")
    let fileLen = fp.len()
    if (fileLen == 0) {
      logL("Log file is empty")
      return null
    }

    let startBytes = min(fileLen, LOG_XOR_BLOCK_SIZE * LOG_START_BLOCKS)
    local skipBytes = 0
    local endBytes = 0
    if (fileLen > startBytes) {
      let totalBlocks = (fileLen + (LOG_XOR_BLOCK_SIZE - 1)) / LOG_XOR_BLOCK_SIZE
      skipBytes = max(0, totalBlocks - LOG_START_BLOCKS - LOG_END_BLOCKS) * LOG_XOR_BLOCK_SIZE
      endBytes = fileLen - startBytes - skipBytes
    }

    let buf = fp.readblob(startBytes)
    buf.seek(startBytes)
    if (skipBytes > 0)
      fp.seek(skipBytes, 'c')
    if (endBytes > 0)
      buf.writeblob(fp.readblob(endBytes))
    fp.close()
    buf.flush()
    content = buf
  }
  catch (e) {
    logL($"Failed to read log file: {e}")
    return null
  }
  if (DBGLEVEL <= 0) // Log is encrypted
    applyXorMask(content)
  return {
    filename = "debug.txt"
    mimeType = "text/plain"
    content
  }
}

return {
  hasLogFile
  getLogFileData
}
