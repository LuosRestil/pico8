pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
local pcsz=6 --piece size
local w=10 --board width
local h=20 --board height
local xpad=34 --board marg. l
local ypad=4 --board marg. top
slow_fr=0.01
max_slow_fr=0.93
local fast_fr=1
local fr=slow_fr
local ft=0 --fall timer
local lt=0 --last time
trigger_game_over=false
game_over=false
trigger_line_destroy=false
line_destroy=false
local ld_timer=0
local ld_dur=0.5
lvl=1
score="0"
lines=0
decay_px={}
psyses={}
local exploding=false

function _init()
	init_board()
	init_pieces()
end

function _update()
	if game_over then return end
	
	local now=time()
	local dt=now-lt
	lt=now
	
	for psys in all(psyses) do
		update_psys(psys)
	end
	
	--line destroy
	if line_destroy then
		ld_timer+=dt
		if ld_timer>ld_dur then
			ld_timer=0
			ft=0
			line_destroy=false
			increment_lines()
			increment_score()
			fill_destroyed()
			decay_px={}
			for psys in all(psyses) do
				psys.active=false
			end
			exploding=false
		else
			decay_lines()
			if #to_destroy==4 and not exploding then
				explode_lines()
				exploding=true
			end
		end
		return
	end
	local destroy_psyses=true
	for psys in all(psyses) do
		if #psys.ps>0 then
			destroy_psyses=false
			goto end_destroy_check
		end
	end
	::end_destroy_check::
	if destroy_psyses then
		psyses={}
	end
	
	ft+=dt
	
	if btn(⬇️) then
		fr=fast_fr
	else
		fr=slow_fr
	end
	
	if ft>1-fr then
		ft-=1-fr
		drop_piece()
	end
	
	if btnp(➡️) and can_move("r") then
		move_piece("r")
	end
	if btnp(⬅️) and can_move("l") then
		move_piece("l")
	end
	if btnp(🅾️) then
		rot_piece("l")
	end
	if btnp(❎) then
		--rot_piece("r")
		--for play testing...
		--stick on demand
		next_piece.shape=pieces[4]
	end
	
	check_lines()
	
	if #to_destroy>0 then
		trigger_line_destroy=true
	end
end

function _draw()
	cls()
	map(0)

	--board bg
 rectfill(xpad,ypad,xpad+pcsz*w,ypad+pcsz*h,0)
	
	--game over
	if game_over then
		print("game over",47,64,8)
		return
	end
	
	--debugging
	if msg~=nil then
		print(msg,xpad,ypad,9)
	end
	
	--board
	for i=1,h do
		for j=1,w do
			if brd[i][j]~=0 then
				local col=brd[i][j]-1
				local x=(j-1)*pcsz+xpad
				local y=(i-1)*pcsz+ypad
				sspr(16+(col*6),0,6,6,x,y) 
			end
		end
	end
	
	--piece
	local col=piece.shape.col-1
	local spr_pos=16+col*6
	for c in all(brd_coords()) do
		local x=(c[1]-1)*pcsz+xpad
		local y=(c[2]-1)*pcsz+ypad
		if y>=0 then
			sspr(spr_pos,0,6,6,x,y)
		end
	end
	
	--decay px
	for px in all(decay_px) do
		pset(px.x,px.y,0)
	end
	
	--particles
	for psys in all(psyses) do
		draw_psys(psys)
	end
	
	--next piece
	rectfill(96,4,126,36,0)
	print("next",104,8,7)
	col=next_piece.shape.col-1
	spr_pos=16+col*6
	local pc=next_piece
	local shp=pc.shape
	local vars=shp.vars
	local v=vars[1]
	for b in all(v) do
		local x=(b[1]-1)*pcsz+108+shp.np_pad[1]
		local y=(b[2]-1)*pcsz+25+shp.np_pad[2]
		sspr(spr_pos,0,6,6,x,y)
	end
	
	--stat container
	rectfill(2,2,30,45,0)
	
	--level
	print("level",5,4,7)
	print(lvl,5,10,7)
	
	--lines
	print("lines",5,18,7)
	print(lines,5,24,7)
	
		--score
	print("score",5,32,7)
	print(score,5,38,7)
	
	if trigger_line_destroy then
		line_destroy=true
		trigger_line_destroy=false
	end
	
	if trigger_game_over then
		game_over=true
	end
end
-->8
--board
function init_board()
	brd=new_board()
	to_destroy={}
end

function new_board()
	local nb={}
	for i=1,20 do
		local row={}
		for j=1,10 do
			add(row,0)
		end
		add(nb,row)
	end
	return nb
end

function check_lines()
	for row=1,#brd do
		for col in all(brd[row]) do
			if col==0 then
				goto continue
			end
		end
		--todo use set?
		add(to_destroy,row)
		::continue::
	end
end

--todo this seems inefficient
function decay_lines()
	for row in all(to_destroy) do
		for i=1,30 do
			local x=rnd(10*pcsz)+xpad
			local y=rnd(6)+ypad+(row-1)*pcsz
			add(decay_px,{x=x,y=y})
		end
	end
end

function explode_lines()
	for row in all(to_destroy) do
		for i=1,10 do
			local x=xpad+(i-1)*pcsz+3
			local y=ypad+(row-1)*pcsz+3
			add(psyses,new_psys(x,y))
		end
	end
end

--todo score overflows
local lines_base_score={40,100,300,1200}

function increment_lines()
	lines+=#to_destroy
	local new_lvl=flr(lines/10)+1
	if new_lvl~=lvl then
		slow_fr+=.08
		if slow_fr>max_slow_fr then
			slow_fr=max_slow_fr
		end
		--todo level up indicator
	end
	lvl=new_lvl
end

function increment_score()
	local l=#to_destroy
	local base=lines_base_score[l]
	local to_add=tostr(base*lvl)
	assert(base*lvl>0)
	
	local carry=0
	local res=""
	local slen=#score
	local talen=#to_add
	local maxlen=max(slen,talen)
	for i=0,maxlen-1 do
		local dig1=sub(score,slen-i,slen-i)
		dig1=(dig1=="" and "0" or dig1)
		dig1=tonum(dig1)
		local dig2=sub(to_add,talen-i,talen-i)
		dig2=(dig2=="" and "0" or dig2)
		dig2=tonum(dig2)
		local sum=dig1+dig2+carry
		carry=flr(sum/10)
		res=tostr(sum%10)..res
	end
	if carry > 0 then
		res=tostr(carry)..res
	end
	score=res
end

function fill_destroyed()
	local nb=new_board()
	for i=1,20 do
		local shift=0
		for row in all(to_destroy) do
			if row==i then
				goto continue
			end
			if (row>i) shift+=1
		end

		nb[i+shift]=brd[i]
		::continue::
	end
	to_destroy={}
	brd=nb
end
-->8
--pieces
function init_pieces()
	pieces={
		--left zig
		{
			vars={
				{{0,0},{1,0},{1,1},{2,1}},
				{{2,-1},{1,0},{2,0},{1,1}}
			},
			col=3,
			np_pad={0,0}
		},
		--right zig
		{
			vars={
				{{1,0},{2,0},{0,1},{1,1}},
				{{1,-1},{1,0},{2,0},{2,1}}
			},
			col=2,
			np_pad={0,0}
		},
		--box
		{
			vars={
				{{0,0},{1,0},{0,1},{1,1}}
			},
			col=1,
			np_pad={4,0}
		},
		--stick
		{
		 vars={
		 	{{0,0},{1,0},{2,0},{3,0}},
		 	{{1,1},{1,0},{1,-1},{1,-2}}
		 },
		 col=1,
		 np_pad={-2,3},
		 shiftl=true
		},
		--tri
		{
			vars={
				{{0,0},{1,0},{2,0},{1,1}},
				{{1,-1},{0,0},{1,0},{1,1}},
				{{1,-1},{0,0},{1,0},{2,0}},
				{{1,-1},{1,0},{2,0},{1,1}},
			},
			col=1,
			np_pad={1,0},
		},
		--left ell
		{
			vars={
				{{0,0},{1,0},{2,0},{0,1}},
				{{0,-1},{1,-1},{1,0},{1,1}},
				{{2,-1},{0,0},{1,0},{2,0}},
				{{1,-1},{1,0},{1,1},{2,1}}
			},
			col=3,
			np_pad={0,0}
		},
		--right ell
		{
			vars={
				{{0,0},{1,0},{2,0},{2,1}},
				{{1,-1},{1,0},{0,1},{1,1}},
				{{0,-1},{0,0},{1,0},{2,0}},
				{{1,-1},{2,-1},{1,0},{1,1}}
			},
			col=2,
			np_pad={0,0}
		}
	}

	piece=new_piece()
	next_piece=new_piece()
end


function new_piece()
	local pc=rnd(pieces)
	return {
		shape=pc,
		loc={
			pc.shiftl and 4 or 5,
			1
		},
		variant=1
	}
end

function drop_piece()
	if piece_can_drop() then
		piece.loc[2]+=1
	else
		anchor()
		piece=next_piece
		next_piece=new_piece()
		if not piece_can_spawn() then
			trigger_game_over=true
		end
	end
end

function set_brd(val)
	local coords=brd_coords()
	for coord in all(coords) do
		brd[coord[2]][coord[1]] = val
	end
end

function anchor()
	set_brd(piece.shape.col)
end

function brd_coords()
	local coords={}
	local shp=piece.shape
	local var=shp.vars[piece.variant]
	for s in all(var) do
		x=s[1]+piece.loc[1]
		y=s[2]+piece.loc[2]
		add(coords,{x,y})
	end
	return coords
end

function piece_can_drop()
	local coords=brd_coords()
	for c in all(coords) do
		local y=c[2]
		if y==20 then
			return false
		end
		if c[2]<1 then
			goto continue
		end
		local blw=brd[c[2]+1][c[1]]
		if blw~=0 then
			return false
		end
		::continue::
	end
	return true
end

function piece_can_spawn()
	local coords=brd_coords()
	for c in all(coords) do
		local y=c[2]
		local brdno=brd[c[2]][c[1]]
		if brdno~=0 then
			return false
		end
	end
	return true
end

function move_piece(dir)
	if can_move(dir) then
		local amt=dir=="l" and -1 or 1
		piece.loc[1]+=amt
	end
end

function can_move(dir)
	local coords=brd_coords()
	if dir=="l" then
		for c in all(coords) do
			local x=c[1]
			if x==1 then
				return false
			end
			if c[2]<1 then
				goto continue 
			end
			local blw=brd[c[2]][c[1]-1]
			if blw~=0 then
				return false
			end
			::continue::
		end
	elseif dir=="r" then
		for c in all(coords) do
			local x=c[1]
			if x==10 then
				return false
			end
			if c[2]<1 then
				goto continue
			end
			local blw=brd[c[2]][c[1]+1]
			if blw~=0 then
				return false
			end
			::continue::
		end
	end
	return true
end

function rot_piece(dir)
	local orig_var=piece.variant
	if dir=="l" then
		piece.variant+=1
		if piece.variant>#piece.shape.vars then
			piece.variant=1
		end
	else
		piece.variant-=1
		if piece.variant<1 then
			piece.variant=#piece.shape.vars
		end
	end

	if not valid() then
		piece.variant=orig_var
	end
end

function valid()	
	local coords=brd_coords()
	for c in all(coords) do
		if c[1]<1 or c[1]>#brd[1] then
			return false
		end
		if c[2]>#brd then
			return false
		end
		if c[2]<1 then
			goto continue
		end
		local bc=brd[c[2]][c[1]]
		if bc~=0 then
			return false
		end
		::continue::
	end
	return true
end




-->8
--particles
function new_psys(x,y)
	return {
		ps={},
		x=x,
		y=y,
		active=true
	}
end

function update_psys(psys)
	local to_del={}
	for p in all(psys.ps) do
		update_p(p)
		if p.life<0 then
			add(to_del,p)
		end
	end
	for td in all(to_del) do
		del(psys.ps,td)
	end
	if psys.active then
		for i=1,3 do
			add(psys.ps, new_p(psys.x,psys.y))
		end
	end
end

function draw_psys(psys)
	for p in all(psys.ps) do
		draw_p(p)
	end
end

function new_p(x,y)
	local p={
		life=flr(rnd(10,30)),
		col=rnd({8,9,10}),
		pos={x,y},
		vel={rnd(4)-2,rnd(4)-2}
	}
	return p
end

function update_p(p)
	p.life-=1
	p.pos[1]+=p.vel[1]
	p.pos[2]+=p.vel[2]
end

function draw_p(p)
	pset(p.pos[1],p.pos[2],p.col)
end
__gfx__
00000000111511111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111511111777711eeee11cccc10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070055555555177c711ee7e11cc7c10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000111111511777711eeee11cccc10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000111111511777711eeee11cccc10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700111111511111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111511110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
