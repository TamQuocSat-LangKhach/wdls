local extension = Package("wd_bingshi")
extension.extensionName = "wandianlunsha"

Fk:loadTranslationTable{
  ["wd_bingshi"] = "玩点-兵势篇",
}

Fk:loadTranslationTable{
  ["wd__chentai"] = "陈泰",
  ["wd__chenyong"] = "沉勇",
  [":wd__chenyong"] = "当你需使用【杀】或【闪】时，你可以拼点，若你赢，视为你使用之。 ",
}

Fk:loadTranslationTable{
  ["wd__cuilin"] = "崔林",
  ["wd__xikou"] = "息寇",
  [":wd__xikou"] = "锁定技，其他角色不能弃置或获得你的手牌，你不能获得其他角色的手牌。 ",
  ["wd__suli"] = "肃吏",
  [":wd__suli"] = "出牌阶段限一次，你可以将手牌摸或弃至体力值；若为弃置，你可以弃置至多你弃牌张数的其他角色各一张牌。",
}

local jiakui = General(extension, "wd__jiakui", "wei", 3)
local wd__wanlan = fk.CreateTriggerSkill{
  name = "wd__wanlan",
  anim_type = "support",
  events = {fk.AfterCardUseDeclared, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.color == Card.Red and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(table.filter(player.room:getAlivePlayers(), function(p)
      return player.hp >= p.hp end), function(p) return p.id end), 1, 1, "#wd__wanlan1-choose", self.name)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:getPlayerById(self.cost_data):drawCards(1, self.name)
  end,
}
local wd__wanlan2 = fk.CreateTriggerSkill{
  name = "#wd__wanlan",
  anim_type = "control",
  events = {fk.AfterCardUseDeclared, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.color == Card.Black and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(table.filter(player.room:getOtherPlayers(player), function(p)
      return player.hp < p.hp end), function(p) return p.id end)
    if #targets == 0 then return end
    local to = player.room:askForChoosePlayers(player, targets, 1, 1, "#wd__wanlan2-choose", "wd__wanlan")
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local id = player.room:askForCardChosen(player, to, "he", "wd__wanlan")
    player.room:throwCard({id}, "wd__wanlan", to, player)
  end,
}
wd__wanlan:addRelatedSkill(wd__wanlan2)
jiakui:addSkill(wd__wanlan)
Fk:loadTranslationTable{
  ["wd__jiakui"] = "贾逵",
  ["wd__wanlan"] = "挽澜",
  [":wd__wanlan"] = "每回合各限一次，当你使用或打出红色牌时，你可以令一名体力值不大于你的角色摸一张牌；当你使用或打出黑色牌时，你可以弃置一名体力值大于你的角色的一张牌。",
  ["#wd__wanlan"] = "挽澜",
  ["#wd__wanlan1-choose"] = "挽澜：你可以令一名体力值不大于你的角色摸一张牌",
  ["#wd__wanlan2-choose"] = "挽澜：你可以弃置一名体力值大于你的角色的一张牌",
}

Fk:loadTranslationTable{
  ["wd__mazhong"] = "马忠",
  ["wd__fuman"] = "抚蛮",
  [":wd__fuman"] = "出牌阶段限一次，你可以将【杀】交给其他角色。其他角色的出牌阶段限一次，其可以将一张【杀】交给你，摸一张牌。 ",
}

Fk:loadTranslationTable{
  ["wd__shixie"] = "士燮",
  ["wd__jujiao"] = "踞交",
  [":wd__jujiao"] = "锁定技，若你的手牌数小于体力值，你于回合外不计入距离和座次计算。 ",
  ["wd__shuaifu"] = "率附",
  [":wd__shuaifu"] = "锁定技，准备阶段开始时，你摸一张牌，然后若你的手牌数大于体力值，你选择一项：1.弃置多余的手牌并回复1点体力；2.将多余的手牌交给一名其他角色。",
}

Fk:loadTranslationTable{
  ["wd__sunli"] = "孙礼",
  ["wd__bohu"] = "搏虎",
  [":wd__bohu"] = "准备阶段，你可以选择一项：1.失去任意点体力，然后你至其他角色的距离-X直到回合结束；2.你使用【杀】伤害基数值改为X直到回合结束。（X为你已损失的体力值）",
  ["wd__fenjie"] = "分界",
  [":wd__fenjie"] = "限定技，回合开始时，你可以减1点体力上限，然后修改〖搏虎〗：<br>"..
  "将“选择一项”改为“选择两项”；增加选项“3.弃牌阶段开始时，你令一至两名其他角色各将X张手牌交给你，然后你分别将等量的牌交给这些角色”。",
}

--王基

Fk:loadTranslationTable{
  ["wd__xiahoushang"] = "夏侯尚",
  ["wd__anxi"] = "暗袭",
  [":wd__anxi"] = "出牌阶段限一次，你可以将一张装备牌置入一名其他角色的装备区（可以替换原装备），令该角色选择一项：1.弃置装备区内所有牌；2.你对其造成X点火焰伤害（X为你至其的距离）。",
  ["wd__shengsha"] = "生杀",
  [":wd__shengsha"] = "限定技，出牌阶段，你可以转置一名角色装备区内任意张牌。",
}

Fk:loadTranslationTable{
  ["wd__yanghong"] = "杨弘",
  ["wd__dinglve"] = "定略",
  [":wd__dinglve"] = "当你或你攻击范围内的一名角色成为【杀】的目标时，你可以将一张手牌交给此【杀】的使用者并选择是此【杀】合法目标的另一名角色，将此【杀】转移给该角色。",
  ["wd__bifeng"] = "避锋",
  [":wd__bifeng"] = "当你成为【杀】或【决斗】的目标时，若使用者的手牌多于你，你可以摸一张牌。",
}

Fk:loadTranslationTable{
  ["wd__zhanggong"] = "张恭",
  ["wd__qianxin"] = "遣信",
  [":wd__qianxin"] = "①出牌阶段，若场上没有“信”，你可以选择一名其他角色为“遣信”目标，并将一张牌作为“信”置于下家的武将牌旁。<br>"..
  "②“遣信”目标回合开始时，若其有“信”，你获得之并摸X张牌（X为你至其的距离）。<br>"..
  "③有“信”的角色准备阶段，其可以将之置于其下家的武将牌旁。<br>"..
  "④你或“遣信”目标死亡时，将“信”置入弃牌堆。",
  ["wd__qiwei"] = "骑卫",
  [":wd__qiwei"] = "锁定技，有“信”的角色手牌上限-1；其回合结束时，你可以弃置两张牌，对其造成1点伤害并将“信”置于其下家的武将牌旁。",
}

Fk:loadTranslationTable{
  ["wd__zhangji"] = "张既",
  ["wd__anxiao"] = "安骁",
  [":wd__anxiao"] = "锁定技，你不是至你距离为1的其他角色于其回合内使用的第一张牌的合法目标。",
  ["wd__suqi"] = "肃齐",
  [":wd__suqi"] = "结束阶段，你可以选择至少两名手牌数相等的其他角色，观看牌堆顶的X张牌（X为这些角色的数量），然后将这些牌任意交给你和这些角色，每名角色至多两张。 ",
}

Fk:loadTranslationTable{
  ["wd__zhaoang"] = "赵昂",
  ["wd__qianzhi"] = "遣质",
  [":wd__qianzhi"] = "出牌阶段限一次，你可以将一张♠牌当【笑里藏刀】使用。",
  ["wd__wenjue"] = "问决",
  [":wd__wenjue"] = "锁定技，每回合各限一次，当你造成或受到伤害时，你需令一名其他角色判定，若结果为：黑色，你摸一张牌；红色，你防止此伤害，然后获得造成伤害的牌。",
}

return extension
