local extension = Package("wd_junxing")
extension.extensionName = "wandianlunsha"

Fk:loadTranslationTable{
  ["wd_junxing"] = "玩点-军形篇",
}

local chengji = General(extension, "wd__chengji", "shu", 3)
local wd__zudi = fk.CreateTriggerSkill{
  name = "wd__zudi",
  anim_type = "defensive",
  events = {fk.EventPhaseStart, fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Start
      else
        return data.card.trueName == "slash" and target:getMark("@@wd__zudi") ~= 0 and table.contains(target:getMark("@@wd__zudi"), player.id)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
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
    if event == fk.EventPhaseStart then
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
      if player:isNude() then
        room:loseHp(player, 1, self.name)
      else
        if #room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#wd__zudi-discard") == 0 then
          room:loseHp(player, 1, self.name)
        end
      end
      AimGroup:cancelTarget(data, target.id)
      if not player.dead and data.from and not room:getPlayerById(data.from).dead and data.from ~= player.id then
        room:useVirtualCard("duel", nil, player, room:getPlayerById(data.from), self.name)
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
  card_filter = function(self, to_select, player)
    return player:hasSkill(self) and to_select.type == Card.TypeBasic and
      not table.contains({"slash", "peach", "analeptic"}, to_select.trueName)
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
}
chengji:addSkill(wd__zudi)
chengji:addSkill(wd__juesi)
Fk:loadTranslationTable{
  ["wd__chengji"] = "程畿",
  ["wd__zudi"] = "阻敌",
  [":wd__zudi"] = "准备阶段，你可以选择一名其他角色。直到你下回合开始，当你或该角色成为【杀】的目标时，你可以弃置一张牌或失去1点体力，"..
  "取消所有目标，然后视为对此【杀】的使用者使用【决斗】。",
  ["wd__juesi"] = "决死",
  [":wd__juesi"] = "锁定技，你除【杀】、【桃】、【酒】以外的基本牌均视为【杀】。",
  ["@@wd__zudi"] = "阻敌",
  ["#wd__zudi-choose"] = "阻敌：选择一名角色，当你或其成为【杀】的目标时，你可以弃置一张牌或失去1点体力取消之，然后视为对使用者使用【决斗】",
  ["#wd__zudi-invoke"] = "阻敌：你可以弃置一张牌或失去1点体力，取消对 %src 使用的【杀】，并视为对 %arg 使用【决斗】",
  ["#wd__zudi2-invoke"] = "阻敌：你可以弃置一张牌或失去1点体力，取消对 %src 使用的【杀】",
  ["#wd__zudi-discard"] = "阻敌：你需弃置一张牌，否则失去1点体力",
}

local fanyufeng = General(extension, "wd__fanyufeng", "qun", 3, 3, General.Female)
local wd__diewu = fk.CreateActiveSkill{
  name = "wd__diewu",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
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
    room:obtainCard(target, Fk:getCardById(effect.cards[1]), false, fk.ReasonGive)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) == 1 then
      player:drawCards(1, self.name)
    end
  end,
}
local wd__muyun = fk.CreateTriggerSkill{
  name = "wd__muyun",
  anim_type = "support",
  events = {fk.AfterCardUseDeclared, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.name == "jink" and target.phase == Player.NotActive
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wd__muyun-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    target:drawCards(1, self.name)
  end,
}
fanyufeng:addSkill(wd__diewu)
fanyufeng:addSkill(wd__muyun)
Fk:loadTranslationTable{
  ["wd__fanyufeng"] = "樊氏",
  ["wd__diewu"] = "蝶舞",
  [":wd__diewu"] = "出牌阶段，你可以将一张【杀】交给一名其他角色，若你于此阶段内首次如此做，你摸一张牌。",
  ["wd__muyun"] = "慕云",
  [":wd__muyun"] = "当一名角色于其回合外使用或打出【闪】时，你可以其摸一张牌。",
  ["#wd__muyun-invoke"] = "慕云：你可以令 %dest 摸一张牌",
}

local furongfuqian = General(extension, "wd__furongfuqian", "shu", 4)
local wd__fenkai = fk.CreateTriggerSkill{
  name = "wd__fenkai",
  mute = true,
  events = {fk.CardEffectCancelledOut, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.card and data.card.trueName == "slash" then
      if event == fk.CardEffectCancelledOut then
        return data.from == player.id
      else
        if player:usedSkillTimes("wd__chengming", Player.HistoryGame) == 0 then
          return target == player or player:inMyAttackRange(target)
        else
          return player:distanceTo(target) < 2
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player:usedSkillTimes("wd__chengming", Player.HistoryGame) == 0 then
      local prompt
      if event == fk.CardEffectCancelledOut then
        prompt = "#wd__fenkai1-invoke::"..data.to
      else
        prompt = "#wd__fenkai2-invoke::"..target.id
      end
      return player.room:askForSkillInvoke(player, self.name, nil, prompt)
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardEffectCancelledOut then
      room:notifySkillInvoked(player, self.name, "offensive")
    else
      room:notifySkillInvoked(player, self.name, "defensive")
    end
    room:loseHp(player, 1, self.name)
    return true
  end,
}
local wd__chengming = fk.CreateTriggerSkill{
  name = "wd__chengming",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    if not player.faceup then
      player:turnOver()
    end
    if player.chained then
      player:setChainState(false)
    end
    player.room:recover({
      who = player,
      num = 2 - player.hp,
      recoverBy = player,
      skillName = self.name
    })
    player:drawCards(2, self.name)
  end,
}
furongfuqian:addSkill(wd__fenkai)
furongfuqian:addSkill(wd__chengming)
Fk:loadTranslationTable{
  ["wd__furongfuqian"] = "傅肜傅佥",
  ["wd__fenkai"] = "奋慨",
  [":wd__fenkai"] = "当你使用的【杀】被抵消时，你可以失去1点体力令此【杀】依然生效。当你或你攻击范围内的角色受到【杀】的伤害时，你可以失去1点体力防止此伤害。",
  ["wd__chengming"] = "承命",
  [":wd__chengming"] = "限定技，当你处于濒死状态时，你可以将武将牌恢复至初始状态，回复体力至2点并摸两张牌，然后将〖奋慨〗改为锁定技，"..
  "“攻击范围内”改成“距离不大于1”。",
  ["#wd__fenkai1-invoke"] = "奋慨：你可以失去1点体力，令对 %dest 使用的【杀】依然生效",
  ["#wd__fenkai2-invoke"] = "奋慨：你可以失去1点体力，防止 %dest 受到的伤害",
}

Fk:loadTranslationTable{
  ["wd__guanqiujian"] = "毌丘俭",
  ["wd__saotao"] = "扫讨",
  [":wd__saotao"] = "锁定技，①你使用的【杀】/非延时类锦囊牌不能被【闪】/【无懈可击】响应。<br>②其他角色成为你使用【杀】/非延时类锦囊牌的目标后，"..
  "可以将一张【闪】/【无懈可击】当【走】使用。",
  ["wd__shizhao"] = "示诏",
  [":wd__shizhao"] = "觉醒技，准备阶段开始时，若你的体力值小于3，你回复1点体力并摸两张牌，然后将一张牌置于武将牌上，称为“诏”，然后获得技能〖鸿举〗。 ",
  ["wd__hongju"] = "鸿举",
  [":wd__hongju"] = "当一名角色展示与“诏”花色不同的牌后，你可以对该角色造成1点伤害。 ",
}

Fk:loadTranslationTable{
  ["wd__heqi"] = "贺齐",
  ["wd__taopan"] = "讨叛",
  [":wd__taopan"] = "出牌阶段开始时，你可以将一张装备牌置入你的装备区，视为使用计入次数限制的【杀】；若你装备区内的红色牌多于黑色牌，此【杀】无视防具，"..
  "否则此【杀】无距离限制。",
  ["wd__yingyuan"] = "应援",
  [":wd__yingyuan"] = "其他角色的结束阶段，你可以获得装备区内的一张非坐骑牌，令该角色摸一张牌。",
}

Fk:loadTranslationTable{
  ["wd__kebineng"] = "轲比能",
  ["wd__yuqi"] = "驭骑",
  [":wd__yuqi"] = "你的回合内，你可以将一名角色装备区内的坐骑牌当【酒】使用；你的回合外，你可以将你的一张坐骑牌当【桃】使用。",
  ["wd__diqiu"] = "狄酋",
  [":wd__diqiu"] = "出牌阶段内限一次，当你于出牌阶段内使用牌指定目标后，若你此阶段使用的牌点数之和大于13，你可以弃置每个目标各一张牌；"..
  "若你以此法弃置的牌不少于三张，你获得“敌酋”标记。当你受到伤害时，若有“敌酋”，此伤害+1。",
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
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      local targets = table.map(room.alive_players, function(p) return p.id end)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#wd__shehuang-choose::"..target.id, self.name, false)
      if #to > 0 then
        to = room:getPlayerById(to[1])
      else
        to = room:getPlayerById(table.random(targets))
      end
      room:setPlayerMark(to, "@@wd__shehuang-turn", 1)
    end
  end
}
local wd__shehuang_trigger = fk.CreateTriggerSkill{
  name = "#wd__shehuang_trigger",
  mute = true,
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase ~= Player.NotActive and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      table.find(player.room.alive_players, function(p)
        return p:getMark("@@wd__shehuang-turn") > 0 and not table.contains(AimGroup:getAllTargets(data.tos), p.id) end)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@@wd__shehuang-turn") > 0 and not table.contains(AimGroup:getAllTargets(data.tos), p.id) and
        not player:isProhibited(p, data.card) then
        if p == player then
          if data.card.skill:targetFilter(player.id, {}, {}, data.card) then
            TargetGroup:pushTargets(data.targetGroup, p.id)
          end
        else
          room:doIndicate(player.id, {p.id})
          TargetGroup:pushTargets(data.targetGroup, p.id)
        end
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
    return player:hasSkill(self) and target ~= player and target.phase == Player.Finish and
      target:getMark("wd__pingman-turn") ~= 0 and #target:getMark("wd__pingman-turn") > player.hp
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("wd__pingman-turn")
    if mark == 0 then mark = {} end
    for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
      table.insertIfNeed(mark, id)
    end
    player.room:setPlayerMark(player, "wd__pingman-turn", mark)
  end,
}
wd__shehuang:addRelatedSkill(wd__shehuang_trigger)
lihui:addSkill(wd__shehuang)
lihui:addSkill(wd__pingman)
Fk:loadTranslationTable{
  ["wd__lihui"] = "李恢",
  ["wd__shehuang"] = "舌簧",
  [":wd__shehuang"] = "其他角色出牌阶段开始时，你可以与其拼点：若你赢，你选择一名角色，此回合内当前回合角色每次使用牌均选择该角色为额外目标。",
  ["wd__pingman"] = "平蛮",
  [":wd__pingman"] = "锁定技，其他角色的结束阶段开始时，若于此回合内被该角色选择过为其使用牌的目标的角色数量大于你的体力值，你摸一张牌。",
  ["#wd__shehuang-invoke"] = "舌簧：你可以与 %dest 拼点，若赢，你指定一名角色为其本回合使用牌的额外目标",
  ["#wd__shehuang-choose"] = "舌簧：选择一名角色， %dest 本回合使用牌均额外指定该角色为目标",
  ["@@wd__shehuang-turn"] = "舌簧",
}

Fk:loadTranslationTable{
  ["wd__liangxi"] = "梁习",
  ["wd__yuzhi"] = "预植",
  [":wd__yuzhi"] = "锁定技，游戏开始时，你将牌堆顶的两张牌扣置于武将牌上，称为“植”；你能如手牌般使用或打出“植”。<br>"..
  "摸牌阶段，你放弃摸牌，改为获得所有“植”，然后将牌堆顶的两张牌作为“植” 。",
  ["wd__junlong"] = "峻隆",
  [":wd__junlong"] = "当你受到1点伤害后，或当一张“植”于你的回合外移入游戏后，你可以将当前回合角色的两张牌置于其武将牌旁，称为“质”。<br>"..
  "回合结束时，有“质”的角色需选择一项：1.获得所有“质”，然后你对其造成1点伤害；2.将所有“质”交给你，然后其回复1点体力。",
}

local lukai = General(extension, "wd__lukai", "wu", 3)
local wd__kenjian = fk.CreateActiveSkill{
  name = "wd__kenjian",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choices = {"wd__kenjian_draw"}
    if not target:isKongcheng() then
      table.insert(choices, "wd__kenjian_discard")
    end
    local choice = room:askForChoice(player, choices, self.name, "#wd__kenjian-choice::"..target.id)
    if choice == "wd__kenjian_draw" then
      target:drawCards(1, self.name)
    else
      room:askForDiscard(target, 1, 1, false, self.name, false)
    end
  end,
}
local wd__yijian = fk.CreateTriggerSkill{
  name = "wd__yijian",
  anim_type = "support",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, "#wd__yijian-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player.room:getPlayerById(self.cost_data), "wd__kenjian|wd__yijian", nil, true, false)
  end,
}
lukai:addSkill(wd__kenjian)
lukai:addSkill(wd__yijian)
Fk:loadTranslationTable{
  ["wd__lukai"] = "陆凯",
  ["wd__kenjian"] = "恳谏",
  [":wd__kenjian"] = "出牌阶段限一次，你可以选择一名其他角色并选择一项：1.其摸一张牌；2.其弃置一张手牌。",
  ["wd__yijian"] = "遗荐",
  [":wd__yijian"] = "当你死亡时，你可以令一名其他角色获得〖恳谏〗和〖遗荐〗。",
  ["#wd__kenjian-choice"] = "恳谏：选择令 %dest 执行的一项",
  ["wd__kenjian_draw"] = "其摸一张牌",
  ["wd__kenjian_discard"] = "其弃置一张手牌",
  ["#wd__yijian-choose"] = "遗荐：你可以令一名角色获得〖恳谏〗和〖遗荐〗",
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
local wd__daibing = fk.CreateTriggerSkill{
  name = "wd__daibing",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.card.color == Card.Black and
      data.damageDealt
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wd__daibing-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    local current = room.logic:getCurrentEvent()
    local use_event = current:findParent(GameEvent.UseCard)
    if not use_event then return end
    local phase_event = use_event:findParent(GameEvent.Phase)
    if not phase_event then return end
    use_event:addExitFunc(function()
      phase_event:shutdown()
    end)
    player:gainAnExtraPhase(Player.Play, true)
  end,
}
lvqian:addSkill(wd__zongqin)
lvqian:addSkill(wd__daibing)
Fk:loadTranslationTable{
  ["wd__lvqian"] = "吕虔",
  ["wd__zongqin"] = "纵擒",
  [":wd__zongqin"] = "出牌阶段限一次，你可以将一张♠牌当【欲擒故纵】使用。",
  ["wd__daibing"] = "岱兵",
  [":wd__daibing"] = "当你于出牌阶段内使用黑色牌结算后，若此牌造成过伤害，你可以摸一张牌并结束出牌阶段，然后你执行一个额外的出牌阶段。",
  ["#wd__daibing-invoke"] = "岱兵：你可以摸一张牌，结束出牌阶段，然后执行一个额外的出牌阶段",
}

Fk:loadTranslationTable{
  ["wd__shenying"] = "沈莹",
  ["wd__chizhen"] = "驰阵",
  [":wd__chizhen"] = "出牌阶段，你可以横置一张装备牌并摸一张牌，然后视为使用【决斗】。你不能重置装备牌。",
}

Fk:loadTranslationTable{
  ["wd__mizhu"] = "糜竺",
  ["wd__juqi"] = "居奇",
  [":wd__juqi"] = "出牌阶段限一次，你可以将所有手牌交给一名其他角色，然后将牌堆顶牌置于武将牌上，称为“银”。你可以将一张“银”当【金】使用。",
  ["wd__jiwei"] = "济危",
  [":wd__jiwei"] = "其他角色的出牌阶段开始时，你可以将一张【金】或“银”置入弃牌堆，令该角色摸两张牌。",
}

local sunguan = General(extension, "wd__sunguan", "wei", 4)
local wd__jimeng = fk.CreateTriggerSkill{
  name = "wd__jimeng",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.damageDealt
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@wd__jimeng-phase", 1)
    local n = player:usedSkillTimes(self.name, Player.HistoryPhase)
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
    return target == player and player:hasSkill(self) and player.hp == 1 and data.num < 0 and
      player.room.current and player.room.current.phase == Player.Play
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
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return data.to == Player.NotActive and player:usedSkillTimes("wd__wangsi", Player.HistoryTurn) > 0
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
  [":wd__jimeng"] = "锁定技，当你于出牌阶段内使用牌结算结束后，若此牌造成过伤害，你摸X张牌，然后若X大于你的体力值，你失去1点体力"..
  "（X为你此阶段发动〖激猛〗的次数）。",
  ["wd__wangsi"] = "忘死",
  [":wd__wangsi"] = "锁定技，当你于一名角色的出牌阶段内扣减体力前，若你体力值为1，防止之；此回合结束后，你失去等量的体力。",
  ["@wd__jimeng-phase"] = "激猛",
  ["@wd__wangsi-turn"] = "忘死",
}

Fk:loadTranslationTable{
  ["wd__zhoufang"] = "周鲂",
  ["wd__zhangmu"] = "障目",
  [":wd__zhangmu"] = "当一名角色成为【杀】的目标时，你可以弃置一张牌，然后直到回合结束：其非转化的基本牌无效；可以将两张牌当任意基本牌使用。",
  ["wd__duanfa"] = "断发",
  [":wd__duanfa"] = "①当你成为其他角色使用牌的目标后，若你的体力值大于1，你可以失去体力至1，令此牌对你无效。<br>"..
  "②当你受到非锦囊牌造成的伤害时，若你的体力值为1，防止此伤害。<br>"..
  "③当你受到锦囊牌造成的伤害时，若你的体力值为1且此牌目标数大于1，防止此伤害。",
}

return extension
