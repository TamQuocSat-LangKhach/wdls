local extension = Package("wd_xushi")
extension.extensionName = "wdls"

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
      player:drawCards(1, self.name)
    else
      local id = room:askForCardChosen(player, target, "he", self.name)
      room:throwCard({id}, self.name, target, player)
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
    return true
  end,
}
feishi:addSkill(wd__shuaiyan)
feishi:addSkill(wd__moshou)
Fk:loadTranslationTable{
  ["wd__feishi"] = "费诗",
  ["wd__shuaiyan"] = "率言",
  [":wd__shuaiyan"] = "当其他角色于你的回合外回复体力后，你可以令该角色选择一项：1.你摸一张牌；2.你弃置其一张牌。",
  ["wd__moshou"] = "墨守",
  [":wd__moshou"] = "锁定技，你不能跳过阶段。",
  ["#wd__shuaiyan-invoke"] = "率言：你可以令 %dest 选择你摸一张牌或你弃置其一张牌",
  ["wd__shuaiyan_draw"] = "其摸一张牌",
  ["wd__shuaiyan_discard"] = "其弃置你一张牌",
  ["#wd__shuaiyan-choice"] = "率言：请选择 %src 执行的一项",
}

local hanlong = General(extension, "wd__hanlong", "wei", 4)
local wd__siji = fk.CreateTriggerSkill{
  name = "wd__siji",
  anim_type = "drawcard",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Discard and player:getMark("siji-phase") > 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2*player:getMark("siji-phase"), self.name)
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self) and player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId).trueName == "slash" then
            player.room:addPlayerMark(player, "siji-phase", 1)
          end
        end
      end
    end
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
        return target == player and not data.to:isWounded() and not data.chain
      else
        return player:getMark(self.name) == target.id
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      data.damage = data.damage + 1
    else
      player.room:setPlayerMark(player, self.name, 0)
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
    player.room:setPlayerMark(player, self.name, target.id)
  end,
}
hanlong:addSkill(wd__siji)
hanlong:addSkill(wd__ciqiu)
Fk:loadTranslationTable{
  ["wd__hanlong"] = "韩龙",
  ["wd__siji"] = "伺机",
  [":wd__siji"] = "弃牌阶段结束时，你可以摸2X张牌（X为你于此阶段内弃置的【杀】的数量）。",
  ["wd__ciqiu"] = "刺酋",
  [":wd__ciqiu"] = "①锁定技，当你使用【杀】对目标造成伤害时，若其未受伤，此伤害+1。<br>"..
  "②锁定技，当未受伤的角色因受到你使用【杀】造成的伤害而扣减体力至0时，你杀死该角色，然后你失去〖刺酋〗。",
}

local liufu = General(extension, "wd__liufu", "wei", 3)
local wd__zhucheng = fk.CreateTriggerSkill{
  name = "wd__zhucheng",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local prompt
    if #player:getPile("liufu_zhu") == 0 then
      prompt = "#wd__zhucheng-invoke:::"..math.max(player:getLostHp(), 1)
    else
      prompt = "#wd__zhucheng-get"
    end
    return player.room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player:getPile("liufu_zhu") == 0 then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(room:getNCards(math.max(player:getLostHp(), 1)))
      player:addToPile("liufu_zhu", dummy, true, self.name)
    else
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(player:getPile("liufu_zhu"))
      room:obtainCard(player, dummy, false, fk.ReasonJustMove)
    end
  end,
}
local wd__zhucheng_trigger = fk.CreateTriggerSkill{
  name = "#wd__zhucheng_trigger",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash") and -- or data.card:isCommonTrick()) and
      data.from ~= player.id and #player:getPile("liufu_zhu") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local n = #player:getPile("liufu_zhu")
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
    if player:hasSkill(self) and #player:getPile("liufu_zhu") > 0 and player.room.current and player.room.current.phase == Player.Play then
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
  [":wd__zhucheng"] = "①结束阶段，若没有“筑”，你可以将牌堆顶X张牌置于你的武将牌上（X为你已损失体力值且至少为1），称为“筑”，否则你可以获得所有“筑”。<br>"..
  "②锁定技，当你成为【杀】的目标时，使用者需弃置“筑”的数量张牌，否则此【杀】对你无效。",
  ["wd__duoqi"] = "夺气",
  [":wd__duoqi"] = "当其他角色的出牌阶段内牌被弃置时，你可以将一张“筑”置入弃牌堆，在事件结算完成后结束该出牌阶段。",
  ["liufu_zhu"] = "筑",
  ["#wd__zhucheng-invoke"] = "筑城：你可以将牌堆顶%arg张牌作为“筑”置于武将牌上",
  ["#wd__zhucheng-get"] = "筑城：你可以获得所有“筑”",
  ["#wd__zhucheng_trigger"] = "筑城",
  ["#wd__zhucheng-discard"] = "筑城：你需弃置%arg张牌，否则此【杀】对 %src 无效",
  ["#wd__duoqi-invoke"] = "夺气：你可以将一张“筑”置入弃牌堆，终止一切结算并令 %dest 的出牌阶段立即结束",
}

local liuyan = General(extension, "wd__liuyan", "qun", 4)
local wd__juedao = fk.CreateActiveSkill{
  name = "wd__juedao",
  anim_type = "defensive",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    if not player.chained then
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
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local kingdoms = {}
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
      return player.room:askForSkillInvoke(player, self.name, nil, "#geju-invoke:::"..#kingdoms)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(self.cost_data, self.name)
  end,
}
wd__juedao:addRelatedSkill(wd__juedao_distance)
liuyan:addSkill(wd__juedao)
liuyan:addSkill(wd__geju)
Fk:loadTranslationTable{
  ["wd__liuyan"] = "刘焉",
  ["wd__juedao"] = "绝道",
  [":wd__juedao"] = "①出牌阶段，你可以弃置一张手牌，横置武将牌。<br>②若你处于连环状态，你至其他角色、其他角色至你的距离各+1。",
  ["wd__geju"] = "割据",
  [":wd__geju"] = "准备阶段，你可以摸X张牌（X为攻击范围内不含有你的势力数）。",
  ["#geju-invoke"] = "割据：你可以摸%arg张牌",
}

local liuzan = General(extension, "wd__liuzan", "wu", 4)
local wd__kangyin = fk.CreateActiveSkill{
  name = "wd__kangyin",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local id = room:askForCardChosen(player, target, "he", self.name)
    room:loseHp(player, 1, self.name)
    room:throwCard({id}, self.name, target, player)
    if player.dead then return end
    if Fk:getCardById(id).type == Card.TypeBasic then
      local tos = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), function (p)
        return p.id end), 1, player:getLostHp(), "#wd__kangyin-choose:::"..player:getLostHp(), self.name, true)
      if #tos > 0 then
        table.forEach(tos, function(p) room:getPlayerById(p):drawCards(1, self.name) end)
      end
    else
      room:addPlayerMark(player, "wd__kangyin-turn", 1)
    end
  end,
}
local wd__kangyin_targetmod = fk.CreateTargetModSkill{
  name = "#wd__kangyin_targetmod",
  extra_target_func = function(self, player, skill)
    if skill.trueName == "slash_skill" and player:getMark("wd__kangyin-turn") > 0 then
      return player:getLostHp()
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
wd__kangyin:addRelatedSkill(wd__kangyin_targetmod)
wd__kangyin:addRelatedSkill(wd__kangyin_distance)
liuzan:addSkill(wd__kangyin)
Fk:loadTranslationTable{
  ["wd__liuzan"] = "留赞",
  ["wd__kangyin"] = "亢音",
  [":wd__kangyin"] = "出牌阶段限一次，你可以失去1点体力并弃置一名其他角色的一张牌。若此牌为：<br>"..
  "基本牌，你可以令至多X名角色各摸一张牌；<br>非基本牌，你至其他角色距离-X且你使用【杀】目标上限+X直到回合结束。（X为你已损失体力值）",
  ["#wd__kangyin-choose"] = "亢音：你可以令至多%arg名角色各摸一张牌",
}

local tianyu = General(extension, "wd__tianyu", "wei", 4)
local wd__chezhen = fk.CreateDistanceSkill{
  name = "wd__chezhen",
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
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".|.|.|.|.|equip", prompt, true)
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
tianyu:addSkill(wd__chezhen)
tianyu:addSkill(wd__youzhan)
Fk:loadTranslationTable{
  ["wd__tianyu"] = "田豫",
  ["wd__chezhen"] = "车阵",
  [":wd__chezhen"] = "锁定技，若你的装备区内：没有牌，其他角色至你的距离+1；有牌，你至其他角色的距离-1。",
  ["wd__youzhan"] = "诱战",
  [":wd__youzhan"] = "当以你距离1以内角色为目标的【杀】结算开始时，你可以弃置一张装备牌，视为该角色使用【诱敌深入】。",
  ["#wd__youzhan-invoke"] = "诱战：%src 对 %dest 使用%arg，你可以弃置一张装备牌，视为 %dest 使用【诱敌深入】",
}

local xizhenxihong = General(extension, "wd__xizhenxihong", "shu", 4)
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
local wd__fuchou_distance = fk.CreateDistanceSkill{
  name = "#wd__fuchou_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(self) and from:getMark("@@wd__fuchou-turn") ~= 0 then
      if table.contains(from:getMark("@@wd__fuchou-turn"), to.id) then
        from:setFixedDistance(to, 1)
      else
        from:removeFixedDistance(to)
      end
    end
    return 0
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
wd__fuchou:addRelatedSkill(wd__fuchou_distance)
xizhenxihong:addSkill(wd__fuchou)
xizhenxihong:addSkill(wd__jinyan)
Fk:loadTranslationTable{
  ["wd__xizhenxihong"] = "习珍习宏",
  ["wd__fuchou"] = "负仇",
  [":wd__fuchou"] = "当你成为【杀】的目标时，你可以将一张牌交给此【杀】的使用者，令此【杀】对你无效且你至其距离视为1直到回合结束，"..
  "若如此做，此回合的结束阶段，你摸一张牌，然后你需对其使用【杀】，否则你失去1点体力。",
  ["wd__jinyan"] = "噤言",
  [":wd__jinyan"] = "锁定技，你的体力值不大于2时，你的黑色锦囊牌视为【杀】。",
  ["#wd__fuchou-invoke"] = "负仇：你可以交给 %dest 一张牌令此【杀】对你无效，结束阶段你需对其使用【杀】或失去体力",
  ["@@wd__fuchou-turn"] = "负仇",
  ["#wd__fuchou-use"] = "负仇：你需对 %dest 使用【杀】，否则失去1点体力",
}

Fk:loadTranslationTable{
  ["wd__yangyi"] = "杨仪",
  ["wd__choudu"] = "筹度",
  [":wd__choudu"] = "①出牌阶段限一次，你可以将一张牌当【调兵遣将】使用。<br>②你可以选择你使用的目标数大于一的锦囊牌结算的开始角色与方向。",
  ["wd__liduan"] = "立断",
  [":wd__liduan"] = "当一名其他角色于其回合外获得一张基本牌或装备牌后，你可以令其选择一项：1.使用此牌；2.将一张手牌交给你。",
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
    return target == player and player:hasSkill(self) and data.card.type == Card.TypeTrick and #AimGroup:getAllTargets(data.tos) > 1
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
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
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
  [":wd__jianbi"] = "当锦囊牌指定包括你的多个目标时，你可以令此牌对至多X+1个目标无效（X为你已损失体力值）。",
  ["wd__juntun"] = "军屯",
  [":wd__juntun"] = "出牌阶段，你可以重铸装备牌。",
  ["#wd__liangce_trigger"] = "粮策",
  ["#liangce-choose"] = "粮策：你可以令一名角色获得【五谷丰登】剩余的亮出牌",
  ["#jianbi-choose"] = "坚壁：你可以令此%arg对至多%arg2个目标无效",

}

return extension
