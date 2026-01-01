pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--main
w,h=8,8
jsize=14 -- j="jewel"
padx=jsize/2
pady=jsize
jspr=split("1,3,5,7,9,11")
gravity=0.4
bgosx,bgosy=0,0

score,
mvscore,
mul,
max_move=0,0,0,0

move_record=0
score_record=0

frame=0
flash=true
flashrate=20

state=nil

function _init()
	cartdata("luosrestil_jools")
	move_record=dget(0)
	score_record=dget(1)
	init_start()
end

function _update()
	frame+=1
	if frame%flashrate==0 then
		flash=not flash
	end
	update_bg()
	if state=="start" then
		update_start()
	elseif state=="game" then
		update_game()
	elseif state=="end" then
		update_end()
	end
	update_bg()
end

function _draw()
	draw_bg()
	if state=="start" then
		draw_start()
	elseif state=="game" then
		draw_game()
	elseif state=="end" then
		draw_end()
	end
end


function update_bg()
	bgosx+=0.5
	bgosy-=0.5
	bgosx%=30
	bgosy%=30
end

function draw_bg()
	cls()
	for i=-bgosx,128,30 do
		for j=-bgosy,128,30 do
			spr(64,i,j,4,4)
		end
	end
end
-->8
--start
local drips={}

function init_start()
	state="start"
end

function update_start()
	if rnd()<0.1 then
		spawn_drip()
	end
	update_drips()
	if btnp(🅾️) then
		init_game()
	end
end

function draw_start()
	draw_drips()
	local yoff=sin(t()/2)*4
	printctr(
		"jools",51+yoff,2,true,-1)
	printctr(
		"jools",50+yoff,10,true)

	if flash then
		printctr(
			"press 🅾️ to start",73,6)
	end
end

function spawn_drip()
	local nj=new_jewel()
	nj.x,nj.y=rnd()*(128-jsize),-jsize
	add(drips,nj)
end

function update_drips()
	for i=#drips,1,-1 do
		local drip=drips[i]
		drip.dy+=gravity
		drip.y+=drip.dy
		if drip.y>128 then
			deli(drips,i)
		end
	end
end

function draw_drips()
	for drip in all(drips) do
		spr(
				drip.sprite,
				drip.x,
				drip.y,
				2,2)
	end
end
-->8
--game
jgrid={}
swapspd=jsize/4
swapeps=0.01
ps={} --particles
txt={}
curr={0,0}
selected=nil
lastt=0
tlimit=60
timer=tlimit
tick=false

function init_game()
	state="game"
	score,mvscore,mul,max_move=0,0,0,0
	curr=0
	curr={0,0}
	selected=nil
	ps={}
	txt={}
	lastt=time()
	timer=tlimit
	tick=false
	init_jgrid()
end

function init_jgrid()
	local grid={}
	for r=1,h do
		add(grid,{})
		for c=1,w do
			local gen=true
			--ensure no matches
			while gen do
				gen=false
				local nj=new_jewel()
				nj.offset={0,-128+rnd()*10}
				nj.fall=true
				grid[#grid][c]=nj
				if has_matches(grid) then
					gen=true
				end
			end
		end
	end
	jgrid=grid
end

function update_game()
	--move cursor
	if btnp(➡️) then curr[1]+=1 end
	if btnp(⬅️) then curr[1]-=1 end
	if btnp(⬆️) then curr[2]-=1 end
	if btnp(⬇️) then curr[2]+=1 end
	--clamp cursor to grid
	curr[1]=mid(curr[1],0,w-1)
	curr[2]=mid(curr[2],0,h-1)
	if selected~= nil then
		swap(selected,curr)
	end
	
	--select and swap
	if btn(🅾️) then
		selected={curr[1],curr[2]}
	else
		selected=nil
	end
	
	animate()
	local did_match=match()
	if 
		not are_jmoving() and
		not did_match
	then
		if not tick then
			--gems land at start
			lastt=time()
			tick=true
		end
		local mvtotal=mvscore*mul
		if mvtotal>max_move then
			max_move=mvtotal
		end
		score+=mvtotal
		mvscore,mul=0,0
		if timer==0 then
			if max_move>move_record then
				move_record=max_move
				dset(0,move_record)
			end
			if score>score_record then
				score_record=score
				dset(1,score_record)
			end
			init_end()
		end
	end 
	update_particles()
	
	if tick then
		local currt=time()
		timer-=currt-lastt
		lastt=currt
	end
	if (timer<0) timer=0
end

function draw_game()
	draw_grid()
	draw_particles()
	if tick then
		print_score()
		print_timer()
	end
end

function draw_grid()
	--jewels
	for r=0,h-1 do
		for c=0,w-1 do
			local x=c*jsize+padx
			local y=r*jsize+pady
			local j=jgrid[r+1][c+1]
			spr(
				j.sprite,
				x+j.offset[1],
				y+j.offset[2],
				2,2)
		end
	end
	--cursor
	local currx=curr[1]*jsize+padx
	local curry=curr[2]*jsize+pady
	rect(
		currx,
		curry,
		currx+jsize-1,
		curry+jsize-1,
		9)
	--selection highlight
	if selected~=nil then
		local selx=selected[1]*jsize+padx
		local sely=selected[2]*jsize+pady
		rect(
			selx,
			sely,
			selx+jsize-1,
			sely+jsize-1,14)
	end
end

function animate()
	for r=1,h do
		for c=1,w do
			local j=jgrid[r][c]
			
			assert(not(j.swap and j.fall), r..":"..c)
			
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
				local jswap=(
					j.offset[1]~=0 or
					j.offset[2]~=0)
				j.swap=jswap
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
	local aj=jgrid[a[2]+1][a[1]+1]
	local bj=jgrid[b[2]+1][b[1]+1]
	if aj.fall or bj.fall then
		selected=nil
		return
	end
	if are_neighbors(a,b) then
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
			if 
				j.sprite==last and
				not j.fall and
				not j.swap
			then
				ct+=1
			else
				if ct>2 then
					for i=c-1,c-ct,-1 do
						jgrid[r][i].destroy=true
						pburst(r,i)
					end
				end
				last=j.sprite
				if j.fall or j.swap then
					last=nil
				end
				ct=1
			end
		end
		if ct>2 then
			for i=w,w+1-ct,-1 do
				jgrid[r][i].destroy=true
				pburst(r,i)
			end
		end
	end
	for c=1,w do
		local last=nil
		local ct=0
		for r=1,h do
			local j=jgrid[r][c]
			if 
				j.sprite==last and
				not j.fall and
				not j.swap
			then
				ct+=1
			else
				if ct>2 then
					for i=r-1,r-ct,-1 do
						jgrid[i][c].destroy=true
						pburst(i,c)
					end
				end
				last=j.sprite
				if j.fall or j.swap then
					last=nil
				end
				ct=1
			end
		end
		if ct>2 then
			for i=h,h+1-ct,-1 do
				jgrid[i][c].destroy=true
				pburst(i,c)
			end
		end
	end
	
	-- scoring
	local seen={}
	local grps={}
	for r=1,h do
		for c=1,w do
			local j=jgrid[r][c]
			local k=keyify(r,c)
			if seen[k] or not j.destroy then
				goto continue
			end
			seen[k]=true
			local grp=floodfill(r,c,seen)
			add(grps,grp)
			
			::continue::
		end
	end
	
	for grp in all(grps) do
		mul+=1
		local grpscr=#grp==3 and 1 or #grp
		mvscore+=grpscr
		local totx=0
		local toty=0
		for pos in all(grp) do
			totx+=(pos[2]-1)*jsize
			toty+=(pos[1]-1)*jsize
		end
		local avgx=totx/#grp+padx
		local avgy=toty/#grp+pady
		add(txt,new_txt("+"..grpscr,avgx,avgy))
		if mul>1 then
			add(txt,new_txt("x"..mul,avgx,avgy,true))
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
				if j.swap then
					j.swap=false
				end
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
	return #grps>0
end

function floodfill(r,c,seen)
	local jspr=jgrid[r][c].sprite
	local q={}
	local grp={}
	add(q,{r,c})
	while #q>0 do
		local curr=deli(q,1)
		add(grp,curr)
		local nbrs={
			{curr[1],curr[2]-1},
			{curr[1],curr[2]+1},
			{curr[1]-1,curr[2]},
			{curr[1]+1,curr[2]}
		}
		for nbr in all(nbrs) do
			local k=keyify(nbr[1],nbr[2])
			if 
				seen[k]==nil and
				is_on_grid(nbr) 
			then
				local j=jgrid[nbr[1]][nbr[2]]
				if 
					j.sprite==jspr and 
					j.destroy
				then
					seen[k]=true
					add(q,nbr)
				end
			end
		end
	end
	return grp
end

function has_matches(grid)
	if grid==nil then
		grid=jgrid
	end
	for r=1,#grid do
		local last=nil
		local ct=0
		for c=1,w do
			local j=grid[r][c]
			if 
				j~=nil and
				j.sprite==last
			then
				ct+=1
			else
				if ct>2 then
					return true
				end
				last=nil
				if j~=nil then
					last=j.sprite
				end
				
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
		for r=1,#grid do
			local j=grid[r][c]
			if 
				j~=nil and
				j.sprite==last 
			then
				ct+=1
			else
				if ct>2 then
					return true
				end
				if j~=nil then
					last=j.sprite
				end
				ct=1
			end
		end
		if ct>2 then
			return true
		end
	end
	
	return false
end

function pburst(r,c,n)
	n=n or 20
	for i=1,n do
		local x=(c-1)*jsize+padx
		local y=(r-1)*jsize+pady
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
	
	for i=#txt,1,-1 do
		local it=txt[i]
		it:update()
		if it.ttl==0 then
			deli(txt,i)
		end
	end
end

function draw_particles()
	for p in all(ps) do
		p:draw()
	end
	
	for it in all(txt) do
		it:draw()
	end
end

function keyify(a,b)
	return a..":"..b
end

function is_on_grid(pos)
	return (
		pos[1]>0 and
		pos[2]>0 and
		pos[1]<=w and
		pos[2]<=h
	)
end

function print_score()
	print("score: "..score,2,4,2)
--	print("move:"..mvscore,59,3,2)
	print("score: "..score,3,3,9)
--	print("move:"..mvscore,60,2,9)
end

function print_timer()
	local ceilt=ceil(timer)
	print("time: "..ceilt,79,4,2)
	print("time: "..ceilt,80,3,9)
end

function are_jmoving()
	for row in all(jgrid) do
		for j in all(row) do
			if j.fall or j.swap then
				return true
			end
		end
	end
	return false
end

function has_moves()
	--[[
	todo
	for each jewel
		for each possible direction
			move jewel
			if a match is formed
				return true
	return false
	]]
end
-->8
--end
bsize=0 --boxsize
tbsize=100 --target box size

function init_end()
	bsize=0
	state="end"
end

function update_end()
	if bsize<tbsize then
		bsize+=tbsize/15
	end
	update_particles()
	
	if
		bsize>=tbsize and
		btnp(🅾️)
	then
		init_game()
	end
end

function draw_end()
	--box
	if (bsize<tbsize) then
		draw_game()
	end
	x=64-bsize/2
	y=64-bsize/2
	rrectfill(
		x-1,y-1,
		bsize+2,bsize+2,
		6,7)
	rrectfill(
		x,y,
		bsize,bsize,
		6,0)

	-- game over
	if bsize>=tbsize then
		printctr(
			"game over",36,2,true,-1)
		printctr(
			"game over",35,9,true)
		
		-- max move
		local mm_record=max_move==move_record
		local mmtxt="max move: "..max_move
		if mm_record then
			mmtxt=mmtxt.." new record!"
		end		
		printctr(mmtxt,56,2,false,-1)	
		printctr(mmtxt,55,9)
		if mm_record then
			printctr(
				"             new record!",
				55,10)
		end
			
		-- score
		local s_record=score==score_record
		local stxt="score: "..score
		if s_record then
			stxt=stxt.." new record!"
		end
		printctr(stxt,66,2,false,-1)
		printctr(stxt,65,9)
		if s_record then
			printctr(
				"          new record!",
				65,10)
		end
		if flash then
			printctr(
				"play again? 🅾️",80,6)
		end
	end
end
-->8
--meta
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
	return nj
end

pclrs={7,8,9,10,11,12,14}

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

txtmeta={
	draw=function(self)
		self.clr=rnd(pclrs)
		print(
			self.val,
			self.x-1,self.y+1,
			0)
		print(
			self.val,
			self.x,self.y,
			self.clr)
	end
}
txtmeta.__index=txtmeta
setmetatable(txtmeta,{__index=pmeta})

function new_txt(val,x,y,lg)
	if lg==nil then
		lg=false
	end
	if lg then
		val="\^t\^w"..val
	end
	local txt={
		val=val,
		lg=lg,
		x=x,
		y=y,
		dx=0,
		dy=lg and -1.5 or -0.5,
		ttl=30,
		clr=14,
		destroy=false
	}
	setmetatable(txt,txtmeta)
	return txt
end
-->8
--util

function printctr(txt,y,clr,lg,offset)
	offset=(offset~=nil) and offset or 0
	local w=txtw(txt,lg)
	local hflw=w/2
	if(lg)txt="\^t\^w"..txt
	print(txt,64+offset-hflw,y,clr)
end

function txtw(txt,lg)
	local chrpx=#txt*3
	local spcs=#txt-1
	local w=chrpx+spcs
	return lg==true and w*2 or w 
end
-->8
--todo
--[[

+ persist max_move/score record
+ message for new high mvscore
+ reset board on no moves
	- make all possible swaps,
	  calling has_matches after
	  each. if false for all,
	  reset board

+ bonus stuff?
 - how do we make this fun?
   
]]
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000a70000000000009999990000000000777777000000000aaaaaaaa000000000009a00000000000000cc60000000000000000000000000000000
0070070000000aaa700000000008888888800000000777777770000000bbbbbbbbbb00000000009a0000000000000cccc6000000000000000000000000000000
000770000000aaaaa70000000028888888890000007777777777000003bbbbbbbbbba00000000499a00000000000cccccc600000000000000000000000000000
00077000000aaaa7aa7000000028888988890000077777767777700003bbbbbabbbba00000000499a0000000000dcccc7cc60000000000000000000000000000
0070070000aaaaaa7aa700000028888898890000077777776777700003bbbbbbabbba000000049999a000000000dcccc7cc60000000000000000000000000000
000000000aaaaaaaa7aa70000028888889890000077777777677700003bbbbbbbabba000000049979a000000000dccccc7c60000000000000000000000000000
0000000009aaaaaaaaaaa0000028888888890000077777777777700003bbbbbbbbbba0000004999799a00000000dccccc7c60000000000000000000000000000
00000000009aaaaaaaaa00000028888888890000077777777777700003bbbbbbbbbba0000004999979a00000000dccccccc60000000000000000000000000000
000000000009aaaaaaa000000028888888890000067777777777700003bbbbbbbbbba00000499999799a0000000dccccccc60000000000000000000000000000
0000000000009aaaaa0000000028888888890000006777777777000003bbbbbbbbbba00000499999999a00000000dcccccc00000000000000000000000000000
00000000000009aaa00000000008888888800000000677777770000000bbbbbbbbbb0000049999999999a00000000dcccc000000000000000000000000000000
000000000000009a000000000000222222000000000066666600000000033333333000000444444444449000000000ddd0000000000000000000000000000000
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
00000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000001111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000011111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000011111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000001111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
