pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- virulent
-- by wez
-- documentation at
-- https://gist.github.com/wesleywerner/7eb03373f0d7b8c9125a4d557ee7e777

function _init()
 printw(1)
 reset_game()
 switch(intro_screen)
end

function _update()
 if state then
  state.update()
 end
end

function _draw()
 if state then
  state.draw()
 end
end

function can_redraw()
 if redraw then
  redraw=false
  return true
 end
end

function set_redraw()
 redraw=true
end

function switch(s,arg)
 -- params
 --  :new state
 --  :opt arguments
 s.init(arg)
 state=s
end

function goto_menu()
 switch(menu_screen)
end

function goto_command()
 switch(command_screen)
end

function goto_radar()
 switch(radar_screen,true)
end

function goto_region()
 switch(region_screen)
end

function goto_report()
 switch(report_screen)
end

function printw(m,a,b)
end
-->8
-- tables

stats={
  {"canada",         37,   {2, 5}},
  {"united states",  327,  {1, 3}},
  {"mexico",         126,  {2, 4}},
  {"latin america",  640,  {3}},
  {"greenland",      65,   {1, 6}},
  {"scandinavia",    21,   {5,7,8,11}},
  {"western europe", 196,  {6,8,9}},
  {"eastern europe", 147,  {6,7,10,11}},
  {"africa",         1274, {7,10,15,17}},
  {"middle east",    219,  {8,9,11,12}},
  {"russia",         146,  {6,8,10,12,13}},
  {"indian subcon",  1816, {10,11,13}},
  {"east asia",      1678, {11,12,16}},
  {"australia",      25,   {16}},
  {"south africa",   68,   {9,17}},
  {"southeast asia", 668,  {13,14}},
  {"madagascar",     28,   {9,15}}
}

-- up  dn  lt  rt
keymap={
 {nil,  2, 11,  5}, --1  can
 {  1,  3, 11,  7}, --2  us
 {  2,  4, 13,  9}, --3  mex
 {  3,  0, 14, 15}, --4  sa
 {nil,  1,  1,  6}, --5  green
 {nil,  8,  5, 11}, --6  scan
 {  6,  9,  2,  8}, --7  w eu
 {  6,  9,  7, 10}, --8  e eu
 {  8, 15,  3, 10}, --9  af
 { 11,  9,  8, 12}, --10 mid e
 {nil, 10,  8,  2}, --11 rus
 { 11, 16, 10, 13}, --12 ind
 { 11, 16, 12,  2}, --13 e asia
 { 16,  0, 17,  4}, --14 au
 {  9,  0,  4, 17}, --15 za
 { 13, 14, 17,  3}, --16 se asia
 {  9, 15, 15, 14}, --17 mada
}

roids={}

-- [map sprites]
-- spr w  h  x   y
worldspr={
  {0,  4, 2, 2,  6  },
  {32, 4, 2, 1,  17 },
  {64, 2, 2, 2,  26 },
  {96, 3, 5, 16, 38 },
  {4,  3, 2, 34, 0  },
  {36, 2, 1, 58, 6  },
  {7,  2, 2, 51, 11 },
  {9,  2, 2, 62, 12 },
  {67, 4, 5, 47, 23 },
  {38, 2, 2, 71, 22 },
  {40, 8, 3, 67, 3  },
  {11, 2, 2, 85, 23 },
  {87, 4, 3, 88, 14 },
  {13, 3, 2,107, 49 },
  {66, 1, 1, 64, 55 },
  {91, 4, 3, 98, 33 },
  {82, 1, 1, 75, 50 }
}

remlut={
 {"N1", "INTERFERON"},
 {"N2", "VACCINE"},
 {"N3", "X-RAYS"},
 {"N4", "MARTIAL LAW"},
 {"N5", "GAMMA GLOBULIN"},
 {"N6", "BACK FIRE"},
 {"N7", "CLEAN SUITS"},
 {"N8", "GENE SPLICE"},
 {"P1", "CLOUD SEEDING"},
 {"P2", "MICROWAVES"},
 {"P3", "FIRE STORMS"},
 {"P4", "KILLER SATELLITES"}
}

neff={
   {.25                },
   {.05,.3             },
   {.10,.25,.12        },
   {.12,.15,.28,.15    },
   {.28,.18,.05,.05    },
   {.16,.05,.03,.22,.30},
   {.05,.14,.30,.21,.08},
   {  0,  0,  0,.35,.38}
}

peff={
 {.8, .6},
 {.6, .7},
 {.4, .8},
 {.2, .9}
}

curelev={.8,.7,.6,.5}

gstats={
 {1,  250},
 {2, -550},
 {3,  -.5},
 {4,   25},
 {5,   75},
 {6, -100},
 {7,  -60},
 {8,   25},
 {9,  150},
 {10,   0},
 {11, 250},
 {12,   0}
}
-->8
-- world map

function draw_map(spal)
 -- params
 --  :opt palette swop table
 for i=1, #worldspr do
  draw_con(i,spal)
 end
end

function draw_con(i,spal,x,y)
 -- params
 --  :country index
 --  :opt palette swop table
 --  :opt x draw position
 --  :opt y draw position
 local dat=worldspr[i]

 if spal then
  for p in all(spal) do
   pal(p[1],p[2])
  end
 else
  pal(1, get_level_color(stats[i][5],stats[i][7]))
  pal(7, 5)
 end
 
 -- position override
 x=x or dat[4]
 y=y or dat[5]
 
 for iy=0,dat[3]-1 do
  for ix=0,dat[2]-1 do
   spr(
    dat[1]+(iy*16)+ix,
    x+(ix*8),
    y+(iy*8))
  end
 end
 pal()
end

-- pixel perfect land hit
function landhit(x,y)
 -- params
 --  :x/y *screen* coordinates
 -- returns
 --  :country index of impact
 for i,dat in pairs(worldspr) do
  -- point in country bounds?
  local dx=dat[4] --draw offset
  local dw=dx+(dat[2]*8) --width
  local dy=dat[5] --draw offset
  local dh=dy+(dat[3]*8) --height
  if x>dx and x<dw and y>dy and y<dh then
   -- translate pos rel to origin
   local cx=x-dx
   local cy=y-dy
   -- pos in spritesheet
   cx=flr(cx+(dat[1]%16)*8)
   cy=flr(cy+flr(dat[1]/16)*8)
   -- test pixel color
   if sget(cx,cy)>0 then
    return i
   end
  end
 end
end

-->8
-- game logic

function setstat(i,v)
 gstats[i][1]=v
end

function addstat(i)
 gstats[i][1]+=1
end

function getstatv(i)
 -- raw value
 return gstats[i][1]
end

function getstatm(i)
 -- value * multiplier
 if i==11 and getstatv(2)==#stats then
  -- turns remain &
  -- total destruction
  return 0
 end
 return ceil(gstats[i][1]*gstats[i][2])
end

function game_score()
 _l=0
 for i=1,#gstats do
  _l+=getstatm(i)
 end
 return _l
end

function load_stats(i)
 ci=i
 cstat=stats[i]
 
 cname,
 csouls,
 clinks,
 cpop,
 clev,
 peta,
 deta,
 rem,
 ceta,
 remhist,
 _,
 _,
 _,
 _,
 spreadfrom,
 npop,
 nlev,
 npeta,
 ndeta,
 nceta,
 nrem,
 aprsuc=unpack(cstat)
 
 cdead=csouls-cpop
 ispne=deta>0
 ccol=get_level_color(clev,deta)
 clevname=get_level_name(clev,deta)
 clevtxt=max(1,flr(clev))..":"..clevname
 cpoptxt=human_num(cpop,ci==5)
 cdeadtxt=human_num(cdead,ci==5)
 isntype=rem>0 and rem<9 and ceta>0
 isptype=rem>8 and ceta>0
 instasis=clev<2
 
 if rem==0 then
  remcode=""
  remname=""
  remtxt="NONE"
 else
  remcode=remlut[rem][1]
  remname=remlut[rem][2]
  remtxt=remcode..":"..remname
 end
 
 petatxt=human_time(peta)
 detatxt=human_time(deta)
 cetatxt=human_time(ceta)
end

function reset_game()
 ci=9
 skill=skill or 1
 allot_actions()
 turnno=0
 roids={}
 -- country stats
 for con in all(stats) do
  con[4]=con[2]
  con[5]=0
  con[6]=-1
  con[7]=-1
  con[8]=0
  con[9]=0
  for n=10,22 do
   con[n]=false
  end
  --con[15]=0
  con[18]=-1
  con[19]=-1
  con[20]=-1
 end
 -- starting infections
 _o=2+flr(rnd(2))
 if skill>=3 then
  _o+=flr(rnd(2))
 end
 _i=0
 while _i<_o do
  _c=1+flr(rnd(#stats))
  if stats[_c][5]==0 then
   infect(_c)
   _i+=1
  end
 end
 -- game stats
 for n in all(gstats) do
  n[1]=0
 end
end

function infect(i,neig)
 -- params
 --  :country index
 --  :opt from neighbor
 local nlev=2+rnd(1)
 local npeta=4+flr(rnd(4))
 stats[i][5]=nlev
 stats[i][17]=nlev
 stats[i][6]=npeta
 stats[i][18]=npeta
 stats[i][15]=neig or false
 printw(3,i,neig)
 return nlev
end

function set_remedy(i,r)
 -- params
 --  :country index
 --  :remedy index
 stats[i][8]=r
 -- set ceta
 if r<9 then
  -- n-type
  stats[i][9]=#neff[r]
 else
  -- apr
  stats[i][9]=1
 end
 -- clear histogram
 stats[i][10]={}
 actno-=1
 addstat(8)
 printw(4,r,i)
end

function get_level_name(l,d)
 -- params
 --  :level of infection
 --  :deta
 -- notes
 --  p 0 while pneumonic (nil otherwise)
 if (d and d>0) then
  return "PNEUMONIC"
 elseif l==6 then
  return "DESTROYED"
 elseif l>=4 then
  return "CRITICAL"
 elseif l>=3 then
  return "SERIOUS"
 elseif l>=2 then
  return "MILD"
 elseif l>0 then
  return "IN STASIS"
 else
  return "CLEAR"
 end
end

function get_level_color(l,d)
 -- params
 --  :level of infection
 --  :deta
 if (d and d>0) then
  -- pneumonic
  return 8
 elseif l>=6 then
  -- desroyed
  return 0
 elseif l>=4 then
  -- critical
  return 2
 elseif l>=3 then
  -- serious
  return 14
 elseif l>=2 then
  -- mild
  return 10
 elseif l>0 then
  -- stasis
  return 11
 else
  -- clear
  return 3
 end
end

function max_turns(s)
 return 10+(s*5) 
end

function end_condition()
 -- returns 
 --  1:time out
 --  2:all cured
 --  3:all destroyed
 local curedc,popd=0,0
 for i,c in pairs(stats) do
  if c[5]==0 then
   curedc+=1
  end
  if i!=5 then
   popd+=c[2]-c[4]
  end
 end
 gstats[3][1]=popd
 setstat(11,max_turns(skill)-turnno)
 local code=false
 if turnno==max_turns(skill) then
  code=1
 elseif curedc==#stats-gstats[2][1] then
  code=2
 elseif gstats[2][1]==#stats then
  code=3
 end
 setstat(12,code)
 return code
end

function allot_actions()
 actno=(skill>2) and 2 or 3
end

function end_turn()
 turnno+=1
 printw(5)
 allot_actions()
 for i=1,#stats do
  cturn(i)
 end
end

function cturn(i)
 -- params
 --  :country index
 load_stats(i)
 -- not infected
 if clev==0 then return end
 -- already destroyed
 if clev==6 then return end
 printw(6)
 printw(2)
 
 -- increase level by 15%
 -- and up to 0.75%
 -- based on difficulty
 -- dif--------------incr
 --  1 = 0.001875 = .19%
 --  2 = 0.00375  = .38%
 --  3 = 0.005625 = .56%
 --  4 = 0.0075   = .75%
 if not instasis then
  clev=min(5,clev*1.15+(0.001875*skill))
  printw(7)
 end
 
 -- reduce remedy conclusion
 if ceta>0 then
  ceta-=1
  printw(8)
 end

 -- apply remedy
 if isntype then
  printw(9)
  -- remedy factor for ceta
  local rday=#neff[rem]-ceta
  local fact=neff[rem][rday] or 0
  -- vary the amount -15% to 15%
  fact+=rnd({-1,1})*rnd(0.15)
  -- clamp to 40%
  fact=max(0,min(0.4,fact))
  -- 30% chance of no effect
  if instasis and rnd()<0.3 then
   fact=0
  end
  -- apply factor
  clev=clev-(clev*fact)
  -- record factor history
  add(remhist,fact)
  printw(10,rday,fact)
 elseif isptype then
  local pchance=peff[rem-8][1]
  local peffect=peff[rem-8][2]
  printw(11,pchance,peffect)
  if rnd()<pchance then
   -- success
   clev=clev-(clev*peffect)
   aprsuc=true
   addstat(9)
   printw(12)
  else
   -- failure
   aprsuc=false
   addstat(10)
   printw(13)
  end
 else
  -- not ntype nor ptype. clear:
  rem=0
  -- histogram
  stats[i][10]=false
  aprsuc=0
 end
 
 -- re-evaluate
 instasis=clev<2

 -- is cured?
 if clev<curelev[skill] then
  clev=0
  rem=0
  ceta=0
  peta=-1
  deta=-1
  printw(14)
  addstat(1)
 end

 -- clear countdowns
 if instasis then
  peta=-1
  deta=-1
 end
 
 -- becomes pneumonic via:
 --  1) peta counter reaches 0
 --  2) level reaches 5
 if peta>0 then
  peta-=1
  printw(15)
  -- 4+ carries a risk
  -- of expiditing pne
  if clev>4 and rnd(1)<0.05 then
   peta=max(0,peta-1)
   printw(16)
  end
  if peta==0 then
   -- became pneumonic
   clev=5
   rem=0
   ceta=0
   printw(17)
  end
 end
 
 -- reached level 5
 if clev==5 and peta>0 then
  peta=0
  printw(18)
 end

 -- test destruction
 if deta>0 then
  deta-=1
  printw(19)
  if deta==0 then
   clev=6
   printw(20)
   addstat(2)
  end
 end
 
 -- start deta counter
 if peta==0 then
  peta=-1
  deta=5
  printw(21)
 end
 
 -- population loss %
 local loss=clev*0.0314
 -- stasis locked at 3%
 if instasis then
  loss=.0314
 end
 cpop=flr(cpop-(cpop*loss))
 printw(22,loss)
 if (cpop==0 and clev<6) then
  -- destroyed
  clev=6
  printw(23)
  addstat(2)
 end
 
 -- clear flags on destroy
 if clev==6 then
  peta=-1
  deta=-1
  ceta=-1
  rem=0
  cpop=0
 end

 -- spread infection
 if turnno>4 and clev>3 and rnd()<0.20 then
  local ni=clinks[1+flr(rnd()*#clinks)]
  if stats[ni][5]==0 then
   infect(ni,i)
   addstat(7)
  end
 end
 
 -- persist new values
 cstat[16]=cpop
 cstat[17]=clev
 cstat[18]=peta
 cstat[19]=deta
 cstat[20]=ceta
 cstat[21]=rem
 cstat[22]=aprsuc

end
-->8
-- intro screen
intro_screen={}

local function exit_screen()
 music(-1,500)
 clip()
 camera()
 goto_menu()
end

local function curtains(d,t,l,bt)
 if not t then
  print("❎SKIP",1,122,13)
  if d.f then
   print("❎SKIP",1,122,12)
  end
  clip(0,64-d.z,128,d.z*2)
  rectfill(0,0,127,127,0)
 elseif t==0 then
  d.z=0
 elseif bt(1,70) then
  -- open
  d.z=l(0,32)
  -- flash
  d.f=t>40 and flr(t)%2==0
 elseif bt(70,72) then
  -- close
  d.z=l(32,0)
 elseif bt(72,73) then
  exit_screen()
 end
end

local function stars(d,t,l,bt)
 if not t then
  camera(0,d.cy)
  for r in all(d.s) do
   pset(r[1],r[2],r[3])
  end
  camera()
 elseif t==0 then
  d.cy,d.s=0,{}
  local heat={1,5,7}
  for i=1,30 do
   add(d.s,{
    flr(rnd()*127),
    flr(32+rnd()*64),
    heat[1+flr(rnd()*#heat)]})
 end
 elseif bt(1,20) then
  --+x
  for r in all(d.s) do
   r[1]=(r[1]+r[3]*0.05)%127
  end
 elseif bt(20,25) then
  --hide
  d.cy=l(0,-64,2)
 elseif bt(30,34) then
  --reshow
  d.cy=l(64,0,4)
 elseif bt(34,80) then
  for r in all(d.s) do
   r[1]=(r[1]+r[3]*0.05)%127
  end
 end
end

local function earth(d,t,l,bt)
 if not t then
  --earth
  sspr(96,64,16,16,64,d.y,d.s,d.s)
 elseif t==0 then
  d.y,d.s=64,0
 elseif bt(6,20) then
  -- scale
  d.s=l(0,16,4)
 elseif bt(20,22) then
  d.y=l(64,96,2)
 end
end

local function asteroid(d,t,l,bt)
 if not t then
  sspr(120,40,8,8,d.x,d.y,d.s,d.s)
  if d.i>0 then
   circ(d.x,d.y,d.i,5)
  end
 elseif t==0 then
  d.x,d.y=128,128
  d.s=64
  d.i=0
 elseif bt(14,17) then
  d.x=l(128,64,3)
  d.y=l(96,48,3)
 elseif bt(17,19) then
  d.x=l(64,72,2)
  d.y=l(48,71,2)
  d.s=l(64,0,2)
 elseif bt(19,20) then
  d.i=l(0,10)
 end
end

local function worldmap(d,t,l,bt)
 if not t then
  camera(0,d.y)
  draw_map()--{{1,3}})
  camera()
 elseif t==0 then
  d.y=64
  --clear infections
  for i=1,#stats do
   stats[i][5]=0
  end
 elseif bt(20,24) then
  -- enter
  d.y=l(64,-32,2)
 elseif bt(24,30) then
  -- fake infect
  local f=l(1,6,3)
  for i=1,#stats do
   stats[1+flr(t*10)%#stats][5]=f
  end
 elseif bt(30,40) then
  -- exit
  d.y=l(-32,-100,3)
 end
end

function intro_screen.init()
 add(cmk,curtains)
 add(cmk,stars)
 add(cmk,earth)
 add(cmk,asteroid)
 add(cmk,worldmap)
 cmk:init()
 music(0,2000)
end

function intro_screen.draw()
 cls(1)
 cmk:draw()
end

function intro_screen.update()
 cmk:update()
 if btnp(❎) then
  exit_screen()
 end
end
-->8
-- menu screen
menu_screen={}

local function goto_help()
 switch(help_screen,menu_screen)
end

local function start_game()
 skill=_i
 reset_game()
 goto_report()
end

function menu_screen.init()
 -- _i:toolbar index
 toolbar={
  {224,"EASY GAME",start_game},
  {225,"MEDIUM GAME",start_game},
  {226,"HARD GAME",start_game},
  {227,"DIFFICULT GAME",start_game},
  {245,"HELP",goto_help}}
 lock_tb()
 -- last selected
 _p=0
 -- key hint timer
 _t=90
 -- rock position
 --_x,_y,_l=0,64,0
end

function menu_screen.draw()
 if can_redraw() then
  cls(1)
  print("virulent",50,1,0)
  print("virulent",51,2,15)
  line(0,8,128,8,13)
  camera(0,-20)
  draw_map({{7,5},{1,3}})
  camera()
  if _i<5 then
   rectfill(0,113,128,120,13)
   print(max_turns(_i).." TURNS",2,114,15)
   print(((_i>2) and 2 or 3).." ACTIONS",90,114,15)
  end
 end
 _i=draw_tb()
 if _p!=_i then
  set_redraw()
  _p=_i
 end
 -- keys hint
 if _t>0 then
  print("⬅️➡️❎",56,90,5+(time()%2))
 end
 -- floating rock
 --pal(1,5)
 --spr(95,_x,_y)
end

function menu_screen.update()
 update_tb()
 dec_timer()
 --_x=(_x+0.5)%128
 --_l+=0.01
 --_y+=sin(_l)
 --set_redraw()
end
-->8
-- report screen
report_screen = {}

local function prepare_report()
 -- report items={ci, level}
 _p = {}
 for i,v in pairs(stats) do
  -- has infection &
  -- not destroyed
  if v[5]>0 and v[5]<6 then
   add(_p,{i,v[5],v[7],v[6]})
  end
 end
 -- order priority
 --  1) deta ASC
 --  2) peta ASC
 --  1) level DESC
 insort(_p,function(a,b)
   -- deta
   local adeta,bdeta=a[3],b[3]
   if adeta>=0 and bdeta==-1 then
    return true
   elseif adeta==-1 and bdeta>=0 then
    return false
   elseif adeta>=0 and bdeta>=0 then
    return adeta<bdeta
   end
   -- peta
   local apeta,bpeta=a[4],b[4]
   if apeta>=0 and bpeta==-1 then
    return true
   elseif apeta==-1 and bpeta>=0 then
    return false
   elseif apeta>=0 and bpeta>=0 then
    return apeta<bpeta
   end
   -- level
   return a[2]>b[2]
  end)
end

local function reposition()
 if _x==0 then
  _x=65
 else
  _x=0
  _y+=25
 end
end

local function compare_stats()
 -- update country stats
 cstat[4]=npop or cpop
 cstat[5]=nlev or clev
 cstat[6]=npeta or peta
 cstat[7]=ndeta or deta
 cstat[8]=nrem or rem
 cstat[9]=nceta or ceta
 
 -- clear spread from flag
 cstat[15]=false
 --cstat[22]=0
 
 -- infection spread
 if type(spreadfrom)=="number" then
  tickmsg("INFECTION HAS SPREAD")
  tickmsg("FROM "..stats[spreadfrom][1])
  tickmsg("TO "..cname)
 end
 
 -- apr outcome
 if rem>8 then
  if aprsuc==true then
   tickmsg("APR SUCCESS IN "..cname)
  elseif aprsuc==false then
   tickmsg("APR FAILED IN "..cname)
  end
 end
 
 -- level change
 local new_levname=get_level_name(nlev,ndeta)
 if new_levname!=clevname then
  tickmsg(cname.." IS NOW "..new_levname)
  -- inc timer
  _t+=20
 end
 
 clev=flr(clev)
 nlev=flr(nlev)
 if nlev>clev then
  if nlev==6 then
   -- destroyed
   sfx(2)
  else
   -- increase
   sfx(0)
  end
 elseif nlev<clev then
  -- decrease
  sfx(1)
 end
end

local function draw_card()
 -- params
 --  :country index
 rectfill(_x,_y,_x+62,_y+23,15)
 rectfill(_x,_y,_x+62,_y+11,12)
 print(cname,_x+1,_y+1,7)
 -- destroyed color
 if clev==6 then ccol=5 end
 -- cured
 if clev==0 then
  print("CURED",_x+1,_y+6,ccol)
 else
  print(clevname,_x+1,_y+6,ccol)
  -- display lowest value of 1
  print("L"..max(1,flr(clev)),_x+55,_y+6,ccol)
 end
 print("POP",_x+1,_y+12,13)
 print(flr((cpop/csouls)*100).."%",_x+1,_y+18,13)
 -- destroyed...
 if clev==6 then return end
 print("REMEDY",_x+18,_y+12,5)
 if rem>0 then
  print(remcode,_x+18,_y+18,5)
  if ceta==0 then
   print("END",_x+30,_y+18,5)
  else
   print(" T-"..ceta,_x+24,_y+18,5)
  end
 end
 if deta>=0 then
  print("DETA",_x+47,_y+12,8)
  print(deta,_x+47,_y+18,8)
 elseif peta>=0 then
  print("PETA",_x+47,_y+12,13)
  print(peta,_x+47,_y+18,13)
 end
end

local function draw_report_items()
 if #_p==0 then return end
 _x=0
 _y=0
 for n=1,_i do
  ci=_p[n][1]
  load_stats(ci)
  draw_card()
  reposition()
 end
end

local function next_item()
 if _o==1 then
  -- draw up to item _i
  _i+=1
  _o=2
 else
  -- update item _i stats
  _o=1
  ci=_p[_i][1]
  load_stats(ci)
  printw(2)
  compare_stats()
  done=_i==#_p 
 end
  -- rewind timer
 _t+=20
end

function report_screen.init()
 end_turn()
 printw(24)
 cls(1)
 done=false
 set_redraw()
 -- camera scroll
 _c=-10
 -- _o, mode
 --  1:draw current stats
 --  2:draw new stats
 _o=1
 -- count items drawn
 _i=0
 _t=30
 clear_ticker()
 prepare_report()
 print_title("country report",12,"week "..turnno)
end

function report_screen.draw()
 if can_redraw() then
  clip(0,10,128,110)
  camera(0,_c)
  rectfill(0,0,127,256,1)
  draw_report_items()
  camera()
  clip()
 end
 draw_ticker()
 if done then
  print("❎",1,116,13)
 end
end

function report_screen.update()
 update_ticker()
 if (not done and not dec_timer()) then
  next_item()
  set_redraw()
  if _i<3 then
   --reset scroll
   _c=-10
  end
 end
 if btnp(❎) then
  -- skip delay
  _t=0
  if done then
   if end_condition() then
    printw(31)
    switch(end_screen)
   else
    switch(radar_screen)
   end
  end
 elseif btn(⬆️) then
  _c=max(-10,_c-2)
  set_redraw()
 elseif btn(⬇️) then
  _c+=2
  set_redraw()
 end
end

-->8
-- radar screen
radar_screen = {}

function rock_impact(x,y)
 -- params
 --  :x/y impact point
 sfx(2)
 tickmsg("ASTEROID IMPACT DETECTED")
 _c=landhit(x,y)
 if not _c then
  tickmsg("IN THE OCEAN")
  return
 end
 load_stats(_c)
 tickmsg("IN "..cname)
 if clev==0 then
  infect(_c)
  tickmsg("AND IS NOW INFECTED")
  gstats[6][1]+=1
 elseif clev==6 then
  tickmsg("BUT THERE IS NOBODY LEFT")
 else
  tickmsg("BUT IS ALREADY INFECTED")
 end
end

local function missile_hit()
 local hs=0.3
 --+20% for good health of
 -- us, russia & west europe
 hs+=(stats[2][5]<3) and 0.2 or 0
 hs+=(stats[7][5]<3) and 0.2 or 0
 hs+=(stats[11][5]<3) and 0.2 or 0
 printw(25,hs)
 if rnd()<hs then
  tickmsg("MISSILE HIT SUCCESS!")
  return true
 else
  if hs>=0.9 then
   tickmsg("TRAGICALLY")
   tickmsg("THE MISSILE MISSED")
  elseif hs>=0.7 then
   tickmsg("TRAGICALLY")
   tickmsg("MISSILE GUIDANCE FAILED")
  elseif hs>=0.5 then
   tickmsg("ILL MISSILE OPS STAFF")
   tickmsg("FAILED TO LAUNCH")
  else
   tickmsg("SICK MISSILE OPS STAFF")
   tickmsg("FAILED TO LAUNCH")
  end
 end
end

local function move_rocks()
 if done then return end
 
 -- next rock
 if not dec_p() then
  _i+=1
  _p=20
  _t=20
  return
 end
 
 -- no moves left
 if _i>#roids then
  done=true
  return
 end

 -- move
 _o=roids[_i]
 _o[1]=2*cos(_o[3])+_o[1]
 _o[2]=2*sin(_o[3])+_o[2]
 sfx(3)
 
 -- reduce altitude
 _o[4]-=2

 -- 0 altitude
 if _o[4]<=0 then
  del(roids,_o)
  -- targeted
  if _o[5] and missile_hit() then
   sfx(2)
   gstats[5][1]+=1
  else
   rock_impact(_o[1],_o[2])
  end
  -- clear step counter
  _p=0
  -- next rock
  _i-=1
  -- rewind timer
  _t=60
 end
 
end

local function check_orbit()
 
 -- max targets
 local maxt=skill*2
 if #roids>=maxt then return end

 -- for chance
 if #roids>0 and rnd(1)>0.5 then return end

 -- x or y
 _x=rnd()<0.5 and flr(rnd(120)) or 0
 _y=_x==0 and flr(rnd(100)) or 0
 
 -- flip axis
 _x=_x==0 and rnd()<.5 and 120 or _x
 _y=_y==0 and rnd()<.5 and 100 or _y
 
 -- distance table
 local lands={}
 for i,l in pairs(worldspr) do
  -- dist to center
  local cx=l[4]+(l[2]*8)/2
  local cy=l[5]+(l[3]*8)/2
  dist=sqrt((abs(cx-_x)^2)
           +(abs(cy-_y)^2))
  -- keep long range
  if dist>70 then
   add(lands,{i,dist,cx,cy,0})
  end
 end

 -- pick target
 _c=lands[flr(rnd(#lands)+1)]
 if _c then
  local alt=flr(_c[2]*max(0.75,rnd(1)))
  local ang=atan2(_c[3]-_x,_c[4]-_y)
  add(roids,{_x,_y,ang,alt})
 end
end

local function launch()
 if _i==0 or roids[_i][5] or actno==0 then
  -- no target 
  -- already targeted
  -- no actions
  sfx(6)
 else
  sfx(1)
  roids[_i][5]=true
  actno-=1
  gstats[4][1]+=1
 end
end

function radar_screen.init(lm)
 -- params
 --  :launch missile mode
 -- _o used in move_rocks()
 printw(26)
 -- launch mode
 _l=lm
 if _l then
  -- selected rock
  _i=#roids
  -- pick timer
  _t=165
  toolbar={
   {242,"CLOSE",goto_command},
   {243,"🅾️ LAUNCH MISSILE ",launch}}
  done=true
  lock_tb()
 else
  done=false
  -- rock index
  _i=0
  -- stepped movement
  _p=0
  -- timer
  _t=15
  clear_ticker()
  check_orbit()
  check_orbit()
 end
end

function radar_screen.draw()
 cls(1)
 print_title("radar tracking",11,"week "..turnno)
 if _l then
  draw_tb(11)
  if turnno<3 and _t>0 then
   print("⬆️⬇️",60,114,5+(time()%2))
  end
 else
  if done then
   print("❎",1,116,11)
  end
  draw_ticker()
 end
 
 camera(0,-20)
 draw_map({{1,0},{7,11}})
 pal()

 for i,r in pairs(roids) do
  spr(95,r[1]-3,r[2]-3)
  if _l then
   -- mark selected
   if _i==i then
    if r[5] then
     pal(10,8)
     print("<TARGET LOCKED>",1,-10,8)
    end
    spr(127,r[1]-3,r[2]-3)
    pal()
   end
  else
   -- mark tracked
   if r[5] then
    pal(10,8)
    spr(127,r[1]-3,r[2]-3)
    pal()
   end
   if i==_i then
    print("ALTITUDE: "..r[4],42,90,11)
   end
  end
 end
 camera()
 pal()
end

function radar_screen.update()
 if _l then
  update_tb()
  dec_timer()
  _i=rot_sel(_i,#roids)
  if btnp(🅾️) then
   launch()
  end
 else
  update_ticker()
  if not dec_timer() then
   _t=3
   move_rocks()
  end
  if done and btnp(❎) then
   goto_command()
  elseif btnp(❎) then
   -- skip delay
   _t=0
  end
 end
end
-->8
-- command screen
command_screen={}

local function goto_help()
 switch(help_screen,command_screen)
end

local function navto(b)
 if b==0 then
  -- default
  ci=9
 else
  local i=keymap[ci][b]
  if i==0 then
   focus_tb()
  elseif i then
   ci=i
   sfx(4)
  end
 end
 load_stats(ci)
 set_redraw()
end

local function check_done()
 done=true
 for c in all(stats) do
  if c[5]>0 and c[5]<6 and c[9]<1 then
   done=false
  end
 end
 for r in all(roids) do
  if not r[5] then
   done=false
  end
 end
end

function command_screen.init()
 printw(27)
 toolbar={
  {241,"END TURN",goto_report},
  {245,"HELP",goto_help}}
 if actno>0 then
  add(toolbar,{243,"LAUNCH MISSILE",goto_radar},1)
 end
 cls(1)
 navto()
 print_title("command station",12,"week "..turnno)
 unlock_tb()
 check_done()
end

function command_screen.draw()
 if actno==0 then
  return
 end
 if can_redraw() then
  rectfill(0,8,128,14,2)
  print(cname,4,9,1)
  camera(0,-20)
  draw_map()
  draw_con(ci,{{1,ccol},{7,7}})
  camera()
  pal()
  rectfill(96,102,128,128,1)
  draw_histogram(96,102,true)
 end
 draw_tb()
 if done then
  print("🅾️ END TURN",43,110,12)
 end
end

function command_screen.update()
 if update_tb() then
  --nop
 elseif btnp(⬅️) then
  navto(3)
 elseif btnp(➡️) then
  navto(4)
 elseif btnp(⬆️) then
  navto(1)
 elseif btnp(⬇️) then
  navto(2)
 elseif btnp(❎) then
  goto_region()
 elseif actno==0 or (done and btnp(🅾️)) then
  goto_report()
 end
end
-->8
-- regional screen
region_screen={}

local function needs_remedy()
 -- 1) no active remedy
 -- 2) active remedy concluded
 return (clev>0 and clev<6)
        and (rem==0 or 
            (rem>0 and ceta==0))
end

function draw_histogram(x,y,mini)
 if rem==0 or rem>8 then return end
 local cw=15 -- cell width
 local h=30  -- total height
 local gc=13 -- grid color
 local ec=2  -- estimated effectiveness color
 local ac=9  -- actual effectiveness color
 
 if mini then
  cw=6
  h=16
 end
 
 remedy_chart(rem,x,y,cw,h)
 if remhist then
  -- first point at origin
  local px,py=x,y+h
  -- plot
  for d=1,#remhist do
   -- effective %
   local ep=remhist[d] or 0
   -- scale ep to the 40% box
   ep*=2.4
   -- cell x
   local cx=x+(d*cw)
   -- cell y relative to eff
   local cy=y+h-h*ep
   -- draw from previous point
   line(px,py,cx,cy,ac)
   -- store this point
   px=cx
   py=cy
  end
 end
 if not mini then
  print("ESTIMATED",x,y-6,ec)
  print("VS",x+41,y-6,gc)
  print("ACTUAL",x+53,y-6,ac)
 end
end

local function printline(k,v)
 print(k,1,_i,7)
 print(v,127-(#v*4),_i,7)
 line(1,_i+6,126,_i+6,6)
 _i+=8
end

local function print_stats()
 pal()
 clip(0,0,_c,127)
 _i=20
 printline("deaths",cdeadtxt)
 if clev==6 then
  return
 end
 printline("population",cpoptxt)
 printline("infection level",clevtxt)

 if deta>0 then
  printline("destruction eta",detatxt)
 elseif peta>0 then
  printline("pneumonic eta",petatxt)
 end

 if rem>0 and ceta==0 then
  printline("concluded",remtxt)
 else
  printline("remedy",remtxt)
 end
 if ceta>0 then
  printline("remedy concludes in",cetatxt)
 end
 
 draw_histogram(26,76)
 
 clip()
end

local function calc_land_anim(no_anim)
 local sd=worldspr[ci]
 _x=sd[4]
 _y=sd[5]+20
 _o=64-(sd[2]*4) -- top middle
 _p=10
 -- clear flags
 _c=0
 _l=0
 if no_anim then
  _x,_y=_o,_p
  _l=0.9
 end
end

local function goto_remedy()
 switch(remedy_screen)
end

function region_screen.init(no_anim)
 printw(28)
 sfx(5)
 cls(0)
 load_stats(ci)
 calc_land_anim(no_anim)
 toolbar={{242,"CLOSE",goto_command}}
 if needs_remedy() and actno>0 then
  add(toolbar,{244,"🅾️ APPLY REMEDY ",goto_remedy})
 end
 printw(29)
 print_title(cname,9)
 lock_tb()
end

function region_screen.draw()
 if shift_lerp() then
  rectfill(0,10,128,110,0)
  draw_con(ci,nil,
    lerp(_x,_o,_l),
    lerp(_y,_p,_l))
 elseif shift_clip() then
  print_stats()
 end
 draw_tb()
end

function region_screen.update()
 update_tb()
 if btnp(🅾️) and needs_remedy() then
  goto_remedy()
 end
end
-->8
-- remedy screen
remedy_screen={}

local function is_avail(i)
 if ispne then
  return true
 else
  -- no time limit (stasis)
  if peta==-1 then return true end
  -- specified or selected
  i=i or _i
  -- only if dur <= eta
  return #neff[i]<=peta
 end
end

local function list_ntype()
 _y=16
 print(" TYPE DUR NAME",10,14,6)
 print(" ---- --- ----",10,18,6)
 for i=1,8 do
  if is_avail(i) then
   _p=(_i==i) and 11 or 7
  else
   _p=(_i==i) and 9 or 5
  end
  _y+=6
  print(remlut[i][1],18,_y,_p)
  print(#neff[i],38,_y,_p)
  print(remlut[i][2],50,_y,_p)
 end
 rectfill(0,80,127,108,0)
 remedy_chart(_i,40,80,8,16)
 if _l==3 then
  print("% REDUCTION PER WEEK",23,104,14)
  print("1 2 3 4 5",43,98,9)
  print("0%",83,92,9)
  print("40%",83,80,9)
 elseif not is_avail() then
  print("N/A: DUR>ETA",36,104,14)
 end
end

local function list_ptype()
 _y=16
 print("TYPE S% R% NAME",4,14,6)
 print("---- -- -- ----",4,18,6)
 for i=1,4 do
  _p=(_i==i) and 11 or 7
  _y+=6
  local succ=ceil(peff[i][1]*100)
  local redu=ceil(peff[i][2]*100)
  print(remlut[i+8][1],8,_y,_p)
  print(succ,24,_y,_p)
  print(redu,36,_y,_p)
  print(remlut[i+8][2],48,_y,_p)
 end
end

local function close_screen()
 switch(region_screen,true)
end

local function apply_remedy()
 if is_avail() then
  sfx(1)
  if ispne then
   set_remedy(ci,_i+8)
  else
   set_remedy(ci,_i)
  end
  close_screen()
 else
  sfx(6)
 end
end

local function print_eta()
 if deta>0 then
  rectfill(0,112,128,118,2)
  print("DESTRUCTION IN",1,113,8)
  print(detatxt,100,113,8)
 elseif peta>0 then
  rectfill(0,112,128,118,12)
  print("PNEUMONIC IN",1,113,7)
  print(petatxt,100,113,7)
 end
end

function remedy_screen.init()
 printw(30)
 cls(0)
 print_title(cname,9)
 -- _c used in list_ntype/list_ptype
 -- _l toggles chart labels
 -- selection index
 _i=1
 -- max selection
 _o=ispne and 4 or 8
 -- clip
 _c=0
 toolbar={
  {242,"CLOSE",close_screen},
  {246,"🅾️ APPLY ",apply_remedy}}
 if not ispne then
  add(toolbar,{248,"SHOW LABELS",nil})
 end
 lock_tb()
end

function remedy_screen.update()
 update_tb()
 if btnp(⬆️) or btnp(⬇️) then
  _i=rot_sel(_i,_o)
  set_redraw()
 elseif btnp(⬅️) or btnp(➡️) then
  set_redraw()
 elseif btnp(🅾️) then
  apply_remedy()
 end
end

function remedy_screen.draw()
 _l=draw_tb()
 if shift_clip() or can_redraw() then
  clip(0,0,128,_c)
  if ispne then
   -- pneumonic
   list_ptype()
  else
   list_ntype()
  end
  print_eta()
  clip()
 end
end
-->8
--end game screen
end_screen={}

local function prln(k,v,sc)
 print(k,1,_y,5)
 if v then
  print(v,80,_y,5)
 end
 if sc and sc!=0 then
  print(sc,127-(#tostr(sc)*4),_y,5)
 end
 line(1,_y+6,126,_y+6,6)
 _y+=8
end

function end_screen.init()
 _o=end_condition()
 _l=game_score()
 toolbar={
  {247,"SUMMARY",nil},
  {247,"COUNTRY STATISTICS",nil},
  {243,"PLAY AGAIN",goto_menu},
  }
 lock_tb()
 cls(15)
 print_title("end game report",1)
 -- camera scroll
 _c=0
 set_redraw()
end

function end_screen.draw()
 _i=draw_tb()
 if not can_redraw() then
  return
 end
 rectfill(0,10,127,20,15)
 if _i==1 then
  print("SCORE",108,10,4)
 elseif _i==2 then
  print("HEALTH",4,10,4)
  print("SOULS",35,10,4)
  print("DEATHS",70,10,4)
 end
 clip(0,20,128,100)
 camera(0,_c)
 -- fixed header
 rectfill(0,0,127,300,15)
 _y=22
 if _i==1 then
  prln("COUNTRIES CURED",getstatv(1),getstatm(1))
  prln("COUNTRIES DESTROYED",getstatv(2),getstatm(2))
  prln("TOTAL DEATHS (MIL)",getstatv(3),getstatm(3))
  prln("MISSILES FIRED",getstatv(4),getstatm(4))
  prln("MISSILE HITS",getstatv(5),getstatm(5))
  prln("MISSILE MISSES",getstatv(4)-getstatv(5))
  prln("ASTEROID HITS",getstatv(6),getstatm(6))
  prln("INFECTION SPREADS",getstatv(7),getstatm(7))
  prln("REMEDIES APPLIED",getstatv(8),getstatm(8))
  prln("APR SUCCESSES",getstatv(9),getstatm(9))
  prln("APR FAILURES",getstatv(10),getstatm(10))
  if getstatv(11)>0 and getstatv(2)<#stats then
   prln("EARLY END BONUS",getstatv(11),getstatm(11))
  end
  prln("TOTAL SCORE",nil,_l)
 elseif _i==2 then
  for i=1,#stats do
   _y=6+i*16
   load_stats(i)
   line(0,_y-4,127,_y-4,6)
   print(cname,2,_y,0)
   _y+=6
   rectfill(2,_y,30,_y+2,3)
   local lost=csouls-cpop
   _x=max(2,flr((cpop/csouls)*30))
   if lost>0 then
    rectfill(_x,_y,30,_y+2,8)
   end
   print(human_num(cpop,i==5),35,_y,3)
   if lost>0 then
    print(human_num(lost,i==5),70,_y,8)
   end
  end
 elseif _i==3 then
  camera(0,-20)
  draw_map()
  camera()
  if getstatv(2)==#stats then
   pal(10,8)
   sspr(112,64,16,16,110,100)
   pal()
   print("EARTH CLASSIFICATION:",1,100,8)
   print("GLOBAL BIOLOGICAL HAZARD",1,106,8)
  end
 end
 camera()
 clip()
end

function end_screen.update()
 update_tb()
 if btn(⬆️) then
  _c=max(0,_c-3)
  set_redraw()
 elseif btn(⬇️) then
  _c=min(200,_c+3)
  set_redraw()
 elseif btn(⬅️) or btn(➡️) then
  set_redraw()
  _c=0
 end
end
-->8
-- help screen
help_screen={}

local function head(m)
 _y+=10
 print(m,1,_y,14)
 _y+=6
end

local function par(m,c,n)
 print(m,4,_y,c or 15)
 _y+=5+(n or 0)
end

function help_screen.init(return_to)
 pal()
 cls(0)
 -- page height
 _p=760
 -- scroll
 _i=0
 _o=return_to
 set_redraw()
end

function help_screen.draw()
 if can_redraw() then
  cls(1)
  clip(0,0,128,120)
  camera(0,_i)
  print("virulent",50,1,0)
  print("virulent",51,2,15)
  line(0,8,128,8,13)
  _y=2

  head"the story so far"
  par"A DEADLY VIRUS BROUGHT BY"
  par"ASTEROIDS IS THREATENING"
  par"THE WORLD. YOU ARE CHOSEN"
  par"BY THE TOP NATIONS TO LEAD"
  par"A TASK FORCE TO ERADICATE"
  par"THE DREADED DISEASE."
  par"GOOD LUCK."

  head"how to play"
  par"THE GAME TAKES PLACE OVER"
  par"MULTIPLE TURNS, AND IN EACH"
  par"YOU GET SOME ACTION POINTS"
  par"TO MANAGE THE VIRAL OUTBREAK."
  par"HOW YOU SPEND THOSE POINTS"
  par"IS UP TO YOU."
  par"THE GOAL IS TO ERADICATE"
  par"INFECTIONS BY APPLYING"
  par"REMEDIES TO INFECTED COUNTRIES,"
  par"AND SHOOTING DOWN ASTEROIDS"
  par"BEFORE THEY HIT AND CAUSE NEW"
  par"INFECTIONS."
  par""
  par"A TURN HAS THREE PHASES."

  head"report phase"
  par"THE INFECTION REPORT LISTS"
  par"ALL INFECTED COUNTRIES, AND"
  par"DISPLAYS ANY CHANGE IN THEIR"
  par"STATUS."

  head"radar tracking phase"
  par"ASTEROIDS IN EARTH'S ORBIT ARE"
  par"SHOWN IN THIS PHASE, YOU"
  par"ARE NOTIFIED IMMEDIATELY IF"
  par"A COUNTRY WAS HIT BY"
  par"AN ASTEROID."

  head"command phase"
  par"IN THIS PHASE YOU GET TO"
  par"MAKE THE LIFE-SAVING"
  par"CHOICES."
  
  _y+=7
  sspr(120,48,8,8,50,_y,24,24)
  print("THE C-VIRUS",45,_y+25,13)
  _y+=40
  
  par"SELECT A COUNTRY AND PRESS ❎"
  par"TO OPEN THE REGIONAL UPDATE."
  par"IN THIS SCREEN YOU SEE"
  par"COUNTRY STATISTICS AND"
  par"APPLY REMEDIES."
  par""
  par"TO LAUNCH A MISSLE:"
  par"FROM THE COMMAND SCREEN PRESS"
  par"DOWN UNTIL YOU FOCUS THE"
  par"COMMAND TOOLBAR. SELECT"
  par"THE `LAUNCH MISSLE` OPTION"
  par"AND PRESS ❎."

  head"end of turn"
  par"WHEN YOUR ALOTTED ACTIONS ARE"
  par"SPENT, THE TURN ENDS. INFECTION"
  par"LEVELS ARE ADJUSTED, REMEDIES"
  par"APPLIED AND POPULATION TALLIED."
  par"YOU ARE THEN SHOWN THE NEXT"
  par"TURN REPORT."

  head"infection levels"
  par"LEVELS RANGE FROM MILD TO"
  par"CRITICAL, WITH A SPECIAL"
  par"LEVEL FOR PNEUMONIC."
  par""
  par"WHEN THE ESTIMATED TIME UNTIL"
  par"PNEUMONIC (PETA) REACHES ZERO"
  par"THE COUNTRY ENTERS THIS DEADLY"
  par"LEVEL. THIS STARTS THE"
  par"ESTIMATED TIME UNTIL"
  par"DESTRUCTION (DETA) COUNT-DOWN,"
  par"AND WHEN ZERO, THE COUNTRY IS"
  par"COMPLETELY AND IRREVOCABLY"
  par"DESTROYED."
  
  head"remedies"
  par"APPLY REMEDIES TO INFECTED"
  par"COUNTRIES TO REDUCE LEVELS."
  par""
  par("NORMAL REMEDIES",7)
  par"ARE EFFECTIVE 1-5 WEEKS,"
  par"THEY REDUCE INFECTION LEVELS"
  par"EACH TURN UNTIL THE COURSE"
  par"CONCLUDES."
  par""
  par(" TYPE DUR DESCRIPTION",10,1)
  par(" ---- --- -----------",10,1)
  for i=1,8 do
   par("  "..remlut[i][1]..
       "   "..#neff[i]..
       "  "..remlut[i][2],10,1)
  end
  par""
  par("ANTI-PNEUMONIC REMEDIES",7)
  par"WITH A DURATION OF ONE WEEK,"
  par"THEY YIELD MUCH HIGHER"
  par"REDUCTION FACTORS AT THE COST"
  par"OF SUCCESS. BECAUSE OF THEIR"
  par"EXTREME NATURE, THESE REMEDIES"
  par"CAN ONLY BE APPLIED TO"
  par"PNEUMONIC INFECTION LEVELS."
  par""
  par(" TYPE SUC RED DESCRIPTION",10,1)
  par(" ---- --- --- -----------",10,1)
  for i=1,4 do
   par("  "..remlut[8+i][1]..
       "  "..ceil(peff[i][1]*100)..
       "% "..ceil(peff[i][2]*100)..
       "% "..remlut[8+i][2],10,1)
  end

  head"about this game"
  par"THIS IS A REMAKE OF AN ATARI"
  par"GAME 'EPIDEMIC!' BY STEVEN"
  par"FABER 1982."
  par""
  par"THE CODE, ART, MUSIC AND SCREEN"
  par"LAYOUTS ARE MY OWN WORK."
  par"I INCLUDED COUNTRIES NOT"
  par"PRESENT IN THE ORIGINAL."

  head"i dedicate this game"
  par"TO EVERY PERSON WHO HAS BEEN"
  par"SEPERATED FROM THEIR FAMILY OR"
  par"LOVED ONES DURING THE TRAGIC"
  par"CORONA VIRUS OUTBREAK OF 2020."
  par""
  par"WE MISS YOU DEARLY"
  par("WEZ",7)
  print("♥",16,_y-4,8)

  camera()
  clip()
  rectfill(0,120,127,127,13)
  print("⬆️⬇️ SCROLL",1,121,1)
  print("❎ CLOSE",96,121,1)
  -- progress
  line(0,127,(_i/_p)*127,127,10)
 end
end

local function scroll_help(n)
 _i=max(0, min(_p,_i+n))
 set_redraw()
end

function help_screen.update()
 if btn(⬇️) then
  scroll_help(4)
 elseif btnp(➡️) then
  scroll_help(64)
 elseif btn(⬆️) then
  scroll_help(-4)
 elseif btnp(⬅️) then
  scroll_help(-64)
 elseif btnp(❎) then
  clip()
  switch(_o)
 end
end
-->8
-- utilities

function dec_timer()
 _t=max(0,_t-1)
 return _t>0
end

function dec_p()
 _p=max(0,_p-1)
 return _p>0
end

function shift_lerp()
 _l=min(1,_l+0.05)
 return _l<1
end

function shift_clip(n)
 _c=min(127,_c+(n or 6))
 return _c<127
end

function insort(t,cmp)
 for n=2,#t do
  local i=n
  while i>1 and not cmp(t[i-1],t[i]) do
   t[i],t[i-1]=t[i-1],t[i]
   i-=1
  end
 end
end

function lerp(a,b,t)
 return ((1-t)*a)+(t*b)
end

function human_num(n,isgl)
 -- params
 --  :num
 --  :is greenland (low pop)
 if isgl then
  if n>1 then
   return flr(n).." K"
  else 
   return flr(n*1000)..""
  end
 else
  if n>1 then
   return flr(n).." MIL"
  elseif n>0.001 then
   return flr(n*1000).." K"
  else
   return flr(n*1000)..""
  end
 end
end

function human_time(n)
 if n<=0 then return "" end
 return n.." WEEK"..(n>1 and "S" or "")
end

function remedy_chart(i,x,y,cw,h)
 -- params
 --  :remedy index
 --  :x,y position
 --  :cell width
 --  :chart height
 -- charts 0-40% in 10% increments
 -- of estimated effectiveness,
 -- which is color filled.
 -- ----------------<days
 -- |40|  |  |  |  |
 -- |30|  |  |  |  |
 -- |20|  |  |  |  |^percent
 -- |10|  |  |  |  |
 -- ----------------
 local gc=13 -- grid color
 local ec=2  -- est eff color

 -- bg
 pal()
 rectfill(x,y,x+(cw*5),y+h,1)

 -- fill est eff %
 -- weeks 1-5
 for d=1,5 do
  -- eff %
  local ep=neff[i][d] or 0
  -- scale ep to max 40%
  ep*=2.4
  -- cell x
  local cx=x+((d-1)*cw)
  -- cell y relative to eff
  local cy=y+h-h*ep
  rectfill(cx,
           cy,
           cx+cw,
           y+h,ec)
  -- week column
  rect(cx,y,cx+cw,y+h,gc)
 end

 -- 10% guidelines
 for n=1,3 do
  local ly=y+n*(h/4)
  line(x,ly,x+cw*5,ly,gc)
 end
 
end

function print_title(m,c,s)
 -- params
 --  :text
 --  :col
 --  :opt subtitle
 print(m,1,1,c)
 line(0,7,128,7,c)
 if s then
  print(s,127-(#s*4),1,c)
 end
end

function rot_sel(i,m,b)
 -- params
 --  :current index
 --  :max items
 --  :{dec btn, inc btn}
 if i==0 then
  return i
 end
 b=b or {⬆️,⬇️}
	i=(i+(btnp(b[1]) and -1 or btnp(b[2]) and 1 or 0))%m
 return i==0 and m or i
end
-->8
-- components
-- toolbar
local focus,lock=false,false

function focus_tb()
 focus=1
 lock=false
end

function lock_tb()
 focus_tb()
 lock=true
end

function unlock_tb()
 lock=false
 focus=false
end

function draw_tb(bc)
 -- params
 --  :opt color
 if not toolbar then return end
 bc=bc or 12
 camera(0,-120)
 rectfill(0,0,127,7,focus and 1 or bc)
 for i,t in pairs(toolbar) do
  local x=(i-1)*8
  if focus==i then
   pal(12,bc)
   spr(240,x,0)
   pal()
   print(t[2],128-(#t[2]*4),2,bc)
  end
  spr(t[1],x,0)
 end
 if not focus then
  print("actions:"..actno,90,2,15)
 end
 camera()
 return focus
end

function update_tb()
 if not focus then return end
 if btnp(⬅️) then
  focus=max(1,focus-1)
  sfx(4)
 elseif btnp(➡️) then
  focus=min(#toolbar,focus+1)
  sfx(4)
 elseif btnp(⬆️) then
  if not lock then
   focus=false
  end
 elseif btnp(❎) then
  local f=toolbar[focus][3]
  if type(f)=="function" then
   sfx(5)
   f()
   if not lock then
    focus=false
   end
  end
 end
 return true
end

-- message ticker
local ticker,tickpos=nil,nil

function tickmsg(m)
 add(ticker,m)
 printw(" msg: "..ticker[#ticker])
end

function clear_ticker()
 ticker={}
 tickpos=nil
end

function update_ticker()
 if not ticker then return end
 if tickpos then
  tickpos-=10
  if tickpos>0 then
   sfx(7)
  end
  if tickpos<-650 then
   tickpos=nil
   del(ticker, ticker[1])
  end
 else
  if #ticker>0 then
   tickpos=128
  end
 end
end

function draw_ticker()
 rectfill(0,122,128,128,0)
 if not ticker or not tickpos then return end
 local msg=ticker[1]
 if not msg then return end
 print(msg,max(1,tickpos),123,10)
 if tickpos<0 and #ticker>1 then
  print("…",122,125,5)
 end
end

--< cinematik >--
cmk={}
function cmk.init(c,f)
 c.t,c.r,c.d=0,{},{}
 c.spf=(f and 15 or 30)/1000
 for i=1,#cmk do
  c.d[i]={}
  c[i](c.d[i],0,c.lerp,c.between)
 end
end
function cmk.clear()
 while #cmk>0 do
  deli(cmk,1)
 end
end
function cmk.update(c)
 c.t+=c.spf
 for i=1,#cmk do
  cmk.br=false
  c.r[i]=c[i](c.d[i],c.t,c.lerp,c.between) or cmk.br
 end
end
function cmk.draw(c)
 for i=1,#cmk do
  if c.r[i] then
   c[i](c.d[i])
  end
 end
end
function cmk.lerp(a,b,m)
 local t=cmk.t-cmk.ba
 m=m or 1
 m-=0.1
 t=t/m
 t=max(0,min(1,t))
 return lerp(a,b,t)
end
function cmk.between(a,b)
 cmk.br=cmk.t>a and cmk.t<b
 cmk.ba,cmk.bb=a,b
 return cmk.br
end
__gfx__
00000000777777000000000000000000000000007777777000000000000700000000000000007700000000000077770000000000000000000077000000000000
00007777711117777777777700000000000077771111111777770000007170000000000000071170000000007711117000000000000000000711700070000000
00771111111111111111111700000000077711111111111111170000071170000077000077711117000000007111111700000000000000007111700717000000
07111111111111111111177000000000711111111111111111700000711117007777000071111111700000007111111170000000000000071111177117000000
71111111111111111117700007770000711111111111111117000000711111771117000071111111177000007111111117000000000000711111111111700000
07111111111111111170000071170700077711111111111170000000071111111117000071111111111700007111111111777000000077111111111111700000
00711111111111111170000071177170000071111111111700000000007111111117000071111111117000007111111111111700007711111111111111170000
00711111111111111117000071111170000071111111777000000000007711111117000007111111117000000711111111111700071111111111111111170000
07111111111111111111707711111117000711111177000000000000000711111111700000711111111700000077111111111700071111111111111111117000
07111111111111111111171111111177000711117700000000000000077711177711170000711111111170000000711111177000071111111111111111117000
00711111111111111111111111117700000711170000000000000000711117700071170000711111111117000000071111700000071111111111111111117000
00777777777777771111111117770000000077700000000000000000711177000071170000071111777777000000071117000000071111111111111111170000
00000000000000007711111770000000000000000000000000000000077770000007700000007777000000000000007117000000711111777711111111700000
00000000000000000077777000000000000000000000000000000000000000000000000000000000000000000000007117000000711777000071111177000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000717000000077000000007711700000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000077000000000
00077777777777777000000000777000000007777700000000007777000000000000000000000000000777777700000000007700000000000000000000000000
00711111111111111770000077117000000071111700000007777117777777000000000000000000777111111170000000071177000000000000000000000000
07111111111111111117777711170000000711111700000007111111111111700000000000000777111111111117777777007111777770000000000000000000
07111111111111111111111117700000077111711170000071111111111111700000000000777111111111111111111111771111111117777777700000000000
71111111111111111111111770000000711117071170000071111111111111707777000777111111111111111111111111111111111111111111177770000000
71111111111111111111117000000000711117071170000071111177711111707111777111111111111111111111111111111111111111111111111117000000
71111111111111111111170000000000077117007700000007111170077111700711111111111111111111111111111111111111111111111111111111700000
71111111111111111111700000000000000770000000000007111117000777700711111111111111111111111111111111111111111111111111111177000000
71111111111111111117000000000000000000000000000000711111770000000711111111111111111111111111111111111111111111111111117700000000
07777711111111111170000000000000000000000000000000711111117700007111111111111111111111111111111111111111111117777771170000000000
00000077111777711700000000000000000000000000000000071111111170000711111111111111111111111111111111111111111170000007117000000000
00000000777000071700000000000000000000000000000000007111111170000071111111111111111111111111111111111117711117000000717000000000
00000000000000071700000000000000000000000000000000007111117700000007111111111111111111111111111111111170071111700000070000000000
00000000000000007000000000000000000000000000000000000777770000000000771111111111111111111117777777777700007711170000000000000000
00000000000000000000000000000000000000000000000000000000000000000000007111111111111111111770000000000000000077117000000000000000
00000000000000000000000000000000000000000000000000000000000000000000071111111111111111117000000000000000000000717000000000000000
77777000000000000000077000000000000770000000000000000000000000000000071111111111111111170000000000000000000000717000000000000000
71111770000000000000711700000000077117000000000000000000000000000000007111111111111111170000000000000000000000770000000000000000
71111117700000000077111700000777711117000000000000000000000000000000000711111111111111700000000000000000000000000000000000000000
71111111700000000711111700007111111111770000000000000000000000000000000077771111111117000000000000000000000000000000000000000000
07111111700000007111117000007111111111117777770000000000000000000000000000077777771170000000000000000000000000000000000000000000
07111111700700007111117000071111111111111111117000000000000000000000000000000000007700000000000000000000000000000000000000000000
00771111707170007111170000711111111111111111111700000000000000000000000000000000000000000000000000000000000000000000000000000000
00007111171170007777700007111111111111111111111170000000000000000000000000000000000000000000000000000000000000000000000000000000
00000771111170000000700007111111111111111111111170000000000000000000000000770000000000000000000000000007000000000000000000000000
00000007771117000007700071111111111111111111111117000000000000000000000007117000000000000000000000000071700000000000000000010000
00000000007111700071700071111111111111111111111117000000000000777777777771111770000000000000000000000071700000000000000001dd5100
00000000000711170711700071111111111111111111111111700000000077111111111111111117700000000000770000000071170000000000000005dd5510
00000000000071170711700071111111111111111111111111700000000711111111111111111111170000000000717000000007117700000000000001d55510
00000000000007777111700071111111111111111111111111170000007111111111111111111111170000000000711700000000711170000000000000555500
00000000000000007117000007111111111111111111111111117770007111111111111111111111177000000000717000000070071170000000000000000000
00000000000000000770000007111111111111111111111111111117071111111111111111111111170000000000717000007717007700000000000000000000
00007777000000000000000000711111111111111111111111111170711111111111111111111111170000000000711700071117000000000000000000112100
0007111177700000000000000007111117711111111111111111117077711111111111111111111711700000077007117007111707700070000000000145b320
00711111111700000000000000007777700771111111111111111700000711111111111111111170717000007117007170711170711707177700000014533bb1
0071111111117700000000000000000000000711111111111111170000007111111111111111111707000000711170070071117071700711117700001433b3b2
00711111111111700000000000000000000007111111111111111700000007111111111111111117000000007111170000711170717007111111700025333bb1
07111111111111170000000000000000000007111111111111117000000000711111111111111117000000000711170000071170711700777111170013b3bbb2
071111111111111170000000000000000000071111111111111170000000000777111111111111170000000000711170000077000770000071111700023bbb20
71111111111111111770000000000000000007111111111111170000000000000071111111111117000000000071111700000000000000000777700000121200
711111111111111111177700000000000000007111111111111700000000000000711111111111700000000000071111777700000000000000000000aa0000aa
711111111111111111111170000000000000007111111111111700000000000000711111111777000000000000007111111170000000000000000000a000000a
77111111111111111111111700000000000000711111111111117000000000000007111111700000000000000000071111111700000000000000000000000000
07111111111111111111117000000000000000711111111111117000000000000007111111700000000000000000007777777700000000000000000000000000
00711111111111111111117000000000000000711111111111117000000000000007111111700000000000000000000000000000000000000000000000000000
007111111111111111111700000000000000000711111111111700000000000000007711111700000000000000000000000000000000000000000000a000000a
000711111111111111111700000000000000000711111111117000000000000000000077111700000000000000000000000000000000000000000000aa0000aa
00007111111111111111170000000000000000071111111117000000000000000000000077770000000000000000000000000000000000000000000000000000
00000711111111111111700000000000000000007111117717000000000000000000000000000000000000000000000000000111441000000000a000000a0000
000000711111111111117000000000000000000071111700770000000000000000000000000000000000000000000000000041cbbbb10000000a00000000a000
000000711111111111117000000000000000000071177000000000000000000000000000000000000000000000000000004bccccc3bbb100000a00000000a000
00000071111111111117000000000000000000007170000000000000000000000000000000000000000000000000000000cbccccb3b43b00000aaaaaaaa0a000
00000071111111111170000000000000000000000700000000000000000000000000000000000000000000000000000004ccccbbbbbb3340000aa000000aa000
0000000711111111170000000000000000000000000000000000000000000000000000000000000000000000000000000bbcccbbcb3333b1000aaa0000aaa000
0000007711111111170000000000000000000000000000000000000000000000000000000000000000000000000000004bbcccbbbbb333c10aaaaaaaaaaaaaa0
00000071111111117000000000000000000000000000000000000000000000000000000000000000000000000000000043cccb3333bbcbc1aa0a0aa00aa0a0aa
0000007111111117000000000000000000000000000000000000000000000000000000000000000000000000000000004bcccb33333bbcc1a00a00000000a00a
0000007111111117000000000000000000000000000000000000000000000000000000000000000000000000000000001ccccb43333bccc1000aa00aa00aa000
00000071111111700000000000000000000000000000000000000000000000000000000000000000000000000000000011ccccbb333ccc110000a00aa00a0000
00000071111117000000000000000000000000000000000000000000000000000000000000000000000000000000000004bbcccb33bcbc100000aa0aa0aa0000
0000007111117000000000000000000000000000000000000000000000000000000000000000000000000000000000000033bcccbbcbcc00000000aaaa000000
0000000711170000000000000000000000000000000000000000000000000000000000000000000000000000000000000043bcccbcccc100000000aaaaa00000
000000071117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041cccc110000000aaa0000aaa000
00000007111700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111000000000000000000000
00000000711700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000711170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000771170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000d4000050000000000400904090000000880000000000000000000000000000000000000000000000000
000aa00000099000000ee00000088000000000000000d5500004000000000d509099909000008880000000000000000000000000000000000000000000000000
00aaaa000099990000eeee000088880000000000000d5500000500000000d5000039b000000c8800000000000000000000000000000000000000000000000000
00aaaa000099990000eeee00008888000000000009d5500000050000000d500003090b0000ccc000000000000000000000000000000000000000000000000000
000aa00000099000000ee0000008800000000000a085000000989000008900000039b000000c0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000809000000a0a0000aa00000000b000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000a00000000000000000000000b9300000000000000000000000000000000000000000000000000000000000
0cccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc077777700000000000000750000770000000000000000070077777700777777000000000000000000000000000000000000000000000000000000000
cccccccc076666700007000000007660000770000077700000000760075577700766667000000000000000000000000000000000000000000000000000000000
cccccccc076666700077777000076600077777700000700000007600077777700766667000000000000000000000000000000000000000000000000000000000
cccccccc076666700777777006766000077777700007700007076000075557700777777000000000000000000000000000000000000000000000000000000000
cccccccc0766667000777770f0f60000000770000000000006760000077777700000000000000000000000000000000000000000000000000000000000000000
cccccccc07777770000700000f060000000770000007000000600000075555700777777000000000000000000000000000000000000000000000000000000000
0cccccc0000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111010100010001010101110001001100011111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111110f0f1fff0fff0f0f0f110fff0ff11fff1111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111110f0f10f10f1f0f0f0f110f110f0f10f11111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111110f0f10f10ff10f0f0f110ff10f0f10f11111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111fff00f10f0f1f0f0f010f010f0f10f11111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111f11fff1f1f11ff1fff1fff1f1f11f11111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111155555551111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111555533333335555511111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111555333333333333333511111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111115333333333333333335111111111111111111111111111111111555555511111111115511111111111111111111111
11111111111111111111111111111111115333333333333333351111111111111111111111111111111555333333351111111153355111111111111111111111
11111111111111111111111111111111111555333333333333511111111111111111111111111111555333333333335555555115333555551111111111111111
11111111115555551111111111111111111111533333333335111111111111155555111111111555333333333333333333333553333333335555555511111111
11111155555333355555555555111111111111533333335551111111111111533335555111555333333333333333333333333333333333333333333355551111
11115533333333333333333335111111111115333333551111111111111115333335333555333333333333333333333333333333333333333333333333335111
11153333333333333333333551111111111115333355111111111111111553335333533333333333333333333333333333333333333333333333333333333511
11533333333333333333355111155511111115333511111111111111115333351533533333333333333333333333333333333333333333333333333333355111
11153333333333333333511111533515111111555111111111111151115333351533533333333333333333333333333333333333333333333333333335511111
11115333333333333333511111533553511111111111111111111535111553351155333333333333333333333333333333333333333333335555553351111111
11115333333333333333351111533333511111111111111111115335111115511533533333333333333333333333333333333333333333351111115335111111
11153333333333333333335155333333351111111111111111153333511555555333353333333333333333333333333333333333335533335111111535111111
11153333333333333333333533333333551111111111111111153333355333533333335333333333333333333333333333333333353353333511111151111111
11115333333333333333333333333355111111111111111111115333333333533333333553333333333333333333335555555555533335533351111111111111
11115555555555555533333333355511111111111111111111111533333333533333333335333333333333333333553333333333333333355335111111111111
11153333333333333355333335533511111111111111111111111553333333533333333353333333333333333335333333333333333333333535111111111111
11533333333333333333555553335111111111111111111111111153333333353333333353333333333333333353333333333333333333333535111111111111
11533333333333333333333333551111111111111111111111115553335553335333333335333333333333333353333333333333333333333551111111111111
15333333333333333333333355111111111111111111111111153333551115335333333333533333333333333533333333333333333333333511111111111111
15333333333333333333333511111111111111111111111111153335511115335333333333355553333333335333333333333333333333333511111111111111
15333333333333333333335111111111111111111111111111115555115511551533335555553355555553355553333333333333333333353351111111111111
15333333333333333333351111111111111111111111111111111111553351111155551153333333333335533335333333333333333333515351111111111111
15333333333333333333511111111111111111111111111111115555333351111111111533333333333335333333533333333333333333351511111111111111
11555553333333333335111111111111111111111111111111153333333335511111111533333333333335333333353333333333333333351111111111111111
11533335533355553351111111111111111111111111111111153333333333355555511533333555333335333333335333333333333333351111111111111111
11533333355511115351111111111111111111111111111111533333333333333333351153333511553335333333333555333333333333351111111111111111
11533333335111115351111111111111111111111111111115333333333333333333335153333351115555333333333333533333333333351111111111111111
11153333335111111511111111111111111111111111111153333333333333333333333515333335511111533333333333533333333333511111111111111111
11153333335115111111111111111111111111111111111153333333333333333333333515333333355111155333333333533333333555111111111111111111
11115533335153511111111111111111111111111111111533333333333333333333333351533333333511111533333355153333335111111111111111111111
11111153333533511111111111111111111111111111111533333333333333333333333351153333333511111153333511153333335111111511111111111111
11111115533333511111111111111111111111111111111533333333333333333333333335153333355111111153335111153333335111115351111111111111
11111111155533351111111111111111111111111111111533333333333333333333333335115555511111111115335111115533333511115351111111111111
11111111111153335111111111111111111111111111111533333333333333333333333333511111111111111115335111111155333511115335111111111111
11111111111115333511111111111111111111111111111153333333333333333333333333355511111111111111535111111153555511111533551111111111
11111111111111533511555511111111111111111111111153333333333333333333333333333351111111111111151111111153351111111153335111111111
11111111111111155515333355511111111111111111111115333333333333333333333333333511111111111111111111111153511111115115335111111111
11111111111111111153333333351111111111111111111111533333553333333333333333333511111111111111111111111153511111553511551111111111
11111111111111111153333333335511111111111111111111155555115533333333333333335111111111111111111111111153351115333511111111111111
11111111111111111153333333333351111111111111111111111111111153333333333333335111111111111111111111155115335115333515511151111111
11111111111111111533333333333335111111111111111111111111111153333333333333335111111111111111111111533511535153335153351535551111
11111111111111111533333333333333511111111111111111111111111153333333333333351111111111111111111111533351151153335153511533335511
11111111111111115333333333333333355111111111111111111111111153333333333333351111111111111111111111533335111153335153511533333351
11111111111111115333333333333333333555111111111111111111111153333333333333511111111111111111111111153335111115335153351155533335
11111111111111115333333333333333333333511111111111111111111115333333333333511111111111111111111111115333511111551115511111533335
11111111111111115533333333333333333333351111111111111111111115333333333333511111111111111111111111115333351111111111111111155551
11111111111111111533333333333333333333511111111111111111111115333333333333351111111111111111111111111533335555111111155111111111
11111111111111111153333333333333333333511111111111111111111115333333333333351115111111111111111111111153333333511111533511151111
11111111111111111153333333333333333335111111111111111111111115333333333333351155111111111111111111111115333333351115333511535111
11111111111111111115333333333333333335111111111111111111111111533333333333511535111111111111111111111111555555551153333355335111
11111111111111111111533333333333333335111111111111111111111111533333333335115335111111111111111111111111111111111533333333333511
11111111111111111111153333333333333351111111111111111111111111533333333351115335111111111111111111111111111111155333333333333511
11111111111111111111115333333333333351111111111111111111111111153333355351153335111111111111111111111111111115533333333333333351
11111111111111111111115333333333333351111111111111111111111111153333533551153351111111111111111111111111111153333333333333333351
11111111111111111111115333333333333511111111111111111111111111153355333511115511111111111111111111111111111153333333333333333335
11111111111111111111115333333333335111111111111111111111111111153533333511111111111111111111111111111111111153333333333333333335
11111111111111111111111533333333351111111111111111111111111111115333335111111111111111111111111111111111111153333333333333333335
11111111111111111111115533333333351111111111111111111111111111115333335111111111111111111111111111111111111153333333333333333351
11111111111111111111115333333333511111111111111111111111111111115333351111111111111111111111111111111111111533333555533333333511
11111111111111111111115333333335111111111111111111111111111111115555511111111111111111111111111111111111111533555111153333355111
11111111111111111111115333333335111111111111111111111111111111111111111111111111111111111111111111111111111155111111115533511111
11111111111111111111115333333351111111111111111111111111111111111111111111111111111111111111111111111111111111111111111155111111
11111111111111111111115333333511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111115333335111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111533351111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111533351111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111533351111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111153351111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111153335111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111155335111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111115533511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111155551111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddffddfffdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddfffddddddddddddddddddddddddddddddddddd
dddfddfdddddddfffdfdfdffddffdddffdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddfddddddffddffdfffdfffddffdffdddffddd
dddfddfffddddddfddfdfdfdfdfdfdfddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddffdddddfdfdfddddfdddfddfdfdfdfdfddddd
dddfddddfddddddfddfdfdffddfdfdddfdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddfdddddfffdfddddfdddfddfdfdfdfdddfddd
ddfffdfffddddddfdddffdfdfdfdfdffddddddddddddddddddddddddddddddddddddddddddddddddddddddddddfffdddddfdfddffddfddfffdffddfdfdffdddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
1cccccc1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
cccccccc111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
cccaaccc11199111111ee11111188111117771111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
ccaaaacc1199991111eeee1111888811111171111111111111111111111111111111111111111111111111111111ccc11cc11cc1c1c111111cc11cc1ccc1ccc1
ccaaaacc1199991111eeee1111888811111771111111111111111111111111111111111111111111111111111111cc11c1c1c111ccc11111c111c1c1ccc1cc11
cccaaccc11199111111ee11111188111111111111111111111111111111111111111111111111111111111111111c111ccc111c111c11111c1c1ccc1c1c1c111
cccccccc1111111111111111111111111117111111111111111111111111111111111111111111111111111111111cc1c1c1cc11cc111111ccc1c1c1c1c11cc1
1cccccc1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__sfx__
001400002975030700297500370029700057000370003700037000370003700037000e7000d70020700207001f700007000070000700007000070000700007000070000700007000070000700007000070000700
000a0000247502b7402b7302b7202b71027700247003a7003a7003a7003a7002b7002b7002e7002e7003070033700337003570037700007000070000700007000070000700007000070000700007000070000700
00090000246200c620226200c6201d6200c6101661000610056100010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
01060000167501b700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
011000000c53000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
010800001c73028720007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
011000000433704337000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100000065500600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
001000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400201c053306230420010053246230000010053246232462304223000001c053306230000010053246232862310053000001005328623286231c0531c0532862300000100531005328623000001005328623
01140020103520f311103420f311103320f311103220f311133520f311133420f311133320f311133220f311113520f311113420f311113320f311113220f3110c3520f3110c3420f3110c3320f3110c3220c311
012800000443203433044320343304432034330443203433034320343303432034330343203433034320343305432034330543203433054320343305432034330043203433004320343300432034330043203433
01280000104320f433104320f433104320f433104320f433114320e433114320e433114320e433114320e4330c4320f4330c4320f4330c4320f4330c4320f4330f4320f4330f4320f4330f4320f4330f4320f433
011400201c0521c0121c0421c0121c0321c0121c0221c0121c0521c0121c0421c0121c0321c0121c0221c0121d0521d0121d0421d0121d0321d0121d0221d0121d0521d0121d0421d0121d0321d0121d0221d012
01280000287522775328752277532875227753287522775324752277532475227753247522775324752277532d752277532d752277532d752277532d752277532b752277532b7522775329752277532875227753
01140020182511821218242182121823218212182221821104251042220425204222042520422204252042211b2511b2121b2421b2121b2321b2121b2221b2110025100222002520022200252002220025200221
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001300000f700107000f700107000f700147000f700107000f700107000f700107000f700147000f7001070000000107000000000000000000000000000000000000000000000000000000000000000000000000
00100000110000e4000f0001540010000174000f000154000e000134000f000154000c000154000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41420a0b
00 0c420a0b
00 0c0d0a0e
00 0c0f0a0b
00 0e420a10
00 0e100a0b
00 0c0d4344
00 0c0c430e
00 41430b10
04 41424310

