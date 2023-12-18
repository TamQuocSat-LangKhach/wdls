local extension = Package("wd_xushi")
extension.extensionName = "wandianlunsha"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["wd_xushi"] = "玩点-虚实篇",
  ["wd"] = "玩点",
}

local feishi = General(extension, "wd__feishi", "shu", 3)
local wd__shuaiyan = fk.CreateTriggerSkill{
  name = "wd__shuaiyan",
  anim_type = "control",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and player.phase == Player.NotActive
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#wd__shuaiyan-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local choices = {"wd__shuaiyan_draw"}
    if not target:isNude() then
      table.insert(choices, "wd__shuaiyan_discard")
    end
    local choice = room:askForChoice(target, choices, self.name, "#wd__shuaiyan-choice:"..player.id)
    if choice == "wd__shuaiyan_draw" then
      player:drawCards(2, self.name)
    else
      local cards = room:askForCardsChosen(player, target, 1, 2, "he", self.name)
      room:throwCard(cards, self.name, target, player)
    end
  end,
}
local wd__moshou = fk.CreateTriggerSkill{
  name = "wd__moshou",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseSkipping},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    if player:isWounded() then
      player.room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    return true
  end,
}
feishi:addSkill(wd__shuaiyan)
feishi:addSkill(wd__moshou)
Fk:loadTranslationTable{
  ["wd__feishi"] = "费诗",
  ["wd__shuaiyan"] = "率言",
  [":wd__shuaiyan"] = "当其他角色于你的回合外回复体力后，你可以令该角色选择一项：1.你摸两张牌；2.你弃置其至多两张牌。",
  ["wd__moshou"] = "墨守",
  [":wd__moshou"] = "锁定技，当你跳过阶段时，取消之，然后你回复1点体力。",
  ["#wd__shuaiyan-invoke"] = "率言：你可以令 %dest 选择你摸两张牌或你弃置其两张牌",
  ["wd__shuaiyan_draw"] = "其摸两张牌",
  ["wd__shuaiyan_discard"] = "其弃置你两张牌",
  ["#wd__shuaiyan-choice"] = "率言：请选择 %src 执行的一项",
}

local hanlong = General(extension, "wd__hanlong", "wei", 4)
local wd__siji = fk.CreateTriggerSkill{
  name = "wd__siji",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Discard then
      return #player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId).is_damage_card then
                return true
              end
            end
          end
        end
      end, Player.HistoryPhase) > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local n = 0
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).is_damage_card then
              n = n + 1
            end
          end
        end
      end
    end, Player.HistoryPhase)
    player:drawCards(2 * n, self.name)
  end,
}
local wd__ciqiu = fk.CreateTriggerSkill{
  name = "wd__ciqiu",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.HpChanged},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.DamageCaused then
        return target == player and not data.chain and
          (not data.to:isWounded() or data.to:getEquipment(Card.SubtypeArmor) or data.to:getEquipment(Card.SubtypeDefensiveRide))
      else
        return data.extra_data and data.extra_data.wd__ciqiu and
          data.extra_data.wd__ciqiu[1] == player.id and data.extra_data.wd__ciqiu[2] == target.id
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      if not data.to:isWounded() then
        data.damage = data.damage + 1
      end
      if data.to:getEquipment(Card.SubtypeArmor) or data.to:getEquipment(Card.SubtypeDefensiveRide) then
        data.damage = data.damage + 1
      end
    else
      player.room:killPlayer({
        who = target.id,
        damage = data.damageEvent,
      })
      player.room:handleAddLoseSkills(player, "-wd__ciqiu", nil, true, false)
    end
  end,

  refresh_events = {fk.BeforeHpChanged},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and data.damageEvent and
      data.damageEvent.from == player and not target:isWounded() and
      data.damageEvent.card and data.damageEvent.card.trueName == "slash" and
      data.damageEvent.damage >= target.hp and not data.damageEvent.chain
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.wd__ciqiu = {player.id, target.id}
  end,
}
hanlong:addSkill(wd__siji)
hanlong:addSkill(wd__ciqiu)
Fk:loadTranslationTable{
  ["wd__hanlong"] = "韩龙",
  ["wd__siji"] = "伺机",
  [":wd__siji"] = "弃牌阶段结束时，你可以摸2X张牌（X为你此阶段弃置的【杀】和伤害锦囊牌数）。",
  ["wd__ciqiu"] = "刺酋",
  [":wd__ciqiu"] = "①锁定技，当你使用【杀】对未受伤的目标造成伤害时，此伤害+1。<br>"..
  "②锁定技，当你使用【杀】对有防具或防御坐骑的目标造成伤害时，此伤害+1。<br>"..
  "③锁定技，当未受伤的角色因受到你使用【杀】造成的伤害而扣减体力至0时，你杀死该角色，然后你失去〖刺酋〗。",
}

local liufu = General(extension, "wd__liufu", "wei", 3)
local wd__zhucheng = fk.CreateTriggerSkill{
  name = "wd__zhucheng",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player:getPile("liufu_zhu") > 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(player:getPile("liufu_zhu"))
      room:obtainCard(player, dummy, false, fk.ReasonJustMove)
    end
    if not player.dead then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(room:getNCards(player:getLostHp() + 1))
      player:addToPile("liufu_zhu", dummy, false, self.name)
    end
  end,
}
local wd__zhucheng_trigger = fk.CreateTriggerSkill{
  name = "#wd__zhucheng_trigger",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      data.from ~= player.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local n = player:getLostHp() + 1
    if from.dead or #from:getCardIds("he") < n or
      #room:askForDiscard(from, n, n, true, self.name, true, ".", "#wd__zhucheng-discard:"..player.id.."::"..n) < n then
      table.insertIfNeed(data.nullifiedTargets, player.id)
    end
  end,
}
local wd__duoqi = fk.CreateTriggerSkill{
  name = "wd__duoqi",
  anim_type = "control",
  expand_pile = "liufu_zhu",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and #player:getPile("liufu_zhu") > 0 and player.phase == Player.NotActive and
      player.room.current and player.room.current.phase == Player.Play then
      for _, move in ipairs(data) do
        if move.moveReason == fk.ReasonDiscard then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|liufu_zhu|.|.",
      "#wd__duoqi-invoke::"..player.room.current.id, "liufu_zhu")
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {room.current.id})
    room:moveCards({
      from = player.id,
      ids = self.cost_data,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = self.name,
      specialName = "liufu_zhu",
    })
    room.logic:getCurrentEvent():findParent(GameEvent.Phase):shutdown()
  end,
}
wd__zhucheng:addRelatedSkill(wd__zhucheng_trigger)
liufu:addSkill(wd__zhucheng)
liufu:addSkill(wd__duoqi)
Fk:loadTranslationTable{
  ["wd__liufu"] = "刘馥",
  ["wd__zhucheng"] = "筑城",
  [":wd__zhucheng"] = "①结束阶段，你可以获得所有“筑”，然后将牌堆顶X张牌置于你的武将牌上，称为“筑”。<br>"..
  "②锁定技，当你成为其他角色使用【杀】或普通锦囊牌的目标时，其需弃置X张牌，否则此牌对你无效（X为你已损失体力值+1）。",
  ["wd__duoqi"] = "夺气",
  [":wd__duoqi"] = "当其他角色的出牌阶段内牌被弃置时，你可以将一张“筑”置入弃牌堆，终止一切结算并令当前出牌阶段结束。",
  ["liufu_zhu"] = "筑",
  ["#wd__zhucheng-invoke"] = "筑城：你可以将牌堆顶%arg张牌作为“筑”置于武将牌上",
  ["#wd__zhucheng-get"] = "筑城：你可以获得所有“筑”",
  ["#wd__zhucheng_trigger"] = "筑城",
  ["#wd__zhucheng-discard"] = "筑城：你需弃置%arg张牌，否则对 %src 无效",
  ["#wd__duoqi-invoke"] = "夺气：你可以将一张“筑”置入弃牌堆，终止一切结算并令 %dest 的出牌阶段立即结束",
}

local liuyan = General(extension, "wd__liuyan", "qun", 4)
local wd__juedao = fk.CreateActiveSkill{
  name = "wd__juedao",
  anim_type = "defensive",
  card_num = 1,
  target_num = 0,
  prompt = "#wd__juedao",
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    if not player.dead and not player.chained then
      player:setChainState(true)
    end
  end,
}
local wd__juedao_distance = fk.CreateDistanceSkill{
  name = "#wd__juedao_distance",
  correct_func = function(self, from, to)
    if (from:hasSkill(self) and from.chained) or (to:hasSkill(self) and to.chained) then
      return 1
    end
    return 0
  end,
}
local wd__geju = fk.CreateTriggerSkill{
  name = "wd__geju",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_cost = function(self, event, target, player, data)
    local kingdoms = {"wei", "shu", "wu", "qun"}
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      if p:inMyAttackRange(player) then
        table.removeOne(kingdoms, p.kingdom)
      end
    end
    if #kingdoms > 0 then
      self.cost_data = #kingdoms
      return player.room:askForSkillInvoke(player, self.name)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.cost_data, self.name)
  end,
}
local wd__geju_targetmod = fk.CreateTargetModSkill{
  name = "#wd__geju_targetmod",
  frequency = Skill.Compulsory,
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(self) and not table.find(Fk:currentRoom().alive_players, function(p)
      return p.kingdom ~= player.kingdom and p:inMyAttackRange(player)
    end)
  end,
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(self) and not table.find(Fk:currentRoom().alive_players, function(p)
      return p.kingdom ~= player.kingdom and p:inMyAttackRange(player)
    end)
  end,
}
wd__juedao:addRelatedSkill(wd__juedao_distance)
wd__geju:addRelatedSkill(wd__geju_targetmod)
liuyan:addSkill(wd__juedao)
liuyan:addSkill(wd__geju)
Fk:loadTranslationTable{
  ["wd__liuyan"] = "刘焉",
  ["wd__juedao"] = "绝道",
  [":wd__juedao"] = "①出牌阶段，你可以弃置一张牌，横置你的武将牌。<br>②若你处于连环状态，你至其他角色、其他角色至你的距离各+1。",
  ["wd__geju"] = "割据",
  [":wd__geju"] = "①准备阶段和结束阶段，你可以摸X张牌（X为攻击范围内不含有你的势力数）。<br>②锁定技，若所有其他势力角色的攻击范围内均不含有你，"..
  "你使用牌无距离和次数限制。",
  ["#wd__juedao"] = "绝道：你可以弃置一张牌，横置你的武将牌",
}

local liuzan = General(extension, "wd__liuzan", "wu", 4)
local wd__kangyin = fk.CreateActiveSkill{
  name = "wd__kangyin",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#wd__kangyin",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 3
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isAllNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "hej", self.name)
    room:loseHp(player, 1, self.name)
    room:throwCard({id}, self.name, target, player)
    if player.dead then return end
    if Fk:getCardById(id).type == Card.TypeBasic then
      local n = player:getLostHp()
      if n == 0 then return end
      player:drawCards(n, self.name)
      if player.dead or player:isNude() or not player:isWounded() then return end
      n = player:getLostHp()
      while not player.dead and n > 0 do
        local to, cards = U.askForChooseCardsAndPlayers(room, player, 1, n, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1,
          nil, "#wd__kangyin-give:::"..n, self.name, true)
        if #to > 0 and #cards > 0 then
          local dummy = Fk:cloneCard("dilu")
          dummy:addSubcards(cards)
          n = n - #cards
          to = room:getPlayerById(to[1])
          room:moveCardTo(dummy, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, false, player.id)
        else
          break
        end
      end
    elseif Fk:getCardById(id).type == Card.TypeEquip then
      room:setPlayerMark(player, "wd__kangyin2-phase", 1)
    elseif Fk:getCardById(id).type == Card.TypeTrick then
      room:setPlayerMark(player, "wd__kangyin3-phase", 1)
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase", player:getLostHp())
    end
  end,
}
local wd__kangyin_trigger = fk.CreateTriggerSkill{
  name = "#wd__kangyin_trigger",
  mute = true,
  events = {fk.AfterCardTargetDeclared, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if target == player and data.card and data.card.trueName == "slash" and player:isWounded() then
      if event == fk.AfterCardTargetDeclared then
        return player:getMark("wd__kangyin2-phase") > 0 and #U.getUseExtraTargets(player.room, data, false) > 0
      elseif event == fk.Damage then
        return player:getMark("wd__kangyin3-phase") > 0
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("wd__kangyin")
    if event == fk.AfterCardTargetDeclared then
      local tos = room:askForChoosePlayers(player, U.getUseExtraTargets(room, data, false), 1, player:getLostHp(),
        "#wd__kangyin-choose:::"..data.card:toLogString()..":"..player:getLostHp(), "wd__kangyin", true)
      if #tos > 0 then
        room:notifySkillInvoked(player, "wd__kangyin", "offensive")
        for _, id in ipairs(tos) do
          table.insert(data.tos, {id})
        end
      end
    elseif event == fk.Damage then
      room:notifySkillInvoked(player, "wd__kangyin", "support")
      room:recover({
        who = player,
        num = math.min(data.damage, player:getLostHp()),
        recoverBy = player,
        skillName = "wd__kangyin",
      })
    end
  end,
}
local wd__kangyin_distance = fk.CreateDistanceSkill{
  name = "#wd__kangyin_distance",
  correct_func = function(self, from, to)
    if from:getMark("wd__kangyin-turn") > 0 then
      return -from:getLostHp()
    end
  end,
}
wd__kangyin:addRelatedSkill(wd__kangyin_trigger)
wd__kangyin:addRelatedSkill(wd__kangyin_distance)
liuzan:addSkill(wd__kangyin)
Fk:loadTranslationTable{
  ["wd__liuzan"] = "留赞",
  ["wd__kangyin"] = "亢音",
  [":wd__kangyin"] = "出牌阶段限三次，你可以失去1点体力并弃置一名角色区域内一张牌。若此牌为：<br>基本牌，你摸X张牌，然后可以将至多X张牌任意"..
  "交给其他角色；<br>装备牌，你本阶段至其他角色距离-X且使用【杀】目标上限+X；<br>锦囊牌，你本阶段使用【杀】次数上限+X，使用【杀】造成伤害后回复"..
  "等量的体力。<br>（X为你已损失体力值）",
  ["#wd__kangyin"] = "亢音：你可以失去1点体力，弃置一名角色区域内一张牌",
  ["#wd__kangyin-give"] = "亢音：你可以将牌交给其他角色（还可以交出%arg张）",
  ["#wd__kangyin-choose"] = "亢音：你可以为此%arg额外指定至多%arg2个目标",
}

local tianyu = General(extension, "wd__tianyu", "wei", 4)
local wd__chezhen = fk.CreateTriggerSkill{
  name = "wd__chezhen",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused, fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card and data.card.type == Card.TypeTrick then
      if event == fk.DamageCaused then
        return #player:getCardIds("e") > 0
      elseif event == fk.DamageInflicted then
        return #player:getCardIds("e") == 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.DamageCaused then
      room:notifySkillInvoked(player, self.name, "offensive")
      data.damage = data.damage + 1
    elseif event == fk.DamageInflicted then
      room:notifySkillInvoked(player, self.name, "defensive")
      data.damage = data.damage - 1
    end
  end,
}
local wd__chezhen_distance = fk.CreateDistanceSkill{
  name = "#wd__chezhen_distance",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    if to:hasSkill(self) and #to:getCardIds("e") == 0 then
      return 1
    end
    if from:hasSkill(self) and #from:getCardIds("e") > 0 then
      return -1
    end
    return 0
  end,
}
local wd__youzhan = fk.CreateTriggerSkill{
  name = "wd__youzhan",
  anim_type = "defensive",
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.trueName == "slash" and player:distanceTo(player.room:getPlayerById(data.to)) <= 1 and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = ""
    if data.from then
      prompt = "#wd__youzhan-invoke:"..data.from..":"..data.to..":"..data.card:toLogString()
    end
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".|.|.|.|.|^basic", prompt, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    room:doIndicate(player.id, {data.to})
    local card = Fk:cloneCard("wd_lure_in_deep")
    card.skillName = self.name
    local use = {
      card = card,
      from = data.to,
    }
    use.toCard = data.card
    use.responseToEvent = data
    player.room:useCard(use)
    return true
  end,
}
wd__chezhen:addRelatedSkill(wd__chezhen_distance)
tianyu:addSkill(wd__chezhen)
tianyu:addSkill(wd__youzhan)
Fk:loadTranslationTable{
  ["wd__tianyu"] = "田豫",
  ["wd__chezhen"] = "车阵",
  [":wd__chezhen"] = "锁定技，若你的装备区内：没有牌，其他角色计算至你的距离+1，你受到的锦囊牌伤害-1；有牌，你计算至其他角色的距离-1，"..
  "你使用普通锦囊牌造成伤害+1。",
  ["wd__youzhan"] = "诱战",
  [":wd__youzhan"] = "当以你距离1以内一名角色为目标的【杀】结算开始时，你可以弃置一张非基本牌，视为该角色使用【诱敌深入】。",
  ["#wd__youzhan-invoke"] = "诱战：%src 对 %dest 使用%arg，你可以弃置一张非基本牌，视为 %dest 使用【诱敌深入】",
}

--local xizhenxihong = General(extension, "wd__xizhenxihong", "shu", 4)
local wd__fuchou = fk.CreateTriggerSkill{
  name = "wd__fuchou",
  anim_type = "defensive",
  events = {fk.TargetConfirming},  --奇怪的时机
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and
      data.from and not player.room:getPlayerById(data.from).dead and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, true, self.name, true, ".", "#wd__fuchou-invoke::"..data.from)
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    room:obtainCard(from, self.cost_data, false, fk.ReasonGive)
    local mark = player:getMark("@@wd__fuchou-turn")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, data.from)
    room:setPlayerMark(player, "@@wd__fuchou-turn", mark)
    table.insertIfNeed(data.nullifiedTargets, player.id)
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Finish and
      player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 and player:getMark("@@wd__fuchou-turn") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    for _, id in ipairs(player:getMark("@@wd__fuchou-turn")) do
      if player.dead then return end
      local to = room:getPlayerById(id)
      if to.dead then
        room:loseHp(player, 1, self.name)
      else
        local use = room:askForUseCard(player, "slash", "slash", "#wd__fuchou-use::"..to.id, true, {must_targets = {to.id}})
        if use then
          room:useCard(use)
        else
          room:loseHp(player, 1, self.name)
        end
      end
    end
  end,
}
local wd__jinyan = fk.CreateFilterSkill{
  name = "wd__jinyan",
  anim_type = "offensive",
  card_filter = function(self, to_select, player)
    return player:hasSkill(self) and player.hp < 3 and to_select.type == Card.TypeTrick and to_select.color == Card.Black
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard("slash", to_select.suit, to_select.number)
  end,
}
--xizhenxihong:addSkill(wd__fuchou)
--xizhenxihong:addSkill(wd__jinyan)
Fk:loadTranslationTable{
  ["wd__xizhenxihong"] = "习珍习宏",
  ["wd__fuchou"] = "负仇",
  [":wd__fuchou"] = "当你受到致命伤害时，你可以防止此伤害，若如此做，本回合结束阶段，你需对伤害来源使用一张手牌，若不使用或此牌未造成伤害，你失去1点体力。",
  ["wd__jinyan"] = "噤言",
  [":wd__jinyan"] = "锁定技，你对其他角色使用的黑色普通锦囊牌效果改为【杀】，其他角色对你使用的黑色普通锦囊牌效果改为【杀】。",
  ["#wd__fuchou-invoke"] = "负仇：你可以交给 %dest 一张牌令此【杀】对你无效，结束阶段你需对其使用【杀】或失去体力",
  ["@@wd__fuchou-turn"] = "负仇",
  ["#wd__fuchou-use"] = "负仇：你需对 %dest 使用【杀】，否则失去1点体力",
}

Fk:loadTranslationTable{
  ["wd__yangyi"] = "杨仪",
  ["wd__choudu"] = "筹度",
  [":wd__choudu"] = "①出牌阶段开始时，你可以视为使用一张【调兵遣将】。<br>②你可以选择你使用的目标数大于1的锦囊牌结算的开始角色与方向。",
  ["wd__liduan"] = "立断",
  [":wd__liduan"] = "当一名其他角色于其回合外获得一张牌后，你可以令其选择一项：1.使用此牌；2.将一张手牌交给你。",
}

local zaozhirenjun = General(extension, "wd__zaozhirenjun", "wei", 3)
local wd__liangce = fk.CreateViewAsSkill{
  name = "wd__liangce",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeBasic
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("amazing_grace")
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
}
local wd__liangce_trigger = fk.CreateTriggerSkill{
  name = "#wd__liangce_trigger",
  anim_type = "drawcard",
  priority = 10.1, -- 快于五谷！
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and data.card.name == "amazing_grace" and data.extra_data and data.extra_data.AGFilled then
      return #table.filter(data.extra_data.AGFilled, function(id) return player.room:getCardArea(id) == Card.Processing end) > 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getAlivePlayers(), function (p)
      return p.id end), 1, 1, "#liangce-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    table.forEach(room.players, function(p) room:closeAG(p) end)
    local to = room:getPlayerById(self.cost_data)
    local cards = table.filter(data.extra_data.AGFilled, function(id) return room:getCardArea(id) == Card.Processing end)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(cards)
    room:obtainCard(to, dummy, true, fk.ReasonJustMove)
    data.extra_data.AGFilled = nil
  end,
}
local wd__jianbi = fk.CreateTriggerSkill{
  name = "wd__jianbi",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      #AimGroup:getAllTargets(data.tos) > 1
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askForChoosePlayers(player, AimGroup:getAllTargets(data.tos),
      1, 1 + player:getLostHp(), "#jianbi-choose:::"..data.card:toLogString()..":"..1 + player:getLostHp(), self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    table.insertTable(data.nullifiedTargets, self.cost_data)
  end,
}
local wd__juntun = fk.CreateActiveSkill{
  name = "wd__juntun",
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  prompt = "#wd__juntun",
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  on_use = function(self, room, effect)
    room:recastCard(effect.cards, room:getPlayerById(effect.from), self.name)
  end,
}
wd__liangce:addRelatedSkill(wd__liangce_trigger)
zaozhirenjun:addSkill(wd__liangce)
zaozhirenjun:addSkill(wd__jianbi)
zaozhirenjun:addSkill(wd__juntun)
Fk:loadTranslationTable{
  ["wd__zaozhirenjun"] = "枣祗任峻",
  ["wd__liangce"] = "粮策",
  [":wd__liangce"] = "①出牌阶段限一次，你可以将一张基本牌当【五谷丰登】使用。<br>②当【五谷丰登】亮出的牌结算完毕置入弃牌堆时，你可以令一名角色获得这些牌。",
  ["wd__jianbi"] = "坚壁",
  [":wd__jianbi"] = "当一名角色使用【杀】或锦囊牌指定包括你的多个目标时，你可以令此牌对至多X+1名角色无效（X为你已损失体力值）。",
  ["wd__juntun"] = "军屯",
  [":wd__juntun"] = "出牌阶段，你可以重铸非基本牌。",
  ["#wd__liangce_trigger"] = "粮策",
  ["#liangce-choose"] = "粮策：你可以令一名角色获得【五谷丰登】剩余的亮出牌",
  ["#jianbi-choose"] = "坚壁：你可以令此%arg对至多%arg2名角色无效",
  ["#wd__juntun"] = "军屯：你可以重铸一张非基本牌",

}

return extension
