local wd_xushi = require "packages/wdls/wd_xushi"
local wd_junxing = require "packages/wdls/wd_junxing"
local wd_bingshi = require "packages/wdls/wd_bingshi"

local wd_xushi_cards = require "packages/wdls/wd_xushi_cards"

Fk:loadTranslationTable{ ["wdls"] = "玩点" }

return {
  wd_xushi,
  wd_junxing,
  wd_bingshi,

  wd_xushi_cards,
}
