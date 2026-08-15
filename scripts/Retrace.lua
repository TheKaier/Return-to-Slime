
function WitheringGel(ctx)
    -- 获取施法单位
    local unit = ctx.unit
    if not unit then
        ctx.log("错误：ctx.unit 为空")
        return false
    end

    local game = ctx.game
    local pos = unit.getPosition()
    local ownerName = unit.getOwner()
    local civ = game.getCiv(ownerName)
    if not civ then
        ctx.log("错误：无法获取施法者文明")
        return false
    end

    -- 获取周围 2 格内所有地块
    local tiles = game.getTilesNear(pos.x, pos.y, 2)
    local convertedCount = 0

    -- 遍历每个地块
    for _, tile in ipairs(tiles) do
        -- ★ 关键：生成当前地块上所有单位的“快照”，避免迭代过程中修改原列表
        local unitsOnTile = {}
        for _, u in ipairs(tile.getUnits()) do
            table.insert(unitsOnTile, u)
        end

        -- 处理快照中的每个单位
        for _, u in ipairs(unitsOnTile) do
            -- 排除施法者自身
            if u.id ~= unit.id then
                local uOwner = u.getOwner()
                -- 仅转换非己方单位（敌方单位）
                if uOwner ~= ownerName then
                    local tilePos = tile.position
                    -- 摧毁敌方单位
                    u.destroy()
                    -- 在原地创建一个属于我方的勇士
                    civ.addUnitAtTile("Ebonian Blight Slime", tilePos.x, tilePos.y)
                    convertedCount = convertedCount + 1
                    ctx.log("已转换一个敌方单位为黑檀枯萎史莱姆")
                end
            end
        end
    end

    ctx.log("成功将 " .. convertedCount .. " 个敌方单位转换为黑檀枯萎史莱姆")
    return true
end

-- scripts/myMod.lua

-- 辅助函数：计算两个六边形地块之间的格数距离（轴向坐标转立方体坐标算法）
local function hexDistance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = -dx - dy  -- 六边形轴向坐标中 z = -x - y
    return (math.abs(dx) + math.abs(dy) + math.abs(dz)) / 2
end

-- 主功能：在单位2格外、5格内随机生成6个勇士
function BurstGel(ctx)
    -- 1. 获取施法单位及其信息
    local unit = ctx.unit
    if unit == nil then
        ctx.log("错误：未找到触发单位")
        return false
    end

    local pos = unit.getPosition()
    local game = ctx.game
    local ownerName = unit.getOwner()
    local civ = game.getCiv(ownerName)
    if civ == nil then
        ctx.log("错误：未找到所属文明")
        return false
    end

    -- 2. 获取半径5内的所有地块（六边形范围）
    local allTiles = game.getTilesNear(pos.x, pos.y, 4)
    local candidates = {}

    -- 3. 遍历筛选有效地块（距离>2、必须是陆地、且当前没有单位）
    for _, tile in ipairs(allTiles) do
        local dist = hexDistance(tile.position, pos)
        -- 条件：严格在2格以外（>2），且小于等于5
        if dist > 2 and dist <= 4 then
            -- 必须是陆地（勇士无法下水）
            if tile.isLand then
                -- 检查该格是否已有单位（防止踩踏重叠）
                local unitsOnTile = tile.getUnits()
                if #unitsOnTile == 0 then
                    table.insert(candidates, tile)
                end
            end
        end
    end



    -- 5. 随机挑选最多6个不同的地块
    local spawnCount = math.min(2, #candidates)

    -- 不需要手动设置随机种子，直接使用 math.random
    for i = 1, spawnCount do
        local idx = math.random(1, #candidates)
        local selectedTile = candidates[idx]
        table.remove(candidates, idx)
        local r = math.random(1, 3)
        if r == 1 then
            civ.addUnitAtTile("Bouncy Slime", selectedTile.position.x, selectedTile.position.y)
        elseif r == 2 then
            civ.addUnitAtTile("Heavenly Slime", selectedTile.position.x, selectedTile.position.y)
        else
            civ.addUnitAtTile("Crystal Slime", selectedTile.position.x, selectedTile.position.y)
        end
    end

    return true
end

-- scripts/myMod.lua

-- scripts/myMod.lua

-- scripts/myMod.lua

function PureGel(ctx)
    ctx.log("=== 开始执行转换技能 ===")

    local unit = ctx.unit
    if unit == nil then
        ctx.log("错误：ctx.unit 为空")
        return false
    end

    local game = ctx.game
    local pos = unit.getPosition()
    local ownerName = unit.getOwner()
    local civ = game.getCiv(ownerName)
    if civ == nil then
        ctx.log("错误：无法获取所属文明")
        return false
    end

    -- 获取视野范围（尝试多个属性）
    local visRange = 3
    ctx.log("视野半径 = " .. visRange)

    -- 获取视野内的所有地块
    local tiles = game.getTilesNear(pos.x, pos.y, visRange)
    ctx.log("共 " .. #tiles .. " 个地块")

    local convertedCount = 0
    local enemyCount = 0

    for _, tile in ipairs(tiles) do
        local unitsOnTile = tile.getUnits()
        for _, u in ipairs(unitsOnTile) do
            if u.id ~= unit.id then
                local unitOwner = u.getOwner()
                if unitOwner ~= ownerName then
                    enemyCount = enemyCount + 1
                    ctx.log("发现敌方单位 ID=" .. u.id .. " 类型=" .. (u.type or "未知"))

                    -- 50% 概率
                    if math.random() < 0.8 then
                        -- ★ 方案一：尝试直接 setOwner（最干净） ★
                        local success = false
                        if u.setOwner then
                            -- 注意：有些API是 u:setOwner(ownerName) 或 u.setOwner(ownerName)
                            -- 尝试两种调用方式
                            local ok, err = pcall(function()
                                if type(u.setOwner) == "function" then
                                    u:setOwner(ownerName)
                                else
                                    u.setOwner(ownerName)
                                end
                            end)
                            if ok then
                                success = true
                                ctx.log("成功通过 setOwner 转换单位 " .. u.id)
                            else
                                ctx.log("setOwner 失败: " .. tostring(err))
                            end
                        end

                        -- ★ 方案二：如果 setOwner 无效，采用“保留类型”的摧毁重建 ★
                        if not success then
                            local tilePos = tile.position
                            -- 获取原单位类型
                            local unitType = u.type
                            if type(unitType) == "function" then
                                unitType = unitType(u)
                            end
                            if unitType == nil or unitType == "" then
                                -- 如果无法获取类型，尝试通过其他字段
                                unitType = u.name or u.getName and u:getName() or "Warrior"
                            end
                            ctx.log("采用重建方案，单位类型: " .. tostring(unitType))

                            -- 摧毁原单位
                            u.destroy()
                            -- 新建同类型单位归我
                            civ.addUnitAtTile(unitType, tilePos.x, tilePos.y)
                            ctx.log("重建完成")
                            success = true
                        end

                        if success then
                            convertedCount = convertedCount + 1
                        end
                    else
                        ctx.log("单位 " .. u.id .. " 概率未通过")
                    end
                end
            end
        end
    end

    ctx.log("共发现 " .. enemyCount .. " 个敌方单位，成功转换 " .. convertedCount .. " 个")
    return true
end

-- scripts/myMod.lua

function DevouringGel(ctx)
    local unit = ctx.unit
    if not unit then
        ctx.log("错误：没有单位")
        return false
    end

    local game = ctx.game
    local pos = unit.getPosition()

    -- 周围 1 格
    local tiles = game.getTilesNear(pos.x, pos.y, 1)
    local targets = {}

    for _, tile in ipairs(tiles) do
        for _, u in ipairs(tile.getUnits()) do
            if u.id ~= unit.id then
                -- ★ 使用点号调用 hasUnique
                if u.hasUnique and u.hasUnique("Primal Slime") then
                    table.insert(targets, u)
                    ctx.log("发现带有 Primal Slime 标签的单位")
                end
            end
        end
    end

    local count = #targets
    if count == 0 then
        ctx.log("周围没有可吞噬的目标")
        return true
    end

    -- 消灭目标（点号调用 destroy）
    for _, u in ipairs(targets) do
        if u.destroy then
            u.destroy(u)
            ctx.log("消灭一个目标")
        end
    end

    -- 计算恢复量（每个 20 点）
    local healAmount = count * 20

    -- ★ 使用点号调用 healBy
    if unit.healBy then
        unit.healBy(healAmount)
        ctx.log("已调用 healBy 恢复生命")
    else
        ctx.log("警告：unit.healBy 不存在，无法回血")
    end

    ctx.log("吞噬完成，共吞噬 " .. count .. " 个单位")
    return true
end

function BurrowTransfer(ctx)
    local civ = ctx.civ
    local unit = ctx.unit
    local game = ctx.game
    local pos = unit.getPosition()
    local n_x = pos.x
    local n_y = pos.y
    local x_t, y_t
    while true do
        local r = math.random(1, 18)
        if r == 1 then
            x_t, y_t = 0, 1
        elseif r == 2 then
            x_t, y_t = 1, 0
        elseif r == 3 then
            x_t, y_t = 1, 1
        elseif r == 4 then
            x_t, y_t = -1, 0
        elseif r == 5 then
            x_t, y_t = 0, -1
        elseif r == 6 then
            x_t, y_t = -1, -1
        elseif r == 7 then
            x_t, y_t = 2, 0
        elseif r == 8 then
            x_t, y_t = 2, 1
        elseif r == 9 then
            x_t, y_t = 2, 2
        elseif r == 10 then
            x_t, y_t = 1, 2
        elseif r == 11 then
            x_t, y_t = 0, 2
        elseif r == 12 then
            x_t, y_t = -1, 1
        elseif r == 13 then
            x_t, y_t = -2, 0
        elseif r == 14 then
            x_t, y_t = -2, -1
        elseif r == 15 then
            x_t, y_t = -2, -2
        elseif r == 16 then
            x_t, y_t = -1, -2
        elseif r == 17 then
            x_t, y_t = 0, -2
        elseif r == 18 then
            x_t, y_t = 1, -2
        elseif r == 19 then
            x_t, y_t = 3, 3
        elseif r == 20 then
            x_t, y_t = 2, 3
        elseif r == 21 then
            x_t, y_t = 1, 3
        elseif r == 22 then
            x_t, y_t = 0, 3
        elseif r == 23 then
            x_t, y_t = -1, 2
        elseif r == 24 then
            x_t, y_t = -2, 1
        elseif r == 25 then
            x_t, y_t = -3, 0
        elseif r == 26 then
            x_t, y_t = -3, -1
        elseif r == 27 then
            x_t, y_t = -3, -2
        elseif r == 28 then
            x_t, y_t = -3, -3
        elseif r == 29 then
            x_t, y_t = -2, -3
        elseif r == 30 then
            x_t, y_t = -1, -3
        elseif r == 31 then
            x_t, y_t = 0, -3
        elseif r == 32 then
            x_t, y_t = 1, -2
        elseif r == 33 then
            x_t, y_t = 2, -1
        elseif r == 34 then
            x_t, y_t = 3, 0
        elseif r == 35 then
            x_t, y_t = 3, 1
        else
            x_t, y_t = 3, 2
        end
        local tile = game.getTile(n_x+x_t, n_y+y_t)
        if not tile.isImpassable() then
            break
        end
    end
    unit.addMovement(1)
    unit.teleportTo(n_x+x_t, n_y+y_t)
    return true
end


function ArcaneResonance(ctx)
    -- 1. 获取触发技能的单位
    local unit = ctx.unit
    if unit == nil then
        ctx.log("错误：没有触发单位")
        return false
    end

    local game = ctx.game
    -- 2. 获取单位位置
    local pos = unit.getPosition()
    local x = pos.x
    local y = pos.y
    -- 3. 获取单位所属的文明，用于判断敌我
    local ownerName = unit.getOwner()

    -- 4. 获取周围2格内的所有地块
    local tiles = game.getTilesNear(x, y, 2)
    local damageAmount = 35
    local damagedCount = 0

    -- 5. 遍历这些地块
    for _, tile in ipairs(tiles) do
        -- 获取该地块上的所有单位
        local unitsOnTile = tile.getUnits()
        for _, u in ipairs(unitsOnTile) do
            -- 排除触发技能的单位自身
            if u.id ~= unit.id then
                -- 检查单位是否属于敌方
                if u.getOwner() ~= ownerName then
                    -- 造成35点伤害
                    u.takeDamage(damageAmount)
                    damagedCount = damagedCount + 1
                    ctx.log("对单位 " .. u.id .. " 造成 " .. damageAmount .. " 点伤害")
                end
            end
        end
    end

    ctx.log("技能执行完毕，共对 " .. damagedCount .. " 个敌方单位造成伤害")
    return true
end