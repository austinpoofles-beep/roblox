local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local DSS=game:GetService("DataStoreService")
local Marketplace=game:GetService("MarketplaceService")
local PolicyService=game:GetService("PolicyService")
local C=require(RS.Shared.MysteryConfig)
local Rules=require(RS.Shared.MysteryRules)
local W=require(script.World)
local event=Instance.new("RemoteEvent"); event.Name="MysteryAction"; event.Parent=RS
local store=DSS:GetDataStore("WhosTheKiller_v1")
local rng=Random.new()
local profiles,roles,alive,votes,cooldowns={},{},{},{},{}
local phase="Waiting"; local remaining=0; local roundId=0; local mapFolder=nil; local dropped=nil
local finish
local function mergeReceipts(data,old)
 data.receipts=table.clone(data.receipts or {})
 for id,amount in pairs(old and old.receipts or {}) do
  if not data.receipts[id] then data.gems+=amount; data.receipts[id]=amount end
 end
 return data
end
local function profile() return {coins=C.StarterCoins,gems=0,items={},equipped={},receipts={}} end
local function send(p,message)
 local entry=profiles[p]; if not entry then return end
 local targets={}; for player in pairs(alive) do table.insert(targets,{id=player.UserId,name=player.DisplayName}) end
 local totals={0,0,0}; for _,i in pairs(votes) do totals[i]+=1 end
 event:FireClient(p,{phase=phase,time=remaining,role=roles[p] or "Spectator",alive=alive[p]==true,targets=targets,votes=totals,
 coins=entry.data.coins,gems=entry.data.gems,items=entry.data.items,equipped=entry.data.equipped,message=message or "",saving=entry.canSave,paidRandomAllowed=entry.paidRandomAllowed==true})
end
local function broadcast(message) for _,p in ipairs(Players:GetPlayers()) do send(p,message) end end
local function save(p)
 local entry=profiles[p]
 if not entry or not entry.canSave or entry.busy then return end
 entry.busy=true
 local updated
 local ok,err=pcall(function()
  updated=store:UpdateAsync("p"..p.UserId,function(old)
   if not old or old.session==game.JobId or (old.lockUntil or 0)<os.time() then
    local data=mergeReceipts(table.clone(entry.data),old); data.session=game.JobId; data.lockUntil=os.time()+180
    return data
   end
   return nil
  end)
 end)
 entry.busy=false
 if ok and updated then entry.data=mergeReceipts(entry.data,updated) elseif ok then entry.canSave=false end
 if not ok then warn("Profile save failed",p.UserId,err) end
 return ok and updated~=nil
end
local function clearTools(p)
 for _,container in ipairs({p.Backpack,p.Character}) do
  if container then for _,v in ipairs(container:GetChildren()) do if v:IsA("Tool") then v:Destroy() end end end
 end
end
local function root(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end
local function teleport(p,pos)
 if p.Character then p.Character:PivotTo(CFrame.new(pos)) end
end
local function colorFor(p,kind)
 local id=profiles[p] and profiles[p].data.equipped[kind]
 local tier=id and tonumber(string.match(id,":(%d+)$"))
 return C.Rarities[tier or 1].color
end
local function tool(p,kind)
 local t=Instance.new("Tool"); t.Name=kind; t.CanBeDropped=false
 local h=Instance.new("Part"); h.Name="Handle"; h.Size=kind=="Knife" and Vector3.new(0.3,2.5,0.6) or Vector3.new(0.5,0.8,2)
 h.Color=colorFor(p,kind); h.Material=Enum.Material.Metal; h.CanCollide=false; h.Parent=t
 t.Parent=p.Backpack
end
local function checkWin()
 if phase~="Round" then return end
 local outcome=Rules.outcome(alive,roles)
 if outcome=="Innocents" then finish("Innocents win! The killer was stopped.") elseif outcome=="Murderer" then finish("The murderer wins!") end
end
local function dropGun(position)
 if dropped then dropped:Destroy() end
 dropped=W.part(mapFolder,"DroppedSheriffGun",Vector3.new(1,1,3),position,Color3.fromRGB(255,205,75),Enum.Material.Neon)
 local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Pick up sheriff's gun"; prompt.HoldDuration=0.4; prompt.MaxActivationDistance=9; prompt.Parent=dropped
 prompt.Triggered:Connect(function(p)
  local r=root(p)
  if not r or not dropped or not Rules.canPickup(phase,alive[p],roles[p],(r.Position-dropped.Position).Magnitude) then return end
  local gun=dropped; dropped=nil; gun:Destroy(); roles[p]="Hero"; tool(p,"Gun"); send(p,"You picked up the sheriff's gun. Stop the killer!")
 end)
end
local function eliminated(p)
 if not alive[p] then return end
 local r=root(p); local role=roles[p]; alive[p]=nil; clearTools(p)
 if (role=="Sheriff" or role=="Hero") and r and phase=="Round" then dropGun(r.Position) end
 checkWin(); broadcast()
end
finish=function(message)
 if phase~="Round" then return end
 phase="Results"; remaining=8
 for p in pairs(alive) do
  local entry=profiles[p]; if entry then entry.data.coins+=100 end
 end
 broadcast(message)
 for _,p in ipairs(Players:GetPlayers()) do clearTools(p) end
end
local function vote(p,index)
 if phase~="Voting" or not profiles[p] or typeof(index)~="number" or index%1~=0 or index<1 or index>3 then return end
 votes[p]=index; broadcast()
end
W.lobby(vote)
Players.PlayerAdded:Connect(function(p)
 local entry={data=profile(),canSave=false,busy=false}; profiles[p]=entry
 local ok,loaded=pcall(function()
  return store:UpdateAsync("p"..p.UserId,function(old)
   if old and old.session~=game.JobId and (old.lockUntil or 0)>os.time() then return nil end
   local d=old or profile(); d.session=game.JobId; d.lockUntil=os.time()+180; return d
  end)
 end)
 if profiles[p]~=entry then return end
 if ok and loaded then entry.data=loaded; entry.canSave=true end
 local policyOK,policy=pcall(function() return PolicyService:GetPolicyInfoForPlayerAsync(p) end)
 entry.paidRandomAllowed=policyOK and policy.ArePaidRandomItemsRestricted==false
 local function characterAdded(character)
  if alive[p] then eliminated(p) end
  local h=character:WaitForChild("Humanoid")
  h.Died:Connect(function() eliminated(p) end)
  task.wait(0.2)
  teleport(p,Vector3.new(0,5,40)); send(p,entry.canSave and "Welcome to Who's the Killer?" or "Session-only mode: saving unavailable. Paid gem purchases are disabled.")
 end
 p.CharacterAdded:Connect(characterAdded)
 if p.Character then task.spawn(characterAdded,p.Character) end
 send(p)
end)
Players.PlayerRemoving:Connect(function(p)
 eliminated(p); votes[p]=nil
 local deadline=os.clock()+10
 while profiles[p] and profiles[p].busy and os.clock()<deadline do task.wait(0.1) end
 save(p)
 local entry=profiles[p]
 if entry and entry.canSave then pcall(function() store:UpdateAsync("p"..p.UserId,function(old) if old and old.session==game.JobId then old.lockUntil=0; return old end return nil end) end) end
 profiles[p]=nil; roles[p]=nil; cooldowns[p]=nil
end)
local function buyCase(p,kind,index,currency)
 local entry=profiles[p]; local d=entry.data
 local boxes=kind=="Knife" and C.KnifeBoxes or kind=="Gun" and C.GunBoxes
 if not boxes or typeof(index)~="number" or not boxes[index] or index%1~=0 or (currency~="coins" and currency~="gems") then return end
 if currency=="gems" and not entry.paidRandomAllowed then send(p,"Gem cases are unavailable for your account. You can use earned coins."); return end
 local cost=currency=="gems" and C.CaseGems or C.CaseCoins
 if d[currency]<cost then send(p,"Not enough "..currency.."."); return end
 d[currency]-=cost
 local tier=C.roll(rng:NextInteger(1,10000)); local id=C.itemId(kind,boxes[index],tier)
 d.items[id]=(d.items[id] or 0)+1
 send(p,"Unboxed "..C.Rarities[tier].name.." "..boxes[index].." "..kind.."!")
end
local function accessory(p,kind,name)
 local char=p.Character; if not char then return end
 local old=char:FindFirstChild("Mystery"..kind); if old then old:Destroy() end
 local r=root(p); if not r then return end
 local model=Instance.new("Part"); model.Name="Mystery"..kind; model.CanCollide=false; model.Massless=true
 model.Size=kind=="Pet" and Vector3.new(1.7,1.7,1.7) or Vector3.new(1.8,1.2,0.6)
 model.Color=kind=="Pet" and Color3.fromRGB(232,163,102) or Color3.fromRGB(82,164,215)
 model.CFrame=r.CFrame*CFrame.new(kind=="Pet" and Vector3.new(2,-1,1) or Vector3.new(0,0,1))
 model.Parent=char
 local weld=Instance.new("WeldConstraint"); weld.Part0=r; weld.Part1=model; weld.Parent=model
 W.sign(model,name)
end
local function attack(p,targetPosition)
 if phase~="Round" or not alive[p] or typeof(targetPosition)~="Vector3" then return end
 if targetPosition.X~=targetPosition.X or targetPosition.Y~=targetPosition.Y or targetPosition.Z~=targetPosition.Z or targetPosition.Magnitude>100000 then return end
 local role=roles[p]; local char=p.Character; local r=root(p)
 local t=char and char:FindFirstChildOfClass("Tool")
 local kind=role=="Murderer" and "Knife" or (role=="Sheriff" or role=="Hero") and "Gun"
 if not kind or not t or t.Name~=kind or not r then return end
 local now=os.clock(); local key="attack"..p.UserId
 if now-(cooldowns[key] or 0)<(kind=="Knife" and 0.65 or 1.3) then return end
 cooldowns[key]=now
 local origin=r.Position; local direction=targetPosition-origin
 if direction.Magnitude<0.01 then return end
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={char}
 local result=workspace:Raycast(origin,direction.Unit*(kind=="Knife" and 9 or 200),params)
 if not result then return end
 local hit=result.Instance:FindFirstAncestorOfClass("Model"); local victim=hit and Players:GetPlayerFromCharacter(hit)
 if not victim or not alive[victim] or victim==p then return end
 if kind=="Gun" and roles[victim]~="Murderer" then
  local h=char:FindFirstChildOfClass("Humanoid"); if h then h.Health=0 end
  send(p,"You shot an innocent. You are eliminated."); return
 end
 local h=hit:FindFirstChildOfClass("Humanoid"); if h then h.Health=0 end
end
event.OnServerEvent:Connect(function(p,action,a,b,c)
 local entry=profiles[p]; if not entry or typeof(action)~="string" then return end
 if action=="Attack" then attack(p,a); return end
 local now=os.clock()
 if now-(cooldowns[p] or 0)<0.15 then return end
 cooldowns[p]=now
 if action=="Sync" then send(p)
 elseif action=="Vote" then vote(p,a)
 elseif action=="Case" and not entry.busy then buyCase(p,a,b,c)
 elseif action=="Buy" and not entry.busy then
  local catalog=a=="Emote" and C.Emotes or a=="Radio" and C.Radios or a=="Pet" and C.Pets
  local cost=catalog and catalog[b]; local id=typeof(b)=="string" and (tostring(a)..":"..b)
  if not cost then return end
  if entry.data.items[id] then send(p,"You already own this item."); return end
  if entry.data.coins<cost then send(p,"Not enough coins."); return end
  entry.data.coins-=cost; entry.data.items[id]=1; send(p,"Purchased "..b.."!")
 elseif action=="Equip" and not entry.busy then
  if typeof(a)~="string" or not entry.data.items[a] then return end
  local kind,name=string.match(a,"^(%a+):([^:]+)")
  if kind=="Knife" or kind=="Gun" then entry.data.equipped[kind]=a; send(p,"Skin equipped for your next weapon.")
  elseif kind=="Radio" or kind=="Pet" then
   entry.data.equipped[kind]=a; accessory(p,kind,name); send(p,name.." equipped.")
  elseif kind=="Emote" then
   local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
   if h then pcall(function() h:PlayEmote(string.lower(name)) end) end
  end
 elseif action=="Gems" then
  if not entry.canSave or entry.busy then send(p,"Publish the game and enable data saving before buying gems."); return end
  local id=tonumber(a)
  if id and C.Products[id] then Marketplace:PromptProductPurchase(p,id) else send(p,"Gem purchases are not configured yet.") end
 end
end)
Marketplace.ProcessReceipt=function(receipt)
 local p=Players:GetPlayerByUserId(receipt.PlayerId)
 local entry=p and profiles[p]; local amount=C.Products[receipt.ProductId]
 if not entry or not entry.canSave or entry.busy or not amount then return Enum.ProductPurchaseDecision.NotProcessedYet end
 entry.busy=true
 local updated
 local ok=pcall(function()
  updated=store:UpdateAsync("p"..p.UserId,function(old)
   if not old or old.session~=game.JobId then return nil end
   local data=mergeReceipts(table.clone(entry.data),old)
   if not data.receipts[receipt.PurchaseId] then
    data.gems+=amount; data.receipts[receipt.PurchaseId]=amount
   end
   data.session=game.JobId; data.lockUntil=os.time()+180
   return data
  end)
 end)
 entry.busy=false
 if ok and updated then entry.data=mergeReceipts(entry.data,updated); send(p,"Gems added to your inventory!"); return Enum.ProductPurchaseDecision.PurchaseGranted end
 return Enum.ProductPurchaseDecision.NotProcessedYet
end
local function eligible()
 local list={}
 for _,p in ipairs(Players:GetPlayers()) do
  local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  if profiles[p] and root(p) and h and h.Health>0 then table.insert(list,p) end
 end
 return list
end
local function waitPhase(seconds)
 for n=seconds,1,-1 do remaining=n; broadcast(); task.wait(1) end
end
task.spawn(function()
 while true do
  phase="Waiting"; remaining=0; broadcast("Waiting for at least 3 players. Explore the safe zone!")
  repeat task.wait(1) until #eligible()>=C.MinimumPlayers
  phase="Voting"; votes={}; broadcast("Vote for the next map in the voting room or VOTE menu.")
  waitPhase(C.VoteSeconds)
  local list=eligible()
  if #list<C.MinimumPlayers then continue end
  local selected=Rules.chooseMap(votes,profiles,function(a,b) return rng:NextInteger(a,b) end)
  local spawns
  mapFolder,spawns=W.map(selected)
  for i=#list,2,-1 do local j=rng:NextInteger(1,i); list[i],list[j]=list[j],list[i] end
  roundId+=1; roles={}; alive={}; phase="Round"; remaining=C.RoundSeconds
  for i,p in ipairs(list) do
   roles[p]=i==1 and "Murderer" or i==2 and "Sheriff" or "Innocent"; alive[p]=true
   clearTools(p); teleport(p,spawns[(i-1)%#spawns+1])
   local shield=p.Character:FindFirstChildOfClass("ForceField"); if shield then shield:Destroy() end
   if i==1 then tool(p,"Knife") elseif i==2 then tool(p,"Gun") end
   send(p,W.MapNames[selected].." — Your role: "..roles[p])
  end
  while phase=="Round" and remaining>0 do
   task.wait(1); remaining-=1
   for p in pairs(alive) do
    local r=root(p)
    if not r or r.Position.Y< -30 or math.abs(r.Position.X)>85 or math.abs(r.Position.Z-500)>85 then
     local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid"); if h then h.Health=0 else eliminated(p) end
    end
   end
   broadcast()
  end
  if phase=="Round" then finish("Time is up! The innocents survived.") end
  waitPhase(8)
  alive={}; roles={}
  for _,p in ipairs(Players:GetPlayers()) do clearTools(p); teleport(p,Vector3.new(0,5,40)) end
  if mapFolder then mapFolder:Destroy(); mapFolder=nil end
  dropped=nil
 end
end)
task.spawn(function()
 while task.wait(60) do for p in pairs(profiles) do task.spawn(save,p) end end
end)
game:BindToClose(function()
 for p in pairs(profiles) do task.spawn(save,p) end
 task.wait(5)
end)
