local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Shared.MysteryConfig)
local Shop={}
local category="Knives"
local selected=nil
local function corner(obj) Instance.new("UICorner",obj).CornerRadius=UDim.new(0,8) end
local function text(parent,value,height)
 local t=Instance.new("TextLabel"); t.Size=UDim2.new(1,-12,0,height or 34); t.BackgroundTransparency=1
 t.Text=value; t.TextWrapped=true; t.TextColor3=Color3.fromRGB(237,240,250); t.Font=Enum.Font.GothamBold; t.TextSize=14; t.Parent=parent
 return t
end
local function button(parent,value,callback,color)
 local b=Instance.new("TextButton"); b.Size=UDim2.new(1,-12,0,42); b.Text=value; b.TextWrapped=true
 b.BackgroundColor3=color or Color3.fromRGB(55,72,100); b.TextColor3=Color3.new(1,1,1)
 b.Font=Enum.Font.GothamBold; b.TextSize=14; b.Parent=parent; corner(b); b.Activated:Connect(callback); return b
end
local function preview(parent,kind,color)
 local view=Instance.new("ViewportFrame"); view.Size=UDim2.new(1,-12,0,95); view.BackgroundColor3=Color3.fromRGB(19,26,40)
 view.Parent=parent; corner(view)
 local cam=Instance.new("Camera"); cam.CFrame=CFrame.lookAt(Vector3.new(5,4,6),Vector3.zero); cam.Parent=view; view.CurrentCamera=cam
 local function piece(size,pos,c)
  local p=Instance.new("Part"); p.Size=size; p.Position=pos; p.Anchored=true; p.Color=c; p.Material=Enum.Material.Metal; p.Parent=view
 end
 if kind=="Knife" then
  piece(Vector3.new(0.3,2.8,0.6),Vector3.new(0,0.6,0),color)
  piece(Vector3.new(0.5,1.1,0.5),Vector3.new(0,-1.3,0),Color3.fromRGB(65,48,41))
  piece(Vector3.new(1.5,0.2,0.5),Vector3.new(0,-0.65,0),color)
 elseif kind=="Gun" then
  piece(Vector3.new(0.7,0.8,3),Vector3.new(0,0.5,0),color)
  piece(Vector3.new(0.6,1.6,0.7),Vector3.new(0,-0.6,0.7),Color3.fromRGB(49,52,64))
 else
  piece(Vector3.new(3,2.2,2),Vector3.zero,color)
  piece(Vector3.new(0.3,2.3,2.1),Vector3.zero,Color3.fromRGB(230,185,77))
 end
end
function Shop.render(list,state,send,refresh)
 local tabs=Instance.new("Frame"); tabs.Size=UDim2.new(1,-12,0,98); tabs.BackgroundTransparency=1; tabs.Parent=list
 local grid=Instance.new("UIGridLayout"); grid.CellSize=UDim2.new(1/3,-6,0,44); grid.CellPadding=UDim2.fromOffset(6,6); grid.Parent=tabs
 for _,name in ipairs({"Knives","Guns","Emotes","Radios","Pets","Gems"}) do
  button(tabs,name,function() category=name; selected=nil; refresh() end,category==name and Color3.fromRGB(126,83,166) or nil)
 end
 text(list,"Collect gold coins during rounds • "..C.CaseCoins.." coins or "..C.CaseGems.." gems per case",44)
 if category=="Knives" or category=="Guns" then
  local kind=category=="Knives" and "Knife" or "Gun"
  local boxes=kind=="Knife" and C.KnifeBoxes or C.GunBoxes
  if selected then
   button(list,"← All "..string.lower(category).." cases",function() selected=nil; refresh() end)
   text(list,boxes[selected].." "..kind.." Box — possible rewards",38)
   text(list,"Random reward. Duplicates possible. These skins have equal combat power.",42)
   for tier,rarity in ipairs(C.Rarities) do
    local card=Instance.new("Frame"); card.Size=UDim2.new(1,-12,0,135); card.BackgroundColor3=Color3.fromRGB(33,43,61); card.Parent=list; corner(card)
    local stack=Instance.new("UIListLayout"); stack.HorizontalAlignment=Enum.HorizontalAlignment.Center; stack.Parent=card
    preview(card,kind,rarity.color)
    local caption=text(card,rarity.name.." — "..(rarity.weight/100).."%  |  "..boxes[selected].." "..kind,35); caption.TextColor3=rarity.color
   end
   button(list,"OPEN — "..C.CaseCoins.." COINS (earned free)",function() send("Case",kind,selected,"coins") end,Color3.fromRGB(137,104,34))
   local allowed=state.paidRandomAllowed
   button(list,allowed and "OPEN — "..C.CaseGems.." GEMS" or "Gem cases unavailable for this account",function()
    if allowed then send("Case",kind,selected,"gems") end
   end,allowed and Color3.fromRGB(119,67,155) or Color3.fromRGB(65,65,75))
   button(list,"GET GEMS",function() category="Gems"; selected=nil; refresh() end)
  else
   text(list,"Select a case to preview every rarity and its odds before opening.",42)
   local cards=Instance.new("Frame"); cards.Size=UDim2.new(1,-12,0,math.ceil(#boxes/2)*171); cards.BackgroundTransparency=1; cards.Parent=list
   local layout=Instance.new("UIGridLayout"); layout.CellSize=UDim2.new(0.5,-5,0,161); layout.CellPadding=UDim2.fromOffset(10,10); layout.Parent=cards
   for index,name in ipairs(boxes) do
    local card=Instance.new("Frame"); card.BackgroundColor3=Color3.fromRGB(33,43,61); card.Parent=cards; corner(card)
    local stack=Instance.new("UIListLayout"); stack.HorizontalAlignment=Enum.HorizontalAlignment.Center; stack.Padding=UDim.new(0,4); stack.Parent=card
    preview(card,"Box",Color3.fromHSV(index/#boxes,0.4,0.7))
    button(card,name.." "..kind.." Box\nView rewards",function() selected=index; refresh() end)
   end
  end
 elseif category=="Gems" then
  text(list,"Buy gems through Roblox checkout, then use them to open cases where permitted. Prices appear in checkout.",66)
  local ids={}; for id in pairs(C.Products) do table.insert(ids,id) end; table.sort(ids)
  for _,id in ipairs(ids) do button(list,C.Products[id].." GEMS — Buy",function() send("Gems",id) end,Color3.fromRGB(119,67,155)) end
  if #ids==0 then text(list,"Gem packs are coming soon. The owner must add developer product IDs. You can open cases for free with coins earned in rounds.",95) end
 else
  local kind=category=="Emotes" and "Emote" or category=="Radios" and "Radio" or "Pet"
  local catalog=kind=="Emote" and C.Emotes or kind=="Radio" and C.Radios or C.Pets
  local names={}; for name in pairs(catalog) do table.insert(names,name) end; table.sort(names)
  for _,name in ipairs(names) do
   local owned=state.items[kind..":"..name]~=nil
   button(list,name.." — "..(owned and "OWNED • tap to use" or catalog[name].." coins"),function()
    if owned then send("Equip",kind..":"..name) else send("Buy",kind,name) end
   end)
  end
 end
end
function Shop.reveal(gui,reward)
 local old=gui:FindFirstChild("UnboxedReward"); if old then old:Destroy() end
 local rarity=C.Rarities[reward.tier]; if not rarity then return end
 local frame=Instance.new("Frame"); frame.Name="UnboxedReward"; frame.Size=UDim2.new(0.7,0,0,320)
 frame.AnchorPoint=Vector2.new(0.5,0.5); frame.Position=UDim2.fromScale(0.5,0.5)
 frame.BackgroundColor3=Color3.fromRGB(31,37,55); frame.Active=true; frame.Parent=gui; corner(frame)
 local stroke=Instance.new("UIStroke"); stroke.Color=rarity.color; stroke.Thickness=3; stroke.Parent=frame
 local stack=Instance.new("UIListLayout"); stack.Padding=UDim.new(0,8); stack.HorizontalAlignment=Enum.HorizontalAlignment.Center; stack.Parent=frame
 text(frame,"CASE OPENED!",38)
 preview(frame,reward.kind,rarity.color)
 local caption=text(frame,rarity.name.." "..reward.box.." "..reward.kind,38); caption.TextColor3=rarity.color
 text(frame,"Added to your inventory. Equip it for your next round.",48)
 button(frame,"CONTINUE",function() frame:Destroy() end)
end
return Shop
