pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- opensimplex demo v1.1
-- 2018 felice, incorporating code by kurt spencer

--------------------------------
-- unlicense: i'll follow the
-- original authors 'unlicense'
-- which basically puts the code
-- in the public domain.
-- see https://gist.github.com/kdotjpg/b1270127455a94ac5d19
--------------------------------

-- honestly, the code in *this*
-- tab is just some ugly but 
-- optimized ways of getting 
-- the simplex noise onto the 
-- screen to show it off, and
-- isn't particularly useful.
--
-- what you want to look at is
-- the actual opensimplex
-- functions in tab 1, notably:
--
--  os2d_noise(seed)
--   init the noise generator
--
--  os2d_eval(x,y)
--   returns a val [0-1) at x,y
--
-- the reason why the code in
-- this file is optimugly is
-- because os2d_eval, while
-- fast for what it does, is
-- still not a great real-time
-- function for a platform like
-- pico-8, so i do a bunch of
-- stuff to hide that, slowly
-- generating and caching
-- images incrementally in the
-- background, etc.
--
-- your takeaway from that is
-- you don't want to be calling
-- os2d_eval() for every pixel
-- every frame. use it to 
-- create your landmass or
-- whatever at the start of
-- your game, but don't rely on
-- using it every frame, at 
-- at least not very much.

function _init()
	-- image params
	_seed=0
	_scale=12
	
	-- start palette cycle
	_cyc=0
	_pause=true

	-- show help screen briefly
	_help=true
	_helptimer=90
end

function _update()
	if (btnp(🅾️)) _help=not _help _helptimer=0
	if (btnp(❎)) _pause=not _pause
	
	if (btnp(⬅️)) _seed-=1
	if (btnp(➡️)) _seed+=1
	
	if _lastseed!=_seed then
		_lastseed=_seed
		os2d_noise(_seed)
		_scales={}
		for i=1,24 do
			_scales[i]=
			{
				s=2^(-8+i/4),
				a=0x6000,
				m={}
			}
		end
	end
	
	if (btnp(⬆️)) _scale-=1
	if (btnp(⬇️)) _scale+=1
	_scale=mid(1,_scale,#_scales)
	
	local closest,best=0x7fff
	for i=1,#_scales do
		local s=_scales[i]
		if s.a>0 then
			local dist=abs(_scale-i)
			if closest>dist then
				closest=dist
				best=s
			end
		end
	end
	
	if best then
		-- just caching in locals
		local m=best.m
		local a=best.a
		
		-- back-figure x,y from addr
		local y=flr((a-0x6000)/64)-64
		local x=(a%64)*2-64
		
		-- scaled x-offsets within the
		-- current block of pixels
		local s=best.s
		local s2=s+s
		local s3=s2+s
		local s4=s3+s
		local s5=s4+s
		local s6=s5+s
		local s7=s6+s
		local s8=s7+s
		local s9=s8+s
		local sa=s9+s
		local sb=sa+s
		local sc=sb+s
		local sd=sc+s
		local se=sd+s
		local sf=se+s
		
		-- scaled y position
		local sy=s*y
		
		while stat(1)<0.935 do
			-- we always recompute the
			-- scaled x position to
			-- avoid precision issues
			-- with adding scaled deltas
			local sx=s*x
			
			-- unroll the pixel computes.
			-- 16 pixels at a time seems
			-- to be about as good as it
			-- gets for unrolling vs
			-- being too many committed
			-- cycles per iteration to
			-- get close to the frame
			-- budget without going over.
			m[a]=0x7777.7777+
				flr(os2d_eval(sx   ,sy)*7)*0x0000.0001+
				flr(os2d_eval(sx+s ,sy)*7)*0x0000.0010+
				flr(os2d_eval(sx+s2,sy)*7)*0x0000.0100+
				flr(os2d_eval(sx+s3,sy)*7)*0x0000.1000+
				flr(os2d_eval(sx+s4,sy)*7)*0x0001.0000+
				flr(os2d_eval(sx+s5,sy)*7)*0x0010.0000+
				flr(os2d_eval(sx+s6,sy)*7)*0x0100.0000+
				flr(os2d_eval(sx+s7,sy)*7)*0x1000.0000
			m[a+4]=0x7777.7777+
				flr(os2d_eval(sx+s8,sy)*7)*0x0000.0001+
				flr(os2d_eval(sx+s9,sy)*7)*0x0000.0010+
				flr(os2d_eval(sx+sa,sy)*7)*0x0000.0100+
				flr(os2d_eval(sx+sb,sy)*7)*0x0000.1000+
				flr(os2d_eval(sx+sc,sy)*7)*0x0001.0000+
				flr(os2d_eval(sx+sd,sy)*7)*0x0010.0000+
				flr(os2d_eval(sx+se,sy)*7)*0x0100.0000+
				flr(os2d_eval(sx+sf,sy)*7)*0x1000.0000
				
			-- next block plzkthx
			a+=8
			x+=16
			
			-- done?
			if(a<0) break
			
			-- next row?
			if x==64 then
				x-=128
				y+=1
				sy=s*y
			end
		end
		
		-- <spock>remember...</spock>
		best.a=a
	end

	-- cycle that palette
	if not _pause then
		_cyc+=0x.2
	end
	
	_helptimer=max(_helptimer-1,0)
	if _helptimer==1 then
		_help=false
	end
end

function _draw()
	-- set cycled screen palette
	-- (not draw palette, since
	-- we're just copying memory)
	local red,pink
	for i=0,13 do
		local c=flr((i/2+_cyc)%7+8)
		pal(i,c,1)
	end
	pal(14,0,1)
	pal(15,7,1)

	-- caching indicator,
	-- overwritten when cached.
	rectfill(87,121,127,127,14)
	print("caching...",88,122,15)
	
	-- copy pre-computed noise
	-- to vram
	for a,v in pairs(_scales[_scale].m) do
		poke4(a,v)
	end
	
	if _help then
		rectfill(25,95,101,119,14)
		print("⬅️➡️ to change seed",26, 96,15)
		print("⬆️⬇️ to change zoom",26,102,15)
		print(" ❎  to cycle color",26,108,15)
		print(" 🅾️  show this help",26,114,15)
	end
	
	-- debug
	if false then
		rectfill(0,0,24,6,14)
		print(stat(1),1,1,15)
	end
end

-->8
-- opensimplex noise

-- adapted from public-domain
-- code found here:
-- https://gist.github.com/kdotjpg/b1270127455a94ac5d19

--------------------------------

-- opensimplex noise in java.
-- by kurt spencer
-- 
-- v1.1 (october 5, 2014)
-- - added 2d and 4d implementations.
-- - proper gradient sets for all dimensions, from a
--   dimensionally-generalizable scheme with an actual
--   rhyme and reason behind it.
-- - removed default permutation array in favor of
--   default seed.
-- - changed seed-based constructor to be independent
--   of any particular randomization library, so results
--   will be the same when ported to other languages.

-- (1/sqrt(2+1)-1)/2
local _os2d_str=-0.211324865405187
-- (  sqrt(2+1)-1)/2
local _os2d_squ= 0.366025403784439

-- cache some constant invariant
-- expressions that were 
-- probably getting folded by 
-- kurt's compiler, but not in 
-- the pico-8 lua interpreter.
local _os2d_squ_pl1=_os2d_squ+1
local _os2d_squ_tm2=_os2d_squ*2
local _os2d_squ_tm2_pl1=_os2d_squ_tm2+1
local _os2d_squ_tm2_pl2=_os2d_squ_tm2+2

local _os2d_nrm=47

local _os2d_prm={}

-- gradients for 2d. they 
-- approximate the directions to
-- the vertices of an octagon 
-- from the center
local _os2d_grd = 
{[0]=
	 5, 2,  2, 5,
	-5, 2, -2, 5,
	 5,-2,  2,-5,
	-5,-2, -2,-5,
}

-- initializes generator using a 
-- permutation array generated 
-- from a random seed.
-- note: generates a proper 
-- permutation, rather than 
-- performing n pair swaps on a 
-- base array.
function os2d_noise(seed)
	local src={}
	for i=0,255 do
		src[i]=i
		_os2d_prm[i]=0
	end
	srand(seed)
	for i=255,0,-1 do
		local r=flr(rnd(i+1))
		_os2d_prm[i]=src[r]
		src[r]=src[i]
	end
end

-- 2d opensimplex noise.
function os2d_eval(x,y)
	-- put input coords on grid
	local sto=(x+y)*_os2d_str
	local xs=x+sto
	local ys=y+sto
	
	-- flr to get grid 
	-- coordinates of rhombus
	-- (stretched square) super-
	-- cell origin.
	local xsb=flr(xs)
	local ysb=flr(ys)
	
	-- skew out to get actual 
	-- coords of rhombus origin.
	-- we'll need these later.
	local sqo=(xsb+ysb)*_os2d_squ
	local xb=xsb+sqo
	local yb=ysb+sqo

	-- compute grid coords rel.
	-- to rhombus origin.
	local xins=xs-xsb
	local yins=ys-ysb

	-- sum those together to get
	-- a value that determines 
	-- which region we're in.
	local insum=xins+yins

	-- positions relative to 
	-- origin point.
	local dx0=x-xb
	local dy0=y-yb
	
	-- we'll be defining these 
	-- inside the next block and
	-- using them afterwards.
	local dx_ext,dy_ext,xsv_ext,ysv_ext

	local val=0

	-- contribution (1,0)
	local dx1=dx0-_os2d_squ_pl1
	local dy1=dy0-_os2d_squ
	local at1=2-dx1*dx1-dy1*dy1
	if at1>0 then
		at1*=at1
		local i=band(_os2d_prm[(_os2d_prm[(xsb+1)%256]+ysb)%256],0x0e)
		val+=at1*at1*(_os2d_grd[i]*dx1+_os2d_grd[i+1]*dy1)
	end

	-- contribution (0,1)
	local dx2=dx0-_os2d_squ
	local dy2=dy0-_os2d_squ_pl1
	local at2=2-dx2*dx2-dy2*dy2
	if at2>0 then
		at2*=at2
		local i=band(_os2d_prm[(_os2d_prm[xsb%256]+ysb+1)%256],0x0e)
		val+=at2*at2*(_os2d_grd[i]*dx2+_os2d_grd[i+1]*dy2)
	end
	
	if insum<=1 then
		-- we're inside the triangle
		-- (2-simplex) at (0,0)
		local zins=1-insum
		if zins>xins or zins>yins then
			-- (0,0) is one of the 
			-- closest two triangular
			-- vertices
			if xins>yins then
				xsv_ext=xsb+1
				ysv_ext=ysb-1
				dx_ext=dx0-1
				dy_ext=dy0+1
			else
				xsv_ext=xsb-1
				ysv_ext=ysb+1
				dx_ext=dx0+1
				dy_ext=dy0-1
			end
		else
			-- (1,0) and (0,1) are the
			-- closest two vertices.
			xsv_ext=xsb+1
			ysv_ext=ysb+1
			dx_ext=dx0-_os2d_squ_tm2_pl1
			dy_ext=dy0-_os2d_squ_tm2_pl1
		end
	else  //we're inside the triangle (2-simplex) at (1,1)
		local zins = 2-insum
		if zins<xins or zins<yins then
			-- (0,0) is one of the 
			-- closest two triangular
			-- vertices
			if xins>yins then
				xsv_ext=xsb+2
				ysv_ext=ysb
				dx_ext=dx0-_os2d_squ_tm2_pl2
				dy_ext=dy0-_os2d_squ_tm2
			else
				xsv_ext=xsb
				ysv_ext=ysb+2
				dx_ext=dx0-_os2d_squ_tm2
				dy_ext=dy0-_os2d_squ_tm2_pl2
			end
		else
			-- (1,0) and (0,1) are the
			-- closest two vertices.
			dx_ext=dx0
			dy_ext=dy0
			xsv_ext=xsb
			ysv_ext=ysb
		end
		xsb+=1
		ysb+=1
		dx0=dx0-_os2d_squ_tm2_pl1
		dy0=dy0-_os2d_squ_tm2_pl1
	end
	
	-- contribution (0,0) or (1,1)
	local at0=2-dx0*dx0-dy0*dy0
	if at0>0 then
		at0*=at0
		local i=band(_os2d_prm[(_os2d_prm[xsb%256]+ysb)%256],0x0e)
		val+=at0*at0*(_os2d_grd[i]*dx0+_os2d_grd[i+1]*dy0)
	end
	
	-- extra vertex
	local atx=2-dx_ext*dx_ext-dy_ext*dy_ext
	if atx>0 then
		atx*=atx
		local i=band(_os2d_prm[(_os2d_prm[xsv_ext%256]+ysv_ext)%256],0x0e)
		val+=atx*atx*(_os2d_grd[i]*dx_ext+_os2d_grd[i+1]*dy_ext)
	end
	return val/_os2d_nrm
end

-- note kurt's original code had
-- an extrapolate() function
-- here, which was called in 
-- four places in eval(), but i
-- found inlining it to produce
-- good performance benefits.

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
999aaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccddddddccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaa
999aaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccdddddddddddccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaa
9999aaaaabbbbbbbbbcccccbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccddddddddddddddcccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbba
9999aaaaaabbbbbbbbcccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccdddddddddddddddddccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
9999aaaaaabbbbbbbbcccccccccbbbbbbbbbbbbbbbbbbbbbbccccccccccccdddddddddddddddddddcccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
99999aaaaabbbbbbbbccccccccccbbbbbbbbbbbbbbbbbbbbbcccccccccccccdddddddddddddddddddcccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
99999aaaaaabbbbbbbccccccccccbbbbbbbbbbbbbbbbbbbbbccccccccccccccdddddddddddddddddddccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
999999aaaaabbbbbbbcccccccccccbbbbbbbbbbbbbbbbbbbbbccccccccccccccdddddddddddddddddddccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
999999aaaaaabbbbbbbccccccccccbbbbbbbbbbbbbbbbbbbbbccccccccccccccccddddddddddddddddddcccccccccccccbbbbbbbbbbbbbbbbbbbbbbccccccbbb
9999999aaaaabbbbbbbbcccccccccbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccdddddddddddddddddcccccccccccccbbbbbbbbbbbbbbbbbbbbbcccccccccc
8999999aaaaabbbbbbbbccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccddddddddddddddddccccccccccccbbbbbbbbbbbbbbbbbbbbccccccccccc
8999999aaaaaabbbbbbbbbccccbbbbbbbbbbbbbbbbbbbbbbbbbbbccccccccccccccccccddddddddddddddcccccccccccbbbbbbbbbbbbbbbbbbbbbccccccccccc
88999999aaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccdddddddddddddcccccccccccbbbbbbbbbbbbbbbbbbbbbbcccccccccc
88999999aaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccddddddddddccccccccccccbbbbbbbbbbbbbbbbbbbbbbcccccccccc
888999999aaaaaabbbbbbbbbbbbbbbbbbbbbbbbbaaabbbbbbbbbbbbbbbbccccccccccccccccdddddddddcccccccccccbbbbbbbbbbbbbbbbbbbbbbbcccccccccc
888999999aaaaaabbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaabbbbbbbbbbbbbbccccccccccccccccddddddccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccc
888999999aaaaaaabbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaabbbbbbbbbbbbbbccccccccccccccccdddccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbccccccccc
8888999999aaaaaaabbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbcccccccccccccccccccccccccccccbbbbbbbbbaaaaaaabbbbbbbbbbcccccccc
8888999999aaaaaaaaabbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbccccccccccccccccccccccccccbbbbbbbbbaaaaaaaaaabbbbbbbbcccccccc
88889999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbcccccccccccccccccccccccccbbbbbbbbaaaaaaaaaaaabbbbbbbbccccccc
888889999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbcccccccccccccccccccccccbbbbbbbbaaaaaaaaaaaaaabbbbbbbccccccc
8888899999999aaaaaaaaaaaaaaaaaaaaaaa99999999999aaaaaaaaaaaaaabbbbbbbbbccccccccccccccccccccccbbbbbbbaaaaaaaaaaaaaaaabbbbbbbcccccc
88888899999999aaaaaaaaaaaaaaaaaa999999999999999999aaaaaaaaaaaabbbbbbbbbcccccccccccccccccccccbbbbbbaaaaaaaaaaaaaaaaaabbbbbbcccccc
888888999999999aaaaaaaaaaaaaa999999999999999999999999aaaaaaaaaaabbbbbbbbcccccccccccccccccccbbbbbbbaaaaaaaaaaaaaaaaaaabbbbbbccccc
888888899999999999aaaaaa9999999999999999999999999999999aaaaaaaaaabbbbbbbcccccccccccccccccccbbbbbbaaaaaaaa99999aaaaaaaabbbbbccccc
888888899999999999999999999999999999999999999999999999999aaaaaaaaabbbbbbbcccccccccccccccccbbbbbbbaaaaaaa9999999aaaaaaabbbbbbcccc
88888888999999999999999999999999999988888888899999999999999aaaaaaaabbbbbbbccccccccccccccccbbbbbbaaaaaaa9999999999aaaaaabbbbbcccc
888888889999999999999999999999998888888888888888999999999999aaaaaaabbbbbbbcccccccccccccccbbbbbbbaaaaaa99999999999aaaaaabbbbbbccc
8888888889999999999999999999988888888888888888888899999999999aaaaaaabbbbbbbccccccccccccccbbbbbbaaaaaa9999999999999aaaaabbbbbbccc
88888888889999999999999999888888888888888888888888889999999999aaaaaaabbbbbbccccccccccccccbbbbbbaaaaaa99999999999999aaaaabbbbbccc
888888888899999999999998888888888888888888888888888888999999999aaaaaabbbbbbbccccccccccccbbbbbbbaaaaa999999999999999aaaaabbbbbbcc
8888888888899999999988888888888888888888888888888888888899999999aaaaaabbbbbbccccccccccccbbbbbbaaaaaa999999999999999aaaaabbbbbbcc
88888888888889999888888888888888888888888888888888888888899999999aaaaabbbbbbbccccccccccbbbbbbbaaaaa99999999999999999aaaabbbbbbcc
8888888888888888888888888888888888888eee8888888888888888889999999aaaaabbbbbbbcccccccccbbbbbbbaaaaaa99999999999999999aaaaabbbbbcc
8888888888888888888888888888888888eeeeeeeeee8888888888888889999999aaaaabbbbbbbcccccccbbbbbbbbaaaaa999999999999999999aaaaabbbbbbc
888888888888888888888888888888888eeeeeeeeeeeee88888888888888999999aaaaabbbbbbbbccccccbbbbbbbbaaaaa999999999999999999aaaaabbbbbbc
88888888888888888888888888888888eeeeeeeeeeeeeeee888888888888899999aaaaaabbbbbbbbcccbbbbbbbbbaaaaaa999999999999999999aaaaabbbbbbc
88888888888888888888888888888888eeeeeeeeeeeeeeeee888888888888999999aaaaabbbbbbbbbbbbbbbbbbbbaaaaa9999999998999999999aaaaabbbbbbc
88888888999999888888888888888888eeeeeeeeeeeeeeeeee88888888888999999aaaaabbbbbbbbbbbbbbbbbbbaaaaaa9999999999999999999aaaaabbbbbbb
888888999999999988888888888888888eeeeeeeeeeeeeeeeee8888888888899999aaaaabbbbbbbbbbbbbbbbbbbaaaaaa9999999999999999999aaaabbbbbbbb
8888999999999999988888888888888888eeeeeeeeeeeeeeeeee888888888899999aaaaaabbbbbbbbbbbbbbbbbbaaaaaa999999999999999999aaaaabbbbbbbb
88999999999999999988888888888888888eeeeeeeeeeeeeeeee8888888888999999aaaaabbbbbbbbbbbbbbbbbaaaaaaa999999999999999999aaaaabbbbbbbb
9999999999999999999888888888888888888eeeeeeeeeeeeeeee888888888999999aaaaabbbbbbbbbbbbbbbbbaaaaaaa999999999999999999aaaaabbbbbbbb
999999999999999999999888888888888888888eeeeeeeeeeeeee888888888999999aaaaabbbbbbbbbbbbbbbbbaaaaaaa99999999999999999aaaaaabbbbbbbb
9999999999999999999999988888888888888888eeeeeeeeeeeee888888888999999aaaaabbbbbbbbbbbbbbbbbaaaaaaa99999999999999999aaaaaabbbbbbbb
999999999999999999999999988888888888888888eeeeeeeeee8888888888999999aaaaabbbbbbbbbbbbbbbbbaaaaaaa99999999999999999aaaaaabbbbbbbb
9999999999999999999999999998888888888888888eeeeeeeee8888888888999999aaaaabbbbbbbbbbbbbbbbbaaaaaaaa999999999999999aaaaaabbbbbbbbb
99999aaaaaaaaa9999999999999998888888888888888eeeeee8888888888899999aaaaaabbbbbbbbbbbbbbbbbaaaaaaaa999999999999999aaaaaabbbbbbbbb
99aaaaaaaaaaaaaaa999999999999998888888888888888eee88888888888899999aaaaaabbbbbbbbbbbbbbbbbbaaaaaaaa9999999999999aaaaaaabbbbbbbbb
aaaaaaaaaaaaaaaaaaa999999999999998888888888888888888888888888999999aaaaaabbbbbbbbbbbbbbbbbbbaaaaaaaa99999999999aaaaaaaabbbbbbbbb
aaaaaaaaaaaaaaaaaaaaaa999999999999988888888888888888888888888999999aaaaaabbbbbbbbbbbbbbbbbbbaaaaaaaaaa99999999aaaaaaaaabbbbbbbbb
aaaaaaaaaaaaaaaaaaaaaaaa9999999999998888888888888888888888888999999aaaaabbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbb
aaaaaaaaaaaaaaaaaaaaaaaaaaa999999999988888888888888888888888999999aaaaaabbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb
aaaabbbbbbbbbbbaaaaaaaaaaaaaa9999999998888888888888888888888999999aaaaaabbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbb
bbbbbbbbbbbbbbbbbbaaaaaaaaaaaa999999999888888888888888888888999999aaaaabbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaabbbbbbb
bbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaa999999998888888888888888888999999aaaaaabbbbbbbbbcccccccbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaabbbbb
bbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaa99999998888888888888888888999999aaaaaabbbbbbbbcccccccccccbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaa
bbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaa9999999888888888888888889999999aaaaabbbbbbbbccccccccccccccbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaa
bbbbcccccccccbbbbbbbbbbbbbaaaaaaaa999999988888888888888888999999aaaaaabbbbbbbccccccccccccccccbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaa
cccccccccccccccbbbbbbbbbbbbaaaaaaaa99999998888888888888889999999aaaaabbbbbbbcccccccccccccccccccbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaa
cccccccccccccccccbbbbbbbbbbbaaaaaaa9999999888888888888888999999aaaaaabbbbbbbccccccccccccccccccccbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaa
cccccccccccccccccccbbbbbbbbbbaaaaaa9999999888888888888888999999aaaaabbbbbbbcccccccccccccccccccccccbbbbbbbbbbaaaaaaaaaaaaaaaaaaaa
ccccccccccccccccccccbbbbbbbbbaaaaaa9999999888888888888889999999aaaaabbbbbbcccccccccccccccccccccccccbbbbbbbbbaaaaaaaaaaaaaaaaaaaa
ccccccccccccccccccccbbbbbbbbbaaaaaaa99999998888888888888999999aaaaaabbbbbbccccccccccccccccccccccccccbbbbbbbbaaaaaaaaaaaaaaaa9999
ccccccccccccccccccccbbbbbbbbbaaaaaaa99999998888888888889999999aaaaabbbbbbccccccccccddddddcccccccccccbbbbbbbbbaaaaaaaaaaaa9999999
ccccccccccccccccccccbbbbbbbbbaaaaaa99999999888888888889999999aaaaaabbbbbbcccccccccdddddddddccccccccccbbbbbbbbaaaaaaaaa9999999999
ccddddddccccccccccccbbbbbbbbbaaaaaa99999999888888888889999999aaaaabbbbbbcccccccccdddddddddddcccccccccbbbbbbbaaaaaaaaa99999999999
cddddddddcccccccccccbbbbbbbbaaaaaaa99999999888888888899999999aaaaabbbbbbccccccccdddddddddddddccccccccbbbbbbbaaaaaaaa999999999999
ddddddddcccccccccccbbbbbbbbaaaaaaaa9999999988888888889999999aaaaaabbbbbbccccccccdddddddddddddcccccccccbbbbbbaaaaaaa9999999999999
ddddddddccccccccccbbbbbbbbbaaaaaaa99999999988888888899999999aaaaabbbbbbccccccccddddddddddddddccccccccbbbbbbbaaaaaa99999999999999
dddddddccccccccccbbbbbbbbbaaaaaaa99999999998888888899999999aaaaaabbbbbbccccccccddddddddddddddccccccccbbbbbbbaaaaaa99999999999999
ccdddcccccccccccbbbbbbbbaaaaaaaaa99999999988888888999999999aaaaaabbbbbbccccccccddddddddddddddccccccccbbbbbbaaaaaa999999999999999
cccccccccccccccbbbbbbbbaaaaaaaaa99999999998888888899999999aaaaaabbbbbbcccccccccddddddddddddddccccccccbbbbbbaaaaaa999999999988888
ccccccccccccccbbbbbbbbaaaaaaaa9999999999998888888999999999aaaaaabbbbbbcccccccccdddddddddddddcccccccccbbbbbbaaaaa9999999998888888
cccccccccccccbbbbbbbaaaaaaaaa9999999999998888888999999999aaaaaabbbbbbbcccccccccdddddddddddddccccccccbbbbbbaaaaaa9999999988888888
cccccccccccbbbbbbbbaaaaaaaa999999999999998888889999999999aaaaaabbbbbbbcccccccccddddddddddddcccccccccbbbbbbaaaaa99999999888888888
ccccccccccbbbbbbbaaaaaaaaa999999999999998888889999999999aaaaaabbbbbbbcccccccccccdddddddddccccccccccbbbbbbaaaaaa99999998888888888
ccccccccbbbbbbbbaaaaaaaa99999999999999998888899999999999aaaaaabbbbbbbccccccccccccccdddcccccccccccccbbbbbbaaaaa999999988888888888
ccccccbbbbbbbbbaaaaaaa999999999999999998888999999999999aaaaaabbbbbbbbcccccccccccccccccccccccccccccbbbbbbbaaaaa999999988888888888
cbbbbbbbbbbbbaaaaaaaa999999999999999998889999999999999aaaaaaabbbbbbbcccccccccccccccccccccccccccccbbbbbbbaaaaaa999999888888888888
bbbbbbbbbbbbaaaaaaa99999999999999999999999999999999999aaaaaabbbbbbbbccccccccccccccccccccccccccccbbbbbbbbaaaaa9999999888888888888
bbbbbbbbbbaaaaaaaa99999999999999999999999999999999999aaaaaaabbbbbbbbcccccccccccccccccccccccccccbbbbbbbbaaaaaa9999998888888888888
bbbbbbbbbaaaaaaaa99999999999999888899999999999999999aaaaaaabbbbbbbbccccccccccccccccccccccccccbbbbbbbbbaaaaaa99999998888888888888
bbbbbbbaaaaaaaaa99999999999988888899999999999999999aaaaaaabbbbbbbbbccccccccccccccccccccccccbbbbbbbbbbbaaaaaa99999998888888888889
bbbbaaaaaaaaaaa99999999999888888899999999999999999aaaaaaabbbbbbbbbccccccccccccccccccccccbbbbbbbbbbbbbaaaaaa999999988888888888889
aaaaaaaaaaaaaa99999999999888888899999999999999999aaaaaaaabbbbbbbbcccccccccccccccccccbbbbbbbbbbbbbbbbaaaaaaa999999988888888888899
aaaaaaaaaaaaa9999999999998888899999999999999999aaaaaaaaabbbbbbbbcccccccccccccccccbbbbbbbbbbbbbbbbbaaaaaaaa9999999888888888888899
aaaaaaaaaaa99999999999999888999999999999999999aaaaaaaabbbbbbbbbcccccccccccccccbbbbbbbbbbbbbbbbbbbaaaaaaaaa9999998888888888888899
aaaaaaaaaa9999999999999999999999999999999999aaaaaaaaabbbbbbbbbccccccccccccccbbbbbbbbbbbbbbbbbbaaaaaaaaaaa99999998888888888888999
aaaaaaaaa999999999999999999999999999999999aaaaaaaaaabbbbbbbbbccccccccccccccbbbbbbbbbbbbbbbbaaaaaaaaaaaaa999999988888888888888999
aaaaaaaa99999999999999999999999999999999aaaaaaaaaaabbbbbbbbbccccccccccccccbbbbbbbbbbbbbbaaaaaaaaaaaaaaa9999999988888888888888999
aaaaa999999999999999999999999999999999aaaaaaaaaaabbbbbbbbbbccccccccccccccbbbbbbbbbbbbaaaaaaaaaaaaaaaa999999999888888888888888999
999999999999999999999999999999999999aaaaaaaaaaabbbbbbbbbbccccccccccccccccbbbbbbbbbbaaaaaaaaaaaaaaaaa9999999998888888888888888999
999999999999999999999999999999999aaaaaaaaaaaaabbbbbbbbbbccccccccccccccccbbbbbbbbbbaaaaaaaaaaaaaaaa999999999988888888888888888999
9999999999999999999999999999999aaaaaaaaaaaaabbbbbbbbbbccccccccccccccccccbbbbbbbbbaaaaaaaaaaaaaa999999999999888888888888888888999
99999999999999999999999990000000000000000000000000000000000000000000000000000000000000000000000000000099998888888888888888888999
99999999999999999999999990077777000777770000007770077000000770707077707700077077700000077077707770770099988888888888888888888999
99999999999999999999999aa0777007707700777000000700707000007000707070707070700070000000700070007000707098888888888888888888888999
99999999999999999999aaaaa0770007707700077000000700707000007000777077707070700077000000777077007700707088888888888888888888888999
9999999999999999999aaaaaa0777007707700777000000700707000007000707070707070707070000000007070007000707088888888888888888888888999
999999999999999999aaaaaaa0077777000777770000000700770000000770707070707070777077700000770077707770777088888888888888888888888999
99999999999999999aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000088888888888888888888888999
99999999999999999aaaaaaaa0077777000777770000007770077000000770707077707700077077700000777007700770777088888888888888888888889999
99999999999999999aaaaaaaa0777077707700077000000700707000007000707070707070700070000000007070707070777088888888888888888888889999
9999999999999999aaaaaaaaa0770007707700077000000700707000007000777077707070700077000000070070707070707088888888888888888888889999
9999999999999999aaaaaaaab0770007707770777000000700707000007000707070707070707070000000700070707070707088888888888888888888889999
99999999999999999aaaaaaab0077777000777770000000700770000000770707070707070777077700000777077007700707088888888888888888888899999
99999999999999999aaaaaaab0000000000000000000000000000000000000000000000000000000000000000000000000000088888888888888888888899999
99999999999999999aaaaaaab0000007777700000000007770077000000770707007707000777000000770077070000770777088888888888888888888999999
99999999999999999aaaaaaab0000077070770000000000700707000007000707070007000700000007000707070007070707088888888888888888889999999
999999999999999999aaaaaab0000077707770000000000700707000007000777070007000770000007000707070007070770088888888888888888899999999
999999999999999999aaaaaab0000077070770000000000700707000007000007070007000700000007000707070007070707088888888888888888999999999
9999999999999999999aaaaaa000000777770000000000070077000000077077700770777077700000077077007770770070708888888888888899999999999a
9999999999999999999aaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000888888888888999999999999aa
99999999999999999999aaaaa0000007777700000000000770707007707070000077707070777007700000707077707000777088888888899999999999999aaa
999999999999999999999aaaa000007700077000000000700070707070707000000700707007007000000070707000700070708888888999999999999999aaaa
999999999999999999999aaaa0000077070770000000007770777070707070000007007770070077700000777077007000777088888999999999999999aaaaaa
9999999998889999999999aaa0000077000770000000000070707070707770000007007070070000700000707070007000700088899999999999999aaaaaaaaa
99999999988888999999999aa00000077777000000000077007070770077700000070070707770770000007070777077707000899999999999999aaaaaaaaaaa
999999998888888899999999a00000000000000000000000000000000000000000000000000000000000000000000000000000999999999999aaaaaaaaaaaaaa
9999999988888888899999999aaaaaabbbbbbbbbbcccccccccccccccccccccccbbbbbbbaaaaaaa9999999999998888889999999999999999aaaaaaaaaaaaaabb
99999999888888888899999999aaaaaaabbbbbbbbbccccccccccccccccccccccbbbbbbbaaaaaaa9999999999999999999999999999999aaaaaaaaaaaaaabbbbb
a99999998888888888889999999aaaaaaabbbbbbbbbbccccccccccccccccccccbbbbbbbaaaaaaaa9999999999999999999999999999aaaaaaaaaaaaabbbbbbbb
a999999988888888888889999999aaaaaaabbbbbbbbbbccccccccccccccccccccbbbbbbbaaaaaaaaa99999999999999999999999aaaaaaaaaaaaaabbbbbbbbbb
aa9999998888888888888899999999aaaaaabbbbbbbbbbcccccccccccccccccccbbbbbbbbaaaaaaaaaa999999999999999999aaaaaaaaaaaaaaabbbbbbbbbbbb
aa99999998888888888888889999999aaaaaaabbbbbbbbbcccccccccccccccccccbbbbbbbbaaaaaaaaaaaaaaa999999aaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbb
aa999999988888888888888889999999aaaaaaabbbbbbbbcccccccccccccccccccbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbb
aaa999999888888888888888889999999aaaaaaabbbbbbbbcccccccccccccccccccbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbb

