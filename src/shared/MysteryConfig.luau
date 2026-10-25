local C = {}
C.Title = "Who's the Killer?"
C.RoundSeconds = 300
C.VoteSeconds = 20
C.MinimumPlayers = 3
C.Rarities = {
 {name="Common",weight=6500,color=Color3.fromRGB(160,160,160)},
 {name="Uncommon",weight=2300,color=Color3.fromRGB(65,145,255)},
 {name="Rare",weight=1000,color=Color3.fromRGB(65,210,115)},
 {name="Legendary",weight=190,color=Color3.fromRGB(245,65,75)},
 {name="Unique",weight=10,color=Color3.fromRGB(255,95,200)},
}
C.KnifeBoxes={"Woodland","Glacier","Solar","Shadow","Ocean","Arcane"}
C.GunBoxes={"Frontier","Neon","Steel","Cosmic"}
C.CaseCoins=250
C.CaseGems=25
C.Products={} -- [Roblox developer product ID] = number of gems; configure before selling gems.
C.Emotes={Wave=100,Cheer=150,Dance=200}
C.Radios={Classic=300,Neon=500}
C.Pets={Fox=400,Cat=350,Orbit=600}
C.StarterCoins=500
function C.roll(roll)
 local cumulative=0
 for index,rarity in ipairs(C.Rarities) do
  cumulative+=rarity.weight
  if roll<=cumulative then return index end
 end
 error("Roll must be within 1..10000")
end
function C.itemId(kind,box,tier)
 return kind..":"..box..":"..tier
end
return C
