local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local remote=ReplicatedStorage:WaitForChild("EarthAction")
local gui=Instance.new("ScreenGui")
gui.Name="EarthExpeditionHUD"; gui.ResetOnSpawn=false; gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
local panel=Instance.new("Frame")
panel.Size=UDim2.new(0.92,0,0,260); panel.Position=UDim2.new(0.04,0,1,-275)
panel.BackgroundColor3=Color3.fromRGB(17,27,43); panel.BackgroundTransparency=0.08; panel.Parent=gui
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,16)
local limit=Instance.new("UISizeConstraint"); limit.MaxSize=Vector2.new(640,260); limit.Parent=panel
local function text(name,y,height,size,color)
 local t=Instance.new("TextLabel"); t.Name=name; t.Position=UDim2.new(0,16,0,y)
 t.Size=UDim2.new(1,-32,0,height); t.BackgroundTransparency=1; t.TextColor3=color or Color3.new(1,1,1)
 t.Font=Enum.Font.GothamBold; t.TextSize=size; t.TextWrapped=true; t.TextXAlignment=Enum.TextXAlignment.Left; t.Parent=panel
 return t
end
text("Title",10,25,19).Text="DIG TO THE CENTER OF THE EARTH"
local stats=text("Stats",42,26,16)
local layer=text("Layer",73,23,14,Color3.fromRGB(104,230,211))
local track=Instance.new("Frame"); track.Position=UDim2.new(0,16,0,104); track.Size=UDim2.new(1,-32,0,10)
track.BackgroundColor3=Color3.fromRGB(49,61,80); track.BorderSizePixel=0; track.Parent=panel
local fill=Instance.new("Frame"); fill.Size=UDim2.fromScale(0,1); fill.BackgroundColor3=Color3.fromRGB(255,183,66); fill.BorderSizePixel=0; fill.Parent=track
local notice=text("Notice",122,48,14,Color3.fromRGB(222,229,243))
notice.Text="Click DIG or press E. Upgrade your pickaxe to dig faster!"
local function button(title,x,width,color,action)
 local b=Instance.new("TextButton"); b.Text=title; b.Position=UDim2.new(x,0,0,184)
 b.Size=UDim2.new(width,-10,0,54); b.BackgroundColor3=color; b.TextColor3=Color3.new(1,1,1)
 b.Font=Enum.Font.GothamBold; b.TextSize=15; b.TextWrapped=true; b.Parent=panel
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,10)
 b.Activated:Connect(function() remote:FireServer(action) end)
 return b
end
local dig=button("DIG [E]",0.025,0.31,Color3.fromRGB(178,102,36),"Dig")
local upgrade=button("UPGRADE",0.35,0.36,Color3.fromRGB(36,126,156),"Upgrade")
button("SURFACE",0.725,0.26,Color3.fromRGB(79,95,121),"Surface")
UserInputService.InputBegan:Connect(function(input,processed)
 if not processed and input.KeyCode==Enum.KeyCode.E then remote:FireServer("Dig") end
end)
remote.OnClientEvent:Connect(function(s)
 stats.Text=string.format("%d / 6,000 m   •   %d coins   •   Pickaxe Lv.%d",s.depth,s.coins,s.level)
 layer.Text=s.won and "EXPEDITION COMPLETE — YOU FOUND THE CORE!" or (s.layer.."  •  Rock: "..s.hits.." / "..s.goal)
 fill.Size=UDim2.fromScale(s.depth/6000,1)
 upgrade.Text=s.level>=12 and "MAX POWER" or ("UPGRADE\n"..s.cost.." coins")
 dig.Text=s.won and "CORE REACHED!" or "DIG [E]"
 if s.message~="" then notice.Text=s.message end
end)
remote:FireServer("Sync")
