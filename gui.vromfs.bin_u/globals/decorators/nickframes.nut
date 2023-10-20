let nickFrames = {
  waves = @(n) $"╈{n}╉"
  bullet = @(n) $"◇{n}◈"
  wings = @(n) $"╊{n}╋"
  cannon = @(n) $"◅{n}◆"
  medal = @(n) $"◄{n}◄"
  aircraft = @(n) $"◂{n}◃"
  tank = @(n) $"◀{n}◁"
  ship = @(n) $"▿{n}▿"
  chevron = @(n) $"▾{n}▾"
  clover = @(n) $"◊{n}◊"
  horseshoe = @(n) $"○{n}○"
  winged_diamond = @(n) $"◉{n}◉"
  blazing_sunrise = @(n) $"◌{n}◌"
  desert_barchan = @(n) $"◍{n}◎"
  palm = @(n) $"●{n}◐"
  machete = @(n) $"◑{n}◒"
  white_squall = @(n) $"◓{n}◔"
  jungle_leaf = @(n) $"◕{n}◖"
  viking_helmet = @(n) $"◗{n}◗"
  iceberg = @(n) $"◘{n}◘"
}

let frameNick = @(nick, frameId) nickFrames?[frameId](nick) ?? nick

return {
  nickFrames
  frameNick
}