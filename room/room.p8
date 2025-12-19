pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--main
local scenes={}
local scene=""
local hovered_item=nil
local ptr={x=64,y=64}
local ptr_spr={x=0,y=8,dim=3}
local ptr_spr_l={x=3,y=8,dim=5}
local msg=nil
local inv={}
local inv_btn
local inv_open=false
local inv_idx=1
local active_item=nil
--navigation
local nav
local nav_r
local nav_l
local nav_b
--
flry=79
--debug stuff
dbg="" --debug message
draw_hitboxes=false

function _init()
	scenes=init_scenes()
	--ensure appropriate txt len
	for _,rm in pairs(scenes) do
		for item in all(rm.items) do
			local lines=
				split(item.desc,"\n")
			for line in all(lines) do
				assert(#line<26)
			end
		end
	end
	
	scene="left"
	init_nav()
	init_inv_btn()
	init_test_inv()
end

function _update()
	dbg=nil
	
	--different input handling
	--for inventory
	if inv_open then
		update_inv()
		return
	end
	
	if
		btn(➡️) or
		btn(⬅️) or
		btn(⬆️) or
		btn(⬇️) or
		btn(❎)
	then
		msg=nil
	end
	
	if btn(➡️) then 
		ptr.x=mid(0,127,ptr.x+2)
	end
	if btn(⬅️) then 
		ptr.x=mid(0,127,ptr.x-2)
	end
	if btn(⬆️) then 
		ptr.y=mid(0,127,ptr.y-2)
	end
	if btn(⬇️) then 
		ptr.y=mid(0,127,ptr.y+2)
	end
	
	hover(scenes[scene])
	
	if 
		btnp(🅾️) and 
		hovered_item~=nil
	then
		hovered_item:activate()
		active_item=nil
	end
end

function _draw()
	--scene
	cls()
	assert(scenes[scene]~=nil)
	scenes[scene].draw_bg()
	draw_items(scenes[scene])
	--ui
	draw_inv_btn()
	if inv_open then
		draw_inv()
	else
		draw_ptr()
		draw_msg()
	end
	--debugging stuff
	draw_dbg()
--	draw_hovered()
end

function draw_ptr()
	if not empty(nav) then
		draw_nav_ptr()
	elseif active_item~=nil then
		draw_item_ptr()
	else
		draw_normal_ptr()
	end
end

function draw_nav_ptr()
	if nav.r then
		spr(32,ptr.x-7,ptr.y-3)
	elseif nav.l then
		spr(33,ptr.x,ptr.y-3)
	elseif nav.b then
		spr(34,ptr.x-4,ptr.y-7)
	end
end

function draw_item_ptr()
	assert(active_item~=nil)
	spr(
		active_item.sp,
		ptr.x-4,ptr.y-4)
	if hovered_item~=nil then
		draw_hover_bang()
	end
end

function draw_hover_bang()
	local x=ptr.x+5
	if ptr.x > 120 then
		x=ptr.x-6
	end
	line(x,ptr.y-5,x,ptr.y-3,
		clrs.yellow)
	pset(x,ptr.y-1,clrs.yellow)
end

function draw_normal_ptr()
	if hovered_item==nil then
		draw_sm_ptr()
	else
		draw_lg_ptr()
	end
end

function draw_sm_ptr()
	sspr(
		ptr_spr.x,
		ptr_spr.y,
		ptr_spr.dim,
		ptr_spr.dim,
		ptr.x-1,
		ptr.y-1)
end

function draw_lg_ptr()
	sspr(
		ptr_spr_l.x,
		ptr_spr_l.y,
		ptr_spr_l.dim,
		ptr_spr_l.dim,
		ptr.x-2,
		ptr.y-2)
end

--determine whether we're
--hovering over something
function hover(scene)
	hovered_item=nil
	
	--navigation
	nav={}
	if 
		colliding(ptr,nav_r) and
		scene_has_dir("right")
	then
		nav.r=true
		hovered_item=nav_r
	elseif 
		colliding(ptr,nav_l) and
		scene_has_dir("left")
	then
		nav.l=true
		hovered_item=nav_l
	elseif 
		colliding(ptr,nav_b) and
		scene_has_dir("back")
	then
		nav.b=true
		hovered_item=nav_b
	end
	
	for item in all(scene.items) 
	do
		if colliding(ptr,item) then
			hovered_item=item
		end
	end
	
	if colliding(ptr,inv_btn) do
		hovered_item=inv_btn
	end
end

function colliding(ptr,item)
	return ptr.x>=item.x and
		ptr.x<=item.x+item.w and
		ptr.y>=item.y and
		ptr.y<=item.y+item.h
end

function draw_msg()
	if msg==nil then return end
	local lines=split(msg,"\n")
	local longest=0
	for l in all(lines) do
		if #l>longest then
			longest=#l
		end
	end
	
	local w=(longest)*4
	local h=#lines*6
	local padx=(128-w)/2
	local pady=(128-h)/2
	--background
	rectfill(
		padx,pady,
		padx+w,pady+h,
		clrs.blue)
	--border
	rect(
		padx-1,pady-1,
		padx+w+1,pady+h+1,
		clrs.white)
	--text
	print(
		msg,
		padx+1,pady+1,
		clrs.black)
end

function draw_dbg()
	if dbg==nil then return end
	print(dbg,0,0,clrs.orange)
end

function draw_hovered()
	if hovered_item==nil then
		return
	end
	print(
		hovered_item.name,
		0,6,
		clrs.yellow)
end
-->8
--scenes
function init_scenes()
	return {
		start=init_scene_start(),
		right=init_scene_right(),
		left=init_scene_left(),
		grate=init_scene_grate()
	}
end

function init_scene_start()
	return {
		left="left",
		right="right",
		back=nil,
		items={
			{
				name="key",
				x=60,y=100,
				w=8,h=5,
				sp=48,
				desc=[[the key!!!]],
				draw=function(self) 
					spr(self.sp,self.x,self.y-1)
				end,
				activate=function(self)
					pickup(self)
				end	
			},
			{
				name="lock",
				x=52,y=48,
				w=5,h=15,
				sp=5,
				desc=[[the door is locked]],
				draw=function(self) 
					spr(
						self.sp,
						self.x,self.y+1,
						1,2)
				end,
				activate=function(self)
					if active_item~=nil then
						if active_item.name=="key" then
							msg="you unlock the door!"
						else
							wrong_item("unlock a door")
						end
					else
						msg="the door is locked!"
					end
				end	
			},
			{
				name="grate",
				x=81,y=4,
				w=15,h=15,
				desc=[[something's rattling
around in there]],
				draw=function(self) 
					draw_grate(self)
				end,
				activate=function(self)
					go_scene("grate")
				end
			}
		},
		draw_bg=function() 
			cls(clrs.purple)
			--floor
			rectfill(
				0,80,128,128,clrs.green)
			draw_door()
			local p="starting room"
			local pw=txt_w(p)
			print(p,64-pw/2,20,clrs.white)
		end
	}
end

function init_scene_right()
	return {
		left="start",
		items={},
		draw_bg=function()
			cls(clrs.red)
			local p="right room"
			local pw=txt_w(p)
			print(p,64-pw/2,62,clrs.white)
		end
	}
end

function init_scene_left()
	return {
		right="start",
		items={},
		draw_bg=function() 
			cls(clrs.purple)
			--floor
			rectfill(
				0,80,128,128,clrs.green)
			draw_bookshelf()
			local p="left room"
			local pw=txt_w(p)
			print(p,64-pw/2,20,clrs.white)
		end
	}
end

function init_scene_grate()
	return {
		back="start",
		items={
			{
				name="screw",
				x=2,y=2,
				w=4,h=4,
				desc="",
				draw=function(self) 
					sspr(8,24,5,5,
						self.x,self.y)
				end,
				activate=function(self)
					activate_screw(self)
				end
			},
			{
				name="screw",
				x=2,y=121,
				w=4,h=4,
				desc="",
				draw=function(self) 
					sspr(8,24,5,5,
						self.x,self.y)
				end,
				activate=function(self)
					activate_screw(self)
				end
			},
			{
				name="screw",
				x=121,y=121,
				w=4,h=4,
				desc="",
				draw=function(self) 
					sspr(8,24,5,5,
						self.x,self.y)
				end,
				activate=function(self)
					activate_screw(self)
				end
			},
		},
		draw_bg=function()
			rectfill(0,0,128,128,
				clrs.charcoal)
			rectfill(8,8,120,119,
				clrs.navy)
			local x=8
			local y=8
			local slat_h=12
			local cl={
				clrs.grey,
				clrs.charcoal,
				clrs.lavender
			}
			for i=0,6 do
				local s_y=y+2+i*(slat_h+4)
				local e_y=s_y+slat_h
				rectfill(x,s_y,120,s_y+2,
					clrs.lavender)
				rectfill(x,s_y+3,120,e_y,
					clrs.grey)
			end
		end
	}
end

function init_nav()
	nav={}
	nav_r={
		x=120,y=16,w=8,h=128-32,
		activate=function()
			navigate("right")
		end}
	nav_l={
		x=0,y=16,w=8,h=128-32,
		activate=function()
			navigate("left")
		end}
	nav_b={
		x=16,y=120,w=128-32,h=8,
		activate=function()
			navigate("back")
		end}
end

function navigate(dir)
	if scene_has_dir(dir) then
		go_scene(scenes[scene][dir])
	end
end

function scene_has_dir(dir)
	return scenes[scene][dir]~=nil
end

function go_scene(name)
	scene=name
	ptr={x=64,y=64}
	hovered_item=nil
	active_item=nil
	nav={}
end

function draw_items(scene)
	for item in all(scene.items) 
	do
		item:draw()
		if draw_hitboxes then
			draw_hitbox(item)
		end
	end
end

function draw_hitbox(item)
	rect(
		item.x,item.y,
		item.x+item.w,item.y+item.h,
		clrs.red)
end

function pickup(item)
	sfx(1)
	inv_add(item)
	rm_from_scene(item.name)
	msg="got "..item.name.."!"
end

function inv_add(item)
	add(inv,{
		name=item.name,
		sp=item.sp,
		desc=item.desc})
	item.remove=true
end

function rm_from_scene(name)
	local items=scenes[scene].items
	for i=1,#items do
		local item=items[i]
		if item.name==name then
			deli(items,i)
			return
		end
	end
end

function draw_door()
	--frame
	rectfill(27,25,63,flry,
		clrs.brown)
	--crack
	rectfill(29,27,61,flry,
		clrs.navy)
	--door	
	rectfill(30,28,60,flry,
		clrs.brown)
	--hinges
	rectfill(29,34,29,38,
		clrs.orange)
	rectfill(29,66,29,70,
		clrs.orange)
end

function draw_grate(grate)
	spr(6,grate.x,grate.y,2,2)
end

function open_grate()
	--todo play grate open sound
	scenes.grate=
		init_scene_grate_2()
end

function init_scene_grate_2()
	return {
		back="start",
		items={},
		draw_bg=function()
			rectfill(0,0,128,128,
				clrs.charcoal)
			rectfill(8,8,120,119,
				clrs.navy)
			circfill(4,4,2,clrs.black)
			circfill(4,123,2,clrs.black)
			circfill(123,123,2,clrs.black)
			print("todo: item goes here",
				24,64,clrs.white)
		end
	}
end

function activate_screw(screw)
	if active_item~=nil then
		if 
			active_item.name==
				"screwdriver"
		then
			open_grate()
		else
			wrong_item("turn a screw")
		end
	else
		msg=[[the grate is held closed with 
screws. you hear something 
rattling around inside.]]
	end
end

function wrong_item(action)
	sfx(0)
	msg="you can't "..action..[[ 
with a ]]..active_item.name
end

function draw_bookshelf()
	local w=40
	local h=70
	local sh=18
	local x=80
	local y=flry-h
	--frame
	rectfill(x,y,x+w,y+h,
		clrs.brown)
	--shelves
	for i=0,2 do
		--shelf hole
		local sxleft=x+2
		local sytop=y+4+i*(sh+4)
		local sxright=x+w-2
		local sybot=sytop+sh
		rectfill(sxleft,sytop,
			sxright,sybot,clrs.navy)
		--books
		draw_books(sxleft,sytop,
			sxright,sybot,i)
	end
end

function draw_books
(
	sxleft,sytop,sxright,sybot,i
)
	if i==0 then
		--top
		rectfill(sxleft,sybot-12,
			sxleft+3,sybot,
			clrs.orange)
		rectfill(sxleft+4,sybot-14,
			sxleft+6,sybot,
			clrs.red)
		rectfill(sxleft+7,sybot-13,
			sxleft+10,sybot,
			clrs.brown)
		line(sxleft+7,sybot,
			sxleft+10,sybot,clrs.purple)
		rspr(8,sxleft+15,sybot-16,
			-45,1,2)
		rectfill(sxleft+25,sybot-13,
			sxleft+27,sybot,clrs.red)
		rectfill(sxleft+28,sybot-12,
			sxleft+32,sybot,clrs.green)
		rectfill(sxleft+33,sybot-13,
			sxleft+36,sybot,clrs.orange)
	elseif i==1 then
		--middle
		rectfill(sxleft,sybot-10,
			sxleft+2,sybot,
			clrs.red)
		rectfill(sxleft+3,sybot-12,
			sxleft+7,sybot,
			clrs.green)
		rectfill(sxleft+8,sybot-14,
			sxleft+11,sybot,
			clrs.orange)
		rectfill(sxleft+12,sybot-13,
			sxleft+14,sybot,
			clrs.red)
		rectfill(sxleft+15,sybot-12,
			sxleft+16,sybot,
			clrs.blue)
		rectfill(sxleft+17,sybot-15,
			sxleft+21,sybot,clrs.brown)
		line(sxleft+17,sybot,
			sxleft+21,sybot,clrs.purple)
		rectfill(sxleft+22,sybot-13,
			sxleft+25,sybot,clrs.green)
		rspr(8,sxleft+29,sybot-14,
			30,1,2)
	else
		--bottom
		rectfill(sxleft,sybot-13,
			sxleft+3,sybot,clrs.green)
		spr(8,sxleft+4,sybot-15,1,2)
		rectfill(sxleft+8,sybot-12,
			sxleft+10,sybot,
			clrs.lavender)
		rectfill(sxleft+11,sybot-14,
			sxleft+15,sybot,clrs.red)
		rectfill(sxleft+11,sybot-11,
			sxleft+15,sybot-10,
			clrs.purple)
		rectfill(sxleft+11,sybot-3,
			sxleft+15,sybot-2,
			clrs.purple)
		rectfill(sxleft+16,sybot-12,
			sxleft+19,sybot,clrs.orange)
		rectfill(sxleft+20,sybot-13,
			sxleft+22,sybot,clrs.blue)
		rectfill(sxleft+23,sybot-15,
			sxleft+25,sybot,clrs.pink)
		rectfill(sxleft+26,sybot-12,
			sxleft+28,sybot,clrs.green)
		rectfill(sxleft+29,sybot-10,
			sxleft+32,sybot,clrs.brown)
		line(sxleft+29,sybot,
			sxleft+32,sybot,clrs.purple)
		rectfill(sxleft+33,sybot-14,
			sxleft+36,sybot,clrs.red)
	end
end


-->8

-->8
--inventory
local w=110
local h=19
local x=7
local by=8 --y of boxes

function update_inv()
	if btnp(➡️) and inv_idx<10 then 
		inv_idx+=1
		sfx(2)
	elseif btnp(⬅️) and inv_idx>1 then 
		inv_idx-=1
		sfx(2)
	elseif btnp(🅾️) then
		active_item=inv[inv_idx]
		inv_open=false
		set_ptr_from_inv()
		sfx(3)
	elseif btnp(❎) then
		inv_open=false
		set_ptr_from_inv()
		active_item=nil
		sfx(5)
	end
end

function set_ptr_from_inv()
	ptr.x=x+(inv_idx-1)*11+6
	ptr.y=by+6
end

function draw_inv()
	--bg
	rectfill(
		x,0,x+w,h,clrs.black)
	--border
	rect(x,0,x+w,h,clrs.white)
	--boxes
	for i=0,9 do
		local bx=x+i*11
		rect(
			bx,by,bx+11,by+11,
			clrs.white)
	end
	--header
	print(
		"inventory",x+2,2,clrs.white)
	--items
	for i,item in ipairs(inv) do
		local ix=x+(i-1)*11+2
		spr(item.sp,ix,by+2)
	end
	--highlight
	local hx=x+(inv_idx-1)*11
	rect(hx,by,hx+11,by+11,
		clrs.orange)
		
	--item detail window
	local item=inv[inv_idx]
	if item==nil then return end
	local desc_lines=
		#split(item.desc,"\n")
	local idh= --item detail hght
		(desc_lines+1)*5+
		desc_lines+5
	local idy=by+11
	--bg
	rectfill(
		x,idy,x+w,idy+idh,clrs.black)
	--border
	rect(
		x,idy,x+w,idy+idh,clrs.white)
	--name
	print(item.name,x+2,idy+2,
		clrs.white)
	--desc
	print(item.desc,x+2,idy+10,
		clrs.white)
	--highlight again...
	rect(hx,by,hx+11,by+11,
		clrs.orange)
end

function init_inv_btn()
	inv_btn={
		name="inventory button",
		x=119,y=0,
		w=8,h=8,
		draw=function(self)
			if hovered_item==self then
				rectfill(
					self.x,
					self.y,
					self.x+self.w,
					self.y+self.h,
					clrs.white)
			end
			rect(
				self.x,
				self.y,
				self.x+self.w,
				self.y+self.h,
				clrs.navy)
			print("i",
				self.x+3,self.y+2,
				clrs.navy)
		end,
		activate=function(self) 
			inv_open=true
			sfx(4)
			hovered_item=nil
		end	
	}
end

function draw_inv_btn()
	inv_btn:draw()
end

function init_test_inv()
	inv={
		{
			name="flower",
			desc=[[it's a flower.
smells nice.]],
			sp=1,
		},
		{
			name="cup of tea",
			desc=[[smells of bitter
almonds.]],
			sp=2,
		},
		{
			name="screwdriver",
			desc=[[equally useful for
screwdriving and 
screw-un-driving.]],
			sp=3,
		},
		{
			name="soy burger",
			desc=[[no animals were
harmed in the making
of this game.]],
			sp=4,
		},
		{
			name="light bulb",
			desc=[[in case you have
a bright idea.]],
			sp=17,
		},
		{
			name="rabbit",
			desc=[[can pull a magician
out of its hat.]],
			sp=18,
		},
		{
			name="toy car",
			desc=[[vroom, vroom.]],
			sp=19,
		},
		{
			name="hat",
			desc=[[keeps the sun
out of your eyes.]],
			sp=20,
		},
	}
end

-->8
--util
function txt_w(txt)
	return #txt*3+#txt-1
end

function empty(table)
	for _ in pairs(table) do
		return false
	end
	return true
end

function rspr(s,x,y,a,w,h)
	local sx=(s%16)*8
	local sy=(s\16)*8
 local sw=(w or 1)*8
 local sh=(h or 1)*8
 local x0=flr(0.5*sw)
 local y0=flr(0.5*sh)
 local a=a/360
 local sa=sin(a)
 local ca=cos(a)
 for ix=sw*-1,sw+4 do
  for iy=sh*-1,sh+4 do
   local dx=ix-x0
   local dy=iy-y0
   local xx=flr(dx*ca-dy*sa+x0)
   local yy=flr(dx*sa+dy*ca+y0)
   if 
   	(xx>=0 and 
   	xx<sw and 
   	yy>=0 and 
   	yy<=sh-1) and
   	sget(sx+xx,sy+yy)~=0
   then
    pset(x+ix,y+iy,
    	sget(sx+xx,sy+yy))
   end
  end
 end
end
-->8
--clrs
clrs={
	black=0,
	navy=1,
	purple=2,
	green=3,
	brown=4,
	charcoal=5,
	grey=6,
	white=7,
	red=8,
	orange=9,
	yellow=10,
	lime=11,
	blue=12,
	lavender=13,
	pink=14,
	peach=15
}
-->8
--todo
--[[
*scale
*bookshelf puzzle
*hats puzzle-dummy heads with
	hats,either you can take all
	the hats and have to find the
	right color order to open the
	drawer of the table the heads
	are on, or you have to find
	the missing hat and put it
	on the dummy to advance
*drawing getting too expensive,
	going to have to store
	drawing instructions as
	strings and write a parser
]]
__gfx__
00000000007000000777700060000000000000000aaaa00055555555555555559999000000000000000000000000000000000000000000000000000000000000
0000000007a70000744447706600000000000000099990005dddddddddddddd59999000000000000000000000000000000000000000000000000000000000000
007007000073300077777707066000000f9ff9f09999a90056666666666666659999000000000000000000000000000000000000000000000000000000000000
0007700000003000767777070069a000fff9ffff999a990055555555555555554444000000000000000000000000000000000000000000000000000000000000
00077000000ccc007677770700999a00bbbbbbbb999999005dddddddddddddd54444000000000000000000000000000000000000000000000000000000000000
007007000000c00076777770000499a0444444449999990056666666666666659999000000000000000000000000000000000000000000000000000000000000
00000000000ccc007777770000004999ffffffff0999900055555555555555559999000000000000000000000000000000000000000000000000000000000000
0000000000ccccc007777000000004900ffffff00aaaa0005dddddddddddddd59999000000000000000000000000000000000000000000000000000000000000
07000700007777000000007700000000000000000a00a00056666666666666659999000000000000000000000000000000000000000000000000000000000000
707007000777a7700077700700888600000000000a00a00055555555555555559999000000000000000000000000000000000000000000000000000000000000
0707707707777a700000777708888660000ccc700aa0a0005dddddddddddddd59999000000000000000000000000000000000000000000000000000000000000
0000070007777770077771718888888800ccccc70a00a00056666666666666654444000000000000000000000000000000000000000000000000000000000000
0000070000777700777777e72888888f00ccccc70aaaa00055555555555555554444000000000000000000000000000000000000000000000000000000000000
00000000000770007777777722228888cccccccc0aaaa0005dddddddddddddd59999000000000000000000000000000000000000000000000000000000000000
00000000000660006777777005500550000000000000000056666666666666659999000000000000000000000000000000000000000000000000000000000000
00000000000660000677777700000000000000000000000055555555555555559999000000000000000000000000000000000000000000000000000000000000
17000000000000710111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16770000000077610166666700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16667700007766610016667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16666666666666610016667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16661100001166610001670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16110000000011610001670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11000000000000110000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000660660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99900000600060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90999999660660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90900909066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
040f0000073550735007350073502a300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000900002d75034750347503474034730007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000a00001c75500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000300001f75027750317550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002062026620326200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000032620246201d62023600246002d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
