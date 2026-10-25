local W={}
local function part(parent,name,size,pos,color,material)
 local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Position=pos; p.Anchored=true
 p.Material=material or Enum.Material.SmoothPlastic; p.Color=color; p.Parent=parent
 return p
end
W.part=part
function W.sign(p,message)
 local g=Instance.new("BillboardGui"); g.Size=UDim2.fromOffset(280,75); g.StudsOffset=Vector3.new(0,5,0); g.MaxDistance=130; g.Parent=p
 local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Text=message
 t.Font=Enum.Font.GothamBold; t.TextScaled=true; t.TextColor3=Color3.new(1,1,1); t.TextStrokeTransparency=0.3; t.Parent=g
 return t
end
function W.lobby(onVote,onShop)
 local base=workspace:FindFirstChild("Baseplate"); if base then base:Destroy() end
 local f=Instance.new("Folder"); f.Name="SafeZone"; f.Parent=workspace
 part(f,"Courtyard",Vector3.new(150,8,150),Vector3.new(0,-4,0),Color3.fromRGB(48,61,76),Enum.Material.Slate)
 for _,x in ipairs({-70,70}) do part(f,"GardenWall",Vector3.new(3,15,150),Vector3.new(x,5,0),Color3.fromRGB(36,43,58)) end
 part(f,"BackWall",Vector3.new(140,15,3),Vector3.new(0,5,-70),Color3.fromRGB(36,43,58))
 local spawn=Instance.new("SpawnLocation"); spawn.Name="LobbySpawn"; spawn.Anchored=true; spawn.Neutral=true
 spawn.Size=Vector3.new(12,1,12); spawn.Position=Vector3.new(0,1,40); spawn.Parent=f
 local fountain=part(f,"Fountain",Vector3.new(18,3,18),Vector3.new(0,1.5,4),Color3.fromRGB(76,151,174))
 W.sign(fountain,"WHO'S THE KILLER?\nSAFE ZONE")
 part(f,"VotingRoomFloor",Vector3.new(100,1,35),Vector3.new(0,0.5,-42),Color3.fromRGB(75,66,91))
 for index,name in ipairs({"Moonlit Manor","Research Lab","Cargo Depot"}) do
  local board=part(f,name,Vector3.new(23,10,2),Vector3.new((index-2)*30,7,-54),Color3.fromRGB(66,92,127))
  W.sign(board,name.."\nVote here or use VOTE menu")
  local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Vote"; prompt.ObjectText=name; prompt.HoldDuration=0; prompt.MaxActivationDistance=15; prompt.Parent=board
  prompt.Triggered:Connect(function(player) onVote(player,index) end)
 end
 for i,name in ipairs({"WEAPONS & CASES","EMOTES & RADIOS","PET CORNER"}) do
  local p=part(f,name,Vector3.new(14,7,12),Vector3.new(-49,3.5,(i-2)*28),Color3.fromRGB(58,103,107)); W.sign(p,name.."\nOpen SHOP")
  local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Open shop"; prompt.ObjectText=name
  prompt.MaxActivationDistance=15; prompt.HoldDuration=0; prompt.Parent=p
  prompt.Triggered:Connect(onShop)
 end
 return f
end
W.MapNames={"Moonlit Manor","Research Lab","Cargo Depot"}
function W.map(index)
 local f=Instance.new("Folder"); f.Name="ActiveMap"; f.Parent=workspace
 local center=Vector3.new(0,0,500)
 local palette={Color3.fromRGB(103,77,83),Color3.fromRGB(87,122,137),Color3.fromRGB(126,103,69)}
 part(f,"Floor",Vector3.new(150,6,150),center-Vector3.new(0,3,0),palette[index],Enum.Material.Concrete)
 for _,x in ipairs({-75,75}) do part(f,"Wall",Vector3.new(3,24,150),center+Vector3.new(x,12,0),palette[index]) end
 for _,z in ipairs({-75,75}) do part(f,"Wall",Vector3.new(150,24,3),center+Vector3.new(0,12,z),palette[index]) end
 if index==1 then
  for _,x in ipairs({-30,30}) do
   for _,z in ipairs({-45,0,45}) do part(f,"ManorPartition",Vector3.new(3,18,26),center+Vector3.new(x,9,z),palette[index]) end
  end
  for _,z in ipairs({-30,30}) do part(f,"DiningTable",Vector3.new(18,5,8),center+Vector3.new(0,2.5,z),Color3.fromRGB(77,49,35)) end
 elseif index==2 then
  for _,x in ipairs({-42,0,42}) do
   for _,z in ipairs({-35,35}) do
    part(f,"LabBench",Vector3.new(20,6,9),center+Vector3.new(x,3,z),Color3.fromRGB(188,200,209))
    part(f,"Reactor",Vector3.new(6,11,6),center+Vector3.new(x,5.5,z+13),Color3.fromRGB(65,220,190),Enum.Material.Neon)
   end
  end
 else
  for x=-2,2 do for z=-2,2 do
   if (x+z)%2==0 then part(f,"CargoContainer",Vector3.new(17,15,23),center+Vector3.new(x*25,7.5,z*25),Color3.fromRGB(143+x*15,94+z*10,62)) end
  end end
 end
 local spawns={}
 for i=1,12 do
  local angle=i*math.pi/6
  spawns[i]=center+Vector3.new(math.cos(angle)*62,5,math.sin(angle)*62)
 end
 return f,spawns
end
return W
