local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local event=RS:WaitForChild("MysteryAction")
local C=require(RS.Shared.MysteryConfig)
local state=nil; local page=nil; local spectating=false; local spectateIndex=1; local currency="coins"
local gui=Instance.new("ScreenGui"); gui.Name="MysteryHUD"; gui.ResetOnSpawn=false; gui.Parent=player:WaitForChild("PlayerGui")
local function roundCorner(o) Instance.new("UICorner",o).CornerRadius=UDim.new(0,10) end
local function label(parent,text,size,pos,height)
 local t=Instance.new("TextLabel"); t.Size=UDim2.new(1,-20,0,height or 30); t.Position=pos or UDim2.fromOffset(10,0)
 t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBold; t.TextSize=size or 16; t.TextColor3=Color3.fromRGB(232,238,250)
 t.TextWrapped=true; t.Text=text; t.Parent=parent; return t
end
local function button(parent,text,callback,color)
 local b=Instance.new("TextButton"); b.Size=UDim2.new(1,-16,0,44); b.BackgroundColor3=color or Color3.fromRGB(51,78,112)
 b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.GothamBold; b.TextSize=14; b.TextWrapped=true; b.Text=text; b.Parent=parent
 roundCorner(b); b.Activated:Connect(callback); return b
end
local header=Instance.new("Frame"); header.Size=UDim2.new(0.94,0,0,110); header.Position=UDim2.fromScale(0.03,0.02)
header.BackgroundColor3=Color3.fromRGB(21,28,44); header.Parent=gui; roundCorner(header)
label(header,C.Title,23,UDim2.fromOffset(10,4))
local status=label(header,"Connecting…",16,UDim2.fromOffset(10,38))
local wallet=label(header,"",14,UDim2.fromOffset(10,74),25)
local toast=label(gui,"",16,UDim2.new(0.05,0,1,-96),70); toast.Size=UDim2.new(0.9,0,0,65)
local menu=Instance.new("Frame"); menu.Size=UDim2.fromOffset(126,255); menu.Position=UDim2.new(0.02,0,0.5,-90)
menu.BackgroundTransparency=1; menu.Parent=gui
local menuLayout=Instance.new("UIListLayout"); menuLayout.Padding=UDim.new(0,8); menuLayout.Parent=menu
local modal=Instance.new("Frame"); modal.Size=UDim2.new(0.7,0,0.62,0); modal.Position=UDim2.fromScale(0.27,0.24)
modal.BackgroundColor3=Color3.fromRGB(24,32,49); modal.Visible=false; modal.Parent=gui; roundCorner(modal)
local title=label(modal,"",19,UDim2.fromOffset(10,6),36)
local list=Instance.new("ScrollingFrame"); list.Size=UDim2.new(1,-16,1,-55); list.Position=UDim2.fromOffset(8,48)
list.BackgroundTransparency=1; list.BorderSizePixel=0; list.ScrollBarThickness=6; list.AutomaticCanvasSize=Enum.AutomaticSize.Y; list.CanvasSize=UDim2.new(); list.Parent=modal
local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,8); layout.Parent=list
local function row(text,callback,color)
 if callback then return button(list,text,callback,color) end
 local t=label(list,text,14,nil,55); t.Position=UDim2.new(); return t
end
local render
local function cameraReset()
 local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if h then workspace.CurrentCamera.CameraSubject=h end
end
local function updateSpectate()
 if not spectating or not state or state.alive then cameraReset(); return end
 local targets=state.targets
 if #targets==0 then cameraReset(); return end
 spectateIndex=(spectateIndex-1)%#targets+1
 local target=Players:GetPlayerByUserId(targets[spectateIndex].id)
 local h=target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
 if h then workspace.CurrentCamera.CameraSubject=h end
end
render=function()
 for _,child in ipairs(list:GetChildren()) do if child~=layout then child:Destroy() end end
 modal.Visible=page~=nil
 if not page or not state then return end
 title.Text=page.."  •  click its menu button to close"
 if page=="SHOP" then
  row("Currency: "..string.upper(currency).." — tap to change",function() currency=currency=="coins" and "gems" or "coins"; render() end)
  row("CASE ODDS: Common 65% • Uncommon 23% • Rare 10% • Legendary 1.9% • Unique 0.1%. Duplicates possible.")
  if not state.paidRandomAllowed then row("Gem cases unavailable for this account. Earned-coin cases are available.") end
  for _,kind in ipairs({"Knife","Gun"}) do
   local boxes=kind=="Knife" and C.KnifeBoxes or C.GunBoxes
   for i,name in ipairs(boxes) do
    row(name.." "..kind.." Box — "..(currency=="coins" and C.CaseCoins.." coins" or C.CaseGems.." gems"),function() event:FireServer("Case",kind,i,currency) end)
   end
  end
  for _,kind in ipairs({"Emote","Radio","Pet"}) do
   local catalog=kind=="Emote" and C.Emotes or kind=="Radio" and C.Radios or C.Pets
   local names={}; for name in pairs(catalog) do table.insert(names,name) end; table.sort(names)
   for _,name in ipairs(names) do row(kind..": "..name.." — "..catalog[name].." coins",function() event:FireServer("Buy",kind,name) end) end
  end
 elseif page=="INVENTORY" then
  row("Tap owned skins to equip for future rounds. Tap emotes to perform them. Radios are cosmetic; pets follow you.")
  local items={}; for id in pairs(state.items) do table.insert(items,id) end; table.sort(items)
  if #items==0 then row("Your inventory is empty. You start with 500 coins: try a case!") end
  for _,id in ipairs(items) do
   local kind=string.match(id,"^(%a+):"); local tier=tonumber(string.match(id,":(%d+)$"))
   local color=tier and C.Rarities[tier].color or Color3.fromRGB(51,78,112)
   local equipped=state.equipped[kind]==id and " [EQUIPPED]" or ""
   row(string.gsub(id,":"," / ").." ×"..state.items[id]..equipped,function() event:FireServer("Equip",id) end,color)
  end
 elseif page=="VOTE" then
  row(state.phase=="Voting" and "Choose one map. Most votes wins; ties are random." or "Voting opens before the next round.")
  for i,name in ipairs({"Moonlit Manor","Research Lab","Cargo Depot"}) do
   row(name.." — "..state.votes[i].." votes",function() event:FireServer("Vote",i) end)
  end
 elseif page=="SPECTATE" then
  if state.alive then row("Spectating is available after elimination or while in the lobby.")
  elseif #state.targets==0 then row("No active players to spectate.")
  else
   row(spectating and "Stop spectating" or "Start spectating",function() spectating=not spectating; updateSpectate(); render() end)
   row("Next player →",function() spectateIndex+=1; updateSpectate(); render() end)
   local target=state.targets[(spectateIndex-1)%#state.targets+1]
   row("Watching: "..target.name)
  end
 elseif page=="GEMS" then
  row("Gems open weapon cases where permitted. Paid cases use the same disclosed odds. Purchases use Roblox's checkout.")
  local any=false
  for id,amount in pairs(C.Products) do
   any=true; row("Buy "..amount.." gems — price shown by Roblox",function() event:FireServer("Gems",id) end)
  end
  if not any then row("Gem sales are not live yet. The owner must configure Roblox developer products first.") end
 end
end
for _,name in ipairs({"SHOP","INVENTORY","VOTE","SPECTATE","GEMS"}) do
 button(menu,name,function() page=page==name and nil or name; render() end)
end
local attackButton=button(gui,"ATTACK / SHOOT",function()
 local char=player.Character; local h=char and char:FindFirstChildOfClass("Humanoid")
 local tool=char and char:FindFirstChildOfClass("Tool") or player.Backpack:FindFirstChildOfClass("Tool")
 if tool and h then h:EquipTool(tool) end
 local camera=workspace.CurrentCamera; local ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
 event:FireServer("Attack",ray.Origin+ray.Direction*200)
end,Color3.fromRGB(156,51,66))
attackButton.Size=UDim2.fromOffset(145,52); attackButton.Position=UDim2.new(1,-160,1,-150); attackButton.Visible=false
local crosshair=label(gui,"+",25,UDim2.new(0.5,-15,0.5,-15),30); crosshair.Size=UDim2.fromOffset(30,30); crosshair.Visible=false
local mouse=player:GetMouse()
local function wireCharacter(char)
 cameraReset()
 char.ChildAdded:Connect(function(child)
  if child:IsA("Tool") then child.Activated:Connect(function() event:FireServer("Attack",mouse.Hit.Position) end) end
 end)
end
player.CharacterAdded:Connect(wireCharacter); if player.Character then wireCharacter(player.Character) end
event.OnClientEvent:Connect(function(s)
 state=s
 local mins=math.floor(s.time/60); local secs=s.time%60
 status.Text=s.phase.."  |  "..string.format("%d:%02d",mins,secs).."  |  "..s.role
 wallet.Text=s.coins.." coins  •  "..s.gems.." gems"..(s.saving and "" or "  •  session-only progress")
 attackButton.Visible=s.phase=="Round" and s.alive and s.role~="Innocent"
 crosshair.Visible=attackButton.Visible
 if s.message~="" then toast.Text=s.message end
 if s.alive then spectating=false end
 updateSpectate()
 if page then render() end
end)
event:FireServer("Sync")
