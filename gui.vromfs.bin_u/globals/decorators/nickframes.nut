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
}

let frameNick = @(nick, frameId) nickFrames?[frameId](nick) ?? nick

return {
  nickFrames
  frameNick
}