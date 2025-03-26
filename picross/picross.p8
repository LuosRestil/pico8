pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
gs=90 --grid size
dim=15 --dimension (15x15)
csize=gs/dim --cell size
grid=nil
pos={r=1,c=1}
lfao=nil --last frame action o
lfax=nil --last frame action x

function _init()
	grid = make_grid()
	load_imgs()
end

function _update()	
	if btnp(⬅️) do
		pos.c-=1
		if (pos.c<1) pos.c=dim
	elseif btnp(➡️) do
		pos.c+=1
		if (pos.c>dim) pos.c=1
	elseif btnp(⬆️) do
		pos.r-=1
		if (pos.r<1) pos.r=dim
	elseif btnp(⬇️) do 
		pos.r+=1
		if (pos.r>dim) pos.r=1
	end
	
	if btn(🅾️) do
		if lfao~=nil then
			grid[pos.r][pos.c]=lfao
		else
			local old=grid[pos.r][pos.c]
			local new=old==1 and 0 or 1
			grid[pos.r][pos.c]=new
			lfao=new
		end
	elseif btn(❎) do
		if lfax~=nil then
			grid[pos.r][pos.c]=lfax
		else
			local old=grid[pos.r][pos.c]
			local new=old==2 and 0 or 2
			grid[pos.r][pos.c]=new
			lfax=new
		end
	end
	
	if (not btn(🅾️)) lfao=nil
	if (not btn(❎)) lfax=nil
end

function _draw()
	cls(white)
	
	for r=1,#grid do
		for c=1,#grid[1] do
			local x,y=rc_to_coord(r,c)
			local clr=0
			if (grid[r][c]==1) clr=12
			if (grid[r][c]==2) clr=8
			rectfill(
				x,y,
				x+csize,y+csize,
				clr)
			rect(x,y,x+csize,y+csize,1)
		end
	end
	
	--draw numbers
	for i=1,#img.nums.rows do
		local x,y=rc_to_coord(i,16)
		y+=1
		x+=2
		local nums=img.nums.rows[i]
		for num in all(nums) do
			print(num,x,y)
			x+=6
			if (num>9) x+=4
		end
	end
	for i=1,#img.nums.cols do
		local x,y=rc_to_coord(16,i)
		y+=2
		local nums=img.nums.cols[i]
		for num in all(nums) do
			print(num,x,y)
			y+=6
		end
	end
	
	local x,y=rc_to_coord(
		pos.r,pos.c
	)
	rect(x,y,x+csize,y+csize,10)
end

function rc_to_coord(r,c)
	r-=1
	c-=1
	return c*csize,r*csize
end

function make_grid()
	local grid={}
	for i=1,dim do
		local row={}
		for j=1,dim do
			add(row,0)
		end
		add(grid,row)
	end
	return grid
end
-->8
--imgs
--todo stringify to save tokens
--[[
{{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{0,0,1,1,1,0,0,0,0,0,1,1,1,0,0},{0,1,1,1,1,1,0,0,0,1,1,1,1,1,0},{1,1,1,1,1,1,1,0,1,1,1,1,1,1,1},{1,1,1,1,1,1,1,1,1,1,1,0,1,1,1},{1,1,1,1,1,1,1,1,1,1,1,0,1,1,1},{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},{0,1,1,1,1,1,1,1,1,1,1,1,1,1,0},{0,0,1,1,1,1,1,1,1,1,1,1,1,0,0},{0,0,0,1,1,1,1,1,1,1,1,1,0,0,0},{0,0,0,0,1,1,1,1,1,1,1,0,0,0,0},{0,0,0,0,0,1,1,1,1,1,0,0,0,0,0},{0,0,0,0,0,0,1,1,1,0,0,0,0,0,0},{0,0,0,0,0,0,0,1,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}}
{{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},{0,1,0,0,1,0,0,1,1,0,1,0,0,0,1},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},{1,1,1,1,0,1,1,1,1,1,1,1,1,0,1},{1,0,1,0,0,1,1,0,1,1,0,1,0,0,1},{0,0,1,0,0,0,1,1,0,0,1,1,0,0,1},{1,1,0,0,0,0,0,1,1,1,1,0,0,0,1},{0,0,0,1,0,0,0,0,0,0,0,0,0,0,1},{0,0,1,1,1,0,0,0,0,0,1,1,1,0,1},{0,0,0,0,0,0,0,0,0,0,0,0,1,0,0},{1,1,1,1,1,1,1,1,1,0,0,0,1,0,0},{1,0,1,0,1,0,1,0,1,0,0,1,1,0,0},{1,1,1,1,1,1,1,1,1,0,0,0,0,0,0},{1,0,1,0,1,0,1,0,1,0,0,0,0,0,0}}
]]
img1={{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},{0,0,1,1,1,0,0,0,0,0,1,1,1,0,0},{0,1,1,1,1,1,0,0,0,1,1,1,1,1,0},{1,1,1,1,1,1,1,0,1,1,1,1,1,1,1},{1,1,1,1,1,1,1,1,1,1,1,0,1,1,1},{1,1,1,1,1,1,1,1,1,1,1,0,1,1,1},{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},{0,1,1,1,1,1,1,1,1,1,1,1,1,1,0},{0,0,1,1,1,1,1,1,1,1,1,1,1,0,0},{0,0,0,1,1,1,1,1,1,1,1,1,0,0,0},{0,0,0,0,1,1,1,1,1,1,1,0,0,0,0},{0,0,0,0,0,1,1,1,1,1,0,0,0,0,0},{0,0,0,0,0,0,1,1,1,0,0,0,0,0,0},{0,0,0,0,0,0,0,1,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}}
--img2={{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},{0,1,0,0,1,0,0,1,1,0,1,0,0,0,1},{0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},{1,1,1,1,0,1,1,1,1,1,1,1,1,0,1},{1,0,1,0,0,1,1,0,1,1,0,1,0,0,1},{0,0,1,0,0,0,1,1,0,0,1,1,0,0,1},{1,1,0,0,0,0,0,1,1,1,1,0,0,0,1},{0,0,0,1,0,0,0,0,0,0,0,0,0,0,1},{0,0,1,1,1,0,0,0,0,0,1,1,1,0,1},{0,0,0,0,0,0,0,0,0,0,0,0,1,0,0},{1,1,1,1,1,1,1,1,1,0,0,0,1,0,0},{1,0,1,0,1,0,1,0,1,0,0,1,1,0,0},{1,1,1,1,1,1,1,1,1,0,0,0,0,0,0},{1,0,1,0,1,0,1,0,1,0,0,0,0,0,0}}

function load_imgs()
	-- populate rows
	local rows={}
	local cur=0
	for row in all(img1) do
		local nums={}
		for col in all(row) do
			if col==1 then 
				cur+=1
			else
				if cur>0 then
					add(nums,cur)
					cur=0
				end
			end
		end
		if cur>0 then 
			add(nums,cur)
		end
		if #nums==0 then
			add(nums,0)
		end
		cur=0
		add(rows,nums)
	end
	
	--populate cols
	local cols={}
	local cur=0
	for col=1,dim do
		local nums={}
		for row=1,dim do
			if img1[row][col]==1 then
				cur+=1
			else
				if cur>0 then
					add(nums,cur)
					cur=0
				end
			end
		end
		if cur>0 then 
			add(nums,cur)
		end
		if #nums==0 then
			add(nums,0)
		end
		cur=0
		add(cols,nums)
	end
	
	
	
	img={
		img=img1,
		nums={
			rows=rows,
			cols=cols
		}
	}
end
-->8
--colors
red=8
blue=12
white=7
black=0
yellow=10
dkblue=1
purple=2
__gfx__
00000000111111101111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001aaaaa101000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007001a999a101080801000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770001a997a101008001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770001a999a101080801000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007001aaaaa101000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111111101111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
