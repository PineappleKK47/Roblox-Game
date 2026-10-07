local Rules = {}
function Rules.absorb(shield, damage)
    local absorbed = math.min(math.max(shield, 0), math.max(damage, 0))
    return shield - absorbed, math.max(0, damage - absorbed)
end
function Rules.capture(rose, aqua, owner, progress)
    if rose > 0 and aqua > 0 then return owner, progress, "CONTESTED" end
    local presence = rose > 0 and "Rose" or aqua > 0 and "Aqua" or nil
    if not presence then return owner, progress, "EMPTY" end
    if presence == owner then return owner, math.min(10, progress + 1), "HELD" end
    progress -= 1
    if progress <= 0 then return presence, 1, "CAPTURED" end
    return owner, progress, "CAPTURING"
end
return Rules
