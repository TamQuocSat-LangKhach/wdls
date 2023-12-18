local extension = Package("wd_bingshi")
extension.extensionName = "wandianlunsha"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["wd_bingshi"] = "玩点-兵势篇",
}

local chentai = General(extension, "wd__chentai", "wei", 4)
local wd__chenyong = fk.CreateViewAsSkill{
  name = "wd__chenyong",
  anim_type = "control",
  pattern = "slash,jink",
  prompt = "#wd__chenyong",
  interaction = function()
    local names = {}
    if Fk.currentResponsePattern == nil and Self:canUse(Fk:cloneCard("slash")) then
      table.insertIfNeed(names, "slash")
    else
      for _, name in ipairs({"slash", "jink"}) do
        if Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard(name)) then
          table.insertIfNeed(names, name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    if use.tos then
      room:doIndicate(player.id, TargetGroup:getRealTargets(use.tos))
    end
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return player:canPindian(p) end), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#wd__chenyong-choose:::"..use.card.name, self.name, false)
    if #to > 0 then
      to = room:getPlayerById(to[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    local pindian = player:pindian({to}, self.name)
    if not player.dead and player:isKongcheng() then
      player:drawCards(1, self.name)
    end
    if pindian.results[to.id].winner == player then
      return
    end
    return ""
  end,
  enabled_at_play = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p) return player ~= p and player:canPindian(p) end)
  end,
  enabled_at_response = function(self, player, response)
    return table.find(Fk:currentRoom().alive_players, function(p) return player ~= p and player:canPindian(p) end)
  end,
}
chentai:addSkill(wd__chenyong)
Fk:loadTranslationTable{
  ["wd__chentai"] = "陈泰",
  ["wd__chenyong"] = "沉勇",
  [":wd__chenyong"] = "当你需使用或打出【杀】或【闪】时，你可以拼点，若你赢，视为你使用或打出之。然后若你没有手牌，你摸一张牌。",
  ["#wd__chenyong"] = "沉勇：声明你需使用或打出的牌并指定目标，然后选择角色拼点",
  ["#wd__chenyong-choose"] = "沉勇：选择一名角色拼点，若赢，视为你使用【%arg】",
}

local cuilin = General(extension, "wd__cuilin", "wei", 3)
local wd__xikou = fk.CreateTriggerSkill{
  name = "wd__xikou",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.BeforeCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.from == player.id then
          if (move.moveReason == fk.ReasonPrey or move.moveReason == fk.ReasonDiscard) and
            (move.proposer ~= player and move.proposer ~= player.id) then
            return true
          end
        else
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              if move.moveReason == fk.ReasonPrey and (move.proposer == player.id or move.proposer == player) then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id then
        if (move.moveReason == fk.ReasonPrey or move.moveReason == fk.ReasonDiscard) and
          (move.proposer ~= player and move.proposer ~= player.id) then
          player.room:notifySkillInvoked(player, self.name, "defensive")
          return true
        end
      else
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            if move.moveReason == fk.ReasonPrey and (move.proposer == player.id or move.proposer == player) then
              player.room:notifySkillInvoked(player, self.name, "negative")
              return true
            end
          end
        end
      end
    end
  end,
}
local wd__suli = fk.CreateActiveSkill{
  name = "wd__suli",
  anim_type = "control",
  card_num = 0,
  target_num = 0,
  prompt = function(self)
    if Self:getHandcardNum() < Self.maxHp then
      return "#wd__suli-draw"
    elseif Self:getHandcardNum() > Self.maxHp then
      return "#wd__suli-discard"
    end
  end,
  can_use = function(self, player)
    return (player:getMark("wd__suli1-phase") == 0 and player:getHandcardNum() < player.maxHp) or
      (player:getMark("wd__suli2-phase") == 0 and player:getHandcardNum() > player.maxHp)
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = player:getHandcardNum() - player.maxHp
    if n > 0 then
      room:setPlayerMark(player, "wd__suli2-phase", 1)
      room:askForDiscard(player, n, n, false, self.name, false)
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end), Util.IdMapper)
      if player.dead or #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 1, n, "#wd__suli-choose:::"..n, self.name, true)
      if #tos > 0 then
        for _, id in ipairs(tos) do
          local p = room:getPlayerById(id)
          if not player.dead and not p.dead and not p:isNude() then
            local c = room:askForCardChosen(player, p, "he", self.name)
            room:throwCard({c}, self.name, p, player)
          end
        end
      end
    else
      room:setPlayerMark(player, "wd__suli1-phase", 1)
      player:drawCards(-n, self.name)
    end
  end,
}
cuilin:addSkill(wd__xikou)
cuilin:addSkill(wd__suli)
Fk:loadTranslationTable{
  ["wd__cuilin"] = "崔林",
  ["wd__xikou"] = "息寇",
  [":wd__xikou"] = "锁定技，其他角色不能弃置或获得你的牌，你不能获得其他角色的手牌。",
  ["wd__suli"] = "肃吏",
  [":wd__suli"] = "出牌阶段各限一次，你可以：1.将手牌摸至体力上限；2.将手牌弃至体力上限，然后弃置至多弃牌张数的其他角色各一张牌。",
  ["#wd__suli-draw"] = "肃吏：你可以将手牌摸至体力上限",
  ["#wd__suli-discard"] = "肃吏：你可以将手牌弃至体力上限，然后弃置至多弃牌数的其他角色各一张牌",
  ["#wd__suli-choose"] = "肃吏：你可以弃置至多%arg名角色各一张牌",
}

local jiakui = General(extension, "wd__jiakui", "wei", 3)
local wd__wanlan = fk.CreateTriggerSkill{
  name = "wd__wanlan",
  mute = true,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.color ~= Card.NoColor
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets, prompt
    if data.card.color == Card.Red then
      targets = table.map(table.filter(room.alive_players, function(p) return player.hp >= p.hp end), Util.IdMapper)
      prompt = "#wd__wanlan1-choose"
    elseif data.card.color == Card.Black then
      targets = table.map(table.filter(room.alive_players, function(p) return player.hp <= p.hp and not p:isNude() end), Util.IdMapper)
      prompt = "#wd__wanlan2-choose"
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if data.card.color == Card.Red then
      player:broadcastSkillInvoke(self.name, 1)
      room:notifySkillInvoked(player, self.name, "support")
      to:drawCards(1, self.name)
      if not to.dead and to:isWounded() then
        room:recover({
          who = to,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        })
      end
    elseif data.card.color == Card.Black then
      player:broadcastSkillInvoke(self.name, 2)
      room:notifySkillInvoked(player, self.name, "offensive")
      if not to:isNude() then
        local id = room:askForCardChosen(player, to, "he", self.name)
        room:throwCard({id}, self.name, to, player)
      end
      if not to.dead then
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
jiakui:addSkill(wd__wanlan)
Fk:loadTranslationTable{
  ["wd__jiakui"] = "贾逵",
  ["wd__wanlan"] = "挽澜",
  [":wd__wanlan"] = "当你使用或打出红色牌时，你可以令一名体力值不大于你的角色摸一张牌并回复1点体力；当你使用或打出黑色牌时，"..
  "你可以弃置一名体力值不小于你的角色的一张牌并对其造成1点伤害。",
  ["#wd__wanlan1-choose"] = "挽澜：令一名角色摸一张牌并回复1点体力",
  ["#wd__wanlan2-choose"] = "挽澜：弃置一名角色的一张牌并对其造成1点伤害",
}

local mazhong = General(extension, "wd__mazhong", "shu", 4)
local wd__fuman = fk.CreateActiveSkill{
  name = "wd__fuman",
  anim_type = "support",
  min_card_num = 1,
  target_num = 1,
  prompt = "#wd__fuman",
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return Fk:getCardById(to_select).trueName == "slash"
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(effect.cards)
    room:obtainCard(target, dummy, false, fk.ReasonGive)
    if not player:isKongcheng() then
      room:askForUseActiveSkill(player, self.name, "#wd__fuman-invoke", true)
    end
  end,
}
local wd__fuman_trigger = fk.CreateTriggerSkill{
  name = "#wd__fuman_trigger",

  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self
    else
      return target == player and player:hasSkill(self, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self, true) then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          room:handleAddLoseSkills(p, "wd__fuman&", nil, false, true)
        end
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      for _, p in ipairs(room:getOtherPlayers(player, true, true)) do
        room:handleAddLoseSkills(p, "-wd__fuman&", nil, false, true)
      end
    end
  end,
}
local wd__fuman_active = fk.CreateActiveSkill{
  name = "wd__fuman&",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#wd__fuman&",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):hasSkill("wd__fuman")
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target, effect.cards[1], false, fk.ReasonGive)
    player:drawCards(1, "wd__fuman")
  end,
}
Fk:addSkill(wd__fuman_active)
wd__fuman:addRelatedSkill(wd__fuman_trigger)
mazhong:addSkill(wd__fuman)
Fk:loadTranslationTable{
  ["wd__mazhong"] = "马忠",
  ["wd__fuman"] = "抚蛮",
  [":wd__fuman"] = "出牌阶段，你可以将【杀】交给其他角色。其他角色的出牌阶段限一次，其可以将一张【杀】交给你，摸一张牌。",
  ["#wd__fuman-invoke"] = "抚蛮：你可以将【杀】交给其他角色",
  ["wd__fuman&"] = "抚蛮",
  [":wd__fuman&"] = "出牌阶段限一次，你可以将一张【杀】交给马忠，摸一张牌。",
  ["#wd__fuman"] = "抚蛮：你可以将【杀】交给其他角色",
  ["#wd__fuman&"] = "抚蛮：你可以将一张【杀】交给马忠，摸一张牌",
}

local shixie = General(extension, "wd__shixie", "wu", 3)
local wd__jujiao = fk.CreateTriggerSkill{
  name = "wd__jujiao",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getHandcardNum() < player.maxHp
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@wd__jujiao", 1)
    room:addPlayerMark(player, MarkEnum.PlayerRemoved, 1)
  end,

  refresh_events = {fk.EventAcquireSkill, fk.RoundStart, fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill then
      return target == player and data == self and not player.room:getTag("FirstRound") and player.room:getTag("RoundCount") == 1
    elseif event == fk.RoundStart then
      return player:hasSkill(self)
    else
      return target == player and player:getMark("@@wd__jujiao") > 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventAcquireSkill then
      room:setPlayerMark(player, self.name, 1)
    elseif event == fk.RoundStart then
      if room:getTag("RoundCount") == 1 then
        room:setPlayerMark(player, self.name, 1)
        room.logic:getCurrentEvent():addCleaner(function()
          room:setPlayerMark(player, self.name, 0)
        end)
      else
        room:setPlayerMark(player, self.name, 0)
      end
    else
      room:setPlayerMark(player, "@@wd__jujiao", 0)
      room:removePlayerMark(player, MarkEnum.PlayerRemoved, 1)
    end
  end,
}
local wd__jujiao_prohibit = fk.CreateProhibitSkill{
  name = "#wd__jujiao_prohibit",
  frequency = Skill.Compulsory,
  is_prohibited = function(self, from, to, card)
    return to:hasSkill(self) and to:getMark("wd__jujiao") > 0 and from ~= to
  end,
}
local wd__shuaifu = fk.CreateTriggerSkill{
  name = "wd__shuaifu",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    player:drawCards(#kingdoms, self.name)
    if player.dead or player:getHandcardNum() <= player.maxHp then return end
    local n = player:getHandcardNum() - player.maxHp
    local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
    if #targets == 0 then
      room:askForDiscard(player, n, n, false, self.name, false)
      return
    end
    local choice = room:askForChoice(player, {"wd__shuaifu1:::"..n, "wd__shuaifu2:::"..n}, self.name)
    if choice[12] == "1" then
      local to, cards = U.askForChooseCardsAndPlayers(room, player, n, n, targets, 1, 1, ".|.|.|hand", "#wd__shuaifu1:::"..n, self.name, false)
      to = room:getPlayerById(to[1])
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(cards)
      room:moveCardTo(dummy, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
      if not player.dead and player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        })
      end
    else
      local cards = room:askForDiscard(player, n, n, false, self.name, false)
      if player.dead or #cards == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#wd__shuaifu2-choose", self.name, false)
      to = room:getPlayerById(to[1])
      if to:isNude() then return end
      local ids = room:askForCardsChosen(player, to, 1, #cards, "he", self.name, "#wd__shuaifu2-discard::"..to.id..":"..#cards)
      room:throwCard(ids, self.name, to, player)
    end
  end,
}
wd__jujiao:addRelatedSkill(wd__jujiao_prohibit)
shixie:addSkill(wd__jujiao)
shixie:addSkill(wd__shuaifu)
Fk:loadTranslationTable{
  ["wd__shixie"] = "士燮",
  ["wd__jujiao"] = "踞交",
  [":wd__jujiao"] = "锁定技，游戏第一轮，其他角色使用牌不能指定你为目标；回合结束时，若你的手牌数小于体力上限，你不计入距离和座次计算直到你下回合开始。",
  ["wd__shuaifu"] = "率附",
  [":wd__shuaifu"] = "锁定技，准备阶段开始时，你摸X张牌，然后若你的手牌数大于体力上限，你选择一项：1.将多余的牌交给一名其他角色，你回复1点体力；"..
  "2.弃置多余的牌，然后弃置一名其他角色至多等量的牌。（X为场上势力数）",
  ["@@wd__jujiao"] = "踞交",
  ["wd__shuaifu1"] = "交给一名其他角色%arg张手牌，你回复1点体力",
  ["wd__shuaifu2"] = "弃置%arg张手牌，弃置一名其他角色等量的牌",
  ["#wd__shuaifu1"] = "率附：交给一名其他角色%arg张牌，你回复1点体力",
  ["#wd__shuaifu2-choose"] = "率附：选择一名其他角色，弃置其等量的牌",
  ["#wd__shuaifu2-discard"] = "率附：弃置 %dest 至多%arg张牌",
}

local sunli = General(extension, "wd__sunli", "wei", 4, 5)
local wd__bohu = fk.CreateTriggerSkill{
  name = "wd__bohu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart, fk.PreCardUse},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Start or (player:getMark("@wd__bohu-turn") ~= 0 and string.find(player:getMark("@wd__bohu-turn"), "3") and
          player.phase == Player.Discard and player:isWounded())
      else
        return player:getMark("@wd__bohu-turn") ~= 0 and string.find(player:getMark("@wd__bohu-turn"), "2") and
          data.card.trueName == "slash" and player:isWounded()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      if player.phase == Player.Start then
        return player.room:askForSkillInvoke(player, self.name)
      else
        local targets = player.room:askForChoosePlayers(player, table.map(table.filter(player.room:getOtherPlayers(player), function(p)
          return not p:isKongcheng() end), function(p) return p.id end), 1, 2, "#wd__bohu-choose:::"..player:getLostHp(), self.name, true)
        if #targets > 0 then
          self.cost_data = targets
          return true
        end
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local room = player.room
      if player.phase == Player.Start then
        local choices = {"wd__bohu1", "wd__bohu2"}
        local n = 1
        if player:usedSkillTimes("wd__fenjie", Player.HistoryGame) > 0 then
          n = 2
          table.insert(choices, "wd__bohu3")
        end
        for i = 1, n, 1 do
          local choice = room:askForChoice(player, choices, self.name, "#wd__bohu-choice")
          if i == 1 then
            room:setPlayerMark(player, "@wd__bohu-turn", string.sub(choice, 9))
          else
            room:setPlayerMark(player, "@wd__bohu-turn", player:getMark("@wd__bohu-turn").."，"..string.sub(choice, 9))
          end
          table.removeOne(choices, choice)
          if choice == "wd__bohu1" then
            local choices2 = {}
            for j = 0, player.hp, 1 do
              table.insert(choices2, tostring(j))
            end
            local choice2 = room:askForChoice(player, choices2, self.name, "#wd__bohu1-choice")
            if choice2 ~= "0" then
              room:loseHp(player, tonumber(choice2), self.name)
              if not player.dead then
                player:drawCards(tonumber(choice2), self.name)
              end
            end
          end
        end
      else
        for _, id in ipairs(self.cost_data) do
          local p = room:getPlayerById(id)
          local n = math.min(p:getHandcardNum(), player:getLostHp())
          local cards = room:askForCard(p, n, n, false, self.name, false, ".", "#wd__bohu-give::"..player.id..":"..n)
          local dummy = Fk:cloneCard("dilu")
          dummy:addSubcards(cards)
          room:obtainCard(player, dummy, false, fk.ReasonGive)
          room:setPlayerMark(p, self.name, n)
        end
        for _, id in ipairs(self.cost_data) do
          local p = room:getPlayerById(id)
          local n = p:getMark(self.name)
          room:setPlayerMark(p, self.name, 0)
          local cards = room:askForCard(player, n, n, true, self.name, false, ".", "#wd__bohu-give::"..p.id..":"..n)
          local dummy = Fk:cloneCard("dilu")
          dummy:addSubcards(cards)
          room:obtainCard(p, dummy, false, fk.ReasonGive)
        end
      end
    else
      data.additionalDamage = (data.additionalDamage or 0) + player:getLostHp()
    end
  end,
}
local wd__bohu_distance = fk.CreateDistanceSkill{
  name = "#wd__bohu_distance",
  correct_func = function(self, from, to)
    if from:getMark("@wd__bohu-turn") ~= 0 and string.find(from:getMark("@wd__bohu-turn"), "1") then
      return -from:getLostHp()
    end
    return 0
  end,
}
local wd__fenjie = fk.CreateTriggerSkill{
  name = "wd__fenjie",
  anim_type = "special",
  frequency = Skill.Limited,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wd__fenjie-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = player:getLostHp(),
        recoverBy = player,
        skillName = self.name,
      })
    end
  end,
}
wd__bohu:addRelatedSkill(wd__bohu_distance)
sunli:addSkill(wd__bohu)
sunli:addSkill(wd__fenjie)
Fk:loadTranslationTable{
  ["wd__sunli"] = "孙礼",
  ["wd__bohu"] = "搏虎",
  [":wd__bohu"] = "准备阶段，你可以选择一项：<br>1.失去任意点体力，摸等量的牌，你至其他角色的距离-X直到回合结束；<br>"..
  "2.你使用【杀】伤害基数值+X直到回合结束。<br>（X为你已损失的体力值）",
  ["wd__fenjie"] = "分界",
  [":wd__fenjie"] = "限定技，回合开始时，你可以减1点体力上限并回复体力至体力上限，然后修改〖搏虎〗：<br>"..
  "“选择一项”改为“选择两项”；<br>增加选项“3.弃牌阶段开始时，你令一至两名其他角色各将X张手牌交给你，然后你分别将等量的牌交给这些角色”。",
  ["#wd__bohu-choice"] = "搏虎：选择一项本回合获得的效果",
  ["wd__bohu1"] = "失去任意点体力，摸等量的牌，你至其他角色距离-X",
  ["wd__bohu2"] = "你使用【杀】伤害基数值+X",
  ["wd__bohu3"] = "弃牌阶段，令一至两名其他角色各将X张手牌交给你，然后交还等量牌",
  ["@wd__bohu-turn"] = "搏虎",
  ["#wd__bohu1-choice"] = "搏虎：你可以失去任意点体力，摸等量牌",
  ["#wd__bohu_trigger"] = "搏虎",
  ["#wd__fenjie-invoke"] = "分界：你可以减1点体力上限，修改〖搏虎〗！",
  ["#wd__bohu-choose"] = "搏虎：你可以令一至两名其他角色各将%arg张手牌交给你，然后交还等量的牌",
  ["#wd__bohu-give"] = "搏虎：选择%arg张牌交给 %dest",
}

--王基

Fk:loadTranslationTable{
  ["wd__xiahoushang"] = "夏侯尚",
  ["wd__anxi"] = "暗袭",
  [":wd__anxi"] = "出牌阶段限一次，你可以将一张装备牌置入一名其他角色的装备区（可以替换原装备），令该角色选择一项：1.弃置装备区内所有牌；"..
  "2.你对其造成X点火焰伤害（X为你至其的距离）。",
  ["wd__shengsha"] = "生杀",
  [":wd__shengsha"] = "限定技，出牌阶段，你可以转置一名角色装备区内任意张牌。",
}

local yanghong = General(extension, "wd__yanghong", "qun", 3)
local wd__dinglve = fk.CreateTriggerSkill{
  name = "wd__dinglve",
  anim_type = "control",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.trueName == "slash" and
      player:distanceTo(player.room:getPlayerById(data.to)) <= 1 and data.from ~= player.id and
      #U.getUseExtraTargets(player.room, data, true, true) > 0 and not player:isNude() and
      not player.room:getPlayerById(data.from).dead
  end,
  on_cost = function(self, event, target, player, data)
    local tos, card = player.room:askForChooseCardAndPlayers(player, U.getUseExtraTargets(player.room, data, true, true), 1, 2, ".",
      "#wd__dinglve-invoke:"..data.to..":"..data.from, self.name, true)
    if #tos > 0 and card then
      self.cost_data = {tos, card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    room:moveCardTo(Fk:getCardById(self.cost_data[2]), Card.PlayerHand, from, fk.ReasonGive, self.name, nil, false, player.id)
    AimGroup:cancelTarget(data, data.to)
    for _, id in ipairs(self.cost_data[1]) do
      AimGroup:addTargets(room, data, id)
    end
  end,
}
local wd__bifeng = fk.CreateTriggerSkill{
  name = "wd__bifeng",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.from ~= player.id and
      (data.card:isCommonTrick() or data.card.trueName == "slash") then
      local from = player.room:getPlayerById(data.from)
      return not from.dead and (from:getHandcardNum() >= player:getHandcardNum() or from.hp >= player.hp)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local n = 0
    if from:getHandcardNum() >= player:getHandcardNum() then
      n = 1
    end
    if from.hp >= player.hp then
      if n == 1 then
        n = 3
      else
        n = 2
      end
    end
    if n ~= 2 then
      player:drawCards(1, self.name)
    end
    if player.dead or n < 2 then return end
    if not player.faceup then
      player:turnOver()
    end
    if player.dead then return end
    if player.chained then
      player:setChainState(false)
    end
    if player.dead then return end
    if n == 3 then
      table.insertIfNeed(data.nullifiedTargets, player.id)
    end
  end,
}
yanghong:addSkill(wd__dinglve)
yanghong:addSkill(wd__bifeng)
Fk:loadTranslationTable{
  ["wd__yanghong"] = "杨弘",
  ["wd__dinglve"] = "定略",
  [":wd__dinglve"] = "当你或你攻击范围内的一名角色成为其他角色使用【杀】的目标时，你可以将一张牌交给此【杀】的使用者并选择至多两名是此【杀】合法目标"..
  "的角色（无距离限制），代替该角色成为此【杀】的目标。",
  ["wd__bifeng"] = "避锋",
  [":wd__bifeng"] = "锁定技，当你成为其他角色使用【杀】或普通锦囊牌的目标后，若使用者的手牌数不少于你，你摸一张牌；体力值不少于你，你重置武将牌；"..
  "均满足，此牌对你无效。",
  ["#wd__dinglve-invoke"] = "定略：你可以将一张牌交给 %dest ，令其对 %src 使用的【杀】转移给至多两名角色",
}

Fk:loadTranslationTable{
  ["wd__zhanggong"] = "张恭",
  ["wd__qianxin"] = "遣信",
  [":wd__qianxin"] = "①出牌阶段，若场上没有“信”，你可以选择一名其他角色为“遣信”目标，并将牌堆顶牌作为“信”置于下家的武将牌旁。<br>"..
  "②“遣信”目标回合开始时，若其有“信”，其获得之，你摸X张牌并回复X点体力（X为你至其的距离）。<br>"..
  "③有“信”的角色准备阶段，其可以将之置于其下家的武将牌旁。<br>"..
  "④你或“遣信”目标死亡时，将“信”置入弃牌堆。",
  ["wd__qiwei"] = "骑卫",
  [":wd__qiwei"] = "锁定技，有“信”的角色手牌上限-1；其回合结束时，你可以弃置一张牌，对其造成1点伤害并将“信”置于其下家的武将牌旁。",
}

local zhangji = General(extension, "wd__zhangjiw", "wei", 3)
local wd__anxiao = fk.CreateProhibitSkill{
  name = "wd__anxiao",
  frequency = Skill.Compulsory,
  is_prohibited = function(self, from, to, card)
    if to:hasSkill(self) then
      return from.phase ~= Player.NotActive and from:getMark("wd__anxiao-turn") == 0 and from:distanceTo(to) == 1
    end
  end,
}
local wd__anxiao_record = fk.CreateTriggerSkill{
  name = "#wd__anxiao_record",

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "wd__anxiao-turn", 1)
  end,
}
local wd__suqi = fk.CreateTriggerSkill{
  name = "wd__suqi",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askForUseActiveSkill(player, "wd__suqi_choose", "#wd__suqi-invoke", true)
    if success then
      self.cost_data = dat.targets
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, self.cost_data)
    local targets = table.map(self.cost_data, function(id) return room:getPlayerById(id) end)
    table.insert(targets, player)
    for _, p in ipairs(targets) do
      room:setPlayerMark(p, "wd__suqi_target-phase", 1)
    end
    local ids = room:getNCards(2 * #self.cost_data)
    local fakemove = {
      toArea = Card.PlayerHand,
      to = player.id,
      moveInfo = table.map(ids, function(id) return {cardId = id, fromArea = Card.Void} end),
      moveReason = fk.ReasonJustMove,
    }
    room:notifyMoveCards({player}, {fakemove})
    for _, id in ipairs(ids) do
      room:setCardMark(Fk:getCardById(id), "wd__suqi", 1)
    end
    while table.find(ids, function(id) return Fk:getCardById(id):getMark("wd__suqi") > 0 end) do
      room:askForUseActiveSkill(player, "wd__suqi_active", "#wd__suqi-give", false)
    end
    for _, p in ipairs(targets) do
      room:setPlayerMark(p, "wd__suqi_target-phase", 0)
      room:setPlayerMark(p, "wd__suqi_num-phase", 0)
    end
  end,
}
local wd__suqi_choose = fk.CreateActiveSkill{
  name = "wd__suqi_choose",
  mute = true,
  min_target_num = 1,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      return true
    else
      local target1 = Fk:currentRoom():getPlayerById(to_select)
      local target2 = Fk:currentRoom():getPlayerById(selected[1])
      return target1:getHandcardNum() == target2:getHandcardNum()
    end
  end,
}
local wd__suqi_active = fk.CreateActiveSkill{
  name = "wd__suqi_active",
  mute = true,
  min_card_num = 1,
  max_card_num = 3,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    return Fk:getCardById(to_select):getMark("wd__suqi") > 0 and #selected < 3
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and target:getMark("wd__suqi_target-phase") > 0 and target:getMark("wd__suqi_num-phase") <= 3 - #selected_cards
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:doIndicate(player.id, {target.id})
    for _, id in ipairs(effect.cards) do
      room:setCardMark(Fk:getCardById(id), "wd__suqi", 0)
    end
    room:addPlayerMark(target, "wd__suqi_num-phase", #effect.cards)
    local fakemove = {
      from = player.id,
      toArea = Card.Void,
      moveInfo = table.map(effect.cards, function(id) return {cardId = id, fromArea = Card.PlayerHand} end),
      moveReason = fk.ReasonGive,
    }
    room:notifyMoveCards({player}, {fakemove})
    room:moveCards({
      fromArea = Card.Void,
      ids = effect.cards,
      to = target.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonGive,
      skillName = self.name,
    })
  end,
}
Fk:addSkill(wd__suqi_choose)
Fk:addSkill(wd__suqi_active)
wd__anxiao:addRelatedSkill(wd__anxiao_record)
zhangji:addSkill(wd__anxiao)
zhangji:addSkill(wd__suqi)
Fk:loadTranslationTable{
  ["wd__zhangjiw"] = "张既",
  ["wd__anxiao"] = "安骁",
  [":wd__anxiao"] = "锁定技，你不是至你距离为1的其他角色于其回合内使用的第一张牌的合法目标。",
  ["wd__suqi"] = "肃齐",
  [":wd__suqi"] = "结束阶段，你可以选择任意名手牌数相等的角色，观看牌堆顶的2X张牌（X为这些角色的数量），然后将这些牌任意交给你和这些角色，"..
  "每名角色至多三张。",
  ["wd__suqi_choose"] = "肃齐",
  ["#wd__suqi-invoke"] = "肃齐：选择任意名手牌数相等的角色，观看牌堆顶等量牌，然后将这些牌任意交给你或这些角色",
  ["wd__suqi_active"] = "肃齐",
  ["#wd__suqi-give"] = "肃齐：将这些牌任意交给你和目标角色，每名角色至多三张",
}

Fk:loadTranslationTable{
  ["wd__zhaoang"] = "赵昂",
  ["wd__qianzhi"] = "遣质",
  [":wd__qianzhi"] = "出牌阶段限一次，你可以将一张♠牌当【笑里藏刀】使用。",
  ["wd__wenjue"] = "问决",
  [":wd__wenjue"] = "锁定技，每回合各限一次，当你造成或受到伤害时，你需令一名其他角色判定，若结果为：黑色，你摸一张牌；"..
  "红色，你防止此伤害，然后获得造成伤害的牌。",
}

return extension
