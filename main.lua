-- [[ ตรวจสอบการโหลด Rayfield ]]
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("ไม่สามารถโหลด Rayfield UI ได้! กรุณาเช็คอินเทอร์เน็ตหรือ URL")
    return
end

local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local LP = game:GetService("Players").LocalPlayer

-- === [ Variables ] ===
local Macro = {}
local Recording = false
local Playing = false
local CurrentActionIndex = 1
local TargetRemote = nil -- ตัวแปรเก็บ Remote ที่ใช้ส่งข้อมูล

-- === [ ฟังก์ชันหา Remote อัตโนมัติ ] ===
-- ระบบจะพยายามหา RemoteFunction หรือ RemoteEvent ที่เกมใช้ส่งข้อมูล
local function FindRemote()
    -- ลองหาชื่อยอดนิยมในเกมแนว Tower Defense
    local names = {"ByteNetQuery", "RemoteFunction", "GameRemote", "Network"}
    for _, name in pairs(names) do
        local found = RS:FindFirstChild(name)
        if found then return found end
    end
    return nil
end

TargetRemote = FindRemote()

-- === [ UI Window ] ===
local Window = Rayfield:CreateWindow({
   Name = "RTD | HYBRID PRO V25",
   LoadingTitle = "Starting Hybrid System...",
   ConfigurationSaving = { Enabled = false }
})

-- === [ Tabs ] ===
local Main = Window:CreateTab("Main", 4483362458)
local FileTab = Window:CreateTab("Files", 4483362458)

local StatusLabel = Main:CreateLabel("Status: Ready")
local CountLabel = Main:CreateLabel("Recorded: 0 Actions")

-- === [ Logic Functions ] ===
local function GetWave()
    local w = workspace:FindFirstChild("Wave") or RS:FindFirstChild("Wave")
    return (w and w.Value) or 0
end

local function GetMoney()
    local s = LP:FindFirstChild("leaderstats")
    if s and s:FindFirstChild("Money") then return s.Money.Value end
    return 0
end

-- === [ ⚡ ระบบดักจับ (Hooking) ] ===
if TargetRemote and TargetRemote:IsA("RemoteFunction") then
    local oldInvoke
    oldInvoke = hookfunction(TargetRemote.InvokeServer, function(self, ...)
        local args = {...}
        if Recording then
            table.insert(Macro, {
                Args = args,
                Wave = GetWave(),
                Money = GetMoney(),
                Label = "Action #" .. (#Macro + 1)
            })
            Rayfield:Notify({Title="บันทึกแล้ว!", Content="บันทึกการกระทำที่ "..#Macro, Duration=1})
            CountLabel:Set("Recorded: " .. #Macro .. " Actions")
        end
        return oldInvoke(self, ...)
    end)
else
    Rayfield:Notify({Title="Warning", Content="ไม่พบ Remote สำหรับบันทึกอัตโนมัติ", Duration=5})
end

-- === [ UI Controls ] ===

Main:CreateToggle({
   Name = "🔴 เริ่มบันทึก (Recording)",
   CurrentValue = false,
   Callback = function(v)
      Recording = v
      if v then
          Macro = {}
          CountLabel:Set("Recorded: 0 Actions")
          Rayfield:Notify({Title="System", Content="เริ่มการบันทึก... กรุณาวางยูนิต", Duration=2})
      else
          Rayfield:Notify({Title="System", Content="หยุดบันทึก! ทั้งหมด: "..#Macro.." รายการ", Duration=3})
      end
   end
})

Main:CreateToggle({
   Name = "▶️ รันมาโคร (Auto Play)",
   CurrentValue = false,
   Callback = function(v)
      Playing = v
      if v then
          CurrentActionIndex = 1
          task.spawn(function()
              while Playing do
                  local action = Macro[CurrentActionIndex]
                  if not action then 
                      StatusLabel:Set("Status: ✅ จบการทำงาน")
                      break 
                  end

                  if GetWave() >= action.Wave and GetMoney() >= action.Money then
                      StatusLabel:Set("Status: 🚀 กำลังทำ "..action.Label)
                      pcall(function()
                          TargetRemote:InvokeServer(unpack(action.Args))
                      end)
                      CurrentActionIndex = CurrentActionIndex + 1
                      task.wait(0.5)
                  else
                      StatusLabel:Set("Status: ⏳ รอเงิน/เวฟ ("..action.Label..")")
                  end
                  task.wait(0.2)
              end
          end)
      end
   end
})

-- === [ File Management ] ===
FileTab:CreateButton({
   Name = "💾 Save to File",
   Callback = function()
      writefile("RTD_Macro_V25.json", HttpService:JSONEncode(Macro))
      Rayfield:Notify({Title="Saved", Content="บันทึกลงเครื่องแล้ว", Duration=2})
   end
})

FileTab:CreateButton({
   Name = "📂 Load from File",
   Callback = function()
      if isfile("RTD_Macro_V25.json") then
          Macro = HttpService:JSONDecode(readfile("RTD_Macro_V25.json"))
          CountLabel:Set("Recorded: " .. #Macro .. " Actions")
          Rayfield:Notify({Title="Loaded", Content="โหลดไฟล์สำเร็จ", Duration=2})
      else
          Rayfield:Notify({Title="Error", Content="ไม่พบไฟล์เซฟ", Duration=2})
      end
   end
})
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
