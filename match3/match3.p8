pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
jsize=16
curr={0,0}
jspr={16,20,22,24,26,28}
jgrid={}
gridlock=false
selected=nil
fallspeed=4

function _init()
	init_jgrid()
end

function _update()
	--move cursor
	if btnp(➡️) then curr[1]+=1 end
	if btnp(⬅️) then curr[1]-=1 end
	if btnp(⬆️) then curr[2]-=1 end
	if btnp(⬇️) then curr[2]+=1 end
	--clamp cursor to grid
	curr[1]=mid(curr[1],0,7)
	curr[2]=mid(curr[2],0,7)
	
	--select and swap
	if btnp(🅾️) then
		if selected==nil then
			selected={curr[1],curr[2]}
		else
			swap(selected,curr)
		end
	end
	
	animate()
	
	if not gridlock then
		match()
	end
end

function _draw()
	cls()
	draw_grid()
end

function draw_grid()
	for r=0,7 do
		for c=0,7 do
			local x=c*jsize
			local y=r*jsize
			local j=jgrid[r+1][c+1]
			spr(
				j.sprite,
				x+j.offset[1],
				y+j.offset[2],
				2,2)
		end
	end
	local currx=curr[1]*jsize
	local curry=curr[2]*jsize
	rect(
		currx,
		curry,
		currx+jsize-1,
		curry+jsize-1,9)
	if selected~=nil then
		local selx=selected[1]*jsize
		local sely=selected[2]*jsize
		rect(
			selx,
			sely,
			selx+jsize-1,
			sely+jsize-1,14)
	end
end

function init_jgrid()
	local grid={}
	for r=1,8 do
		local row={}
		for c=1,8 do
			add(row,
				{
					sprite=rnd(jspr),
					offset={0,0}
				}
			)
		end
		add(grid,row)
	end
	jgrid=grid
end

function animate()
	gridlock=false
	for r=1,8 do
		for c=1,8 do
			local j=jgrid[r][c]
			if j.offset[1]~=0 then
				j.offset[1]-=
					sgn(j.offset[1])*fallspeed
				gridlock=true
			end
			if j.offset[2]~=0 then
				j.offset[2]-=
					sgn(j.offset[2])*fallspeed
				gridlock=true
			end
		end
	end
end

function swap(a,b)
	if are_neighbors(a,b) then
		local aj=jgrid[a[2]+1][a[1]+1]
		local bj=jgrid[b[2]+1][b[1]+1]
		aj.sprite,bj.sprite=bj.sprite,aj.sprite

		if not has_matches() then
			aj.sprite,bj.sprite=bj.sprite,aj.sprite
		else
			-- set anim offsets
			if a[1]~=b[1] then
				aj.offset[1]=jsize*sgn(b[1]-a[1])
				bj.offset[1]=jsize*sgn(a[1]-b[1])
			end
			if a[2]~=b[2] then
				aj.offset[2]=jsize*sgn(b[2]-a[2])
				bj.offset[2]=jsize*sgn(a[2]-b[2])
			end
		end
	end
	selected=nil
end

function are_neighbors(a,b)
	return abs(a[1]-b[1])+
		abs(a[2]-b[2])==1
end

function match()
	-- scan grid, set matches nil
	local to_nil={}
	for r=1,8 do
		local last=nil
		local ct=0
		for c=1,8 do
			local j=jgrid[r][c]
			if j.sprite==last then
				ct+=1
			else
				if ct>2 then
					for i=c-1,c-ct,-1 do
						add(to_nil,{r,i})
					end
				end
				last=j.sprite
				ct=1
			end
		end
		if ct>2 then
			for i=9-1,9-ct,-1 do
				add(to_nil,{r,i})
			end
		end
	end
	for c=1,8 do
		local last=nil
		local ct=0
		for r=1,8 do
			local j=jgrid[r][c]
			if j.sprite==last then
				ct+=1
			else
				if ct>2 then
					for i=r-1,r-ct,-1 do
						add(to_nil,{i,c})
					end
				end
				last=j.sprite
				ct=1
			end
		end
		if ct>2 then
			for i=9-1,9-ct,-1 do
				add(to_nil,{i,c})
			end
		end
	end
	for tn in all(to_nil) do
		jgrid[tn[1]][tn[2]]=nil
	end
	
	--fill nils from above
	for c=1,8 do
		local offset=0
		for r=8,1,-1 do
			local cell=jgrid[r][c]
			if cell==nil then
				offset+=1
			elseif offset>0 then
				local jewel=jgrid[r][c]
				jewel.offset={0,-offset*jsize}
				jgrid[r+offset][c]=jewel
			end
		end
		--add new pieces
		for r=1,offset do
			jgrid[r][c]={
				sprite=rnd(jspr),
				offset={0,-offset*jsize}
			}
		end
	end
end

function has_matches()
	for r=1,8 do
		local last=nil
		local ct=0
		for c=1,8 do
			local j=jgrid[r][c]
			if j.sprite==last then
				ct+=1
			else
				if ct>2 then
					return true
				end
				last=j.sprite
				ct=1
			end
		end
		if ct>2 then
			return true
		end
	end
	for c=1,8 do
		local last=nil
		local ct=0
		for r=1,8 do
			local j=jgrid[r][c]
			if j.sprite==last then
				ct+=1
			else
				if ct>2 then
					return true
				end
				last=j.sprite
				ct=1
			end
		end
		if ct>2 then
			return true
		end
	end
	
	return false
end
-->8
--todo
--[[

+ better dropping animation
+ particles
+ use floodfill for match
  checking so that we can see
  how many pieces were in each
  part of the match, (so we 
  can give bonuses for more
  than 3)
+ scoring
+ title screen
+ reset board on no moves
	- make all possible swaps,
	  calling has_matches after
	  each. if false for all,
	  reset board
]]
__gfx__
00000000000a700000ccc7008999999900777700000e70000aaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaa7000ccccc70288888890777677000dee7003bbbbbba000000000000000000000000000000000000000000000000000000000000000000000000
007007000aa7aa70cccc7cc7288898897777767700dee7003bbbabba000000000000000000000000000000000000000000000000000000000000000000000000
00077000aaaa7aa70dccc7c028888989777777670deeee703bbbbaba000000000000000000000000000000000000000000000000000000000000000000000000
000770009aaaa7aa0dccccc028888889777777770dee7e703bbbbbba000000000000000000000000000000000000000000000000000000000000000000000000
0070070009aaaaa000dccc002888888967777777deeeeee73bbbbbba000000000000000000000000000000000000000000000000000000000000000000000000
00000000009aaa0000dccc002888888906777770deeeeee73bbbbbba000000000000000000000000000000000000000000000000000000000000000000000000
000000000009a000000dc0002222222800666600ddddddde03333330000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000a700000000000dcccccc6000000009999999900000000077777700000000aaaaaaaaaa00000000009a0000000000000ccc60000000000000000000000
000000aaa7000000000dcccccccc60000008888888889000000077777777000000bbbbbbbbbbba0000000009a000000000000ccccc6000000000000000000000
00000aaaaa70000000dcccccccccc6000028888888888900000777777777700003bbbbbbbbbbbba0000000499a0000000000ccccccc600000000000000000000
0000aaaaaaa700000dccccccc7cccc600028888898888900007777776777770003bbbbbbbabbbba0000000499a0000000000cccc7cc600000000000000000000
000aaaaa7aaa70000ccccccccc7cccc00028888889888900077777777677777003bbbbbbbbabbba00000049999a00000000dcccc7ccc60000000000000000000
00aaaaaaa7aaa7000cccccccccc7ccc00028888888988900077777777767777003bbbbbbbbbabba00000049979a00000000dccccc7cc60000000000000000000
0aaaaaaaaa7aaa700cccccccccccccc00028888888888900077777777777777003bbbbbbbbbbbba000004999799a0000000dccccc7cc60000000000000000000
09aaaaaaaaaaaaa00dccccccccccccc00028888888888900077777777777777003bbbbbbbbbbbba000004999979a0000000dcccccccc60000000000000000000
009aaaaaaaaaaa0000dccccccccccc000028888888888900077777777777777003bbbbbbbbbbbba0000499999799a000000dcccccccc60000000000000000000
0009aaaaaaaaa000000dccccccccc0000028888888888900067777777777777003bbbbbbbbbbbba0000499999999a000000dcccccccc60000000000000000000
00009aaaaaaa00000000dccccccc00000028888888888900006777777777770003bbbbbbbbbbbba00049999999999a000000dccccccc00000000000000000000
000009aaaaa0000000000dccccc000000028888888888900000677777777700003bbbbbbbbbbbba00049999999999a000000dccccccc00000000000000000000
0000009aaa000000000000dccc00000000028888888880000000677777770000003bbbbbbbbbbb0004999999999999a000000dccccc000000000000000000000
00000009a00000000000000dc00000000000222222220000000006666660000000033333333330000444444444444490000000dddd0000000000000000000000
