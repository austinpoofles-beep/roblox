local Rules=require("../src/shared/MysteryRules")
local checks=0
local function check(value,message) checks+=1; assert(value,message) end
local roles={killer="Murderer",sheriff="Sheriff",innocent="Innocent"}
check(Rules.outcome({killer=true,sheriff=true,innocent=true},roles)==nil,"Round must continue with living opposition")
check(Rules.outcome({sheriff=true,innocent=true},roles)=="Innocents","Killer death ends the round")
check(Rules.outcome({killer=true},roles)=="Murderer","Last killer wins")
check(Rules.outcome({killer=true,innocent=true},roles)==nil,"Sheriff death alone must not end the round")
check(Rules.canPickup("Round",true,"Innocent",5),"Living innocents can pick up gun")
for _,role in ipairs({"Murderer","Sheriff","Hero"}) do check(not Rules.canPickup("Round",true,role,5),role.." cannot pick up gun") end
check(not Rules.canPickup("Round",false,"Innocent",5),"Dead player cannot pick up gun")
check(not Rules.canPickup("Voting",true,"Innocent",5),"No lobby pickup")
check(not Rules.canPickup("Round",true,"Innocent",12),"No remote pickup")
local profiles={a=true,b=true,c=true}
check(Rules.chooseMap({a=2,b=2,c=1},profiles,function() return 1 end)==2,"Most votes must win")
check(Rules.chooseMap({a=1,b=3,departed=3},profiles,function(_,maximum) return maximum end)==3,"Tied votes can choose last tied map")
check(Rules.chooseMap({a=1,b=3,departed=3},profiles,function() return 1 end)==1,"Departed vote must not turn tie into majority")
check(Rules.chooseMap({},profiles,function(_,maximum) return maximum end)==3,"No votes selects from every map")
check(Rules.canCollect("Round",true,0,30),"Living player can collect coins")
check(Rules.canCollect("Round",true,29,30),"Final bag slot can be filled")
check(not Rules.canCollect("Round",true,30,30),"Full bags cannot farm more coins")
check(not Rules.canCollect("Round",false,0,30),"Spectators cannot collect coins")
check(not Rules.canCollect("Voting",true,0,30),"No collection outside rounds")
print(checks.." round-rule checks passed")
