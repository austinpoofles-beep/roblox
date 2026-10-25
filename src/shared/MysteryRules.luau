local Rules={}
function Rules.outcome(alive,roles)
 local killer=false; local others=0
 for player in pairs(alive) do
  if roles[player]=="Murderer" then killer=true else others+=1 end
 end
 if not killer then return "Innocents" end
 if others==0 then return "Murderer" end
 return nil
end
function Rules.chooseMap(votes,profiles,choose)
 local totals={0,0,0}
 for player,index in pairs(votes) do if profiles[player] then totals[index]+=1 end end
 local maximum=math.max(table.unpack(totals)); local tied={}
 for index,count in ipairs(totals) do if count==maximum then table.insert(tied,index) end end
 return tied[choose(1,#tied)]
end
function Rules.canPickup(phase,isAlive,role,distance)
 return phase=="Round" and isAlive==true and role=="Innocent" and distance<=11
end
return Rules
