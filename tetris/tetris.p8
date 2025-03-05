pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
msg=nil
pcsz=6 --piece size
local w=10 --board width
local h=20 --board height
xpad=34 --board marg. l
ypad=4 --board marg. top
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
lvl=0
score="0"
lines=0
decay_px={}
psyses={}
local exploding=false
local flash_timer=0
local flash=false
local flash_chg_timer=0
local flash_rate=3
local flash_duration=15
pc_id=0

function _init()
	init_board()
	init_pieces()
end

function _update()
	if game_over then return end
	
	if flash_timer>0 then
		update_flash()
	else
		flash=false
	end
	
	local now=time()
	local dt=now-lt
	lt=now
	
	for psys in all(psyses) do
		update_psys(psys)
	end
	
	--line destroy
	if line_destroy then
		handle_destroy(dt)
		return
	end
	local psyses_done=true

	--particles
	for psys in all(psyses) do
		if #psys.ps>0 then
			psyses_done=false
			goto end_psys_check
		end
	end
	::end_psys_check::
	if psyses_done then
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
	
	if 
		btnp(➡️) and 
		can_move("r") 
	then
		move_piece("r")
	end
	if 
		btnp(⬅️) and 
		can_move("l") 
	then
		move_piece("l")
	end
	if btnp(🅾️) then
		rot_piece("l")
	end
	if btnp(❎) then
		rot_piece("r")

		--stick on demand
		--next_piece.shape=pieces[4]
	end
	
	check_lines()
	
	if #to_destroy>0 then
		trigger_line_destroy=true
		sfx(01)
	end
end

function _draw()
	cls()
	if flash then
		rectfill(0,0,128,128,7)
	else
		map(0)
	end

	--board bg
	rectfill(
		xpad,
		ypad,
		xpad+pcsz*w,
		ypad+pcsz*h,
		0
	)
	
	--game over
	if game_over then
		print("game over",47,64,8)
		return
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
		local x=
			(b[1]-1)*
			pcsz+
			108+
			shp.np_pad[1]
		local y=
			(b[2]-1)*
			pcsz+
			25+
			shp.np_pad[2]
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
	
	--debugging
	if msg~=nil then
		print(msg,xpad,ypad,9)
	end
	
	if trigger_line_destroy then
		line_destroy=true
		trigger_line_destroy=false
	end
	
	if trigger_game_over then
		game_over=true
	end
end

function init_flash()
	flash=true
	flash_timer=flash_duration
	flash_chg_timer=flash_rate
end

function update_flash()
	flash_timer-=1
	if flash_chg_timer>0 then
		flash_chg_timer-=1
		if flash_chg_timer==0 then
			flash_chg_timer=flash_rate
			flash=not flash
		end
	end
end

function handle_destroy(dt)
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
		if 
			#to_destroy==4 and 
			not exploding 
		then
			explode_lines()
			exploding=true
			init_flash()
		end
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
		for cell in all(brd[row]) do
			if cell==0 then
				goto continue
			end
		end
		add(to_destroy,row)
		::continue::
	end
end

--todo this seems inefficient
function decay_lines()
	for row in all(to_destroy) do
		for i=1,30 do
			local x=
				rnd(10*pcsz)+
				xpad
			local y=
				rnd(6)+ypad+
				(row-1)*pcsz
			add(decay_px,{x=x,y=y})
		end
	end
end

function explode_lines()
	sfx(02)
	for row in all(to_destroy) do
		for i=1,10 do
			local x=xpad+(i-1)*pcsz+3
			local y=ypad+(row-1)*pcsz+3
			add(psyses,new_psys(x,y))
		end
	end
end

function increment_lines()
	lines+=#to_destroy
	local new_lvl=flr(lines/10)
	if new_lvl~=lvl then
		slow_fr+=.08
		if slow_fr>max_slow_fr then
			slow_fr=max_slow_fr
		end
		level_up()
	end
	lvl=new_lvl
end

local lines_base_score={
	40,100,300,1200
}

--string arithmetic
function increment_score()
	local l=#to_destroy
	local base=lines_base_score[l]
	local to_add=
		tostr(base*(lvl+1))
	local carry=0
	local res=""
	local slen=#score
	local talen=#to_add
	local maxlen=max(slen,talen)
	for i=0,maxlen-1 do
		local dig1=sub(
			score,
			max(slen-i,0),
			max(slen-i,0)
		)
		dig1=
			(dig1=="" and "0" or dig1)
		dig1=tonum(dig1)
		local dig2=sub(
			to_add,
			max(talen-i,0),
			max(talen-i,0)
		)
		dig2=
			(dig2=="" and "0" or dig2)
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

local pals = {
	{2,3},--purp,dkgrn
	{11,9},--ltgrn,orng
	{4,8},--brn,red
	{5,14},--dkgry,pink
	{3,12},--dkgrn,ltblue
	{8,2},--red,purp
	{9,4},--orng,brn
	{11,6},--ltgrn,ltgry
	{12,14}--ltblue,pink
}
local next_pal_idx=1

function level_up()
	local next_pal=
		pals[next_pal_idx]
	pal(12,next_pal[1])
	pal(14,next_pal[2])
	next_pal_idx+=1
	if next_pal_idx>#pals then
		next_pal_idx=1
	end
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
	pc_id+=1
	return {
		shape=pc,
		loc={
			pc.shiftl and 4 or 5,
			1
		},
		variant=1,
	}
end

function drop_piece()
	if piece_can_drop() then
		piece.loc[2]+=1
	else
		sfx(00)
		anchor()
		piece=next_piece
		next_piece=new_piece()
		if not piece_can_spawn() then
			trigger_game_over=true
		end
	end
end

function anchor()
	local coords=brd_coords()
	for c in all(coords) do
		if c[2]>0 and c[1]>0 then
			brd[c[2]][c[1]]=piece.shape.col
		else
			trigger_game_over=true
		end
	end
end

function on_brd(row,col)
	return (
		row>=1 and 
		row<=#brd and
		col>=1 and
		col<=#brd[1]
	)
end

--gets board coords of curr pc
function brd_coords()
	local coords={}
	local shp=piece.shape
	local var=
		shp.vars[piece.variant]
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
		local cx=c[1]
		local cy=c[2]
		if cy==20 then
			return false
		end
		if cy<1 then
			goto continue
		end
		local blw=brd[cy+1][cx]
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
		local amt=
			dir=="l" and -1 or 1
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
		if 
			piece.variant>
			#piece.shape.vars 
		then
			piece.variant=1
		end
	else
		piece.variant-=1
		if piece.variant<1 then
			piece.variant=
				#piece.shape.vars
		end
	end

	if not valid() then
		piece.variant=orig_var
	end
end

function valid()	
	local coords=brd_coords()
	for c in all(coords) do
		if 
			c[1]<1 or c[1]>#brd[1] 
		then
			return false
		end
		if c[2]>#brd then
			return false
		end
		if c[2]<1 then
			goto continue
		end
		local cell=brd[c[2]][c[1]]
		if cell~=0 then
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
			add(
				psys.ps,
				new_p(psys.x,psys.y)
			)
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
-->8
--todo
--[[

don't destroy gold in lines

create gold *after* 
	resolving destroyed lines
	
drop gold as far as possible

destroy gold lines

better game over

title screen

sound

choose level

save score with name input

animation for good score

]]


-->8
--util
function get_idx(tbl,val)
	for i=1,#tbl do
		if tbl[i]==val then
			return i
		end
	end
	return nil
end

function has_key(tbl,key)
	return (
		key~=nil and tbl[key]~=nil
	)
end

function print_arr(arr,label)
	local str=""
	for elem in all(arr) do
		if str=="" then
			str=elem
		else
			str=str..","..elem
		end
	end
	printh(
		(label~=nil and label..": "
		or "")..str
	)
end

function print_tbl(tbl)
	printh("to drop = {")
	for k,v in pairs(to_drp) do
		printh("	"..k..": "..v)
	end
	printh("}")
end

function print_brd_ids()
	printh("****************")
	for row in all(brd) do
		local rowstr=""
		for cell in all(row) do
			local val
			if cell.id~=nil then
				val=tostr(cell.id)
			else
				val="   "
			end
		 if #val<2 then 
		 	val="0"..val
		 end
		 if #val<3 then
		 	val="0"..val
   end
			rowstr=rowstr.."| "..val
		end
		printh(rowstr.."|")
	end
	printh("****************")
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
__sfx__
000200001534013340113400e3400734005340003400430000300213001d300173000f300003000f3000f3000f3000f3001030010300103001030010300103001030010300103001030011300113001230023300
000300002135321353223532235323353233532535326353263532734327343283432834328333293332b3332d3332e3332f33330323313233232333313343133431335313353133631336303113030a30300303
000500001b6401b6401c6402064024640286402b6402f6403164034640366403664036630366303563033630326302f6302c6302b6302862025620206201f6201d6201b6201a6201862017610156101361011610
011b0000243571c357123570c35500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011900000c050000001305000000070500000013050000000c0500000013050000000705000000130500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01190000000001f0501e0501f05020050000001f050000001e050000001f050000001d0501d0501d050000001c0501c0501c050000001b0501b0501b050000001a0501e0511f0511f0511f0521f0521f05200000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002000001885000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 0a0b4344

