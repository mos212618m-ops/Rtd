local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local HttpService = game:GetService("HttpService")

local Window = Rayfield:CreateWindow({
   Name = "RTD | HYBRID PRO V24.1",
   LoadingTitle = "Improved Capture & Notify System",
   ConfigurationSaving = { Enabled = false }
})

-- === [ Variables ] ===
local RS = game:GetService("ReplicatedStorage")
local B_Query = RS:WaitForChild("ByteNetQuery", 15)
local LP = game:GetService("Players").LocalPlayer

local Macro = {}
local Recording = false
local Playing = false
local CurrentActionIndex = 1

-- === [ Helper Functions ] ===
local function GetWave()
    local waveVal = workspace:FindFirstChild("Wave") or RS:FindFirstChild("Wave")
    return (waveVal and waveVal.Value) or 0
end

local function GetMoney()
    local stats = LP:FindFirstChild("leaderstats")
    if stats and stats:FindFirstChild("Money") then return stats.Money.Value end
    return 0
end

-- === [ ⚡ ระบบดักจับการกระทำ (Improved Hook) ] ===
-- หาก B_Query ไม่ทำงาน ให้ตรวจสอบว่าเกมใช้ RemoteEvent หรือ RemoteFunction อื่นหรือไม่
local oldInvoke
oldInvoke = hookfunction(B_Query.InvokeServer, function(self, ...)
    local args = {...}
    if Recording then
        -- บันทึกข้อมูล
        table.insert(Macro, {
            Args = args,
            Wave = GetWave(),
            RequiredMoney = GetMoney(),
            Label = "Action #" .. (#Macro + 1)
        })
        -- แจ้งเตือนทุกครั้งที่กด (เพื่อให้รู้ว่าบันทึกติดไหม)
        Rayfield:Notify({
            Title = "บันทึกสำเร็จ ✅",
            Content = "ลำดับที่: " .. #Macro .. " | Wave: " .. GetWave(),
            Duration = 1
        })
    end
    return oldInvoke(self, ...)
end)

-- === [ UI Tabs ] ===
local Main = Window:CreateTab("Macro Controls", 4483362458)
local StatusTab = Window:CreateTab("Status", 4483362458)

local NextLabel = StatusTab:CreateLabel("Next: Waiting...")
local CountLabel = StatusTab:CreateLabel("Total Actions: 0")

-- === [ 🔴 Toggle บันทึก ] ===
Main:CreateToggle({
   Name = "🔴 เริ่มการบันทึก (Recording)",
   CurrentValue = false,
   Callback = function(v)
      Recording = v
      if v then
          Macro = {} -- ล้างค่าเก่า
          Rayfield:Notify({
              Title = "เริ่มบันทึกแล้ว!",
              Content = "ระบบกำลังดักจับการวางยูนิตของคุณ...",
              Duration = 3
          })
      else
          -- เมื่อกดปิด (หยุดอัด) ให้แจ้งเตือนสรุปผล
          Rayfield:Notify({
              Title = "หยุดการบันทึกแล้ว ⏹️",
              Content = "บันทึกไปทั้งหมด: " .. #Macro .. " การกระทำ",
              Duration = 5
          })
          CountLabel:Set("Total Actions: " .. #Macro)
      end
   end
})

-- === [ ▶️ Toggle รันมาโคร ] ===
Main:CreateToggle({
   Name = "▶️ รันมาโคร (Auto Play)",
   CurrentValue = false,
   Callback = function(v)
      Playing = v
      if v then
          if #Macro == 0 then
              Rayfield:Notify({Title="Error", Content="ไม่มีข้อมูลมาโคร! กรุณาอัดหรือโหลดไฟล์ก่อน", Duration=3})
              return
          end
          
          CurrentActionIndex = 1
          Rayfield:Notify({Title="Started!", Content="เริ่มทำงานลำดับที่ 1 จาก " .. #Macro, Duration=3})
          
          task.spawn(function()
              while Playing do
                  local action = Macro[CurrentActionIndex]
                  if not action then 
                      NextLabel:Set("✅ จบการทำงานทั้งหมดแล้ว")
                      Playing = false
                      break 
                  end

                  local currentWave = GetWave()
                  local currentMoney = GetMoney()

                  -- เงื่อนไข: Wave ถึง และ เงินถึง
                  if currentWave >= action.Wave and currentMoney >= action.RequiredMoney then
                      NextLabel:Set("🚀 กำลังส่งข้อมูล: " .. action.Label)
                      
                      -- พยายามส่งข้อมูลไปที่ Server
                      local success, err = pcall(function()
                          return B_Query:InvokeServer(unpack(action.Args))
                      end)

                      if success then
                          CurrentActionIndex = CurrentActionIndex + 1
                          task.wait(0.7) -- หน่วงเวลาเล็กน้อยเพื่อให้เซิร์ฟเวอร์ตอบรับ
                      else
                          warn("วางไม่สำเร็จ: " .. tostring(err))
                          task.wait(1) -- ถ้า Error ให้รอแป๊บหนึ่งแล้วลองใหม่ใน Loop หน้า
                      end
                  else
                      -- แสดงสถานะการรอ
                      NextLabel:Set("⏳ รอ " .. action.Label .. " (W:" .. action.Wave .. "/M:" .. action.RequiredMoney .. ")")
                  end
                  task.wait(0.3)
              end
          end)
      end
   end
})

-- === [ File Management ] ===
local FileTab = Window:CreateTab("Files", 4483362458)
FileTab:CreateButton({
   Name = "💾 เซฟลงไฟล์",
   Callback = function()
      writefile("RTD_Hybrid_Macro.json", HttpService:JSONEncode(Macro))
      Rayfield:Notify({Title="Saved!", Content="เซฟมาโคร " .. #Macro .. " รายการลงไฟล์แล้ว", Duration=3})
   end
})

FileTab:CreateButton({
   Name = "📂 โหลดจากไฟล์",
   Callback = function()
      if isfile("RTD_Hybrid_Macro.json") then
          Macro = HttpService:JSONDecode(readfile("RTD_Hybrid_Macro.json"))
          CountLabel:Set("Total Actions: " .. #Macro)
          Rayfield:Notify({Title="Loaded!", Content="โหลดมาโคร " .. #Macro .. " รายการแล้ว", Duration=3})
      else
          Rayfield:Notify({Title="Error", Content="ไม่พบไฟล์เซฟ", Duration=3})
      end
   end
})
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
