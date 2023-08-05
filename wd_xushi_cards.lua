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
    if card.name == "peach" and player.dying then
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

Fk:loadTranslationTable{
  ["wd_run"] = "走",
  ["wd_run_skill"] = "走",--♠3，♣3，♣6，♥3，♦6
	[":wd_run"] = "基本牌<br/><b>时机</b>：成为【杀】或普通锦囊牌的目标后<br/><b>目标</b>：你<br/><b>效果</b>：目标角色展示所有手牌，"..
  "然后此牌对目标角色无效。",
}

Fk:loadTranslationTable{
  ["wd_rice"] = "粮",
  ["wd_rice_skill"] = "粮",--♥10，♦A，♦10
	[":wd_rice"] = "基本牌<br/><b>时机</b>：弃牌阶段开始时<br/><b>目标</b>：你<br/><b>效果</b>：目标角色摸一张牌，然后其此回合手牌上限无限。",
}

Fk:loadTranslationTable{
  ["wd_gold"] = "金",
  ["wd_gold_skill"] = "金",--♥2，♦2
	[":wd_gold"] = "基本牌<br/><b>时机</b>：受到其他角色造成的伤害时<br/><b>目标</b>：伤害来源<br/><b>效果</b>：目标角色获得此牌，防止此伤害。",
}

Fk:loadTranslationTable{
  ["wd_gold"] = "草船借箭",
  ["wd_gold_skill"] = "草船借箭",--♠K，♦K
	[":wd_gold"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名有手牌的其他角色<br/><b>效果</b>：目标选择一项：1.将至少一张【杀】交给你，"..
  "若其中有火【杀】，其对你造成1点火属性伤害；2.令你观看其手牌并弃置其中一张牌，若如此做，其手牌于此回合内对所有角色可见。",
}

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

local wdLeOffEnemySkill = fk.CreateActiveSkill{
  name = "wd_let_off_enemy_skill",
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return to_select ~= Self.id
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
    local cardEffectEvent = effect
    cardEffectEvent.card = Fk:cloneCard(choice)
    cardEffectEvent.card.skill:onEffect(room, cardEffectEvent)
  end,
}
local wd_let_off_enemy = fk.CreateTrickCard{
  name = "wd_let_off_enemy",
  skill = wdLeOffEnemySkill,
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

Fk:loadTranslationTable{
  ["wd_gold"] = "诱敌深入",
  ["wd_gold_skill"] = "诱敌深入",--♠J，♠Q，♣9
	[":wd_gold"] = "锦囊牌<br/><b>时机</b>：成为其他角色使用【杀】的目标后<br/><b>目标</b>：此【杀】<br/><b>效果</b>：抵消此【杀】对你产生的效果，"..
  "然后目标需重复对你使用【杀】直到以此法使用的【杀】对你造成伤害，否则你对其造成1点伤害。",
}

Fk:loadTranslationTable{
  ["wd_gold"] = "调兵遣将",
  ["wd_gold_skill"] = "调兵遣将",--♥4，♦4
	[":wd_gold"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：所有角色<br/><b>效果</b>：亮出牌堆顶的X张牌（X为角色数的一半，向下取整）。"..
  "目标角色依次可以用一张手牌替换其中一张牌。结算结束时，你将其中任意张牌以任意顺序置于牌堆顶。",
}

Fk:loadTranslationTable{
  ["wd_gold"] = "水淹七军",
  ["wd_gold_skill"] = "水淹七军",--♠A，♣A，♣7
	[":wd_gold"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：所有其他角色<br/><b>效果</b>：你展示一张手牌，目标角色依次选择一项："..
  "1.弃置一张与此牌类别相同的牌；2.你对其造成1点伤害。",
}

extension:addCards{
  Fk:cloneCard("iron_chain", Card.Spade, 4),
}

return extension
