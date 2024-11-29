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
score=0
lines=0

function _init()
	cls()
	map(0)
	init_board()
	init_pieces()
end

function _update()
	if game_over then return end
	
	local now=time()
	local dt=now-lt
	lt=now
	
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
		else
			decay_lines()
		end
		return
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
		rot_piece("r")
	end
	
	check_lines()
	
	if #to_destroy>0 then
		trigger_line_destroy=true
	end
end

function _draw()
	if line_destroy then return end

	--clear bg
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
			pset(x,y,0)
		end
	end
end

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
	score+=base*lvl
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

-- add board vals for piece
function set_brd(val)
	local coords=brd_coords()
	for coord in all(coords) do
		brd[coord[2]][coord[1]] = val
	end
end

function anchor()
	set_brd(piece.shape.col)
	--make_gold()
end

function make_gold()
	local seen={}
	for i=1,#brd do
		for j=1,#brd[1] do
			local val=brd[i][j]
			if val==0 and not seen[i..":"..j] do
				--flood fill
				local gold=true
				local area={}
				local q={}
				local tag=i..":"..j
				add(q,tag)
				seen[tag]=true
				while #q>0 do
					--process cell
					local cell=q[1]
					del(q,cell)
					add(area,cell)
					local rc=split(cell,":")
					local row=rc[1]
					local col=rc[2]
					if row==1 then gold=false end
					--add neighbors to queue
					--todo dry up
					local nrow
					local ncol
					--up
					nrow=row-1
					ncol=col
					tag=nrow..":"..ncol
					if (
						not seen[tag] and
						nrow>=1 and 
						nrow<=#brd and
						ncol>=1 and
						ncol<=#brd[1] and
						brd[nrow][ncol]==0
					) then
						seen[tag]=true
						add(q,tag)
					end 
					--down
					nrow=row+1
					ncol=col
					tag=nrow..":"..ncol
					if (
						not seen[tag] and
						nrow>=1 and 
						nrow<=#brd and
						ncol>=1 and
						ncol<=#brd[1] and
						brd[nrow][ncol]==0
					) then
						seen[tag]=true
						add(q,tag)
					end 
					--left
					nrow=row
					ncol=col-1
					tag=nrow..":"..ncol
					if (
						not seen[tag] and
						nrow>=1 and 
						nrow<=#brd and
						ncol>=1 and
						ncol<=#brd[1] and
						brd[nrow][ncol]==0
					) then
						seen[tag]=true
						add(q,tag)
					end 
					--right
					nrow=row
					ncol=col+1
					tag=nrow..":"..ncol
					if (
						not seen[tag] and
						nrow>=1 and 
						nrow<=#brd and
						ncol>=1 and
						ncol<=#brd[1] and
						brd[nrow][ncol]==0
					) then
						seen[tag]=true
						add(q,tag)
					end 
				end
				if gold then
					for cell in all(area) do
						local rc=split(cell,":")
						local row=rc[1]
						local col=rc[2]
						brd[row][col]=4
					end
				end
			end
		end
	end
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




__gfx__
00000000111511111111111111111111119999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111511111777711eeee11cccc19aaaa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070055555555177c711ee7e11cc7c19aa7a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000111111511777711eeee11cccc19aaaa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000111111511777711eeee11cccc19aaaa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700111111511111111111111111119999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
