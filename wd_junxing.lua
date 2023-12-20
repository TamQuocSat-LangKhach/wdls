local extension = Package("wd_junxing")
extension.extensionName = "wdls"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["wd_junxing"] = "玩点-军形篇",
}

local chengji = General(extension, "wd__chengji", "shu", 3)
local wd__zudi = fk.CreateTriggerSkill{
  name = "wd__zudi",
  anim_type = "defensive",
  events = {fk.GameStart, fk.EventPhaseStart, fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Start
      else
        return data.card.trueName == "slash" and target:getMark("@@wd__zudi") ~= 0 and table.contains(target:getMark("@@wd__zudi"), player.id)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventPhaseStart then
      local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
        return p.id end), 1, 1, "#wd__zudi-choose", self.name, true)
      if #to > 0 then
        self.cost_data = to[1]
        return true
      end
    else
      local prompt
      if data.from and not room:getPlayerById(data.from).dead and data.from ~= player.id then
        prompt = "#wd__zudi-invoke:"..target.id..":"..data.from
      else
        prompt = "#wd__zudi2-invoke:"..target.id
      end
      return room:askForSkillInvoke(player, self.name, nil, prompt)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventPhaseStart then
      local mark = player:getMark("@@wd__zudi")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, player.id)
      room:setPlayerMark(player, "@@wd__zudi", mark)
      local to = room:getPlayerById(self.cost_data)
      mark = to:getMark("@@wd__zudi")
      if mark == 0 then mark = {} end
      table.insertIfNeed(mark, player.id)
      room:setPlayerMark(to, "@@wd__zudi", mark)
    else
      local beishui = false
      if player:isNude() then
        room:loseHp(player, 1, self.name)
      else
        if #room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#wd__zudi-discard") == 0 then
          room:loseHp(player, 1, self.name)
        elseif room:askForSkillInvoke(player, self.name, nil, "#wd__zudi-beishui") then
          room:loseHp(player, 1, self.name)
          beishui = true
        end
      end
      AimGroup:cancelTarget(data, target.id)
      if not player.dead and data.from and not room:getPlayerById(data.from).dead and data.from ~= player.id then
        local use = {
          from = player.id,
          tos = {{data.from}},
          card = Fk:cloneCard("duel"),
        }
        if beishui then
          use.disresponsive = true
          use.additionalDamage = 1
        end
        use.card.skillName = self.name
        room:useCard(use)
      end
      return true
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@wd__zudi") ~= 0 and table.contains(player:getMark("@@wd__zudi"), player.id) and
      data.from == Player.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@@wd__zudi") ~= 0 and table.contains(p:getMark("@@wd__zudi"), player.id) then
        local mark = p:getMark("@@wd__zudi")
        table.removeOne(mark, player.id)
        if #mark == 0 then mark = 0 end
        room:setPlayerMark(p, "@@wd__zudi", mark)
      end
    end
  end,
}
local wd__juesi = fk.CreateFilterSkill{
  name = "wd__juesi",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  card_filter = function(self, to_select, player)
    return player:hasSkill(self) and to_select.type == Card.TypeBasic and
      not table.contains({"slash", "peach", "analeptic"}, to_select.trueName)
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
}
local wd__juesi_maxcards = fk.CreateMaxCardsSkill{
  name = "#wd__juesi_maxcards",
  frequency = Skill.Compulsory,
  exclude_from = function(self, player, card)
    return player:hasSkill(self) and table.contains(card.skillNames, "wd__juesi")
  end,
}
wd__juesi:addRelatedSkill(wd__juesi_maxcards)
chengji:addSkill(wd__zudi)
chengji:addSkill(wd__juesi)
Fk:loadTranslationTable{
  ["wd__chengji"] = "程畿",
  ["wd__zudi"] = "阻敌",
  [":wd__zudi"] = "游戏开始时或准备阶段开始时，你可以选择一名其他角色。直到你下回合开始，当你或该角色成为【杀】的目标时，你可以弃置一张牌或失去1点体力，"..
  "取消所有目标，然后视为对此【杀】的使用者使用【决斗】。背水：此【决斗】不可响应且伤害+1。",
  ["wd__juesi"] = "决死",
  [":wd__juesi"] = "锁定技，你除【杀】、【桃】、【酒】以外的基本牌均视为【杀】且不计入手牌上限。",
  ["@@wd__zudi"] = "阻敌",
  ["#wd__zudi-choose"] = "阻敌：选择一名角色，当你或其成为【杀】的目标时，你可以视为对使用者使用【决斗】",
  ["#wd__zudi-invoke"] = "阻敌：你可以弃置一张牌或失去1点体力，取消对 %src 使用的【杀】，并视为对 %arg 使用【决斗】",
  ["#wd__zudi2-invoke"] = "阻敌：你可以弃置一张牌或失去1点体力，取消对 %src 使用的【杀】",
  ["#wd__zudi-discard"] = "阻敌：弃置一张牌，或点“取消”失去1点体力",
  ["#wd__zudi-beishui"] = "阻敌：你可以再失去1点体力，令此【决斗】不可响应且伤害+1！",
}

local fanyufeng = General(extension, "wd__fanyufeng", "qun", 3, 3, General.Female)
local wd__diewu = fk.CreateActiveSkill{
  name = "wd__diewu",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#wd__diewu",
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCardTo(Fk:getCardById(effect.cards[1]), Card.PlayerHand, target, fk.ReasonGive, self.name, nil, true, player.id)
    if not player.dead then
      player:drawCards(1, self.name)
    end
    if target.dead then return end
    local use = room:askForUseCard(target, self.name, "slash", "#wd__diewu-use", true, {bypass_times = true})
    if use then
      use.extraUse = true
      room:useCard(use)
      if not target.dead then
        target:drawCards(1, self.name)
      end
    end
  end,
}
local wd__muyun = fk.CreateTriggerSkill{
  name = "wd__muyun",
  anim_type = "support",
  events = {fk.AfterCardUseDeclared, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if data.card:isVirtual() then
        return #data.card.subcards > 0 and table.find(data.card.subcards, function(id) return Fk:getCardById(id, true).trueName == "jink" end)
      else
        return data.card.name == "jink"
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wd__muyun-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    player.room:doIndicate(player.id, {target.id})
    player:drawCards(1, self.name)
    if not target.dead then
      target:drawCards(1, self.name)
    end
  end,
}
fanyufeng:addSkill(wd__diewu)
fanyufeng:addSkill(wd__muyun)
Fk:loadTranslationTable{
  ["wd__fanyufeng"] = "樊氏",
  ["wd__diewu"] = "蝶舞",
  [":wd__diewu"] = "出牌阶段，你可以将一张【杀】交给一名其他角色，摸一张牌。若如此做，其可以使用一张【杀】，摸一张牌。",
  ["wd__muyun"] = "慕云",
  [":wd__muyun"] = "当一名角色使用或打出牌时，若这些牌中包含【闪】，你可以与其各摸一张牌。",
  ["#wd__diewu"] = "蝶舞：你可以将一张【杀】交给其他角色，摸一张牌",
  ["#wd__diewu-use"] = "蝶舞：你可以使用一张【杀】，摸一张牌",
  ["#wd__muyun-invoke"] = "慕云：你可以与 %dest 各摸一张牌",
}

local furongfuqian = General(extension, "wd__furongfuqian", "shu", 4)
local wd__fenkai = fk.CreateTriggerSkill{
  name = "wd__fenkai",
  mute = true,
  events = {fk.CardEffectCancelledOut, fk.DamageInflicted, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Play and player:getMark("wd__fenkai3") == 0
      elseif data.card and data.card.trueName == "slash" then
        if event == fk.CardEffectCancelledOut then
          return data.from == player.id and player:getMark("wd__fenkai1") == 0
        elseif event == fk.DamageInflicted then
          return (target == player or player:inMyAttackRange(target)) and player:getMark("wd__fenkai2") == 0
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local prompt
    if event == fk.CardEffectCancelledOut then
      prompt = "#wd__fenkai1-invoke::"..data.to
    elseif event == fk.DamageInflicted then
      prompt = "#wd__fenkai2-invoke::"..target.id
    elseif event == fk.EventPhaseStart then
      prompt = "#wd__fenkai3-invoke"
    end
    return player.room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.CardEffectCancelledOut then
      room:notifySkillInvoked(player, self.name, "offensive")
      room:loseHp(player, 1, self.name)
      return true
    elseif event == fk.DamageInflicted then
      room:notifySkillInvoked(player, self.name, "defensive")
      room:loseHp(player, 1, self.name)
      return true
    elseif event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name, "drawcard")
      room:loseHp(player, 1, self.name)
      if player.dead then return end
      local cards = {}
      for _, pattern in ipairs({"slash", ".|.|.|.|.|equip"}) do
        local card = room:getCardsFromPileByRule(pattern, 1, "allPiles")
        if card then
          table.insert(cards, card[1])
        end
      end
      if #cards == 0 then return end
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
local wd__chengming = fk.CreateTriggerSkill{
  name = "wd__chengming",
  anim_type = "defensive",
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    if not player.faceup then
      player:turnOver()
    end
    if player.dead then return end
    if player.chained then
      player:setChainState(false)
    end
    if player.dead then return end
    if player:isWounded() then
      room:recover({
        who = player,
        num = player.maxHp - player.hp,
        recoverBy = player,
        skillName = self.name
      })
    end
    if player.dead or not player:hasSkill("wd__fenkai", true) then return end
    local all_choices = table.map({1, 2, 3}, function(i) return "wd__fenkai"..i end)
    local choices = table.simpleClone(all_choices)
    for i = 1, 3, 1 do
      if player:getMark("wd__fenkai"..i) > 0 then
        table.removeOne(choices, "wd__fenkai"..i)
      end
    end
    if #choices == 0 then return end
    room:setPlayerMark(player, room:askForChoice(player, choices, self.name, "#wd__fenkai-lose", true, all_choices), 1)
  end,
}
furongfuqian:addSkill(wd__fenkai)
furongfuqian:addSkill(wd__chengming)
Fk:loadTranslationTable{
  ["wd__furongfuqian"] = "傅肜傅佥",
  ["wd__fenkai"] = "奋慨",
  [":wd__fenkai"] = "①当你使用的【杀】被抵消时，你可以失去1点体力令此【杀】依然生效。<br>②当你或你攻击范围内的一名角色受到【杀】的伤害时，"..
  "你可以失去1点体力防止此伤害。<br>③出牌阶段开始时，你可以失去1点体力，从牌堆或弃牌堆获得一张【杀】和一张装备牌。",
  ["wd__chengming"] = "承命",
  [":wd__chengming"] = "当你处于濒死状态时，你可以减1点体力上限，复原武将牌并回复体力至体力上限，然后移除〖奋慨〗的一项效果。",
  ["#wd__fenkai1-invoke"] = "奋慨：你可以失去1点体力，令对 %dest 使用的【杀】依然生效",
  ["#wd__fenkai2-invoke"] = "奋慨：你可以失去1点体力，防止 %dest 受到的伤害",
  ["#wd__fenkai3-invoke"] = "奋慨：你可以失去1点体力，获得一张【杀】和一张装备牌",
  ["#wd__fenkai-lose"] = "承命：选择你移除的“奋慨”效果",
  ["wd__fenkai1"] = "1",
  ["wd__fenkai2"] = "2",
  ["wd__fenkai3"] = "3",
  [":wd__fenkai1"] = "当你使用的【杀】被抵消时，你可以失去1点体力令此【杀】依然生效。",
  [":wd__fenkai2"] = "当你或你攻击范围内的一名角色受到【杀】的伤害时，你可以失去1点体力防止此伤害。",
  [":wd__fenkai3"] = "出牌阶段开始时，你可以失去1点体力，从牌堆或弃牌堆获得一张【杀】和一张装备牌。",
}

local guanqiujian = General(extension, "wd__guanqiujian", "wei", 4)
local wd__saotao = fk.CreateTriggerSkill{
  name = "wd__saotao",
  anim_type = "offensive",
  events = {fk.AfterCardUseDeclared},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    if data.card.trueName == "slash" then
      data.prohibitedCardNames = {"jink"}
    elseif data.card:isCommonTrick() then
      data.prohibitedCardNames = {"nullification"}
    end
    if data.card.is_damage_card then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,

  refresh_events = {fk.TargetConfirmed},
  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(self, false, true) and data.from == player.id and (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(target, "wd__saotao&", nil, false, true)
    local e = room.logic:getCurrentEvent()
    if e ~= nil then
      e:addCleaner(function()
        room:handleAddLoseSkills(target, "-wd__saotao&", nil, false, true)
      end)
    end
  end,
}
local wd__saotao_viewas = fk.CreateViewAsSkill{
  name = "wd__saotao&",
  mute = true,
  pattern = "wd_run",
  prompt = "#wd__saotao&",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and table.contains({"jink", "nullification"}, Fk:getCardById(to_select).trueName)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("wd_run")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
}
local wd__shizhao = fk.CreateTriggerSkill{
  name = "wd__shizhao",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player.hp < 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    player:drawCards(2, self.name)
    if not player:isNude() then
      local card = room:askForCard(player, 1, 1, true, self.name, false, ".", "#wd__shizhao-put")
      player:addToPile("wd__guanqiujian_zhao", card[1], true, self.name)
    end
    room:handleAddLoseSkills(player, "wd__hongju", nil, true, false)
  end,
}
local wd__hongju = fk.CreateTriggerSkill{
  name = "wd__hongju",
  anim_type = "offensive",
  events = {fk.TargetSpecified, fk.CardShown},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.TargetSpecified then
        if target == player and (data.card.trueName == "slash" or data.card:isCommonTrick()) then
          local to = player.room:getPlayerById(data.to)
          return U.isOnlyTarget(to, data, fk.TargetSpecified) and not to:isKongcheng()
        end
      elseif #player:getPile("wd__guanqiujian_zhao") > 0 and not target.dead then
        return table.find(data.cardIds, function(id)
          return Fk:getCardById(id).suit ~= Card.NoSuit and
            Fk:getCardById(id).suit ~= Fk:getCardById(player:getPile("wd__guanqiujian_zhao")[1]).suit
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      return room:askForSkillInvoke(player, self.name, nil, "#wd__hongju-show::"..data.to)
    else
      return room:askForSkillInvoke(player, self.name, nil, "#wd__hongju-invoke::"..target.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TargetSpecified then
      local to = room:getPlayerById(data.to)
      local id = table.random(to:getCardIds("h"))
      to:showCards(id)
    else
      room:doIndicate(player.id, {target.id})
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
Fk:addSkill(wd__saotao_viewas)
guanqiujian:addSkill(wd__saotao)
guanqiujian:addSkill(wd__shizhao)
guanqiujian:addRelatedSkill(wd__hongju)
Fk:loadTranslationTable{
  ["wd__guanqiujian"] = "毌丘俭",
  ["wd__saotao"] = "扫讨",
  [":wd__saotao"] = "锁定技，①你使用的【杀】/非延时类锦囊不能被【闪】/【无懈可击】响应且伤害+1。<br>②其他角色成为你使用【杀】/非延时类锦囊的目标后，"..
  "可以将一张【闪】/【无懈可击】当【走】使用。",
  ["wd__shizhao"] = "示诏",
  [":wd__shizhao"] = "觉醒技，准备阶段开始时，若你的体力值小于3，你回复1点体力并摸两张牌，然后将一张牌置于武将牌上，称为“诏”，然后获得技能〖鸿举〗。",
  ["wd__hongju"] = "鸿举",
  [":wd__hongju"] = "①当你使用【杀】/非延时类锦囊指定一名其他角色为唯一目标后，你可以令其展示随机一张手牌。<br>②当一名角色展示与“诏”花色不同的牌后，"..
  "你可以对其造成1点伤害。",

  ["wd__saotao&"] = "扫讨",
  [":wd__saotao&"] = "你可以将一张【闪】或【无懈可击】当【走】使用。",
  ["#wd__saotao&"] = "扫讨：你可以将一张【闪】或【无懈可击】当【走】使用",
  ["#wd__shizhao-put"] = "示诏：将一张牌置为“诏”",
  ["wd__guanqiujian_zhao"] = "诏",
  ["#wd__hongju-show"] = "鸿举：你可以令 %dest 展示随机一张手牌",
  ["#wd__hongju-invoke"] = "鸿举：你可以对 %dest 造成1点伤害",
}

Fk:loadTranslationTable{
  ["wd__heqi"] = "贺齐",
  ["wd__taopan"] = "讨叛",
  [":wd__taopan"] = "当你使用装备牌后，你可以视为使用一张无距离次数限制的【杀】。若你装备区内：红色牌不少于黑色牌，此【杀】无视防具；"..
  "黑色牌不少于红色牌，此【杀】不可被闪避；均满足，此【杀】伤害+1。",
  ["wd__yingyuan"] = "应援",
  [":wd__yingyuan"] = "其他角色的结束阶段，你可以获得你装备区内的一张牌，然后你与其各摸一张牌。",
}

Fk:loadTranslationTable{
  ["wd__kebineng"] = "轲比能",
  ["wd__yuqi"] = "驭骑",
  [":wd__yuqi"] = "你可以场上的坐骑牌当【桃】或【酒】使用。",
  ["wd__diqiu"] = "狄酋",
  [":wd__diqiu"] = "①每回合限一次，当你使用牌指定目标后，若你本阶段使用的牌点数之和不小于13，你可以获得每名目标角色各一张牌；若你本次获得的牌不少于三张，"..
  "你获得“敌酋”标记。②若你有“敌酋”标记，当你造成或受到伤害时，此伤害+1。",
}

local lihui = General(extension, "wd__lihui", "shu", 3)
local wd__shehuang = fk.CreateTriggerSkill{
  name = "wd__shehuang",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Play and
      not player:isKongcheng() and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#wd__shehuang-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player and not player.dead then
      local tos = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 2,
        "#wd__shehuang-choose::"..target.id, self.name, true)
      if #tos > 0 then
        for _, id in ipairs(tos) do
          room:setPlayerMark(room:getPlayerById(id), "@@wd__shehuang-turn", 1)
        end
      end
    end
  end
}
local wd__shehuang_trigger = fk.CreateTriggerSkill{
  name = "#wd__shehuang_trigger",
  mute = true,
  events = {fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase ~= Player.NotActive and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      table.find(player.room.alive_players, function(p)
        return p:getMark("@@wd__shehuang-turn") > 0 and table.contains(U.getUseExtraTargets(player.room, data, true), p.id) end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@@wd__shehuang-turn") > 0 and table.contains(U.getUseExtraTargets(player.room, data, true), p.id) then
        room:doIndicate(player.id, {p.id})
        table.insert(data.tos, {p.id})
      end
    end
  end,
}
local wd__pingman = fk.CreateTriggerSkill{
  name = "wd__pingman",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
      local use = e.data[1]
      if use.from == target.id then
        for _, id in ipairs(TargetGroup:getRealTargets(use.tos)) do
          table.insertIfNeed(tos, id)
        end
      end
    end, Player.HistoryTurn)
    local n = math.max(#tos - player.hp, 1)
    player:drawCards(n, self.name)
  end,
}
wd__shehuang:addRelatedSkill(wd__shehuang_trigger)
lihui:addSkill(wd__shehuang)
lihui:addSkill(wd__pingman)
Fk:loadTranslationTable{
  ["wd__lihui"] = "李恢",
  ["wd__shehuang"] = "舌簧",
  [":wd__shehuang"] = "其他角色出牌阶段开始时，你可以与其拼点：若你赢，你可以选择至多两名角色，此回合内当前回合角色每次使用牌均额外选择这些角色为目标。",
  ["wd__pingman"] = "平蛮",
  [":wd__pingman"] = "锁定技，其他角色结束阶段开始时，你摸X张牌（X为本回合被该角色使用牌指定为目标的角色数减你的体力值，至少为1）。",
  ["#wd__shehuang-invoke"] = "舌簧：你可以与 %dest 拼点，若赢，你指定两名角色为其本回合使用牌的额外目标",
  ["#wd__shehuang-choose"] = "舌簧：选择至多两名角色，%dest 本回合使用牌均额外指定其为目标",
  ["@@wd__shehuang-turn"] = "舌簧",
}

local liangxi = General(extension, "wd__liangxi", "wei", 3)
local wd__yuzhi = fk.CreateTriggerSkill{
  name = "wd__yuzhi",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      elseif event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Draw
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local skip = false
    if event == fk.EventPhaseStart and #player:getPile("wd__yuzhi&") > 0 then
      skip = true
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(player:getPile("wd__yuzhi&"))
      player.room:obtainCard(player.id, dummy, false, fk.ReasonJustMove)
      if player.dead then return end
    end
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(player.room:getNCards(3))
    player:addToPile("wd__yuzhi&", dummy, false, self.name)
    if skip then
      return true
    end
  end,
}
local wd__junlong = fk.CreateTriggerSkill{
  name = "wd__junlong",
  anim_type = "masochism",
  events = {fk.Damaged, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.Damaged then
        return target == player
      elseif player.phase == Player.NotActive then
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromSpecialName == "wd__yuzhi&" then
                return true
              end
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local current = player.room.current
    if not current or current.dead or current:isNude() then return end
    if event == fk.Damaged then
      self.cancel_cost = false
      for i = 1, data.damage do
        if self.cancel_cost or not current or current.dead or current:isNude() then break end
        self:doCost(event, target, player, data)
      end
    else
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name, data, "#wd__junlong-invoke::"..player.room.current.id) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room.current
    room:doIndicate(player.id, {to.id})
    local cards = room:askForCardsChosen(player, to, 1, 3, "he", self.name, "#wd__junlong-choose::"..to.id)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(cards)
    to:addToPile("wd__liangxi_zhi", dummy, false, self.name)
  end,
}
local wd__junlong_trigger = fk.CreateTriggerSkill{
  name = "#wd__junlong_trigger",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and #target:getPile("wd__liangxi_zhi") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    player:broadcastSkillInvoke("wd__junlong")
    room:notifySkillInvoked(player, "wd__junlong", "control")
    local choice = room:askForChoice(target, {"wd__junlong1", "wd__junlong2"}, "wd__junlong", "#wd__junlong-choice:"..player.id)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(target:getPile("wd__liangxi_zhi"))
    if choice == "wd__junlong1" then
      room:obtainCard(target, dummy, false, fk.ReasonJustMove)
      if not target.dead then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = "wd__junlong",
        }
      end
    else
      room:obtainCard(player, dummy, false, fk.ReasonJustMove)
      if not target.dead and target:isWounded() then
        room:recover({
          who = target,
          num = 1,
          recoverBy = player,
          skillName = "wd__junlong",
        })
      end
    end
  end,
}
wd__junlong:addRelatedSkill(wd__junlong_trigger)
liangxi:addSkill(wd__yuzhi)
liangxi:addSkill(wd__junlong)
Fk:loadTranslationTable{
  ["wd__liangxi"] = "梁习",
  ["wd__yuzhi"] = "预植",
  [":wd__yuzhi"] = "①锁定技，游戏开始时，你将牌堆顶的三张牌扣置于武将牌上，称为“植”；你可以如手牌般使用或打出“植”。<br>"..
  "②锁定技，摸牌阶段开始时，若你有“植”，你放弃摸牌，改为获得所有“植”。然后将牌堆顶的三张牌置为“植” 。",
  ["wd__junlong"] = "峻隆",
  [":wd__junlong"] = "当你受到1点伤害后，或当一张“植”于你的回合外移入游戏后，你可以将当前回合角色的至多三张牌置于其武将牌旁，称为“质”。"..
  "每回合结束时，有“质”的角色需选择一项：1.获得所有“质”，然后你对其造成1点伤害；2.将所有“质”交给你，然后其回复1点体力。",
  ["wd__yuzhi&"] = "植",
  ["#wd__junlong-invoke"] = "峻隆：你可以将 %dest 的至多三张牌扣为“质”",
  ["#wd__junlong-choose"] = "峻隆：将 %dest 至多三张牌扣为“质”",
  ["wd__liangxi_zhi"] = "质",
  ["#wd__junlong-choice"] = "峻隆：%src 令你选择执行一项",
  ["wd__junlong1"] = "收回所有“质”，对你造成1点伤害",
  ["wd__junlong2"] = "交出所有“质”，你回复1点体力",
}

local lukai = General(extension, "wd__lukai", "wu", 3)
local wd__kenjian = fk.CreateActiveSkill{
  name = "wd__kenjian",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#wd__kenjian",
  interaction = function()
    local choices = {}
    if Self:getMark("wd__kenjian1-phase") == 0 then
      table.insert(choices, "wd__kenjian1")
    end
    if Self:getMark("wd__kenjian2-phase") == 0 then
      table.insert(choices, "wd__kenjian2")
    end
    if #choices == 0 then return end
    return UI.ComboBox {choices = choices}
  end,
  can_use = function(self, player)
    return player:getMark("wd__kenjian1-phase") == 0 or player:getMark("wd__kenjian2-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= Self.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if self.interaction.data == "wd__kenjian1" then
        return target:getHandcardNum() < Self:getHandcardNum()
      elseif self.interaction.data == "wd__kenjian2" then
        return target:getHandcardNum() > Self:getHandcardNum()
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, self.interaction.data.."-phase", 1)
    local n = target:getHandcardNum() - player:getHandcardNum()
    if n > 0 then
      room:askForDiscard(target, n, n, false, self.name, false)
    else
      target:drawCards(-n, self.name)
    end
  end,
}
local wd__yijian = fk.CreateTriggerSkill{
  name = "wd__yijian",
  anim_type = "support",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper),
      1, 1, "#wd__yijian-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    to:drawCards(3, self.name)
    if to.dead then return end
    room:handleAddLoseSkills(to, "wd__kenjian|wd__yijian", nil, true, false)
  end,
}
lukai:addSkill(wd__kenjian)
lukai:addSkill(wd__yijian)
Fk:loadTranslationTable{
  ["wd__lukai"] = "陆凯",
  ["wd__kenjian"] = "恳谏",
  [":wd__kenjian"] = "出牌阶段各限一次，你可以令一名其他角色：1.将手牌摸至与你相同；2.将手牌弃至与你相同。",
  ["wd__yijian"] = "遗荐",
  [":wd__yijian"] = "当你死亡时，你可以令一名其他角色摸三张牌，然后获得〖恳谏〗和〖遗荐〗。",
  ["#wd__kenjian"] = "恳谏：令一名角色将手牌调整至与你相同",
  ["wd__kenjian1"] = "摸牌",
  ["wd__kenjian2"] = "弃牌",
  ["#wd__yijian-choose"] = "遗荐：你可以令一名角色摸三张牌并获得〖恳谏〗和〖遗荐〗",
}

local lvqian = General(extension, "wd__lvqian", "wei", 4)
local wd__zongqin = fk.CreateViewAsSkill{
  name = "wd__zongqin",
  anim_type = "offensive",
  pattern = "wd_let_off_enemy",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Spade
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("wd_let_off_enemy")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_response = function(self, player, response)
    return not response and player.phase == Player.Play and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
}
local wd__zongqin__wdLetOffEnemySkill = fk.CreateActiveSkill{
  name = "wd__zongqin__wd_let_off_enemy_skill",
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return user ~= to_select
  end,
  target_filter = function(self, to_select, selected, selected_cards, card)
    if #selected < self:getMaxTargetNum(Self, card) then
      return self:modTargetFilter(to_select, selected, Self.id, card)
    end
  end,
  on_effect = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.to)
    if target.dead then return end
    target:drawCards(1, "wd_let_off_enemy")
    if player.dead or target.dead then return end
    local all_choices = {"dismantlement", "duel", "fire_attack", "Cancel"}
    local choices = {"duel"}
    if not target:isAllNude() then
      table.insert(choices, 1, "dismantlement")
    end
    if not target:isKongcheng() then
      table.insert(choices, "fire_attack")
    end
    for i = 1, 3, 1 do
      if player.dead or target.dead then return end
      if target:isAllNude() then
        table.removeOne(choices, "dismantlement")
      end
      if target:isKongcheng() then
        table.removeOne(choices, "fire_attack")
      end
      if i == 2 then
        table.insert(choices, "Cancel")
      end
      local choice = room:askForChoice(player, choices, "wd_let_off_enemy", "#wd_let_off_enemy-choice::"..target.id, false, all_choices)
      if choice == "Cancel" then break end
      table.removeOne(choices, choice)
      if choice ~= "fire_attack" then
        room:broadcastPlaySound("./packages/standard_cards/audio/card/"..(player.gender == General.Male and "male/" or "female/")..choice)
      else
        room:broadcastPlaySound("./packages/maneuvering/audio/card/"..(player.gender == General.Male and "male/" or "female/").."fire_attack")
      end
      room:doIndicate(player.id, {target.id})
      Fk:cloneCard(choice).skill:onEffect(room, effect)
    end
  end,
}
local wd__zongqin_trigger = fk.CreateTriggerSkill{
  name = "#wd__zongqin_trigger",
  main_skill = wd__zongqin,
  mute = true,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("wd__zongqin") and data.from == player.id and data.card.trueName == "wd_let_off_enemy"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local card = data.card:clone()
    local c = table.simpleClone(data.card)
    for k, v in pairs(c) do
      if card[k] == nil then
        card[k] = v
      end
    end
    card.skill = wd__zongqin__wdLetOffEnemySkill
    data.card = card
  end,
}
local wd__daibing = fk.CreateTriggerSkill{
  name = "wd__daibing",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.card.color == Card.Black and
      data.damageDealt
  end,
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askForChoice(player, {"wd__daibing1", "wd__daibing2", "Cancel"}, self.name)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local current = room.logic:getCurrentEvent()
    local use_event = current:findParent(GameEvent.UseCard)
    if not use_event then return end
    local phase_event = use_event:findParent(GameEvent.Phase)
    if not phase_event then return end
    use_event:addExitFunc(function()
      phase_event:shutdown()
    end)
    if self.cost_data == "wd__daibing1" then
      player:drawCards(1, self.name)
      player:gainAnExtraPhase(Player.Play, true)
    else
      player:gainAnExtraPhase(Player.Draw, true)
      player:skip(Player.Discard)
    end
  end,
}
Fk:addSkill(wd__zongqin__wdLetOffEnemySkill)
wd__zongqin:addRelatedSkill(wd__zongqin_trigger)
lvqian:addSkill(wd__zongqin)
lvqian:addSkill(wd__daibing)
Fk:loadTranslationTable{
  ["wd__lvqian"] = "吕虔",
  ["wd__zongqin"] = "纵擒",
  [":wd__zongqin"] = "出牌阶段限一次，你可以将一张♠牌当【欲擒故纵】使用。你使用【欲擒故纵】可以任意顺序执行全部三种牌的效果。",
  ["wd__daibing"] = "岱兵",
  [":wd__daibing"] = "当你于出牌阶段内使用黑色牌结算后，若此牌造成过伤害，你可以结束出牌阶段，然后选择一项：1.摸一张牌并执行一个额外的出牌阶段；"..
  "2.执行一个额外的摸牌阶段并跳过弃牌阶段。",

  ["wd__daibing1"] = "摸一张牌并执行一个额外的出牌阶段",
  ["wd__daibing2"] = "执行一个额外的摸牌阶段并跳过弃牌阶段",
}

Fk:loadTranslationTable{
  ["wd__shenying"] = "沈莹",
  ["wd__chizhen"] = "驰阵",
  [":wd__chizhen"] = "出牌阶段，你可以：1.横置一张装备牌；2.废除一个有横置装备牌的装备栏。然后你摸一张牌，视为使用【决斗】。你不能重置装备牌。",
}

local mizhu = General(extension, "wd__mizhu", "shu", 3)
local wd__juqi = fk.CreateActiveSkill{
  name = "wd__juqi",
  anim_type = "support",
  min_card_num = 1,
  target_num = 1,
  prompt = "#wd__juqi",
  can_use = function(self, player)
    return not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.TrueFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(effect.cards)
    room:moveCardTo(dummy, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
    if not player.dead then
      local dummy2 = Fk:cloneCard("dilu")
      dummy2:addSubcards(room:getNCards(#effect.cards))
      player:addToPile("wd__mizhu_silver", dummy2, false, self.name)
    end
  end,
}
local wd__juqi_trigger = fk.CreateTriggerSkill{
  name = "#wd__juqi_trigger",

  refresh_events = {fk.DamageInflicted},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill("wd__juqi")
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-wd__juqi|wd__juqi_viewas", nil, false, true)
    local e = room.logic:getCurrentEvent()
    if e ~= nil then
      e:addCleaner(function()
        room:handleAddLoseSkills(player, "wd__juqi|-wd__juqi_viewas", nil, false, true)
      end)
    end
  end,
}
local wd__juqi_viewas = fk.CreateViewAsSkill{
  name = "wd__juqi_viewas",
  anim_type = "defensive",
  pattern = "wd_gold",
  expand_pile = "wd__mizhu_silver",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "wd__mizhu_silver"
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("wd_gold")
    c.skillName = "wd__juqi"
    c:addSubcard(cards[1])
    return c
  end,
}
local wd__jiwei = fk.CreateTriggerSkill{
  name = "wd__jiwei",
  anim_type = "support",
  expand_pile = "wd__mizhu_silver",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Play and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, false, self.name, true,
      "wd_gold;.|.|.|wd__mizhu_silver", "#wd__jiwei-invoke::"..target.id, "wd__mizhu_silver")
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    room:moveCardTo(Fk:getCardById(self.cost_data), Card.DiscardPile, nil, fk.ReasonJustMove, self.name, nil, true, player.id)
    if not target.dead then
      target:drawCards(3, self.name)
    end
  end,
}
Fk:addSkill(wd__juqi_viewas)
wd__juqi:addRelatedSkill(wd__juqi_trigger)
mizhu:addSkill(wd__juqi)
mizhu:addSkill(wd__jiwei)
Fk:loadTranslationTable{
  ["wd__mizhu"] = "糜竺",
  ["wd__juqi"] = "居奇",
  [":wd__juqi"] = "出牌阶段限一次，你可以将任意张牌交给一名其他角色，然后将牌堆顶等量的牌置于武将牌上，称为“银”。你可以将“银”当【金】使用。",
  ["wd__jiwei"] = "济危",
  [":wd__jiwei"] = "一名角色出牌阶段开始时，你可以将一张【金】或“银”置入弃牌堆，令该角色摸三张牌。",
  ["#wd__juqi"] = "居奇：将任意张牌交给一名其他角色，将牌堆顶等量牌置为“银”",
  ["wd__mizhu_silver"] = "银",
  ["wd__juqi_viewas"] = "居奇",
  [":wd__juqi_viewas"] = "出牌阶段限一次，你可以将任意张牌交给一名其他角色，然后将牌堆顶等量的牌置于武将牌上，称为“银”。你可以将“银”当【金】使用。",
  ["#wd__jiwei-invoke"] = "济危：你可以将一张【金】或“银”置入弃牌堆，令 %dest 摸三张牌",
}

local sunguan = General(extension, "wd__sunguan", "wei", 4)
local wd__jimeng = fk.CreateTriggerSkill{
  name = "wd__jimeng",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.damageDealt
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@wd__jimeng-turn", 1)
    local n = player:usedSkillTimes(self.name, Player.HistoryTurn)
    player:drawCards(n, self.name)
    if n > player.hp then
      room:loseHp(player, 1, self.name)
    end
  end,
}
local wd__wangsi = fk.CreateTriggerSkill{
  name = "wd__wangsi",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.BeforeHpChanged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.hp <= -data.num
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@wd__wangsi-turn", -data.num)
    return true
  end,
}
local wd__wangsi_trigger = fk.CreateTriggerSkill{
  name = "#wd__wangsi_trigger",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:usedSkillTimes("wd__wangsi", Player.HistoryTurn) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("wd__wangsi")
    room:notifySkillInvoked(player, "wd__wangsi", "negative")
    room:loseHp(player, player:getMark("@wd__wangsi-turn"), "wd__wangsi")
  end,
}
wd__wangsi:addRelatedSkill(wd__wangsi_trigger)
sunguan:addSkill(wd__jimeng)
sunguan:addSkill(wd__wangsi)
Fk:loadTranslationTable{
  ["wd__sunguan"] = "孙观",
  ["wd__jimeng"] = "激猛",
  [":wd__jimeng"] = "锁定技，当你使用牌结算结束后，若此牌造成过伤害，你摸X张牌，然后若X大于你的体力值，你失去1点体力（X为你本回合发动〖激猛〗的次数）。",
  ["wd__wangsi"] = "忘死",
  [":wd__wangsi"] = "锁定技，当你不因此技能扣减体力前，若扣减值不小于你的体力值，防止之；此回合结束后，你失去等量的体力。",
  ["@wd__jimeng-turn"] = "激猛",
  ["@wd__wangsi-turn"] = "忘死",
}

Fk:loadTranslationTable{
  ["wd__zhoufang"] = "周鲂",
  ["wd__zhangmu"] = "障目",
  [":wd__zhangmu"] = "一名角色出牌阶段开始时，你可以弃置一张牌指定一名角色，直到回合结束：其非转化的基本牌无效；可以将两张牌当任意基本牌使用。",
  ["wd__duanfa"] = "断发",
  [":wd__duanfa"] = "①当你成为其他角色使用牌的目标后，若你的体力值大于1，你可以失去体力至1，令此牌对你无效。<br>"..
  "②当你受到非锦囊牌造成的伤害时，若你的体力值为1，防止此伤害。<br>"..
  "③当你受到锦囊牌造成的伤害时，若你的体力值为1且此牌目标数大于1，防止此伤害。",
}

return extension
