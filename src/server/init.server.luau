-- Dig to the Center of the Earth: server owns rewards, tools and progression.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local old = Workspace:FindFirstChild("Baseplate")
if old then old:Destroy() end
local world = Instance.new("Folder")
world.Name = "EarthExpedition"
world.Parent = Workspace
local remote = Instance.new("RemoteEvent")
remote.Name = "EarthAction"
remote.Parent = ReplicatedStorage
local states = {}
local layers = {
 {name="TOPSOIL", color=Color3.fromRGB(119,82,54), value=5},
 {name="STONE", color=Color3.fromRGB(112,125,143), value=9},
 {name="CRYSTAL CAVERNS", color=Color3.fromRGB(124,87,196), value=15},
 {name="MOLTEN MANTLE", color=Color3.fromRGB(211,85,43), value=23},
 {name="OUTER CORE", color=Color3.fromRGB(239,156,40), value=34},
 {name="INNER CORE", color=Color3.fromRGB(255,218,104), value=50},
}
local function part(name, size, position, color, material)
 local p = Instance.new("Part")
 p.Name=name; p.Size=size; p.Position=position; p.Color=color
 p.Material=material or Enum.Material.SmoothPlastic; p.Anchored=true
 p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=world
 return p
end
local function label(p, text)
 local gui=Instance.new("BillboardGui")
 gui.Size=UDim2.fromOffset(330,65); gui.StudsOffset=Vector3.new(0,6,0)
 gui.AlwaysOnTop=true; gui.MaxDistance=140; gui.Parent=p
 local t=Instance.new("TextLabel")
 t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1
 t.Text=text; t.TextColor3=Color3.new(1,1,1); t.TextStrokeTransparency=0.4
 t.Font=Enum.Font.GothamBold; t.TextScaled=true; t.Parent=gui
end
part("Surface",Vector3.new(180,8,180),Vector3.new(0,-4,0),Color3.fromRGB(70,136,86),Enum.Material.Grass)
local spawn=Instance.new("SpawnLocation")
spawn.Size=Vector3.new(10,1,10); spawn.Position=Vector3.new(0,1,25)
spawn.Anchored=true; spawn.Neutral=true; spawn.Color=Color3.fromRGB(68,209,189)
spawn.Parent=world
local sign=part("ExpeditionSign",Vector3.new(35,9,2),Vector3.new(0,7,-30),Color3.fromRGB(23,39,57))
label(sign,"DIG TO THE CENTER\nOF THE EARTH")
local station=part("UpgradeStation",Vector3.new(12,3,12),Vector3.new(24,1.5,20),Color3.fromRGB(49,181,203),Enum.Material.Neon)
label(station,"PICKAXE LAB\nUse UPGRADE on your screen")
local minePad=part("MineEntrance",Vector3.new(18,1,18),Vector3.new(0,0.6,0),Color3.fromRGB(88,64,45))
label(minePad,"YOUR EXPEDITION\nPress DIG to begin")
-- Each explorer gets a separate tunnel. Digging is button driven for mobile and desktop.
local function buildLane(index)
 local x=250+index*36
 local blocks={}
 for depth=1,60 do
  local layer=layers[math.ceil(depth/10)]
  local y=-(depth-1)*7
  blocks[depth]=part("Stratum_"..depth,Vector3.new(24,6,24),Vector3.new(x,y,0),layer.color,Enum.Material.Slate)
 end
 part("CoreChamber",Vector3.new(28,3,28),Vector3.new(x,-423,0),Color3.fromRGB(255,185,50),Enum.Material.Neon)
 for _,offset in ipairs({Vector3.new(-14,-205,0),Vector3.new(14,-205,0),Vector3.new(0,-205,-14),Vector3.new(0,-205,14)}) do
  local size=math.abs(offset.X)>0 and Vector3.new(2,450,28) or Vector3.new(28,450,2)
  part("TunnelWall",size,Vector3.new(x,0,0)+offset,Color3.fromRGB(30,35,47))
 end
 return x,blocks
end
local function snapshot(player, message)
 local s=states[player]
 if not s then return end
 remote:FireClient(player,{coins=s.coins,depth=s.depth*100,level=s.level,cost=math.floor(35*1.65^(s.level-1)),
  layer=layers[math.min(6,math.floor(s.depth/10)+1)].name,hits=s.hits,goal=s.depth<60 and (2+math.floor(s.depth/10)) or 0,
  won=s.depth>=60,message=message or ""})
end
local function moveTo(player, position)
 local character=player.Character
 if character then character:PivotTo(CFrame.new(position)) end
end
local nextLane=0
Players.PlayerAdded:Connect(function(player)
 nextLane+=1
 local x,blocks=buildLane(nextLane)
 states[player]={coins=0,depth=0,level=1,hits=0,last=0,x=x,blocks=blocks,underground=false}
 local stats=Instance.new("Folder"); stats.Name="leaderstats"; stats.Parent=player
 local depth=Instance.new("IntValue"); depth.Name="Depth"; depth.Parent=stats
 local coins=Instance.new("IntValue"); coins.Name="Coins"; coins.Parent=stats
 player.CharacterAdded:Connect(function()
  task.wait(0.2)
  local s=states[player]
  if not s then return end
  s.underground=false
  snapshot(player,"Welcome, explorer! Dig down 6,000 meters to reach the core.")
 end)
end)
Players.PlayerRemoving:Connect(function(player)
 local s=states[player]
 if s then
  for _,block in pairs(s.blocks) do block:Destroy() end
 end
 states[player]=nil
end)
remote.OnServerEvent:Connect(function(player,action)
 local s=states[player]
 if not s or typeof(action)~="string" then return end
 if action=="Sync" then snapshot(player); return end
 if os.clock()-s.last<0.16 then return end
 s.last=os.clock()
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not humanoid or humanoid.Health<=0 or not root then return end
 local message=""
 if action=="Surface" then
  s.underground=false; moveTo(player,Vector3.new(0,5,25)); message="Back at expedition camp. Your tunnel is saved this session."
 elseif action=="Upgrade" then
  local cost=math.floor(35*1.65^(s.level-1))
  if s.level>=12 then message="Your pickaxe is at maximum power!"
  elseif s.coins<cost then message="Dig for more coins to upgrade your pickaxe."
  else s.coins-=cost; s.level+=1; message="Pickaxe upgraded! Power +1." end
 elseif action=="Dig" and s.depth<60 then
  if not s.underground or math.abs(root.Position.X-s.x)>18 then
   s.underground=true
   moveTo(player,Vector3.new(s.x,8-s.depth*7,0))
   message="You entered your tunnel. Keep digging!"
  else
   s.hits+=s.level
   local required=2+math.floor(s.depth/10)
   if s.hits>=required then
    s.hits=0; s.depth+=1
    local layer=layers[math.ceil(s.depth/10)]
    local reward=layer.value
    if s.depth%5==0 then reward*=3; message="TREASURE VEIN! Bonus coins +"..reward end
    s.coins+=reward
    s.blocks[s.depth]:Destroy()
    -- Teleport to each new floor to prevent long fall damage and keep progression deterministic.
    moveTo(player,Vector3.new(s.x,8-s.depth*7,0))
    if s.depth%10==0 and s.depth<60 then message="NEW LAYER: "..layers[s.depth/10+1].name end
    if s.depth==60 then
     s.coins+=1000
     message="YOU REACHED THE CENTER OF THE EARTH! +1,000 coins!"
    end
   end
  end
 end
 player.leaderstats.Depth.Value=s.depth*100
 player.leaderstats.Coins.Value=s.coins
 snapshot(player,message)
end)
