pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
w,h=8,8
jsize=16 -- j="jewel"
curr={0,0}
jspr={16,20,22,24,26,28}
--jspr={64,66,68,70,72,74}
jgrid={}
gridlock=false
selected=nil
gravity=0.4
swapspd=jsize/4
swapeps=0.01
ps={} --particles

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
	curr[1]=mid(curr[1],0,w-1)
	curr[2]=mid(curr[2],0,h-1)
	
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
	
	update_particles()
end

function _draw()
	cls()
	draw_grid()
	draw_particles()
end

function draw_grid()
	--jewels
	for r=0,h-1 do
		for c=0,w-1 do
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
	--cursor
	local currx=curr[1]*jsize
	local curry=curr[2]*jsize
	rect(
		currx,
		curry,
		currx+jsize-1,
		curry+jsize-1,9)
	--selection highlight
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
	for r=1,h do
		local row={}
		for c=1,w do
			add(row,new_jewel())
		end
		add(grid,row)
	end
	jgrid=grid
end

function animate()
	gridlock=false
	for r=1,h do
		for c=1,w do
			local j=jgrid[r][c]
			
			assert(not(j.swap and j.fall))

			if j.swap or j.fall then
				gridlock=true
			end
			if j.swap then
				if j.offset[1]~=0 then
					j.offset[1]-=
						sgn(j.offset[1])*swapspd
					if abs(j.offset[1])<=swapeps then
						j.offset[1]=0
					end
				end
				if j.offset[2]~=0 then
					j.offset[2]-=
						sgn(j.offset[2])*swapspd
					if abs(j.offset[2])<=swapeps then
						j.offset[2]=0
					end
				end
				j.swap=
					(j.offset[1]~=0 or
					j.offset[2]~=0)
			elseif j.fall then
				j.dy+=gravity
				j.offset[2]+=j.dy
				if j.offset[2]>0 then
					j.offset[2]=0
					j.fall=false
					j.dy=-1
				end
			end
		end
	end
end

function swap(a,b)
	if a.fall or b.fall then
		selected=nil
		return
	end
	if are_neighbors(a,b) then
		local aj=jgrid[a[2]+1][a[1]+1]
		local bj=jgrid[b[2]+1][b[1]+1]
		aj.sprite,bj.sprite=bj.sprite,aj.sprite

		if not has_matches() then
			aj.sprite,bj.sprite=bj.sprite,aj.sprite
		else
			aj.swap=true
			bj.swap=true
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
	for r=1,h do
		local last=nil
		local ct=0
		for c=1,w do
			local j=jgrid[r][c]
			if j.sprite==last then
				ct+=1
			else
				if ct>2 then
					for i=c-1,c-ct,-1 do
						jgrid[r][i].destroy=true
						particle_burst(r,i)
					end
				end
				last=j.sprite
				ct=1
			end
		end
		if ct>2 then
			for i=w,w+1-ct,-1 do
				jgrid[r][i].destroy=true
				particle_burst(r,i)
			end
		end
	end
	for c=1,w do
		local last=nil
		local ct=0
		for r=1,h do
			local j=jgrid[r][c]
			if j.sprite==last then
				ct+=1
			else
				if ct>2 then
					for i=r-1,r-ct,-1 do
						jgrid[i][c].destroy=true
						particle_burst(i,c)
					end
				end
				last=j.sprite
				ct=1
			end
		end
		if ct>2 then
			for i=h,h+1-ct,-1 do
				jgrid[i][c].destroy=true
				particle_burst(i,c)
			end
		end
	end
	
	--fill nils from above
	for c=1,w do
		local offset=0
		for r=h,1,-1 do
			local j=jgrid[r][c]
			if j.destroy then
				offset+=1
			elseif offset>0 then
				j.offset={0,-offset*jsize}
				jgrid[r+offset][c]=j
				j.fall=true
			end
		end
		--add new pieces
		for r=1,offset do
			local nj=new_jewel(
				{0,-offset*jsize}
			)
			nj.fall=true
			jgrid[r][c]=nj
		end
	end
end

function has_matches()
	for r=1,h do
		local last=nil
		local ct=0
		for c=1,w do
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
	for c=1,w do
		local last=nil
		local ct=0
		for r=1,h do
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

function count_destroyed()
	local ct=0
	for r=1,h do
		for c=1,w do
			if jgrid[r][c].destroy then
				ct+=1
			end
		end
	end
	return ct
end

function particle_burst(r,c,n)
	n=n or 20
	for i=1,n do
		local x=(c-1)*jsize
		local y=(r-1)*jsize
		local rx=rnd()*jsize+x
		local ry=rnd()*jsize+y
		add(ps,new_particle(rx,ry))
	end
end

function update_particles()
	for i=#ps,1,-1 do
		local p=ps[i]
		p:update()
		if p.ttl==0 then
			deli(ps,i)
		end
	end
end

function draw_particles()
	for p in all(ps) do
		p:draw()
	end
end
-->8
--todo
--[[

+ count pieces per match (so
  we can give bonuses
  for >3)
+ count chains (matches since
  last swap)
+ scoring
+ title screen
+ reset board on no moves
	- make all possible swaps,
	  calling has_matches after
	  each. if false for all,
	  reset board
+ bonus stuff
 - how do we make this
   actually fun?
]]
-->8
jmeta={
 prnt=function(self)
 	printh("spr: "..self.sprite..", offset: {"..self.offset[1]..", "..self.offset[2]..", fall:  "..self.fall..", swap: "..self.swap..", dy: "..self.dy..", destroy: "..self.destroy)
 end
}
jmeta.__index=jmeta

function new_jewel(offset)
	offset=offset or {0,0}
	local nj={
		sprite=rnd(jspr),
		offset=offset,
		fall=false,
		swap=false,
		dy=-1,
		destroy=false
	}
	setmetatable(nj,jmeta)
	return nj
end

local pclrs={7,8,9,10,11,12,14}

pmeta={
	update=function(self)
		self.x+=self.dx
		self.y+=self.dy
		self.ttl-=1
	end,
	draw=function(self)
		circfill(self.x,self.y,
			1,self.clr)
	end
}
pmeta.__index=pmeta

function new_particle(x,y)
	local p={
		x=x,
		y=y,
		dx=rnd()*5-2.5,
		dy=rnd()*5-2.5,
		ttl=flr(rnd()*10+10),
		clr=rnd(pclrs),
		destroy=false
	}
	setmetatable(p,pmeta)
	return p
end


__gfx__
00000000000a700000ccc70089999999007777000009a0000aaaaaa000ccc6000000000000000000000000000000000000000000000000000000000000000000
0000000000aaa7000ccccc70288888890777677000499a003bbbbbba00ccc6000000000000000000000000000000000000000000000000000000000000000000
007007000aa7aa70cccc7cc7288898897777767700499a003bbbabba0dc7cc600000000000000000000000000000000000000000000000000000000000000000
00077000aaaa7aa70dccc7c02888898977777767049999a03bbbbaba0dcc7c600000000000000000000000000000000000000000000000000000000000000000
000770009aaaa7aa0dccccc02888888977777777049979a03bbbbbba0dcccc600000000000000000000000000000000000000000000000000000000000000000
0070070009aaaaa000dccc0028888889677777774999999a3bbbbbba0dcccc600000000000000000000000000000000000000000000000000000000000000000
00000000009aaa0000dccc0028888889067777704999999a3bbbbbba00dccc000000000000000000000000000000000000000000000000000000000000000000
0000000000097000000dc0002222222800666600444444490333333000dddd000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a70000000000000ccc60000000000899999990000000000777700000000000009a000000000000aaaaaa00000000000000000000000000000000000000000
00aaa7000000000000ccc600000000002888888900000000077767700000000000499a00000000003bbbbbba0000000000000000000000000000000000000000
0aa7aa70000000000dc7cc60000000002888988900000000777776770000000000499a00000000003bbbabba0000000000000000000000000000000000000000
aaaa7aa7000000000dcc7c600000000028888989000000007777776700000000049999a0000000003bbbbaba0000000000000000000000000000000000000000
9aaaa7aa000000000dcccc600000000028888889000000007777777700000000049979a0000000003bbbbbba0000000000000000000000000000000000000000
09aaaaa0000000000dcccc6000000000288888890000000067777777000000004999999a000000003bbbbbba0000000000000000000000000000000000000000
009aaa000000000000dccc0000000000288888890000000006777770000000004999999a000000003bbbbbba0000000000000000000000000000000000000000
000970000000000000dddd0000000000222222280000000000666600000000004444444900000000033333300000000000000000000000000000000000000000
