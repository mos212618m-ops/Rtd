local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")

local Window = Rayfield:CreateWindow({
   Name = "RTD | HYBRID PRO V24",
   LoadingTitle = "Wave + Money + Queue System",
   ConfigurationSaving = { Enabled = false }
})

-- === [ Variables ] ===
local RS = game:GetService("ReplicatedStorage")
local B_Query = RS:WaitForChild("ByteNetQuery")
local LP = game:GetService("Players").LocalPlayer

local Macro = {}
local Recording = false
local Playing = false
local CurrentActionIndex = 1

-- === [ Get Game Data Functions ] ===
local function GetWave()
    local waveVal = workspace:FindFirstChild("Wave") or RS:FindFirstChild("Wave")
    if waveVal and waveVal:IsA("IntValue") then return waveVal.Value end
    return 0
end

local function GetMoney()
    -- ปรับตำแหน่งตามตัวแปรเงินในเกมของคุณ (ปกติจะเป็น leaderstats หรือ PlayerGui)
    local stats = LP:FindFirstChild("leaderstats")
    if stats and stats:FindFirstChild("Money") then
        return stats.Money.Value
    elseif LP.PlayerGui:FindFirstChild("GameGui") then
        -- กรณีเงินอยู่ใน UI
        local moneyText = LP.PlayerGui.GameGui.MoneyLabel.Text
        return tonumber(moneyText:gsub("%D", "")) or 0
    end
    return 0
end

-- === [ Tabs ] ===
local Main = Window:CreateTab("Macro", 4483362458)
local StatusTab = Window:CreateTab("Status", 4483362458)

local NextLabel = StatusTab:CreateLabel("Next: Waiting...")
local MoneyLabel = StatusTab:CreateLabel("Money Status: -")

-- === [ ⚡ ระบบ Auto-Capture (Hybrid) ] ===
local oldInvoke
oldInvoke = hookfunction(B_Query.InvokeServer, function(self, ...)
    local args = {...}
    if Recording then
        table.insert(Macro, {
            Args = args,
            Wave = GetWave(),
            RequiredMoney = GetMoney(), -- จำเงินที่ต้องใช้ในตอนนั้น
            Label = "Action #" .. (#Macro + 1)
        })
        Rayfield:Notify({Title="บันทึกแล้ว", Content="จำ Wave และจำนวนเงินแล้ว", Duration=1})
    end
    return oldInvoke(self, ...)
end)

-- === [ UI Controls ] ===

Main:CreateToggle({
   Name = "🔴 บันทึกแบบไฮบริด (Wave + Money)",
   CurrentValue = false,
   Callback = function(v)
      Recording = v
      if v then Macro = {} CurrentActionIndex = 1 end
   end
})

Main:CreateToggle({
   Name = "▶️ เริ่มรันมาโคร (Hybrid Queue)",
   CurrentValue = false,
   Callback = function(v)
      Playing = v
      if v then
          CurrentActionIndex = 1
          task.spawn(function()
              while Playing do
                  local action = Macro[CurrentActionIndex]
                  if not action then 
                      NextLabel:Set("Next: จบงานแล้ว")
                      break 
                  end

                  local currentWave = GetWave()
                  local currentMoney = GetMoney()
                  
                  -- เช็คเงื่อนไข: ถึง Wave หรือยัง? และ เงินพอหรือยัง?
                  if currentWave >= action.Wave then
                      if currentMoney >= action.RequiredMoney then
                          -- เงินพอและถึงเวฟ -> ทำงาน
                          NextLabel:Set("กำลังทำ: " .. action.Label)
                          pcall(function() B_Query:InvokeServer(unpack(action.Args)) end)
                          
                          CurrentActionIndex = CurrentActionIndex + 1 -- ไปลำดับถัดไป
                          task.wait(0.5) -- รอช่วงสั้นๆ ป้องกันรันซ้อน
                      else
                          -- ถึงเวฟแต่เงินยังไม่พอ -> รอเงิน
                          NextLabel:Set("Next: " .. action.Label .. " (รอเงินให้ถึง " .. action.RequiredMoney .. ")")
                          MoneyLabel:Set("ขาดอีก: " .. (action.RequiredMoney - currentMoney))
                      end
                  else
                      -- ยังไม่ถึงเวฟ -> รอเวฟ
                      NextLabel:Set("Next: " .. action.Label .. " (รอ Wave " .. action.Wave .. ")")
                  end
                  
                  task.wait(0.2)
              end
          end)
      end
   end
})

-- === [ File Management ] ===
local FileTab = Window:CreateTab("Files", 4483362458)
FileTab:CreateButton({
   Name = "💾 Save Hybrid Macro",
   Callback = function()
      writefile("RTD_Hybrid_Macro.json", HttpService:JSONEncode(Macro))
      Rayfield:Notify({Title="Success", Content="เซฟไฟล์ไฮบริดแล้ว", Duration=2})
   end
})
FileTab:CreateButton({
   Name = "📂 โหลดไฟล์จาก Workspace",
   Callback = function()
      if isfile("RTD_Hybrid_Macro.json") then
          Macro = HttpService:JSONDecode(readfile("RTD_Hybrid_Macro.json"))
          Rayfield:Notify({Title="Success", Content="โหลดข้อมูลมาโครสำเร็จ!", Duration=2})
      else
          Rayfield:Notify({Title="Error", Content="ไม่พบไฟล์เซฟใน Workspace", Duration=2})
      end
   end
})
