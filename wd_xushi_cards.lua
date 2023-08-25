-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("wd_xushi_cards", Package.CardPack)
Fk:loadTranslationTable{
  ["wd_xushi_cards"] = "玩点-虚实篇",
}

extension:addCards{
  Fk:cloneCard("slash", Card.Spade, 6),
  Fk:cloneCard("slash", Card.Diamond, 9),
}

local slash = Fk:cloneCard("slash")
local wdPoisonSlashSkill = fk.CreateActiveSkill{
  name = "wd_poison__slash_skill",
  max_phase_use_time = 1,
  target_num = 1,
  can_use = slash.skill.canUse,
  mod_target_filter = slash.skill.modTargetFilter,
  target_filter = slash.skill.targetFilter,
  on_effect = function(self, room, effect)
    local to = effect.to
    local from = effect.from
    room:damage({
      from = room:getPlayerById(from),
      to = room:getPlayerById(to),
      card = effect.card,
      damage = 1,
      damageType = 555,  --"fk.wdPoisonDamage"
      skillName = self.name
    })
  end
}
Fk:addSkill(wdPoisonSlashSkill)
local wdPoisonTrigger = fk.CreateTriggerSkill{
  name = "wd_poison_trigger",
  mute = true,
  global = true,
  priority = 0, -- game rule
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.damage and data.damage.damageType == 555
  end,
  on_trigger = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.wdPoison = true
  end,
}
local wdPoisonProhibit = fk.CreateProhibitSkill{
  name = "#wd_poison_prohibit",
  global = true,
  prohibit_use = function(self, player, card)
    if card and card.name == "peach" and player.dying then
      if RoomInstance and RoomInstance.logic:getCurrentEvent().event == GameEvent.Dying then
        local data = RoomInstance.logic:getCurrentEvent().data[1]
        return data and data.extra_data and data.extra_data.wdPoison
      end
    end
  end,
}
Fk:addSkill(wdPoisonTrigger)
Fk:addSkill(wdPoisonProhibit)
local wdPoisonSlash = fk.CreateBasicCard{
  name = "wd_poison__slash",
  skill = wdPoisonSlashSkill,
  is_damage_card = true,
}
extension:addCards{
  wdPoisonSlash:clone(Card.Spade, 9),
  wdPoisonSlash:clone(Card.Heart, 9),
  wdPoisonSlash:clone(Card.Club, 4),
  wdPoisonSlash:clone(Card.Club, 10),
}
Fk:loadTranslationTable{
  ["wd_poison__slash"] = "毒杀",
	[":wd_poison__slash"] = "基本牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：攻击范围内的一名角色<br/><b>效果</b>：对目标角色造成1点毒素伤害。"..
  "（一名角色受到毒素伤害而进入的濒死结算中，其不能使用【桃】）。",
}

extension:addCards{
  Fk:cloneCard("jink", Card.Heart, 6),
  Fk:cloneCard("jink", Card.Diamond, 3),
  Fk:cloneCard("jink", Card.Diamond, 11),

  Fk:cloneCard("peach", Card.Heart, 5),
  Fk:cloneCard("peach", Card.Heart, 7),
}

local wdRunTrigger = fk.CreateTriggerSkill{
  name = "wd_run_trigger",
  global = true,
  mute = true,
  priority = 0,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id).trueName == "wd_run" end)
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = ""
    if data.from then
      prompt = "#wd_run-use:"..data.from.."::"..data.card:toLogString()
    end
    local use = player.room:askForUseCard(player, "wd_run", nil, prompt, true, nil, data)
    if use then
      self.cost_data = use
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local use = self.cost_data
    player.room:useCard(use)
    if not table.contains(use.nullifiedTargets, player.id) then  --FIXME: 还有取消等情况！
      table.insertIfNeed(data.nullifiedTargets, player.id)
    end
  end,
}
local wdRunSkill = fk.CreateActiveSkill{
  name = "wd_run_skill",
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return true
  end,
  can_use = function()
    return false
  end,
  on_use = function(self, room, use)
    if not use.tos or #TargetGroup:getRealTargets(use.tos) == 0 then
      use.tos = { { use.from } }
    end
  end,
  on_effect = function(self, room, effect)
    local target = room:getPlayerById(effect.to)
    if not target.dead and not target:isKongcheng() then
      target:showCards(target:getCardIds("h"))
    end
    --[[local event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if event then
      local data = event.data[1]
      table.insertIfNeed(data.nullifiedTargets, target.id)
    end]]--FIXME: 正确插入了无效目标但未生效，why？
  end
}
local wd_run = fk.CreateBasicCard{
  name = "wd_run",
  skill = wdRunSkill,
}
Fk:addSkill(wdRunTrigger)
extension:addCards{
  wd_run:clone(Card.Spade, 3),
  wd_run:clone(Card.Heart, 3),
  wd_run:clone(Card.Club, 3),
  wd_run:clone(Card.Club, 6),
  wd_run:clone(Card.Diamond, 6),
}
Fk:loadTranslationTable{
  ["wd_run"] = "走",
  ["wd_run_skill"] = "走",
	[":wd_run"] = "基本牌<br/><b>时机</b>：成为【杀】或普通锦囊牌的目标后<br/><b>目标</b>：你<br/><b>效果</b>：目标角色展示所有手牌，"..
  "然后此【杀】或锦囊对目标角色无效。",
  ["#wd_run-use"] = "%src 对你使用%arg，你可以使用【走】令此牌对你无效",
}

local wdRiceTrigger = fk.CreateTriggerSkill{
  name = "wd_rice_trigger",
  global = true,
  mute = true,
  priority = 0,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Discard and
      table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id).trueName == "wd_rice" end)
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askForUseCard(player, "wd_rice", nil, "#wd_rice-use", true)
    if use then
      self.cost_data = use
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local use = self.cost_data
    player.room:useCard(use)
  end,
}
local wdRiceSkill = fk.CreateActiveSkill{
  name = "wd_rice_skill",
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return true
  end,
  can_use = function()
    return false
  end,
  on_use = function(self, room, use)
    if not use.tos or #TargetGroup:getRealTargets(use.tos) == 0 then
      use.tos = { { use.from } }
    end
  end,
  on_effect = function(self, room, effect)
    local target = room:getPlayerById(effect.to)
    if not target.dead then
      target:drawCards(1, self.name)
      room:addPlayerMark(target, MarkEnum.AddMaxCardsInTurn, 999)
    end
  end
}
local wd_rice = fk.CreateBasicCard{
  name = "wd_rice",
  skill = wdRiceSkill,
}
Fk:addSkill(wdRiceTrigger)
extension:addCards{
  wd_rice:clone(Card.Heart, 10),
  wd_rice:clone(Card.Diamond, 1),
  wd_rice:clone(Card.Diamond, 10),
}
Fk:loadTranslationTable{
  ["wd_rice"] = "粮",
  ["wd_rice_skill"] = "粮",
	[":wd_rice"] = "基本牌<br/><b>时机</b>：弃牌阶段开始时<br/><b>目标</b>：你<br/><b>效果</b>：目标角色摸一张牌，然后其此回合手牌上限无限。",
  ["#wd_rice-use"] = "你可以使用【粮】，摸一张牌且本回合手牌上限无限",
}

local wdGoldTrigger = fk.CreateTriggerSkill{
  name = "wd_gold_trigger",
  global = true,
  mute = true,
  priority = 0,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.from and data.from ~= player and not data.from.dead and
      table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id).trueName == "wd_gold" end)
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askForUseCard(player, "wd_gold", nil, "#wd_gold-use::"..data.from.id, true)
    if use then
      self.cost_data = use
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local use = self.cost_data
    use.tos = {{data.from.id}}
    player.room:useCard(use)
  end,
}
local wdGoldSkill = fk.CreateActiveSkill{
  name = "wd_gold_skill",
  can_use = function()
    return false
  end,
  on_effect = function(self, room, effect)
    local target = room:getPlayerById(effect.to)
    if target and not target.dead and not effect.card:isVirtual() or #effect.card.subcards > 0 then
      room:moveCards{
        ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        skillName = self.name,
        proposer = effect.from,
      }
    end
    local event = room.logic:getCurrentEvent():findParent(GameEvent.Damage)
    if event then
      event:shutdown()
    end
  end
}
local wd_gold = fk.CreateBasicCard{
  name = "wd_gold",
  skill = wdGoldSkill,
}
Fk:addSkill(wdGoldTrigger)
extension:addCards{
  wd_gold:clone(Card.Heart, 2),
  wd_gold:clone(Card.Diamond, 2),
}
Fk:loadTranslationTable{
  ["wd_gold"] = "金",
  ["wd_gold_skill"] = "金",
	[":wd_gold"] = "基本牌<br/><b>时机</b>：受到其他角色造成的伤害时<br/><b>目标</b>：伤害来源<br/><b>效果</b>：目标角色获得此牌，防止此伤害。",
  ["#wd_gold-use"] = "你可以使用【金】，令伤害来源 %dest 获得【金】，防止你受到的伤害",
}

extension:addCards{
  Fk:cloneCard("iron_chain", Card.Spade, 4),
}

--[[Fk:loadTranslationTable{
  ["wd_gold"] = "草船借箭",
  ["wd_gold_skill"] = "草船借箭",--♠K，♦K
	[":wd_gold"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名有手牌的其他角色<br/><b>效果</b>：目标选择一项：1.将至少一张【杀】交给你，"..
  "若其中有火【杀】，其对你造成1点火属性伤害；2.令你观看其手牌并弃置其中一张牌，若如此做，其手牌于此回合内对所有角色可见。",
}]]

local wdStopThirstSkill = fk.CreateActiveSkill{
  name = "wd_stop_thirst_skill",
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return true
  end,
  target_filter = function(self, to_select)
    return true
  end,
  on_effect = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.to)
    if target.dead then return end
    if table.every(room.alive_players, function(p) return p:getHandcardNum() >= target:getHandcardNum() end) then
      target:drawCards(2, self.name)
    end
    if not target.dead and target:isWounded() and table.every(room.alive_players, function(p) return p.hp >= target.hp end) then
      room:recover({
        who = target,
        num = 1,
        card = effect.card,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local wd_stop_thirst = fk.CreateTrickCard{
  name = "wd_stop_thirst",
  skill = wdStopThirstSkill,
}
extension:addCards{
  wd_stop_thirst:clone(Card.Club, 8),
  wd_stop_thirst:clone(Card.Club, 11),
}
Fk:loadTranslationTable{
  ["wd_stop_thirst"] = "望梅止渴",
  ["wd_stop_thirst_skill"] = "望梅止渴",
	[":wd_stop_thirst"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名角色<br/><b>效果</b>：若目标是手牌最少的角色，其摸两张牌；"..
  "然后若目标是体力值最小的角色，其回复1点体力。",
}

local wdLetOffEnemySkill = fk.CreateActiveSkill{
  name = "wd_let_off_enemy_skill",
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return user ~= to_select
  end,
  target_filter = function(self, to_select)
    return to_select ~= Self.id
  end,
  on_effect = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.to)
    if target.dead then return end
    target:drawCards(1, self.name)
    if player.dead or target.dead then return end
    local choices = {"duel"}
    if not target:isAllNude() then
      table.insert(choices, 1, "dismantlement")
    end
    if not target:isKongcheng() then
      table.insert(choices, "fire_attack")
    end
    local choice = room:askForChoice(player, choices, self.name, "#wd_let_off_enemy-choice::"..target.id)
    if choice ~= "fire_attack" then
      room:broadcastPlaySound("./packages/standard_cards/audio/card/".. (player.gender == General.Male and "male/" or "female/") .. choice)
    else
      room:broadcastPlaySound("./packages/maneuvering/audio/card/".. (player.gender == General.Male and "male/" or "female/") .. "fire_attack")
    end
    room:doIndicate(player.id, {target.id})
    Fk:cloneCard(choice).skill:onEffect(room, effect)
  end,
}
local wd_let_off_enemy = fk.CreateTrickCard{
  name = "wd_let_off_enemy",
  skill = wdLetOffEnemySkill,
  is_damage_card = true,
}
extension:addCards{
  wd_let_off_enemy:clone(Card.Spade, 8),
  wd_let_off_enemy:clone(Card.Heart, 8),
  wd_let_off_enemy:clone(Card.Diamond, 7),
  wd_let_off_enemy:clone(Card.Diamond, 8),
}
Fk:loadTranslationTable{
  ["wd_let_off_enemy"] = "欲擒故纵",
  ["wd_let_off_enemy_skill"] = "欲擒故纵",
	[":wd_let_off_enemy"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br/><b>效果</b>：目标角色摸一张牌，然后你对其执行"..
  "下列一种牌的效果：【过河拆桥】、【决斗】、【火攻】。",
  ["#wd_let_off_enemy-choice"] = "欲擒故纵：选择对 %dest 执行一种牌的效果",
}

local wdLureInDeepTrigger = fk.CreateTriggerSkill{
  name = "wd_lure_in_deep_trigger",
  global = true,
  mute = true,
  priority = 0,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return data.card.trueName == "slash" and data.to == player.id and
      not (data.unoffsetable or table.contains(data.unoffsetableList or {}, data.to)) and
      table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id).trueName == "wd_lure_in_deep" end)
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = ""
    if data.from then
      prompt = "#wd_lure_in_deep-use:"..data.from.."::"..data.card:toLogString()
    end
    local use = player.room:askForUseCard(player, "wd_lure_in_deep", nil, prompt, true, nil, data)
    if use then
      self.cost_data = use
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local use = self.cost_data
    use.toCard = data.card
    use.responseToEvent = data
    player.room:useCard(use)
    if use.responseToEvent.isCancellOut then
      return true
    end
  end,
}
local wdLureInDeepSkill = fk.CreateActiveSkill{
  name = "wd_lure_in_deep_skill",
  can_use = function()
    return false
  end,
  on_effect = function(self, room, effect)
    if effect.responseToEvent then
      effect.responseToEvent.isCancellOut = true
      local player = room:getPlayerById(effect.from)
      local from = room:getPlayerById(effect.responseToEvent.from)
      if not from or from.dead then return end
      local yes = true
      while not player.dead and not from.dead do
        local use = room:askForUseCard(from, "slash", "slash", "#wd_lure_in_deep-slash:"..player.id, true,
          {must_targets = {player.id}, exclusive_targets = {player.id}, bypass_times = true})
        if use then
          room:useCard(use)
          if use.damageDealt and use.damageDealt[player.id] then
            yes = false
          end
        else
          break
        end
      end
      if yes and not from.dead then
        room:doIndicate(player.id, {from.id})
        room:damage{
          from = player,
          to = from,
          card = effect.card,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end
}
local wd_lure_in_deep = fk.CreateTrickCard{
  name = "wd_lure_in_deep",
  skill = wdLureInDeepSkill,
  is_damage_card = true,
}
Fk:addSkill(wdLureInDeepTrigger)
extension:addCards{
  wd_lure_in_deep:clone(Card.Spade, 11),
  wd_lure_in_deep:clone(Card.Spade, 12),
  wd_lure_in_deep:clone(Card.Club, 9),
}
Fk:loadTranslationTable{
  ["wd_lure_in_deep"] = "诱敌深入",
  ["wd_lure_in_deep_skill"] = "诱敌深入",
	[":wd_lure_in_deep"] = "锦囊牌<br/><b>时机</b>：当【杀】对你生效前<br/><b>目标</b>：此【杀】<br/><b>效果</b>：抵消此【杀】对你产生的效果，"..
  "然后此【杀】使用者需重复对你使用【杀】直到以此法使用的【杀】对你造成伤害，否则你对其造成1点伤害。",
  ["#wd_lure_in_deep-use"] = "%src 对你使用%arg，你可以使用【诱敌深入】",
  ["#wd_lure_in_deep-slash"] = "诱敌深入：请继续对 %src 使用【杀】直到对其造成伤害，否则其对你造成1点伤害",
}

--[[Fk:loadTranslationTable{
  ["wd_gold"] = "调兵遣将",
  ["wd_gold_skill"] = "调兵遣将",--♥4，♦4
	[":wd_gold"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：所有角色<br/><b>效果</b>：亮出牌堆顶的X张牌（X为角色数的一半，向下取整）。"..
  "目标角色依次可以用一张手牌替换其中一张牌。结算结束时，你将其中任意张牌以任意顺序置于牌堆顶。",
}]]

local wdDrowningSkill = fk.CreateActiveSkill{
  name = "wd_drowning_skill",
  can_use = Util.AoeCanUse,
  on_use = Util.AoeOnUse,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return user ~= to_select
  end,
  on_effect = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.to)
    if not (effect.extra_data and effect.extra_data.wdDrowning) or target.dead then return end
    if target:hasSkill("#vine_skill") then
      local skill = Fk.skills["#vine_skill"]
      skill:use(fk.PreCardEffect, target, target, effect)
    else
      if target:isNude() then
        room:damage({
          from = player,
          to = target,
          damage = 1,
          card = effect.card,
          skillName = self.name,
        })
      else
        local card = room:askForDiscard(target, 1, 1, true, self.name, true, ".|.|.|.|.|"..effect.extra_data.wdDrowning,
          "#wd_drowning-discard:::"..effect.extra_data.wdDrowning)
        if #card == 0 then
          room:damage({
            from = player,
            to = target,
            damage = 1,
            card = effect.card,
            skillName = self.name,
          })
        end
      end
    end
  end
}
local wdDrowningAction = fk.CreateTriggerSkill{
  name = "wd_drowning_action",
  global = true,
  priority = 0,
  events = {fk.BeforeCardUseEffect},
  can_trigger = function(self, event, target, player, data)
    return data.card.trueName == 'wd_drowning' and (not data.extra_data or not data.extra_data.wdDrowning)
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    if not from.dead and not from:isKongcheng() then
      local card = room:askForCard(from, 1, 1, false, "wd_drowning", false, ".", "#wd_drowning-show:::"..data.card:toLogString())
      data.extra_data = data.extra_data or {}
      data.extra_data.wdDrowning = Fk:getCardById(card[1]):getTypeString()
      from:showCards(card)
    end
  end,
}
Fk:addSkill(wdDrowningAction)
local wdDrowning = fk.CreateTrickCard{
  name = "wd_drowning",
  is_damage_card = true,
  multiple_targets = true,
  skill = wdDrowningSkill,
}
extension:addCards({
  wdDrowning:clone(Card.Spade, 1),
  wdDrowning:clone(Card.Club, 1),
  wdDrowning:clone(Card.Club, 7),
})
Fk:loadTranslationTable{
  ["wd_drowning"] = "水淹七军",
  ["wd_drowning_skill"] = "水淹七军",
	[":wd_drowning"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：所有其他角色<br/><b>效果</b>：你展示一张手牌，目标角色依次选择一项："..
  "1.弃置一张与展示牌类别相同的牌；2.你对其造成1点伤害。",
  ["#wd_drowning-show"] = "请为%arg展示一张手牌",
  ["#wd_drowning-discard"] = "水淹七军：弃置一张%arg，否则受到1点伤害",
}

local wdSaveEnergySkill = fk.CreateActiveSkill{
  name = "wd_save_energy_skill",
  target_num = 1,
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      local player = Fk:currentRoom():getPlayerById(to_select)
      if Self ~= player then
        return not player:hasDelayedTrick("wd_save_energy")
      end
    end
    return false
  end,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    local judge = {
      who = to,
      reason = "wd_save_energy",
      pattern = ".|.|spade,heart,club",
    }
    room:judge(judge)
    local result = judge.card
    if result.suit ~= Card.Diamond then
      to:skip(Player.Discard)
      if not effect.card:isVirtual() or #effect.card.subcards > 0 then
        if effect.card:isVirtual() then
          to:addVirtualEquip(effect.card)
        end
        room:moveCards{
          ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
          to = to.id,
          toArea = Card.PlayerJudge,
          moveReason = fk.ReasonUse
        }
      end
    else
      self:onNullified(room, effect)
    end
  end,
  on_nullified = function(self, room, effect)
    room:moveCards{
      ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonUse
    }
  end,
}
local wd_save_energy = fk.CreateDelayedTrickCard{
  name = "wd_save_energy",
  suit = Card.Heart,
  number = 11,
  skill = wdSaveEnergySkill,
}
extension:addCards({
  wd_save_energy,
})
Fk:loadTranslationTable{
  ["wd_save_energy"] = "养精蓄锐",
  ["wd_save_energy_skill"] = "养精蓄锐",
	[":wd_save_energy"] = "延时锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br/><b>效果</b>：将此牌置于目标角色判定区内。"..
  "其判定阶段进行判定：若结果不为<font color='red'>♦</font>，其跳过弃牌阶段，将此牌置于其判定区。",
}

local wdSevenStarsSwordSkill = fk.CreateTriggerSkill{
  name = "#wd_seven_stars_sword_skill",
  attached_equip = "wd_seven_stars_sword",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.card.trueName == "slash" then
      if event == fk.TargetSpecified then
        return data.firstTarget
      else
        return (not data.damageDealt or table.find(TargetGroup:getRealTargets(data.tos), function(id)
          return not data.damageDealt[id] and not player.room:getPlayerById(id).dead end)) and
          player:getEquipment(Card.SubtypeWeapon) ~= nil and
          Fk:getCardById(player:getEquipment(Card.SubtypeWeapon)).name == "wd_seven_stars_sword"
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.TargetSpecified then
      data.fixedResponseTimes = data.fixedResponseTimes or {}
      data.fixedResponseTimes["jink"] = data.fixedResponseTimes["jink"] or 1
      data.fixedResponseTimes["jink"] = data.fixedResponseTimes["jink"] + 1
    else
      local room = player.room
      for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
        local p = room:getPlayerById(id)
        if (not data.damageDealt or not data.damageDealt[id]) and not p.dead and player:getEquipment(Card.SubtypeWeapon) then
          room:obtainCard(p, player:getEquipment(Card.SubtypeWeapon), true, fk.ReasonPrey)
          break
        end
      end
    end
  end,
}
Fk:addSkill(wdSevenStarsSwordSkill)
local wdSevenStarsSword = fk.CreateWeapon{
  name = "wd_seven_stars_sword",
  suit = Card.Spade,
  number = 7,
  attack_range = 2,
  equip_skill = wdSevenStarsSwordSkill,
}
extension:addCard(wdSevenStarsSword)
Fk:loadTranslationTable{
  ["wd_seven_stars_sword"] = "七星刀",
  ["#wd_seven_stars_sword_skill"] = "七星刀",
  [":wd_seven_stars_sword"] = "装备牌·武器<br/><b>攻击范围</b>：2<br/><b>武器技能</b>：锁定技，当你使用【杀】指定目标后，目标抵消此【杀】需"..
  "额外使用一张【闪】；你使用【杀】结算后，若此【杀】未对目标角色造成过伤害，其获得你装备区内的【七星刀】。",
}

local wdSunMoonHalberdSkill = fk.CreateTriggerSkill{
  name = "#wd_sun_moon_halberd_skill",
  attached_equip = "wd_sun_moon_halberd",
  anim_type = "offensive",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not player:isProhibited(p, data.card) then
        table.insertIfNeed(targets, p.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#wd_sun_moon_halberd-invoke:::"..data.card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    TargetGroup:pushTargets(data.targetGroup, self.cost_data)
    if player:getEquipment(Card.SubtypeWeapon) and Fk:getCardById(player:getEquipment(Card.SubtypeWeapon)).name == "wd_sun_moon_halberd" then
      room:throwCard({player:getEquipment(Card.SubtypeWeapon)}, self.name, player, player)
    end
  end,
}
local wdSunMoonHalberdTrigger = fk.CreateTriggerSkill{
  name = "wd_sun_moon_halberd_trigger",
  mute = true,
  global = true,
  priority = 0, -- game rule
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if table.find(player:getCardIds("he"), function(id) return Fk:getCardById(id).name == "wd_sun_moon_halberd" end) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).name == "wd_sun_moon_halberd" and
              (info.fromArea ~= Card.PlayerEquip or move.moveReason ~= fk.ReasonPutIntoDiscardPile) then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).name == "wd_sun_moon_halberd" and
            (info.fromArea ~= Card.PlayerEquip or move.moveReason ~= fk.ReasonPutIntoDiscardPile) then
            local room = player.room
            if room:getCardArea(info.cardId) == Card.DiscardPile then
              room:delay(1500)
              room:obtainCard(player, info.cardId, true, fk.ReasonPrey)
              return
            end
          end
        end
      end
    end
  end,
}
Fk:addSkill(wdSunMoonHalberdSkill)
Fk:addSkill(wdSunMoonHalberdTrigger)
local wd_sun_moon_halberd = fk.CreateWeapon{
  name = "wd_sun_moon_halberd",
  attack_range = 2,
  equip_skill = wdSunMoonHalberdSkill,
}
extension:addCards{
  wd_sun_moon_halberd:clone(Card.Club, 12),
  wd_sun_moon_halberd:clone(Card.Heart, 13),
}
Fk:loadTranslationTable{
  ["wd_sun_moon_halberd"] = "日月戟",
  ["#wd_sun_moon_halberd_skill"] = "日月戟",
  [":wd_sun_moon_halberd"] = "装备牌·武器<br/><b>攻击范围</b>：2<br/><b>武器技能</b>：当你使用【杀】指定目标时，你可以增加一个目标"..
  "（无距离限制且可重复），然后你弃置装备区里的【日月戟】。每回合限一次，当【日月戟】不因替换进入弃牌堆后，区域内有【日月戟】的角色获得之。",
  ["#wd_sun_moon_halberd-invoke"] = "日月戟：你可以为此%arg增加一个目标（无距离限制且可重复）",
}

local wdBreastplateSkill = fk.CreateTriggerSkill{
  name = "#wd_breastplate_skill",
  attached_equip = "wd_breastplate",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player:getEquipment(Card.SubtypeArmor) ~= nil and Fk:getCardById(player:getEquipment(Card.SubtypeArmor)).name == "wd_breastplate" and
      not player:prohibitDiscard(Fk:getCardById(player:getEquipment(Card.SubtypeArmor)))
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wd_breastplate_skill-invoke")
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard({player:getEquipment(Card.SubtypeArmor)}, self.name, player, player)
    return true
  end,
}
Fk:addSkill(wdBreastplateSkill)
local wd_breastplate = fk.CreateArmor{
  name = "wd_breastplate",
  suit = Card.Club,
  number = 1,
  equip_skill = wdBreastplateSkill,
  on_uninstall = function(self, room, player)
    if not player.dead and self.equip_skill:isEffectable(player) then
      player:drawCards(1, self.name)
    end
  end,
}
extension:addCard(wd_breastplate)
Fk:loadTranslationTable{
  ["wd_breastplate"] = "护心镜",
  ["#wd_breastplate_skill"] = "护心镜",
  [":wd_breastplate"] = "装备牌·防具<br/><b>防具技能</b>：当你受到伤害时，你可以弃置装备区里的【护心镜】，然后防止此伤害；"..
  "锁定技，当你失去装备区里的【护心镜】时，你摸一张牌。",
  ["#wd_breastplate_skill-invoke"] = "护心镜：你可以弃置装备区内的【护心镜】，防止你受到的伤害",
}

local wdBaiHu = fk.CreateDefensiveRide{
  name = "wd_baihu",
  suit = Card.Diamond,
  number = 5,
}
extension:addCards({
  wdBaiHu,
})
Fk:loadTranslationTable{
  ["wd_baihu"] = "白鹄",
  [":wd_baihu"] = "装备牌·坐骑<br/><b>坐骑技能</b>：锁定技，其他角色至你的距离+1。",
}

local wdCrossbowTankSkill = fk.CreateTargetModSkill{
  name = "#wd_crossbow_tank_skill",
  residue_func = function(self, player, skill, scope, card)
    if card and player:hasSkill(self.name) and card.trueName == "slash" and scope == Player.HistoryPhase then
      return 1
    end
  end,
}
Fk:addSkill(wdCrossbowTankSkill)
local wdCrossbowTank = fk.CreateOffensiveRide{
  name = "wd_crossbow_tank",
  suit = Card.Spade,
  number = 10,
  equip_skill = wdCrossbowTankSkill,
}
extension:addCards({
  wdCrossbowTank,
})
Fk:loadTranslationTable{
  ["wd_crossbow_tank"] = "连弩战车",
  [":wd_crossbow_tank"] = "装备牌·坐骑<br/><b>坐骑技能</b>：锁定技，你至其他角色的距离-1；出牌阶段，你使用【杀】次数上限+1。",
}

return extension
