-- [[ ส่วนที่พี่ต้องการให้รันตลอดเวลา ]]
task.spawn(function()
    while true do
        local success, err = pcall(function()
            local args = {
                [1] = {
                    [1] = {
                        [1] = "\226\129\130("
                    }
                }
            }

            local remote = game:GetService("ReplicatedStorage")
                :WaitForChild("NetworkingContainer", 5)
                :WaitForChild("DataRemote", 5)
                
            if remote then
                remote:FireServer(unpack(args))
            end
        end)
        
        task.wait(0.1) -- ส่งรัวๆ ทุก 0.1 วินาที
    end
end)

-- [[ ส่วนโค้ดวาร์ป + จิ้มหน้าจอ (ยังทำงานปกติ) ]]
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = game.Players.LocalPlayer
local lobbyPlaceId = 93712201161812 

local function isInLobby()
    return game.PlaceId == lobbyPlaceId
end

local function forceClickStart()
    local lobby = player.PlayerGui:FindFirstChild("Lobby")
    if not lobby then return end

    for _, btn in pairs(lobby:GetDescendants()) do
        if btn.Name == "Start" and btn:IsA("GuiButton") and btn.Visible and btn.Parent.Visible then
            local absPos = btn.AbsolutePosition
            local absSize = btn.AbsoluteSize
            local centerX = absPos.X + (absSize.X / 2)
            local centerY = absPos.Y + (absSize.Y / 2) + 60

            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
            return true
        end
    end
end

task.spawn(function()
    local locations = {
        CFrame.new(-19.4254074, 19.6875057, -158.799988),
        CFrame.new(1.57457733, 19.6875057, -158.799988),
        CFrame.new(22.5745888, 19.6875057, -158.799988),
        CFrame.new(43.5745735, 19.6875057, -158.799988)
    }

    while true do
        if not isInLobby() then 
            -- ถ้าเข้าด่านแล้ว ส่วนวาร์ปจะหยุดทำงาน (แต่ส่วนส่ง Remote ข้างบนยังรันต่อ)
            task.wait(5)
        else
            for i, pos in ipairs(locations) do
                if not isInLobby() then break end
                local char = player.Character or player.CharacterAdded:Wait()
                local root = char:WaitForChild("HumanoidRootPart")
                root.CFrame = pos
                task.wait(0.8) 
                local startTime = tick()
                while tick() - startTime < 5 do
                    if not isInLobby() then break end
                    forceClickStart()
                    task.wait(0.3)
                end
                task.wait(1)
            end
        end
        task.wait(1)
    end
end)
