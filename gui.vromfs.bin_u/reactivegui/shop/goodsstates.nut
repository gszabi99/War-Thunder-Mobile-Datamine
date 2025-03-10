return {
  PURCHASING           = 0x01
  DELAYED              = 0x02 //delayed by other purchase progress
  NOT_READY            = 0x04 //for rewards by ads view
  HAS_PURCHASES        = 0x08 //user has already bought it before
  ALL_PURCHASED        = 0x10
  IS_ACTIVE            = 0x20 //Only for subscriptions - mean that it already acive
  HAS_UPGRADE          = 0x40
}