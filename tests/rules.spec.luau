local Rules = require("../src/shared/Rules")
local count = 0
local function check(condition, message)
    assert(condition, message)
    count += 1
end
local shield, healthDamage = Rules.absorb(50, 21)
check(shield == 29 and healthDamage == 0, "shield absorbs rifle damage")
shield, healthDamage = Rules.absorb(10, 64)
check(shield == 0 and healthDamage == 54, "overflow damages health")
shield, healthDamage = Rules.absorb(0, 30)
check(shield == 0 and healthDamage == 30, "no shield means full health damage")
local owner, progress, status = Rules.capture(1, 0, "Neutral", 0)
check(owner == "Rose" and progress == 1 and status == "CAPTURED", "first unoccupied capture")
owner, progress, status = Rules.capture(1, 1, "Rose", 10)
check(owner == "Rose" and progress == 10 and status == "CONTESTED", "contested point freezes control")
owner, progress, status = Rules.capture(0, 0, "Rose", 7)
check(owner == "Rose" and progress == 7 and status == "EMPTY", "empty zone cannot generate held state")
owner, progress, status = Rules.capture(0, 1, "Rose", 10)
check(owner == "Rose" and progress == 9 and status == "CAPTURING", "enemy must break established control")
for _ = 1, 9 do owner, progress, status = Rules.capture(0, 1, owner, progress) end
check(owner == "Aqua" and progress == 1 and status == "CAPTURED", "enemy flips control after ten ticks")
for _ = 1, 20 do owner, progress, status = Rules.capture(0, 1, owner, progress) end
check(owner == "Aqua" and progress == 10 and status == "HELD", "held progress has a cap")
owner, progress, status = Rules.capture(2, 1, "Aqua", 10)
check(status == "CONTESTED" and progress == 10, "numerical advantage cannot score while contested")
print(string.format("PASS: %d combat/objective rule assertions", count))
