pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- config: num_players 1 or 2
num_players = 1
corrupt_mode = false
max_actors = 128

music(1, 1, 1)


function make_actor(k,x,y,d)
	local a = {}
	a.kind = k
	a.life = 1
	a.x=x a.y=y a.dx=0 a.dy=0
	a.ddy = 0.05 -- gravity
 a.w=0.3 a.h=0.5 -- half-width
 a.d=d a.bounce=0.8
 a.frame = 1  a.f0 = 0
 a.t=0
 a.standing = false
 if (count(actor) < max_actors) then
  add(actor, a)
 end
	return a
end

function make_sparkle(x,y,frame,col)
 local s = {}
 s.x=x
 s.y=y
 s.frame=frame
 s.col=col
 s.t=0 s.max_t = 8+rnd(4)
 s.dx = 0 s.dy = 0
 s.ddy = 0
 add(sparkle,s)
 return s
end

function make_player(x, y, d)
 pl = make_actor(1, x, y, d)
 pl.super  = 0
 pl.score  = 0
 pl.bounce = 0
 pl.delay  = 0
 pl.id     = 0 -- player 1
 pl.pal    = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
 
 return pl
end

-- called at start by pico-8
function _init()

 actor = {}
 sparkle = {}
 
 -- spawn player
 for y=0,63 do for x=0,127 do
  if (mget(x,y) == 48) then
   player = make_player(x,y+1,1)

   if (num_players==2) then
    player2 = make_player(x+2,y+1,1)
    player2.id = 1
    player2.pal = {1,3,3,4,5,6,7,11,9,10,11,12,13,15,7} 
   end
   
  end
 end end
 t = 0
 
 death_t = 0
end

function clear_cel(x, y)
 val0 = mget(x-1,y)
 val1 = mget(x+1,y)
 if (val0 == 0 or val1 == 0) then
  mset(x,y,0)
 elseif (not fget(val1,1)) then
  mset(x,y,val1)
 else
  mset(x,y,val0)
 end
end


function move_spawns(x0, y0)

 for y=0,32 do
  for x=x0-10,x0+10 do
   val = mget(x,y)
   m = nil

   -- pickup
   if (fget(val, 5)) then    
    m = make_actor(2,x+0.5,y+1,1)
    m.f0 = val
    m.frame = val
    if (fget(val,4)) then
     m.ddy = 0 -- zero gravity
    end
   end

   -- monster
   if (fget(val, 3)) then
    m = make_actor(3,x+0.5,y+1,-1)
    m.f0=val
    m.frame=val
   end
   
   -- clear cel if spawned something
   if (m ~= nil) then
    clear_cel(x,y)
   end
  end
 end

end

-- test if a point is solid
function solid (x, y)
	if (x < 0 or x >= 128 ) then
		return true end
				
	val = mget(x, y)
	return fget(val, 1)
end

function move_pickup(a)
 a.frame = a.f0
-- if (flr((t/4) % 2) == 0) then
--  a.frame = a.f0+1
-- end
end

function move_player(pl)

 local b = pl.id

 if (pl.life == 0) then
    death_t = 1
    for i=1,32 do
     s=make_sparkle(
      pl.x, pl.y-0.6, 96, 0)
     s.dx = cos(i/32)/2
     s.dy = sin(i/32)/2
     s.max_t = 30 
     s.ddy = 0.01
     s.frame=96+rnd(3)
     s.col = 7
    end
    
    del(actor,pl)
    
    sfx(16)
    music(-1)
    sfx(5)

  return
 end

 accel = 0.05
 
 if (not pl.standing) then
  accel = accel / 2
 end
  
 -- player control
	if (btn(0,b)) then 
			pl.dx = pl.dx - accel; pl.d=-1 end
	if (btn(1,b)) then 
		pl.dx = pl.dx + accel; pl.d=1 end

	if ((btn(4,b) or btn(2,b)) and 
--		solid(pl.x,pl.y)) then 
  pl.standing) then
		pl.dy = -0.7
  sfx(8)
 end
 
 -- frame	

 if (pl.standing) then
	 pl.f0 = (pl.f0+abs(pl.dx)*2+4) % 4
 else
	 pl.f0 = (pl.f0+abs(pl.dx)/2+4) % 4 
 end
 
 if (abs(pl.dx) < 0.1) 
 then
  pl.frame=48 pl.f0=0
 else
	 pl.frame = 49+flr(pl.f0)
	end

 if (pl == player2) then
  pl.frame = pl.frame +75-48
 end
	
end

function move_monster(m)
 m.dx = m.dx + m.d * 0.02

	m.f0 = (m.f0+abs(m.dx)*3+4) % 4
 m.frame = 112 + flr(m.f0)

 if (false and m.standing and rnd(100) < 1)
 then
  m.dy = -1
 end

end

function move_actor(pl)

 -- to do: replace with callbacks

 if (pl.kind == 1) then
  move_player(pl)
 end
 
 if (pl.kind == 2) then
  move_pickup(pl)
 end

 if (pl.kind == 3) then
  move_monster(pl)
 end

 pl.standing=false
 
 -- x movement
	
 x1 = pl.x + pl.dx +
      sgn(pl.dx) * 0.3
      
 local broke_block = false

 if(not solid(x1,pl.y-0.5)) then
		pl.x = pl.x + pl.dx  
	else -- hit wall
		
	 -- search for contact point
	 while (not solid(pl.x + sgn(pl.dx)*0.3, pl.y-0.5)) do
	  pl.x = pl.x + sgn(pl.dx) * 0.1
	 end

  -- bounce	
  if (pl.super == 0 or 
      not broke_block) then
   pl.dx = pl.dx * -0.5
  end

  if (pl.kind == 3) then
   pl.d = pl.d * -1
   pl.dx=0
  end

	end
	
 -- y movement

 if (pl.dy < 0) then
  -- going up
  
  if (solid(pl.x-0.2, pl.y+pl.dy-1) or
   solid(pl.x+0.2, pl.y+pl.dy-1))
  then
   pl.dy=0
   
   -- search up for collision point
   while ( not (
   solid(pl.x-0.2, pl.y-1) or
   solid(pl.x+0.2, pl.y-1)))
   do
    pl.y = pl.y - 0.01
   end

  else
   pl.y = pl.y + pl.dy
  end

	else

  -- going down
  if (solid(pl.x-0.2, pl.y+pl.dy) or
   solid(pl.x+0.2, pl.y+pl.dy)) then

	  -- bounce
   if (pl.bounce > 0 and 
       pl.dy > 0.2) 
   then
    pl.dy = pl.dy * -pl.bounce
   else
 
    pl.standing=true
    pl.dy = 0
    
   end

   --snap down
   while (not (
     solid(pl.x-0.2,pl.y) or
     solid(pl.x+0.2,pl.y)
     ))
    do pl.y = pl.y + 0.05 end
  
   --pop up even if bouncing
   while(solid(pl.x-0.2,pl.y-0.1)) do
    pl.y = pl.y - 0.05 end
   while(solid(pl.x+0.2,pl.y-0.1)) do
    pl.y = pl.y - 0.05 end
    
  else
   pl.y = pl.y + pl.dy  
  end

 end


 -- gravity and friction
	pl.dy = pl.dy + pl.ddy
 pl.dy = pl.dy * 0.95

 -- x friction
 if (pl.standing) then
 	pl.dx = pl.dx * 0.8
	else
 	pl.dx = pl.dx * 0.9
	end

 -- counters
 pl.t = pl.t + 1
end

function collide_event(a1, a2)
 if(a1.kind==1) then
  if(a2.kind==2) then

   if (a2.frame==64) then
    a1.super = 120
    a1.dx = a1.dx * 2
    sfx(13)
   end

   -- gem
   if (a2.frame==80) then
    a1.score = a1.score + 1
    sfx(9)
   end

   del(actor,a2)

  end
  
  if(a2.kind==3) then -- monster
   if((a1.y-a1.dy) < a2.y-0.7) then
    -- slow down player
    a1.dx = a1.dx * 0.7
    a1.dy = a1.dy * -0.7-- - 0.2
    
    -- explode
    for i=1,16 do
     s=make_sparkle(
      a2.x, a2.y-0.5, 96+rnd(3), 7)
     s.dx = s.dx + rnd(0.4)-0.2
     s.dy = s.dy + rnd(0.4)-0.2
     s.max_t = 30 
     s.ddy = 0.01
     
    end
    
    -- kill monster
    sfx(14)
    del(actor,a2)
    
   else

    -- player death
    a1.life=0


   end
  end
   
 end
end

function move_sparkle(sp)
 if (sp.t > sp.max_t) then
  del(sparkle,sp)
 end
 
 sp.x = sp.x + sp.dx
 sp.y = sp.y + sp.dy
 sp.dy= sp.dy+ sp.ddy
 sp.t = sp.t + 1
end


function collide(a1, a2)
 if (a1==a2) then return end
 local dx = a1.x - a2.x
 local dy = a1.y - a2.y
 if (abs(dx) < a1.w+a2.w) then
  if (abs(dy) < a1.h+a2.h) then
   collide_event(a1, a2)
  end
 end
end

function collisions()

 for a1 in all(actor) do
  collide(player,a1)
 end

 if (player2 ~= nil) then
  for a1 in all(actor) do
   collide(player2,a1)
  end
 end

end

function outgame_logic()

 if (death_t > 0) then
  death_t = death_t + 1
  if (death_t > 30 and 
   btn(4) or btn(5))
  then 
    music(-1)
    sfx(-1)
    sfx(0)
    dpal={0,1,1, 2,1,13,6,
          4,4,9,3, 13,1,13,14}
          
    -- palette fade
    for i=0,40 do
     for j=1,15 do
      col = j
      for k=1,((i+(j%5))/4) do
       col=dpal[col]
      end
      pal(j,col,1)
     end
     flip()
    end
    
    -- restart cart end of slice
    run()
   end
 end
end

function _update()

	foreach(actor, move_actor)		
	foreach(sparkle, move_sparkle)
 collisions()
 move_spawns(player.x, player.y)

 outgame_logic()
 
 if (corrupt_mode) then
  for i=1,5 do
   poke(rnd(0x8000),rnd(0x100))
  end
 end
 
	t=t+1
end

function draw_sparkle(s)
 
 if (s.col > 0) then
  for i=1,15 do
   pal(i,s.col)
  end
 end

 spr(s.frame, s.x*8-4, s.y*8-4)

 pal()
end

function draw_actor(pl)

 if (pl.pal ~= nil) then
  for i=1,15 do
--   pal(i, pl.pal[i])
  end
 end

	spr(pl.frame, 
  pl.x*8-4, pl.y*8-8, 
  1, 1, pl.d < 0)
  
 pal()
end

function _draw()

 -- sky
	camera (0, 0)
	rectfill (0,0,127,127,12) 
 
 -- sky gradient
 if (false) then
 for y=0,127 do
  col=sget(88,(y+(y%4)*6) / 16)
  line(0,y,127,y,col)
 end
 end

 -- clouds behind mountains
 local x = t / 8
 x = x % 128
 local y=0
 mapdraw(16, 32, -x, y, 16, 16, 0)
 mapdraw(16, 32, 128-x, y, 16, 16, 0)
 
 local bgcol = 13 -- mountains
 pal(5,bgcol) pal(2,bgcol)
 pal(13,6) -- highlights 
 y = 0
 mapdraw (0, 32, 0, y, 16, 16, 0)
	pal()
 
 
 -- map and actors
	cam_x = mid(0,player.x*8-64,1024-128)

 if (player2 ~= nil) then
  cam_x = 
   mid(0,player2.x*8-64,1024-128) / 2 +
   cam_x / 2
 end
 
 cam_y = 84
	camera (cam_x,cam_y)
 pal(12,0)	
	mapdraw (0,0,0,0,256,64,1)
 pal()
 foreach(sparkle, draw_sparkle)
	foreach(actor, draw_actor)

 -- player score
 camera(0,0)
 color(7)
 

 if (pl.super > 0) then
    print("congratulations! \nyou found da wae!",
    30-1,10-0,8+(t/4)%2)
   print("congratulations! \nyou found da wae!",
    30,10,7)
 end

 if (death_t > 60) then
  print("press button to restart",
   18-1,10-0,8+(t/4)%2)
  print("press button to restart",
   18,10,7)
   
 end
 
 if (false) then
  cursor(0,2)
  print("actors:"..count(actor))
  print("score:"..player.score)
  print(stat(1))
 end
end








__gfx__
0000000000000000ffffffff55f555f5dddddddddddddddd41111114d00000000000000021111112cccccccccccccccc4000000045544554cc5ccccc00000000
0000000000000000ffffffff55555555dddddddd5ddd5ddd144444415d0000000000000012222221ccccccccccccccc55400000054455445c55555cc00000000
0000000000700700ff4fffff44444444dd5dddddd5d5dd5d14444441d5d0000000000000122aa221cccccccccccccc55454000004554455455555ccc40000000
0000000000077000ffffffffffffffffdddddddd5d555ddd144aa4415ddd00000000000012222221ccccccccccccc5555444000054455445c555cccc54040000
0000000000077000ffffffffffffffffddddddddd5d5d5dd14444441d5ddd0000000000012222221cccccccccccccc5c4544400045544554cc5ccccc45454000
0000000000700700fffff4fffffff4ffddddd5dd5d5d5d5d144444415d5ddd000000000012222221ccccccccccc55555545444005445544555cccccc54545000
0000000000000000ffffffffffffffffddddddddd5d5dddd14444441d5d5ddd00000000012222221cccccccccc55c55545454440455445545ccccccc45454500
0000000000000000ffffffffffffffffdddddddd5d5d5d5d411111145d5d5d5d0000000021111112ccccccccc55555555454545454455445cccccccc54545450
00067000555fff6600004444444400000000000000000000000000003333000000033333cc5cccc5000000000000000ddddd4545dddddddd000000004545454d
0006700055fff66700001444444100000000000000000000000000003333300000333333c555555500000077000000dd5ddd5454dddddddd000000005454545d
00566700c5f6667c00001114111100000000000000000000004444003333330000333333555555550000077700000dd545d5dd454ddddd4500000000454545dd
00566700c5f6667c00004411444400000000000004444440004444003333333003333333c5555555000077770000ddd454ddddd454dddd540000000054545ddd
05f66670cc5667cc00004444444400000000000011111111001444003333333003333333cc5ccc5c00777777000dddd5454ddd454545d5450000000045454ddd
05f66670cc5667cc000014444441000000000000444aa4440011440033333333333333335555c5550777777700dddd54545d54545454545400000000545454dd
55ff6667ccc67ccc0000114411110000000000004444444400000000333333333333333355555555077777770dd5d545454545454545454500000000454545dd
555fff66ccc67ccc000041111444000000000000111111110000000033333333333333335555c55577777777dd5dd4545454545454545454000000005454545d
4441444444444444cccccccc4f4f4f4f4f4f4f4f000000000000bb3333bb000033333333bbbbbbbb000000000000000ddddd4545dddddddd0000000000000000
44444414f444f444ccccccccfff4ff44f4f4f4f400000000000bb333333bb00033333333bbbbbbbb77000000000000dddddd5454dddddddd0000000000000000
414141414f4f44f4cccccccc4f4f4fff4f4f444f0000000000bb33333333bb00333333333333333377770000000000ddddd54545dddddddd0000000000000000
14141414f4fff444ccccccccf4f4f4f4f4f4f444000000000bb3333033333bb03333333333333333777770000000ddddddd45454dddddddd4888888888888884
444111414f4f4f44cccccccc4f44ff4f4f1f4f4f00000000bb333300033333bb333333333333333377777700000dddddddd54545dddddddd4444444444444444
41141414f4f4f4f4ccccccccfff444f4f4fffff400000000b33330000033333b33333333333333337777770000ddd5dddd545454dddddddd4544544545445445
444141414f4f4444cccccccc4fff4f4f4f4f1f4f0000000033330000000033333333333333333333777777700ddd5dddd5444545dddddddd4445444444454444
14141414f4f4f4f4ccccccccf4f4f4f4f4f4f4f4000000003330000000000333333333333333333377777777d5ddddddd4545454dddddddd4544454445444544
00088800000888000008880000088800000888000000000000000333000000003333333300333300777777770000777700000000000000000000000000000000
00178710001787100017871000178710001787100000000000000033000000003333333303333330777777770000777700000000000000000000000000000000
08fff1f008fff1f008fff1f008fff1f008fff1f00000000000000003000000003333333333333333777777770000777700000000000000000000000000000000
888fff88888fff88888fff88888fff88888fff880007700000000000000000003333333333333333777777770000777700000000000000008888888800000000
88877788888777888887778888877788888777880007700000000000000000003313313333333333777777777777777777777777777700004444444400000000
78888887078888807888898778988887088888800000000000000000000000003131131333333333777777777777777777777777777777004544544500000000
00b00b0000b0098000b0000000000b0000980b000000000000000000300000001311113133333333777777777777777777777777777777704445444400000000
00980980009800000098000000000980000009800000000000000000330000001111111133333333777777777777777777777777777777774544454400000000
00000000055555500000000000000000aaaaaaaaaaaaaaaa00000000cccccccc0000000000000000000000006766666767666667676666676766666767666667
11111111550000550000000000000000888888888888888800000000cc1ccccc0000000000000000000000006717871767178717671787176717871767178717
11777711500055050000000000000000fff1fffff1ffffff00000000ccccc1cc000000000000000000000000e6fff1fee6fff1fee6fff1fee6fff1fee6fff1fe
aa7777aa500055050000000000000000fafafaaffaffafaa00000000cccccccc000000000000000000000000ee8fff8eee8fff8eee8fff8eee8fff8eee8fff8e
aa7777aa501000050000000000000000f8f8ffffffffffff00000000cc111ccc000000000000000000000000eee777ee1ee777e11ee777e11ee777e11ee777e1
88777788508a00050000000000000000fff1f11fffff1f1100000000cccccccc0000000000000000000000001eeeeee10eeeeee00eeeeee00eeeeee00eeeeee0
88888888550000550000000000000000aaaaaaaaaaaaafff00000000cc1ccccc0000000000000000000000000010010000100110001101100011010001101100
00000000055555500000000000000000888888888888888800000000cccccccc0000000000000000000000000011011000110000000000000000011000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
099d8990099819900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09d1a890098a71900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d1d8a8008a817100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08a8d1d001718a800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
098a1d900917a8900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0998d990099189900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000700000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09000900000000000900090009000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09909990099099900990999009909990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999999999999999999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99919919999199199991991999919919000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fff1ff1ffff1ff1ffff1ff1ffff1ff1f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fffffff1fffffff1fffffff1fffffff1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0fff11100fff11100fff11100fff1110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000949494949494949494
94000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000a3a3a3a300a3a3a3a3000000a300a300a300a3a3a3a300a3a3a3a3
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000a1a2000000000000000000000000000000a30000a300a30000a3000000a300a300a300a30000a300a3000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000b1c00000b1c00000000000000000a1a2a1a3a3a2a1a2000000000000000000000000a30000a300a30000a3000000a300a300a300a30000a300a3a3a3a3
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b1c0b1d0d0c0b1c2d0e2e3f2f00000b1a1a3a3a3a3a3a3a3a3a2a1a3a20000000000000000a30000a300a3a3a3a3000000a300a300a300a3a3a3a300a3000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5050505050505050505050505070b2c2a3a3a3a3a3a3a3a3a3a3a3a3a3a2a1a20000000000a3a3a3a300a30000a3000000a3a3a3a3a300a30000a300a3a3a3a3
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50505050505050505050505050505050a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a30000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40404040404040404040404040404040a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a30000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40404040404040404040404040404040a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a30000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40404040404040404040404040404040a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a30000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222222a0a0a0a0a0a0a0a0a0a0a0a022a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a30000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22a0a0a0a0a0a0a0a0a0a0a0a0a02222a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a30000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
74747474747474747474747474747474747474747474747474747474747474740000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
74747474747474747474747474747474747474747474747474747474747474740000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
74747474747474747474747474747474747474747474747474747474747474740000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c2c3c000000000000000000000000
74747474747474747474747474747474747474747474747474747474747474740000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d2d3d000000000000000000000000
74747474747474747474747474747474747474747474747474747474747474740000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e1e2e3e000000000000000000000000
74747474747474747474747474747474747474747474747474747474747474740000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f1f2f3f000000000000000000000000
75000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000030303031303000300010000010003030101010103030101000000000000030303030301010101030100000000000000000000000303010101000000000020002000010100030000000000000000200020200000000000000000000000000000000000000000000000000000000008080808000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000044440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000262726270000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000004b4c00000000000026271817262700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005b5c00000000000000261213270000000000000000000000000000000000000000000000000000000051515153000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000001213000000000000000000000000000000000000000000000000000000000006060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000026272627000000000000001213000000000000000000000000000000000000000000000051515141000000000000000303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000
0000000000000000000000000000000000000000000000000000002627181726270000000000001213000000000000000000000000000000000000000000000006060606000000000000000202020202020200000000000000000000000000000000262726270000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000050000000000000000026121327000000000000001213000000000000000000000000000000000000000000000000000000000000000000000202020202020200000000000000000000000000000026271817262700000000000000000000000000000000000000000006060015
0000000000000000000000000000000000000000000000000000000000121300000000000070001213000000060600000050505050505000000000005200000000000000000000000000000202020202020200000000000000000000000000000000261213270000000000000000000000000000000000000603030303030303
0000000000000000000000000000000000000606060000000000000000121300000000000003030303030303030303030606060606060606060606060600000000000000000000000000000202020202020200000000000606000000000000000000001213000000000000000000000000000000000000030302020202020202
0000000000000000000000000000000000000000000000000000000000121300000000000002020202020202020202020000000000000000000000000000000000000000000000000000000202020202020200000070000606000000000000000000001213005000000000000000700000000000700000020202020202020202
0000000000000000000000000000000000000000000000000000000000121300000070000002020202020202020202020000000000000000000000000000000000000000000000000000000202020202020203030303030303007000150000001500001213001500000000000303030303030303030303020202020202020202
0015000030000000000000000600000000001500000000007000030303030303030303030302020202232323230202020000000000000000000000000000000000000000000000000000000202020202020202020202020202030303030303030303030303030303030303030202020202020202020202020202020202020202
0303030303030303030303030303030303030303030303030303020202020202020202020202020223232323230202020606060606060606060606060606060606060606060606060606060202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0202020202020202020202020202020202020202020202020202020202020202020202020202022323232323230202020000000000000000000000000000000000000000000000000000000202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0202020202020202020202020202020202020202020202020202020202020223230223232302022323232323232323020a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0202020202020202020202020202020202020202020223020202022323232323232323232323232323232323232323230a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
2302020202020202020202020223242323232302022323232323232323232323232323232323232323232323232323234747474747474747474747474747474747474747474747474747470202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000200020000000000
2323232323232324232323232323232323232323232323232323232323232323232323232323232323232323232323234747474747474747474747474747474747474747474747474747470202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323234747474747474747474747474747474747474747474747474747474702020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323232323232323232323232323232323232323232323232323232323232323232302232323232302024747474747474747474747474747474747474747474747474747474702020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01030000185701c5701f57024570185701c5701f57024560185601c5601f56024560185501c5501f550245501a5501d5501f540245401a5301d5301f530235301a5301d5301f5301a5201d510215102451023515
001400202164520150212502024520645201502124521250206422021620245202501f6551f225202501f250206452225022235222262164222250211452125020645212502124521246216451f1502124222225
001000001074710050100501074510745100501074510050107451005010745100501074510050100501074510745100501005010745107451005010745100501074510050107451005010745100501074510050
00100000305003c50000600006003e600006000c30018600355000050000600006003e600006000060018600295003250029500006003e600006000060018600305000050018600006003e600246000060000600
001000000c575145750757516575175750e575025751157515575045750d575165751b5751e5750657511575185751b575195750b5750257501575025750a5750f575135750c5750657510575095750957503575
001000001807217075180721b0722007524075280722a0752b07529077240751e0721b07515077120750f0750d1720d1620c1520c1420b1350b1500b150000000000000000000000000000000000000000000000
001000000e475174751e4751c4751a472184721647115472144721347212471124511243112411133001830214302143021830218302003000030000300003000030000300003000030000300003000030000300
001000000c37300300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000000001e17022170251702712038110381503515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002f36035350363302f3402c3302f35033330353303332032310343103531033310383103a3103c7003f700007000070000700007000070000700007000070000700007000070000700007000070000700
00020000221501115010150161501914017130101200a1300d1301013007110011100111002110021100115013600106000d60010600116000e6001160012600116000a600066000960003600026000260002600
0001000023175271752a1652a1552a1552a1552614522125221352312526125291252d1252e1152f11530115305052e505305052e5053050530505335052b5052e5052b5052e5052e5053350530505335052e505
0002000022153231431b123111230a113011500215000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000f771167731c7751d7711777315775197711b7731c7751a771197731b7751e7711c7731a7751b7711c7731b76516761157631b7611c7551b7531e75523741287432d73131735367332b7212c7252d713
00020000281712017119171131710f1710b1710717105171041610116101161011510115101141011310112101111011110000000000000000000000000000000000000000000000000000000000000000000000
000200002807017070130731b0711c063140610e0430d0610e0230f01102010010500010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00040000174701a4701c4701d4701e4701e4701e4701d4701b4701747013470104700e4700e47010470104700e47011470144701a4701e4602145023450244302443023420244202342022410214101f4101e450
__music__
01 0b434144
00 02034144
00 02434244
05 59434444
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144

