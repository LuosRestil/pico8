pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
flry=99
hovered=nil
held=nil
ptr={x=64,y=64}
nav={}
inv_open=false
started=false

rf=rectfill
rrf=rrectfill

function _init()
	scenes=init_scenes()
	scene=scenes["bathroom"]
	init_nav()
	init_inv_btn()
end

function _update60()
	if inv_open then
		update_inv()
		return
	end
	
	if
		btnp(➡️) or
		btnp(⬅️) or
		btnp(⬆️) or
		btnp(⬇️) or
		btnp(❎) or
		btnp(🅾️)
	then
		msg=nil
	end
	
	if(btn(➡️))ptr.x+=1
	if(btn(⬅️))ptr.x-=1
	if(btn(⬆️))ptr.y-=1
	if(btn(⬇️))ptr.y+=1
	ptr.x=mid(0,127,ptr.x)
	ptr.y=mid(0,127,ptr.y)
	
	hover()
	
	if btnp(🅾️) and hovered~=nil then
		hovered:act()
		held=nil
	end
	if (btnp(❎)) held=nil	
end

function _draw()
	cls(0)
	scene:draw()
	for item in all(scene.items) do
		if(not item.hide and item.draw)item:draw()
	end
	if(started)inv_btn:draw()
	if inv_open then
		draw_inv()
	else
		draw_ptr()
		draw_msg()
	end
--	print(ptr.x..":"..ptr.y,0,0,10)
end

function draw_ptr()
	if nav.r or nav.l or nav.b then
		draw_nav_ptr()
	elseif held~=nil then
		draw_item_ptr()
	else
		draw_normal_ptr()
	end
end

function draw_nav_ptr()
	if nav.r then
		spr(2,ptr.x-7,ptr.y-3)
	elseif nav.l then
		spr(3,ptr.x,ptr.y-3)
	elseif nav.b then
		spr(4,ptr.x-4,ptr.y-7)
	end
end

function draw_item_ptr()
	spr(held.sp,ptr.x-4,ptr.y-4)
	if(hovered~=nil)draw_bang()
end

function draw_bang()
	local x=ptr.x+5
	if(ptr.x>120)x=ptr.x-6
	line(x,ptr.y-5,x,ptr.y-3,10)
	pset(x,ptr.y-1,10)
end

function draw_normal_ptr()
	palt(0b0000000000000010)
	if hovered==nil then 
		sspr(96,9,5,5,ptr.x-2,ptr.y-2)
	else
		sspr(96,16,7,7,ptr.x-3,ptr.y-3)
	end
	palt()
end

function hover()
	hovered=nil
	nav={}
	if colliding(ptr,nav_r) and scene.r then
		nav.r=true
		hovered=nav_r
	elseif colliding(ptr,nav_l) and scene.l then
		nav.l=true
		hovered=nav_l
	elseif colliding(ptr,nav_b) and scene.b then
		nav.b=true
		hovered=nav_b
	end
	
	for i in all(scene.items) do
		if(colliding(ptr,i) and not i.hide )hovered=i
	end
	
	if(colliding(ptr,inv_btn))hovered=inv_btn
end

function colliding(ptr,itm)
	return itm.x~=nil and 
		ptr.x>=itm.x and
		ptr.x<=itm.x+itm.w and
		ptr.y>=itm.y and
		ptr.y<=itm.y+itm.h
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
	rf(
		padx,pady,
		padx+w,pady+h,
		12)
	--border
	rect(
		padx-1,pady-1,
		padx+w+1,pady+h+1,
		7)
	--text
	print(
		msg,
		padx+1,pady+1,
		0)
end


-->8
function init_scenes()
	return{
		start=init_start(),
		books=init_books(),
		kitchen=init_kitchen(),
		basement=init_basement(),
		piano_rm=init_piano_rm(),
		piano=init_piano(),
		grate=init_grate(),
		clr_box=init_clr_box(),
		bathroom=init_bathroom(),
		radio=init_radio(),
		title=init_title(),
		outside=init_outside()
	}
end

function init_nav()
	nav={}
	nav_r={
		x=120,y=16,w=8,h=96,
		act=function()
			navigate("r")
		end
	}
	nav_l={
		x=0,y=16,w=8,h=96,
		act=function()
			navigate("l")
		end
	}
	nav_b={
		x=16,y=120,w=96,h=8,
		act=function()
			navigate("b")
		end
	}
end

function navigate(dir)
	if(scene[dir])go(scene[dir])
end

function go(scn_name)
	scene=scenes[scn_name]
	ptr={x=64,y=64}
	hovered=nil
	held=nil
	nav={}
end

function pickup(item,pmsg)
	pmsg=pmsg~=nil and pmsg or "got "..item.name.."!"
	add(inv,item)
	--todo pass pickup sfx
	set_msg(pmsg,0)
end

function scn_rm(item_name)
	items_rm(scene.items,item_name)
end

function inv_rm(item_name)
	items_rm(inv,item_name)
end

function items_rm(items,name)
	for i=1,#items do
		if items[i].name==name then
			deli(items,i)
			return
		end
	end
end

function wrong_item(action)
	--todo pass sfx no
	set_msg("you can't "..action.."\nwith "..article(held.name)..held.name,0)
end

function article(name)
	if name[-1]=="s" or name=="sheet music" then return "" end
	for v in all({"a","e","i","o","u"}) do
		if(name[1]==v)return "an "
	end
	return "a "
end

function get_item(name,scn_name)
	local scn=scn_name~=nil and scenes[scn_name] or scene
	for i in all(scn.items) do
		if(i.name==name)return i
	end
end

function set_msg(new_msg,fx)
	--todo msg fx as default
	fx=fx~=nil and fx or 0
	msg=new_msg
	sfx(fx)
end
-->8
--scenes
door_locked=true
grate_open=false
clr_box_open=false
rabbit_taken=false

function init_title()
	return {
		draw=function()
			sspr(24,32,78,15,27,30)
			print("arrow keys to move",30,55,9)
			print("z to interact",38,65,9)
			print("x to cancel",42,75,9)
		end,
		items=init_title_items()
	}
end

function init_title_items()
	return{
		{
			x=47,y=93,w=31,h=13,
			act=function()
				go("start")
				--change music
				started=true
			end,
			draw=function()
				rect(47,93,77,105,7)
				rf(48,94,76,104,1)
				print("start",53,97,7)
			end
		}
	}
end

function init_start()
	return {
		l="books",
		r="piano_rm",
		draw=function(self)
			std_bg()
			--window
			rf(104,8,127,48,7)
			rf(106,10,125,25,12)
			rf(106,29,125,46,12)
			sspr(8,8,11,6,111,13)
			sspr(6,14,20,7,106,40)
			-- drawer
			line(3,71,38,71,15)
			rf(3,72,38,78,4)
			rect(7,73,34,77,1)
			sspr(19,8,6,3,18,74)
			rf(3,79,5,100,4)
			rf(36,79,38,100,4)
		end,
		items=init_start_items()
	}
end

function init_start_items()
	local door={
		x=51,y=33,w=37,h=64,
		act=function()
			if door_locked then
				set_msg("a door leading\nto the outside.\nit's locked.")
			else
				go("outside")
				-- switch music
			end
		end,
		draw=function()
			draw_door(48)
		end
	}
	local lock={
		name="lock",
		x=80,y=60,w=6,h=15,
		act=function()
			if held==nil then
				set_msg("looks like you'll\nneed a key.")
			elseif held.name=="key" then
				--todo pass sfx unlock
				set_msg("you unlock the door!",0)
				door_locked=false
				scn_rm("lock")
				inv_rm("key")
			else
				--wrong item
			end
		end
	}
	local hole={
		x=47,y=103,w=44,h=5,
		draw=function()
			rf(48,103,90,107,1)
			line(47,104,47,107,1)
			line(91,104,91,107,1)
			rf(61,104,62,107,4)
			rf(75,104,76,107,4)
			line(63,107,74,107,4)
		end,
		act=function()
			go("basement")
		end,
		hide=true
	}
	local rug={
		name="rug",
		x=39,y=101,w=62,h=9,
		act=function()
			--todo pass rug sfx
			set_msg("throwing aside the rug\nreveals a ladder\nleading to a cellar.",0)
			hole.hide=false
			scn_rm("rug")
		end,
		draw=function()
			ovalfill(39,102,100,109,5)
			ovalfill(39,101,100,108,15)
			oval(44,103,95,106,4)
		end
	}
	local grate={
		x=8,y=5,w=23,h=23,
		act=function()
			go("grate")
		end,
		draw=function()
			rect(8,5,31,26,5)
			if grate_open then
				rf(9,6,30,25,1)
			else
				local cs={13,6,5}
				for i=0,6 do
					for j=0,2 do
						line(9,6+i*3+j,30,6+i*3+j,cs[j+1])
					end
				end
			end
		end
	}
	local radio={
		x=9,y=57,w=22,h=14,
		act=function()
			go("radio")
		end,
		draw=function()
			palt(0b0000000000000010)
			sspr(26,8,22,14,9,57)
			palt()
			line(26,44,26,56,6)
			pset(25,44,6)
		end
	}
	local drawer={
		name="drawer",
		x=9,y=73,w=25,h=4,
		act=function()
			pickup(
				{
					name="pencil",
					weight=5,
					desc="2b or not 2b?\nthat is the pencil.",
					sp=48
				},
				"you find a pencil\nin the drawer.")
			scn_rm("drawer")
		end
	}
	local clrbox={
		x=96,y=84,w=23,h=14,
		act=function()
			go("clr_box")
		end,
		draw=function()
			if not clr_box_open then
				sspr(48,8,23,15,96,84)
			else
				sspr(0,32,23,21,96,78)
				if not rabbit_taken then
					sspr(76,0,3,4,104,86)
					sspr(76,0,3,4,108,86)
				end
			end
		end
	}
	
	return {
		door,lock,rug,grate,radio,
		drawer,clrbox,hole
	}
end

function std_bg()
	rf(0,0,128,flry,2)
	line(0,flry,128,flry,5)
	rf(0,flry+1,128,128,3)
end

function draw_door()
	rf(48,30,91,98,4)
	rect(50,32,89,98,1)
	line(50,39,50,43,9)
	line(50,62,50,66,9)
	line(50,87,50,91,9)
	--lock
	palt(0b0000000000000010)
	sspr(0,8,6,14,80,60)
	palt()
end

function draw_door(x,white)
	if white then
		pal(4,7)
		pal(9,6)
	end
	rf(x,30,x+43,98,4)
	rect(x+2,32,x+41,98,1)
	line(x+2,39,x+2,43,9)
	line(x+2,62,x+2,66,9)
	line(x+2,87,x+2,91,9)
	--lock
	if white then
		pal(9,5)
		pal(10,6)
	end
	palt(0b0000000000000010)
	sspr(0,8,6,14,x+32,60)
	palt()
	pal()
end

sheet_music_item={
	name="sheet music",
	weight=33,
	desc="\"moonlight sonata\"",
	sp=54
}

bdoor_locked=true
paper_down=false
key_pushed=false
function init_books()
	return {
		l="kitchen",
		r="start",
		draw=function()
			std_bg()
			draw_door(11,true)
			--shelf
			rf(70,13,118,98,4)
			rf(73,17,115,37,1)
			rf(73,41,115,61,1)
			rf(73,65,115,85,1)
		end,
		items=init_book_items()
	}
end

function init_book_items()
local floorpaper={
	x=21,y=99,w=30,h=3,
	hide=true,
	act=function(self)
		self.hide=true
		paper_down=false
		if key_pushed then
			pickup({
				name="bathroom key",
				weight=25,
				desc="opens the bathroom door.",
				sp=57
			})
		else
			pickup(sheet_music_item)
		end
	end,
	draw=function()
		sspr(80,6,31,3,21,99)
	end
}
local door={
		x=11,y=30,w=37,h=64,
		act=function()
			if not bdoor_locked then
				go("bathroom")
				return
			end
			
			if held==nil then
				set_msg("the door is locked.")
			elseif held.name=="sheet music" then
				inv_rm("sheet music")
				paper_down=true
				floorpaper.hide=false
				--sfx paper down
			else
				--todo pass sfx no
				set_msg("you rub the "..held.name.."\non the door.\n\"open sesame!\"\nit doesn't work.",0)
			end
		end,
		draw=function()
			draw_door(11,true)
		end
	}
	local lock={
		name="lock",
		x=44,y=60,w=6,h=15,
		act=function()
			if held==nil then
				if key_pushed then
					set_msg("you peep through the\nkeyhole into what\nappears to be a\nbathroom.")
				else
					set_msg("you try to look\nthrough the keyhole\nbut something is\nblocking it from\nthe other side.")
				end
			elseif held.name=="hatpin" then
				if paper_down then
					key_pushed=true
					--todo pass sfx pushkey
					set_msg("you push the object\nout of the keyhole\nand it falls onto\nthe sheet music below.")
					inv_rm("hatpin")		
				else
					set_msg("if you do that now,\nyou won't be able\nto reach what\nfalls out.")
				end
			elseif held.name=="bathroom key" then
				--todo pass sfx unlock
				set_msg("you unlock the door.",0)
				inv_rm("bathroom key")
				scn_rm("lock")
				bdoor_locked=false
			else
				--todo pass sfx no
				set_msg("that doesn't fit in\nthe keyhole.",0)
			end
		end
	}
	local items={door,lock,floorpaper}
	book_clrs={
		o=0,
		r=0,
		g=0
	}
	local books=nil
	while 
		book_clrs.o==0 or 
		book_clrs.r==0 or 
		book_clrs.g==0 or
		book_clrs.o>9 or 
		book_clrs.r>9 or 
		book_clrs.g>9 
	do
		books=gen_books()
	end
	for book in all(books) do
		add(items,book)
	end
	return items
end

function gen_books()
	book_clrs={
		o=0,
		r=0,
		g=0
	}
	local books={}
	local clrs={
		{8,2},{9,4},{3,5},{12,1},
		{14,8},{13,5},{4,5}
	}
	local last_clr=nil
	local bk_txts=split(
	"the cadbury tales;incorrect trivia vol. 2;the end-bulbs of krause;doby mick;how to drain your dragon;my life - sleve mcdichael;the little book of snails;the invincible sponge;fun with lying;the big book of snails;cooking with ogg;how to finish anyth...;book titles for dummies;for whom the belt holes;the ill lad;the oddish sea;the alphabet pt. 2;the dogan;anna karmina burana;birds and other hoaxes;cream and pastryment;the bobbitt;jude the obnoxious;ethics for toddlers;all about coffee tables;the jelloship of the ring mold;the cherry pies of windsor;speling is eesy;whales are fish too;your microwave is listening;gary podder;the chronicles of arby's;not a secret hiding spot;space jelly;mein harumph;the hunchback of scuzz holler"
	,";")
	for top in all({17,41,65}) do
		local sw=43
		while sw>0 do
			local x=73+43-sw
			local w=flr(rnd(5))+2
			if (sw<=6) w=sw
			local g=flr(rnd(7))+3
			local y=top+g
			local h=21-g
			local clr=rnd(clrs)
			while
				clr==last_clr or
				(sw==43 or sw<=6) and clr[1]==4
			do
				clr=rnd(clrs)
			end
			if(clr[1]==8)book_clrs.r+=1
			if(clr[1]==9)book_clrs.o+=1
			if(clr[1]==3)book_clrs.g+=1 
			last_clr=clr
			local bumps=rnd()<0.2
			local by1=y+flr(h/5)
			local by2=y+h-1-flr(h/5)
			local thickness=flr(rnd(2))
			local txt=rnd(bk_txts)
			del(bk_txts,txt)
			add(books,{
				x=x,y=y,w=w,h=h-1,
				txt=txt,
				act=function()
					set_msg(txt)
				end,
				draw=function()
					rf(x,y,x+w-1,y+h-1,clr[1])
					if(clr[1]==4)line(x,y+h-1,x+w,y+h-1,clr[2])
					if bumps and clr[1]~=4 then
						rf(x,by1,x+w-1,by1+thickness,clr[2])
						rf(x,by2,x+w-1,by2+thickness,clr[2])
					end
				end
			})
			sw-=w
		end
	end
	return books
end

function init_kitchen()
	return {
		r="books",
		draw=function()
			draw_encoded("8080410000134003001f4003001f4003001f4007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014008a0020001a0024001a00b000140030001a00b4001a0020001a0024001a00b000140030001a00b4001a0020001a0024001a00b000140030001a00b4001a0020001a0024001a00b00014009a0010001a0014003a00a000140030001a00a4003a0010001a0014003a00a000140030001a00a4003a0010001a0014003a00a000140030001a00a4003a0010001a0014003a00a00014008a0020001a0024001a00b000140030001a00b4001a0020001a0024001a00b000140030001a00b4001a0020001a0024001a00b000140030001a00b4001a0020001a0024001a00b00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e00014007a0030001a00e000140030001a00e0001a00e000140030001a00e0001a00e000140030001a00e0001a00e0001400700134003001f4003001f4003001f41070080f01a000160250001f059000160250001f059000160250001f0140028f01d0001601600046003000460040001f0130001c0280001f01c0001601600046003000460040001f0130001c0280001f01c000160250001f0130001c0280001f01d0025f0140001c0280001f0560001c0280001f0560001c0040003c0210001f0560001c004000160010001c0210001f0560001c004000160010001c0210001f0560001c004000160010001c0210001f0560001c004000160010001c0210001f0560001c004000160010001c0210001f0560001c004000160010001c0210001f0560001c004000160010001c0210001f0560001c004000160010001c0210001f0560001c004000160010001c0210001f0560001c004000160010001c0210001f0560001c0040003c0210001f0560001c0280001f0560001c0280001f0560001c0280001f0560002c0260002f056002af0560002c0260002f0560001c0280001f0560001c0280001f0560001c0280001f01d0025f0140001c0280001f01c000160250001f0130001c0280001f01c000160250001f0130001c0280001f01c000160250001f0130001c0040003c0210001f01c000160250001f0130001c004000160010001c0210001f01c000160250001f0130001c004000160010001c0210001f01c00016004500b6008500b60030001f0130001c004000160010001c0210001f01c0027f0130001c004000160010001c0210001f0020019f001000160250001f0130001c004000160010001c0210001f00240180001f001000160050003600900036009000360050001f0130001c004000160010001c0210001f00240180001f001000160040005600700056007000560040001f0130001c004000160010001c0210001f00240180001f001000160040005600700056007000560040001f0130001c004000160010001c0210001f0020019f001000160050003600900036009000360050001f0130001c004000160010001c0210001f002a0050001a00f000140020001f001000160250001f0130001c004000160010001c0210001f002a0050001a00f000140020001f0010027f0130001c004000160010001c0210001f002a0050001a00f000140020001f00100016009000160100001600a0001f0130001c004000160010001c0210001f002a0050001a00f000140020001f00100016009000160100001600a0001f0130001c0040003c0210001f002a0050001a00f000140020001f00100016005001b60050001f0130001c0280001f002a0050001a00f000140020001f00100016005000150137001500170015003000160050001f0130001c0280001f002a0050001a00f000140020001f00100016005000150127001500170015004000160050001f0130001c0280001f002a0050001a00f000140020001f00100016005000150127001500170015004000160050001f0130001c0280001f002a0050001a00f000140020001f00100016005000150117001500170015005000160050001f0130001c0280001f002a0050001a00f000140020001f00100016005000150107001500170015006000160050001f0130001c0280001f002a0050001a00f000140020001f00100016005000150107001500170015006000160050001f0130001c0280001f002a0050001a00f000140020001f001000160050001500f7001500170015007000160050001f0130001c0280001f002a0050001a00f000140020001f001000160050001500e7001500170015008000160050001f0130001c0280001f002a0024001a0020001a0024001a00c000140020001f001000160050001500e7001500170015008000160050001f0130001c0280001f002a0014003a0010001a0014003a00b000140020001f001000160050001500d7001500170015009000160050001f0130001c0280001f002a0024001a0020001a0024001a00c000140020001f001000160050001500c700150017001500a000160050001f0130001c0280001f002a0050001a00f000140020001f001000160050001500c700150017001500a000160050001f0130001c0280001f002a0050001a00f000140020001f001000160050001500b700150017001500b000160050001f0130001c0280001f002a0050001a00f000140020001f001000160050001500a700150017001500c000160050001f0130001c0280001f002a0050001a00f000140020001f001000160050001500a700150017001500c000160050001f0130001c0280001f002a0050001a00f000140020001f0010001600500015009700150017001500d000160050001f0130001c0280001f002a0050001a00f000140020001f00100016005001b60050001f0130001c0280001f002a0050001a00f000140020001f001000160250001f0130001c0280001f002a0050001a00f000140020001f001000160250001f0130001c0280001f002a0050001a00f000140020001f0010027f0130001c0280001f002a0050001a00f000140020001f001000160250001f0130001c0280001f002a0050001a00f000140020001f001000160250001f0130001c0280001f002a0050001a00f000140020001f0010001600c000d600c0001f0130001c0280001f002001640020001f001000160250001f0130001c0280001f00240180001f001000160250001f0130001c0280001f0020080d0080001d0160001d0160001d0160001d0160001d0160001d00c0001d0160001d0160001d0160001d0160001d0160001d00c0001d0160001d0160001d0160001d0160001d0160001d00c0001d0160001d0160001d0160001d0160001d0160001d0040080d0140001d0160001d0160001d0160001d0160001d0230001d0160001d0160001d0160001d0160001d0230001d0160001d0160001d0160001d0160001d0230001d0160001d0160001d0160001d0160001d00f0080d0080001d0160001d0160001d0160001d0160001d0160001d00c0001d0160001d0160001d0160001d0160001d0160001d00c0001d0160001d0160001d0160001d0160001d0160001d00c0001d0160001d0160001d0160001d0160001d0160001d0040080d0140001d0160001d0160001d0160001d0160001d0230001d0160001d0160001d0160001d0160001d0230001d0160001d0160001d0160001d0160001d0230001d0160001d0160001d0160001d0160001d00f0080d0080001d0160001d0160001d0160001d0160001d0160001d00c0001d0160001d0160001d0160001d0160001d0160001d00c0001d0160001d0160001d0160001d0160001d0160001d00c0001d0160001d0160001d0160001d0160001d0160001d0040080d0140001d0160001d0160001d0160001d0160001d0230001d0160001d0160001d0160001d0160001d0230001d0160001d0160001d0160001d0160001d00f",
			0,0)
		end,
		items=init_kitchen_items()
	}
end

function init_kitchen_items()
	local peg={
		x=75,y=65,w=1,h=1,
		draw=function()
			rf(75,65,76,66,6)
		end,
		act=function()
			set_msg("a nail in the wall\nto hang things from.")
		end
	}
	local tongs={
		name="tongs",
		x=72,y=64,w=7,h=14,
		act=function()
		 scn_rm("tongs")
		 pickup({
		 	name="ice block tongs",
		 	desc="used for carrying\nlarge blocks of ice.",
		 	weight=2679,
		 	sp=49
		 })
		end,
		draw=function()
			sspr(72,8,8,15,72,64)
		end
	}
	local freezer={
		name="freezer",
		x=85,y=30,w=34,h=20,
		act=function()
			pickup(
				{
					name="book",
					desc="the whining - stefan kang",
					weight=294,
					sp=50
				},
				"you found a book\nin the freezer. what's\nthat doing in there?")
			scn_rm("freezer")
		end
	}
	return {tongs,peg,freezer}
end

bulb_taken=false
function init_basement()
	return {
		draw=function()
			if bulb_taken then
				rf(0,0,127,127,0)
				return
			end
			draw_encoded("8080101e00011011400210100001100a40021017000110069001103000011011400210100001100a40021017000110069001103000011011400210100001100a40021017000110069001103000011011400210100001100a40021017000110069001103000011011400210100001100a40021017000110069001103000011011400210100001100a40021017000110069001103000011011400210100001100a40021017000110069001103000011011401f1017000110069001103000011011401f1017000110069001101200304002001b4002001e90010012100b0001102300014002101b40021004000110199001100a000110120001102300014002101b40021004000110189002100a000110120001102300014002101b40021004000110186002100a000110120001102300014002101b40021004000110186002100a000110120001102300014002101b40021004000110187002100a000110120001102300014002101b400210040001101770041009000110120001102300014002101b400210040001101670061008000110120001102300014002101b40021004000110167004a00170011008000110120001102300014002101b40021004000110167003a00170021008000110120001102300014002101b40021004000110177004100900011012000110230001401f10040001102400011012000110230001401f10040001101b60011008000110120001102300014002101b4002100400011024000110120001102300014002101b400210040001101b60011008000110120001102300014002101b4002100400011024000110120001102300014002101b400210040001101b60011008000110120001102300014002101b40021004000110240001100700304002001b40020031101e00011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011401f10170001103700011011401f10170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001101900304002001b40020031100b000110230001401f10040001102300011013000110230001401f100400011023000110130001102300014002101b4002100400011023000110130001102300014002101b4002100400011023000110130001102300014002101b4002100400011023000110130001102300014002101b4002100400011023000110130001102300014002101b4002100400011023000110130001102300014002101b4002100400011023000110130001102300014002101b4002100400011023000110130001102300014002101b4002100400011023000110130001102300014002101b4002100400011023000110130001102300014002101b4002100400011023000110130001102300014002101b400210040001102300011013000110230001401f10040001102300011013000110230001401f100400011023000110130001102300014002101b4002100400011023000110130001102300014002101b40021004000110230001100800304002001b40020031101e00011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011401f10170001103700011011401f10170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001103700011011400210100001100a400210170001101900304002001b40020031100b00254002101b40021004000110230001101300254002101b40021004000110230001101300254002101b4002100400011023000110130025401f100400011023000110130025401f1004000110230001101300254002101b40021004000110230001101300254002101b40021004000110230001101300254002101b40021004000110230001101300254002101b40021004000110230001101300254002101b40021004000110230001101300254002101b40021004000110230001101300254002101b40021004000110230001101300254002101b40021004000110230001101300254002101b40021004000110230001101300254002101b40021004000110230001101300254002101b40021004000110230001101300254002101b400210040001102300011008d080501910015005100150061001500610015061100150191001506a1001500c1001507b100150071001506c10015092100150031001506d10015002100150851001505c0003507b0002507c0002507d0001507d0002507b0003506e000a5003000250700001500a000350710001507d0002507d0001507a000550790002507d0001507e0001507e0001507f0001507e0001507b0004507b0001507e00015031",
			0,0)
		end,
		items=init_basement_items()
	}
end

function init_basement_items()
	local ladder={
		x=48,y=0,w=30,h=98,
		act=function()
			go("start")
		end
	}
	local dust={
		x=13,y=100,w=32,h=8,
		act=function()
			set_msg("there's some brick dust\non the floor.")
		end
	}
	local hat={
		name="hat",
		hide=true,
		x=16,y=95,w=8,h=4,
		act=function()
			pickup({
				name="hat",
				desc="keeps the sun out of\nyour eyes, and ever\nso fabulously.",
				sp=51,
				weight=308
			})
			scn_rm("hat")
		end,
		draw=function()
			if(not bulb_taken)spr(51,16,93)
		end
	}
	local hatpin={
		name="hatpin",
		hide=true,
		x=30,y=93,w=6,h=6,
		act=function()
			pickup({
				name="hatpin",
				desc="long, thin, and sharp.",
				sp=52,
				weight=12
			})
			scn_rm("hatpin")
		end,
		draw=function()
			if(not bulb_taken)spr(52,29,92)
		end
	}
	local brick={
		name="brick",
		x=12,y=82,w=34,h=16,
		act=function()
			if held==nil then
				set_msg("this brick feels a\nlittle loose. i\ncan't move it with\nmy bare hands.")
			elseif held.name=="ice block tongs" then
				inv_rm("ice block tongs")
				scn_rm("brick")
				hat.hide=false
				hatpin.hide=false
				--todo pass sfx brick pull
				set_msg("you remove the brick to\nreveal a lady's hat\nand a hatpin.",0)
			else
				wrong_item("pull a brick")
			end
		end,
		draw=function()
			if(not bulb_taken)rf(12,82,46,98,1)
		end
	}
	local bulb={
		x=105,y=12,w=8,h=8,
		act=function()
			if not bulb_taken then
				bulb_taken=true
				pickup({
					name="light bulb",
					desc="in case you have\na bright idea.",
					weight=42,
					sp=53
				})
			else
				if held==nil then
					set_msg("an empty light bulb socket")
				elseif held.name=="light bulb" then
					inv_rm("light bulb")
					bulb_taken=false
				else
					wrong_item("fill an empty\nlight bulb socket")
				end
			end
		end
	}
	
	return {
		ladder,dust,brick,hat,hatpin,
		bulb
	}
end

function init_piano_rm()
	return {
		l="start",
		draw=function()
			draw_encoded("808027087024205c7024205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c0077003c0057002c00f7002205c7002c0077006c0027002c0035001c0025001c0087002205c7002c0097004c00160017002c0016001c0015006c0067002205c7002c00f7002c0065001c0087002205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7024205c7024205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c00f7002c00f7002205c7002c00f7002c0093003c0037002205c7002c0043005c0067002c004300b7002205c7002c0033007c0057002c003300c7002205c7002c002300ac0037002c003300c7002205c7002c002300bc0027002c004300b7002205c7002c002300bc0027002c004300b7002205c7024205c7024231f4030204f4032204e4032204e4032204e4032204e4032204e403220084039200d403220094037200e403220094037200e403220094004502e4005200e4032200940045001402c50014005200e4032200940045001402c50014005200e0006d006000ad006000ad0060006200940045001402c50014005200e4004d00a4006d00a4006d00a4004200940045001402c50014005200e4003d00c4004d00c4004d00c4003200940045001402c50014005200e40035001d00a500140045001d00a500140045001d00a50014003200940045001402c50014005200e40045002d006500240065002d006500240065002d00650024004200940045001402c50014005200e40065006400a5006400a50064006200940045001402c50014005200e4032200940045001402c50014005200e0032200940045001402c50014005200e403220094004502e4005200e4032200940045001402c50014005200e4032200940045001402c50014005200e40322009400450014002000140010001400200014001000140010001400200014001000140020001400100014001000140020001400100014002000140010001400100014002000140010001400350014005200e4032200940045001702c50014005200e401100104011200940045001702c50014005200e401100104011200940045001402c50014005200e401100104011200940045001402c50014005200e40110010401120094004502e4005200e401100104011200940045001402c50014005200e401100104011200940045001402c50014005200e401100104011200940045001402c50014005200e401100104011200940045001402c50014005200e4011001040112009400450014009d01a400950014005200e4011001040112009400450014008d01c400850014005200e40110002400c000240112009400450014008d01c400850014005200e40110002400c000240112009400450014009d01a400950014005200e40110001400e00014011200940045001400a7018400a50014005200e40110001400e00014011200940045001400a700240147002400a50014005200e401100104011200940045001400a700240147002400a50014005200e4032200940045001400a700240147002400a50014005200e4032200940045001400a700240147002400a50014005200e4032200940045001400a700240147002400a50014005200e40322004500540045001400a700240147002400a50014005500e40325004300540045001400a700240069001400290024002900140067002400a50014005300d500140323007500140055001400a700240069001400290024002900140067002400a50014006300c50014032300850107002500590025002900250029002500570025011300c503330177002301670023c53")
		end,
		items=init_piano_rm_items()
	}
end

targets={42,291,5}--bulb,rabbit,pencil
slots={{},{},{}}
weight_box_open=false
piano_open=false

function check_weights()
	if(weight_box_open)return
	for i=1,3 do
		if slots[i].weight~=targets[i] then
			return
		end
	end
	get_item("binos").hide=false
	get_item("box door").hide=true
	--sfx open
	weight_box_open=true
end

function drop_zone_activate(self)
	if slots[self.idx].name~=nil then
		if held==nil then
			pickup(slots[self.idx])
			slots[self.idx]={}
		else
			--todo pass sfx no
			set_msg("there's already something\non that plate.",0)
		end	
	elseif held==nil then
		set_msg("a metal plate mounted\nonto a large box with\na door on the front.")
	else
		slots[self.idx]=held
		inv_rm(held.name)
		--sfx weight box put
	end
	check_weights()
end

function drop_zone_draw(self)
	local item=slots[self.idx]
	if item.sp then
		local osx,osy=item.osx~=nil and item.osx or 0,item.osy~=nil and item.osy or 0
		spr(item.sp,self.x+osx+2,self.y+osy-2)
	end
	print(targets[self.idx],self.x+self.otxt,self.y-8,10)
end

function init_piano_rm_items()
	local window={
		x=9,y=14,w=35,h=36,
		act=function()
			if held==nil then
				set_msg("such a lovely day\noutside. what a shame\nyou're trapped in here.")
			elseif held.name=="binoculars" then
				set_msg("through the binoculars, you\nsee an airplane flying\na banner advertisement\n\"101.1 krlc\"")
			else
				--todo pass sfx no
				set_msg("i'm not sure what that\nwould accomplish.",0)
			end
		end
	}
	local piano={
		x=9,y=76,w=45,h=8,
		act=function()
			go("piano")
		end
	}
	local lid={
		name="lid",
		draw=function()
			line(5,61,59,61,4)
			line(6,61,58,61,9)
			rf(4,53,60,60,4)
			rf(5,54,59,59,5)
		end,
		hide=true
	}
	local screwdriver={
		name="screwdriver",
		x=26,y=52,w=8,h=8,
		draw=function()
			spr(56,26,52)
		end,
		act=function()
			pickup(
				{
					name="screwdriver",
					desc="equally useful for\nscrewdriving and\nscrew un-driving.",
					weight=943,
					sp=56
				},
				"the piano tuner must\nhave left a screwdriver\nin there. finders\nkeepers!")
			scn_rm("screwdriver")	
		end,
		hide=true
	}
	local bench={
		name="bench",
		x=18,y=89,w=27,h=3,
		act=function()
			pickup(
				sheet_music_item,
				"you found sheet music\nin the piano bench.\n\"moonlight sonata\"")
			scn_rm("bench")
		end
	}
	local stand={
		name="stand",
		x=17,y=66,w=30,h=9,
		act=function(self)
			if held==nil then
				set_msg("a place to put\nsheet music.")
			elseif held.name=="sheet music" then
				self.hide=true
				get_item("stand music").hide=false
				--sfx paper down
			else
				--todo pass sfx no
				set_msg("that doesn't go there.")
			end
		end
	}
	local stand_music={
		name="stand music",
		hide=true,
		x=17,y=66,w=30,h=9,
		draw=function()
			sspr(80,0,31,9,17,66)
		end,
		act=function(self)
			pickup(sheet_music_item)
			get_item("stand").hide=false
			self.hide=true
		end
	}
	local binos={
		name="binos",
		hide=true,
		x=96,y=83,w=4,h=7,
		act=function()
			pickup({
				name="binoculars",
				weight=2023,
				desc="look through the small end",
				sp=55
			})
			scn_rm("binos")
		end,
		draw=function()
			spr(55,95,82)
		end
	}
	local door={
		name="box door",
		x=91,y=80,w=15,h=14,
		act=function()
			set_msg("the door doesn't budge.")
		end,
		draw=function()
			rf(92,81,105,93,4)
			circfill(102,87,1,9)
		end
	}
	local bulbslot={
		x=77,y=67,w=11,h=5,
		idx=1,otxt=2,
		act=drop_zone_activate,
		draw=drop_zone_draw
	}
	local rabbitslot={
		x=93,y=67,w=11,h=5,
		idx=2,otxt=0,
		act=drop_zone_activate,
		draw=drop_zone_draw
	}
	local pencilslot={
		x=109,y=67,w=11,h=5,
		idx=3,otxt=4,
		act=drop_zone_activate,
		draw=drop_zone_draw
	}

	return {
		window,piano,bench,stand,
		stand_music,binos,door,
		bulbslot,rabbitslot,
		pencilslot,lid,screwdriver
	}
end

piano_hist={0,0,0,0}
piano_ans={7,10,3,7}
function check_piano()
	if(piano_open)return
	for i=1,4 do
		if(piano_hist[i]~=piano_ans[i])return
	end
	--todo pass sfx piano open
	set_msg("the piano top pops open!")
	get_item("lid","piano_rm").hide=false
	get_item("screwdriver","piano_rm").hide=false
	piano_open=true	
end

function init_piano()
	local p={
		b="piano_rm",
		draw=function()
			rf(0,0,127,127,4)
			line(0,35,0,104,0)
			for i=0,6 do
				local x=i*18+1
				rect(x,35,x+18,104,0)
				rf(x+1,36,x+17,103,7)
				line(x+1,99,x+17,99,5)
				rf(x+1,100,x+17,103,6)
			end
			local bxs={15,33,69,87,105}
			for bx in all(bxs) do
				rf(bx,36,bx+8,63,0)
			end
		end,
		items=init_piano_items()
	}
	for item in all(p.items) do
		item.act=function(self)
			sfx(self.fx,3)
			deli(piano_hist,1)
			add(piano_hist,self.idx)
			check_piano()
		end
	end
	return p
end

function init_piano_items()
	local keys={
		{x=2,y=64,w=17,h=35},
		{x=15,y=36,w=9,h=28},
		{x=20,y=64,w=17,h=35},
		{x=33,y=36,w=9,h=28},
		{x=38,y=64,w=17,h=35},
		{x=56,y=64,w=17,h=35},
		{x=69,y=36,w=9,h=28},
		{x=74,y=64,w=17,h=35},
		{x=87,y=36,w=9,h=28},
		{x=92,y=64,w=17,h=35},
		{x=105,y=36,w=9,h=28},
		{x=110,y=64,w=17,h=35},
	}
	for i=1,#keys do
		keys[i].fx=30+i-1
		keys[i].idx=i
	end
	return keys
end

function init_bathroom()
	return {
		b="books",
		draw=function()
			rf(0,0,127,127,15)
			line(0,99,127,99,0)
			rf(0,100,127,127,14)
			
			rect(8,57,48,60,0)
			rf(9,58,47,59,7)
			rect(10,60,27,93,0)
			rf(11,61,26,92,7)
			rect(28,61,46,93,0)
			rf(29,61,45,92,7)
			circfill(23,75,1,9)
			circfill(32,75,1,9)
			rect(10,93,46,99,0)
			rf(11,94,45,98,7)
			rect(10,10,46,57,0)
			rect(11,11,45,56,7)
			rect(12,12,44,55,0)
			rf(13,13,43,54,6)
			for i=0,5 do
				line(37+i,13,17+i,54,7)
			end
			line(19,54,20,54,5)
			rf(21,54,22,56,5)
			pset(22,54,8)
			line(35,54,36,54,5)
			rf(33,54,34,56)
			pset(33,54,12)
			rf(26,49,29,56,5)
			line(26,52,29,52,0)
			line(29,50,29,51,7)
			line(9,11,9,56,5)
			
			for x=-1,127,15 do
				sspr(40,50,16,14,x,100)
				spr(101,x,113,2,2)
			end
			
			spr(99,56,20,2,2)
			line(55,21,55,35,6)
			line(56,36,70,36,6)
			
			rf(89,13,111,38,4)
			rf(91,15,109,36,7)
			line(88,14,88,38,6)
			line(89,39,110,39,6)
			
			rrect(85,53,28,5,1,0)
			rf(86,54,111,56,7)
			line(88,58,109,58,5)
			line(87,58,87,75,0)
			line(110,58,110,75,0)
			rf(88,59,109,75,7)
			line(89,60,93,60,9)
			line(92,61,93,61,9)
			
			palt(0b0000000000000010)
			sspr(0,53,14,3,94,19)
			sspr(0,56,14,2,94,24)
			sspr(0,58,14,3,94,29)
			
			sspr(0,64,30,23,84,76)
			
			sspr(32,64,9,13,119,72)
			palt()
		end,
		items=init_bathroom_items()
	}
end

function init_bathroom_items()
	local pic={
		x=89,y=13,w=22,h=25,
		act=function()
			set_msg("we aim to please.\nplease aim.")
		end
	}
	local scale={
		x=56,y=56,w=22,h=48,
		act=function()
			local weight=big_add("62000",inv_weight())			
			if held~=nil and held.weight~=nil then
				weight=held.weight
			end
			set_msg("the readout says: "..weight.."g.")
		end,
		draw=function()
			rrect(56,98,23,7,1,5)
			rf(57,99,77,103,6)
			line(76,99,75,100,7)
			rrect(65,64,5,36,1,5)
			rf(66,65,68,98,6)
			line(68,75,68,79,7)
			line(66,67,68,67,5)
			rrect(56,56,23,10,1,5)
			rf(57,57,77,64,6)
			rrf(58,58,19,6,1,5)
			line(61,59,73,59,11)
			line(62,62,72,62,11)
		end
	}
	local matches={
		name="matches",
		x=38,y=53,w=10,h=3,
		act=function()
			pickup({
				name="matches",
				desc="matches from the bathroom.",
				weight=8,
				sp=59
			})
			scn_rm("matches")
		end,
		draw=function()
			spr(59,38,51)
		end
	}
	return {pic,scale,matches}
end

screwlocs={
	{4,4},{4,123},{123,123}
}
function init_grate()
	return {
		b="start",
		draw=function()
			rf(0,0,127,127,5)
			rf(8,8,119,120,1)
			if not grate_open then
				for i=0,6 do
					local y=i*16+10
					rf(8,y,119,y+2,13)
					rf(8,y+3,119,y+12,6)
					for loc in all(screwlocs) do
						circfill(loc[1],loc[2],2,6)
						circfill(loc[1],loc[2],1,5)
					end
				end
			else
				draw_encoded("808051030003507c0005507b0005507b0005507c00035102106f000150100001106d00011001501010010001106b00011002501010020001106900011003501010030001106700011004501010040001106500011005501010050001106300011006501010060001106100011007501010070001105f00011008501010080001105d00011009501010090001105b0001100a5010100a000110590001100b5010100b000110570001100c5010100c000110550001100d5010100d000110530001100e5010100e000110510001100f5010100f0001104f00011010501010100001104d00011011501010110001104b00011012501010120001104900011013501010130001104700011014501010140001104500011015501010150001104300011016501010160001104100011017501010170001103f00011018501010180001103d00021018501010190001103b000310185010101a00011039000410185010101b00011037000510185010101c003c10185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c00011035000610185010101c50021034000610185010101b50010001500410310006101850101019500210010001500110035002102f0006101850101018500110030001500110055002102d0006101850101017500110040001500110075002102b000610185010101650011005500210085002102a00061018501010155001100550010001500210065001100250011029000610185010101550011004500110010001500110015002100450011002500110290006101850101014500210035001100200015001100350021001500110045001102800061018501010135001100250011002500110020001100150011004500210055001102700061018501010135001100350021003000110015001100450021005500110270006101850101012500110045002100350031003500110025001100550011026000610185010101250011003500110025003000110015002100250011003500110045001102600061018501010125001100350011003500200011001500110015002100450011003500210260006101850101012500110025001100350011002500110015001100150011001500110045003100250011025000610185010101150051003500110020001500210015001100250011001500310045001102500061018501010115001100350070001100150021003500210025001100450011025000610185010101150011003500110025001100350041001500210015001100250011004500110250006101850101011500110035001100250011003000150041003500110025001100550011024000610185010101150011003500110025001100350010001500100015001000350010002500100045002002a1018501010125001100250011003500110015001100250011002500110015002100150011005500110260005101850101012500110025001100350021003500110025002100350011004500110280004101850101012500110035001100250081002500110015001100550011029000310185010101250011003500110015001100550011005500210045001102b0002101850101012500110035002100650011005500210045001102c000110185010101350011002500e1002500110025001102e0001101750101013500110015001100850011008500110015001102f00011016501010135002100950011008500210310001101550101013500510065001100650021034000110145010101200011005500d103700011013501010110001104b00011012501010100001104d000110115010100f0001104f000110105010100e000110510001100f5010100d000110530001100e5010100c000110550001100d5010100b000110570001100c5010100a000110590001100b501010090001105b0001100a501010080001105d00011009501010070001105f00011008501010060001106100011007501010050001106300011006501010040001106500011005501010030001106700011004501010020001106900011003501010010001106b0001100250100001106d000110015010106f0001500b00035074000350050005507200055004000550720005500400055072000550050003507400035103",
				0,0)
			end
		end,
		items=init_grate_items()
	}
end

function init_grate_items()
	local key={
		name="key",
		x=42,y=87,w=8,h=6,
		hide=true,
		draw=function()
			spr(58,42,87)
		end,
		act=function(self)
			pickup({
				name="key",
				weight=25,
				sp=58,
				desc="the key!!!\nlet's get out of here."
			})
			self.hide=true
		end
	}
	local darkness={
		name="darkness",
		hide=true,
		x=8,y=8,w=110,h=111,
		act=function()
			if held==nil then
				set_msg("it's too dark to\nsee anything.")
			elseif held.name=="matches" then
				scn_rm("darkness")
				key.hide=false
				inv_rm("matches")
				--todo sfx matches
			else
				wrong_item("get back there")
			end
		end,
		draw=function()
			rf(8,8,119,120,1)
		end
	}
	local items={darkness,key}
	for i=1,#screwlocs do
		local loc=screwlocs[i]
		local screw={
			x=loc[1]-2,y=loc[2]-2,
			w=5,h=5,
			name="screw"..i,
			act=function(self)
				if held==nil then
					set_msg("the grate is held closed with\nscrews. you hear something\nrattling around inside.")
				else
					if held.name=="screwdriver" then
						grate_open=true
						inv_rm("screwdriver")
						scn_rm("screw1")
						scn_rm("screw2")
						scn_rm("screw3")
						darkness.hide=false
						for loc in all(screwlocs) do
							local hole={
								draw=function()
									circfill(loc[1],loc[2],2,0)
								end
							}
							add(items,hole)
						end
					else
						wrong_item("turn a screw")	
					end	
				end
			end
		}
		add(items,screw)
	end

	return items
end


alpha=" abcdefghijklmnopqrstuvwxyz"
radio_ans={12,19,13,4}
btn_vals={1,1,1,1}
fun_words={
	{20,9,10,21},
	{7,22,4,12},
	{5,10,4,12},
	{4,22,15,21}
}
radio_on=false
radio_tuned=false
function init_radio()
	return {
		draw=function()
			rf(0,0,127,111,2)
			line(0,112,127,112,5)
			rf(0,113,127,127,4)
			rrf(5,31,118,87,1,6)
			
			rrf(10,38,108,13,1,5)
			local long=true
			for x=17,115,8 do
				line(x,38,x,38+(long and 4 or 2),7)
				long=not long
			end
			
			rf(26,42,27,50,8)
			
			for x=10,73,21 do
				rrf(x,55,18,18,1,0)
			end
			
			circfill(104,63,8,3)
			circ(104,63,3,7)
			line(104,60,104,62,7)
			pset(103,60,3)
			pset(105,60,3)
			
			rrect(10,79,108,35,1,5)
			for y=83,107,6 do
				rf(14,y,113,y+2,5)
				pset(14,y,6)
				pset(113,y,6)
				pset(14,y+2,6)
				pset(113,y+2,6)
			end
			
			line(4,112,4,116,5)
			pset(5,117,5)
			line(6,118,121,118,5)
			
			rf(92,0,94,30,6)
			pset(90,31,5)
			pset(96,31,5)
			line(91,32,95,32,5)
		end,
		items=init_radio_items()
	}
end

function init_radio_items()
	local pwr_btn={
		x=97,y=56,w=15,h=15,
		act=function()
			--sfx click
			radio_on=not radio_on
			if radio_on then
				if radio_tuned then
					-- piano music
				else
					-- static
				end
			else
				--music off
			end
		end
	}
	local items={}
	local idx=1
	for x=10,73,21 do
		local button={
			x=x,y=55,w=18,h=18,
			idx=idx,
			act=function(self)
				btn_vals[self.idx]+=1
				if(btn_vals[self.idx]>#alpha)btn_vals[self.idx]=1			
				
				local win=true
				local fwt={}
				for _=1,#fun_words do
					add(fwt,true)
				end
				for i=1,#radio_ans do
					if btn_vals[i]~=radio_ans[i] then
						win=false
					end
					for j=1,#fun_words do
						if(btn_vals[i]~=fun_words[j][i])fwt[j]=false
					end
				end
				
				for fw in all(fwt) do
					if fw then
						--todo pass sfx no
						set_msg("naughty...",0)
					end 
				end
				
				if radio_on then
					if win then
						-- piano music
					elseif radio_tuned then
						-- static
					end
				end
				
				radio_tuned=win
			end,
			draw=function(self)
				print("\^t\^w"..alpha[btn_vals[self.idx]],self.x+6,59,11)
			end
		}
		add(items,button)
		idx+=1
	end
	return items
end

clr_box_code={0,0,0}
function init_clr_box()
	return {
		b="start",
		draw=function()
			rf(0,0,127,127,2)
			line(0,107,127,107,5)
			rf(0,108,127,127,3)
			if not clr_box_open do
				rrf(3,35,122,90,2,4)
				
				rf(44,42,82,50,9)
				print("\^o55aex libris",46,44,10)
				
				line(3,58,8,63,1)
				line(8,63,119,63,1)
				line(119,63,124,58,1)
				
				rrf(60,58,11,18,1,9)
				line(68,60,68,62,7)
			else
				rrf(3,3,122,34,2,4)
				rrf(4,4,120,32,2,5)
				line(5,37,122,37,1)
				
				rrf(3,38,122,87,2,4)
				
				rf(21,36,35,37,9)
				line(32,36,33,36,10)
				rf(92,36,106,37,9)
				line(103,36,104,36,10)
				
				rrf(5,40,118,24,4,1)
				rrf(5,40,118,10,1,1)
				line(3,61,7,65,5)
				line(7,65,120,65,5)
				line(120,65,124,61,5)
				
			end
			
			local clrs={9,8,3}
			for i=1,3 do
				local x=20+36*(i-1)
				rrf(x,78,19,41,1,7)
				rf(x+1,79,x+17,95,clrs[i])
				palt(0b0000000000000010)
				spr(42,x+2,99,2,1)
				spr(42,x+2,109,2,1,false,true)
				palt()
				print("\^t\^w"..clr_box_code[i],x+6,83,0)
			end
			
			line(2,108,2,122,5)
			line(2,122,5,125,5)
			line(5,125,121,125,5)
		end,
		items=init_clr_box_items()
	}
end

function init_clr_box_items()
	local ears={
		name="ears",
		hide=true,
		x=50,y=44,w=32,h=19,
		act=function()
			pickup({
				name="toy rabbit",
				desc="a stuffed rabbit. the\ntag reads \"shrodinger\".",
				weight=291,
				sp=60
			})
			scn_rm("ears")
			rabbit_taken=true
		end,
		draw=function()
			sspr(112,0,11,20,50,44)
			sspr(112,0,11,20,72,44)
		end
	}
	
	local items={ears}
	
	for i=1,3 do
		local x=22+36*(i-1)
		
		for j=1,2 do
			add(items,{
				name="clr box btn",
				x=x,y=99+(j-1)*10,w=15,h=8,
				act=function()
					clr_box_code[i]+=j==1 and 1 or -1
					if clr_box_code[i]>9 then
						clr_box_code[i]=0
					elseif clr_box_code[i]<0 then
						clr_box_code[i]=9
					end
					if 
						clr_box_code[1]==book_clrs.o and
						clr_box_code[2]==book_clrs.r and
						clr_box_code[3]==book_clrs.g
					then
						ears.hide=false
						clr_box_open=true
						for _=1,6 do
							scn_rm("clr box btn")
						end
					end
				end
			})
		end
	end
	
	return items
end

function init_outside()
	return {
		draw=function()
			draw_encoded("8080c2ee9007c0257007c04b900bc020700dc047900dc01e700fc045900fc01c7011c0167006c0279011c0157018c013700ac0259011c012701bc012700cc0249011c011701cc011700ec024900fc011701dc0117018c01b900dc011701dc013701cc017900bc012701cc0127021c0169007c0146001701ac0117025c03060017016c0137027c03060017016c0127027c03160037014c0127025c0356007700cc0147023c03d60027009c0127027c03e6007c012702ac055702bc055702bc05560017029c05760027010c00360017012c05a6003700bc00660017010c05e6008c00a60017006c00260027003c0736005c0056002ccbcb018c05fb0093018b009c050b006302ab006c048b0023036b005c043303db004c03f3041b003c03c3044b002c03a3046b003c0373049b001c036304ab002c034304cb001c033304db001c032304eb001c031304fb001c002b015c0193050b0023015b008c011306fb004c00d3073b004c009301cb0013001b0013058b003c006301db001305cb003c003307db002c001307fb00133d7b002307ab0023001b001303a70013043b001303a7001a0017001307e7001b0013080b0013002b001307cb0013001b001307cb0013001b001307fb001341ee001307ee001a001e0013036b0013001b0013044b001e0013038b0013044b001307cb0023080b0013001b002307db00134ebb0013001b001307eb00130c98001307e8001a0018001307db0018001307ab0013002b001307db0013001b001307eb001307fb0013001b002307db0013199",0,0)
			print("\^t\^wyou win!",36,56,10)
		end
	}
end
-->8
--inv
inv={}
local w=110
local h=19
local x=6
local y=1
local by=8+y --y of boxes
local iidx=1

function update_inv()
	if btnp(➡️) and iidx<10 then 
		iidx+=1
		sfx(2)
	elseif btnp(⬅️) and iidx>1 then 
		iidx-=1
		sfx(2)
	elseif btnp(🅾️) then
		held=inv[iidx]
		inv_open=false
		set_ptr_from_inv()
		sfx(3)
	elseif btnp(❎) then
		inv_open=false
		set_ptr_from_inv()
		held=nil
		sfx(5)
	end
end

function set_ptr_from_inv()
	ptr.x=x+(iidx-1)*11+6
	ptr.y=by+6
end

function draw_inv()
	--bg
	rf(x,y,x+w,y+h,0)
	--border
	rect(x,y,x+w,y+h,7)
	--boxes
	for i=0,9 do
		local bx=x+i*11
		rect(
			bx,by,bx+11,by+11,7)
	end
	--header
	print(
		"inventory",x+2,y+2,7)
	--items
	for i,item in ipairs(inv) do
		local ix=x+(i-1)*11+2
		spr(item.sp,ix,by+2)
	end
	--highlight
	local hx=x+(iidx-1)*11
	rect(hx,by,hx+11,by+11,9)
	--item detail window
	local item=inv[iidx]
	if not item then return end
	local desc_lines=
		#split(item.desc,"\n")
	local idh= --item detail hght
		(desc_lines+1)*5+
		desc_lines+5
	local idy=by+11
	--bg
	rf(x,idy,x+w,idy+idh,0)
	--border
	rect(
		x,idy,x+w,idy+idh,7)
	--name
	print(item.name,x+2,idy+2,7)
	--desc
	print(item.desc,x+2,idy+10,7)
	--highlight again...
	rect(hx,by,hx+11,by+11,9)
end

function init_inv_btn()
	inv_btn={
		name="inventory button",
		x=118,y=1,
		w=8,h=8,
		draw=function(self)
			local hvrc=hovered==self and 7 or 12
			rf(
				self.x,
				self.y,
				self.x+self.w,
				self.y+self.h,
				hvrc)
			rect(
				self.x,
				self.y,
				self.x+self.w,
				self.y+self.h,
				1)
			print("i",
				self.x+3,self.y+2,1)
		end,
		act=function(self) 
			inv_open=true
			sfx(4)
			hovered=nil
		end	
	}
end

function inv_weight()
	local total=0
	for item in all(inv) do
		total+=item.weight
	end
	return total
end
-->8
--util
function draw_encoded(s,x,y)
	local basex = x or 0
	local basey = y or 0
	local w=tonum('0x'..sub(s,1,2))
	local h=tonum('0x'..sub(s,3,4))
	local rowpx=w
	local x=basex
	local y=basey
	
	for i=5,#s,4 do
		local clr=-1
		local clrchr=sub(s,i,i)		
		if clrchr ~= 'x' then
			clr=tonum('0x'..clrchr)
		end
		local len=tonum('0x'..sub(s,i+1,i+3))
		while len>=rowpx do
			if clr~=-1 then
				line(x,y,x+rowpx-1,y,clr)
			end
			len=len-rowpx
			rowpx=w
			y=y+1
			x=basex
		end
		if len>0 do
			if clr~=-1 then
				line(x,y,x+len-1,y,clr)
			end
			rowpx=rowpx-len
			x=x+len
		end
	end
end

--string arithmetic
--a is str, b is int
function big_add(a,b)
	local carry=0
	local res=""
	local to_add=tostr(b)
	local alen=#a
	local blen=#to_add
	local maxlen=max(alen,blen)
	for i=0,maxlen-1 do
		local dig1=sub(
			a,
			max(alen-i,0),
			max(alen-i,0)
		)
		dig1=
			(dig1=="" and "0" or dig1)
		dig1=tonum(dig1)
		local dig2=sub(
			to_add,
			max(blen-i,0),
			max(blen-i,0)
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
	return res
end
-->8
--todo
--[[

* sfx/music

----------------
* mus 0 start/end
* mus 24 piano
* mus 56 static
----------------

]]
__gfx__
0000000007000700170000000000007101111111fffffffffffffffffffffffffffffffffff00700077777777777777577777777777777000007777700000000
00000000707007001677000000007761016666674444444444444444444444444444444444407e70777555555555577577755555555557700777777777000000
00700700070770771666770000776661001666704441111111111111111111111111111444407e70775777777777757577577777777775707777777777700000
00077000000007001666666666666661001666704441444444444449999444444444441444407e70777777777777777577777777777777707777777777700000
00077000000007001666110000116661000167004441444444444499997944444444441444400000777555555555577577755555555557707777777777700000
00700700000000001611000000001161000167004441444444444449999444444444441444400000775777777777757577577777777775707777eee777700000
0000000000000000110000000000001100006000444111111111111111111111111111144440000077777777777777757777777777777770777eeeee77700000
0000000000000000000000000000000000006000444444444444444444444444444444444440000077555555555555757755555555555570777eeeee77700000
eaaaae00000077007700999900e66666666666666666666e0444444444444444444444004444444477777777777777757777777777777770777eeeee77700000
e9999e000777777777799997906655558555555555555566444444444444444444444440444444440000000000000000e000e00000000000777eeeee77700000
9997990077777777777099990066666666666666666666664444444444444444444444405000000500000000000000000070000000000000777eeeee77700000
99997900677777777700000000660060060060066633666644444444444444444444444005000050000000000000000007e7000000000000777eeeee77700000
9999990006606777700000000066006006006006663366661444444444997444444444100050050000000000000000000070000000000000777eeeee77700000
999999000000066000000000006666666666666666666666411111111199911111111140000550000000000000000000e000e00000000000777eeeee77700000
e9999e0000003033000000000366555555555555555555664444444444999444444444400005500000000000000000000000000000000000777eeeee77700000
eaaaae0000033333300000003366566666666666666665664455555445555544555554400050050000000000000000000000000000000000777eeeee77700000
ea00ae00003333333333000033665555555555555555556644599954458885445333544005000050eeeeeee0eeeeeeeeee000ee000000000777eeeee77700000
ea00ae00003333333333300333665666666666666666656644599954458885445333544050000005eeeeee0a0eeeeeeeee070ee000000000777eeeee77700000
eaa0ae00003333433333330033665555555555555555556644599954458885445333544050000005eeeee0aaa0eeeeee0007000000000000777eeeee77700000
ea00ae30000333343334333003665666666666666666656644555554455555445555544050000005eeee0aaaaa0eeeee077e770000000000777eeeee77700000
eaaaae33000033343343330333665555555555555555556644444444444444444444444050000005eee0aaaaaaa0eeee00070000000000000000000000000000
eaaaae00000000000000000000666666666666666666666644444444444444444444444005000050ee0aaaaaaaaa0eeeee070ee0000000000000000000000000
00000000000000000000000000000000000000000000000044444444444444444444444000500500e0aaaaaaaaaaa0eeee000ee0000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000
00050000004444009999999900000000000000000006600007777770000000006000000000000000000000000000000000000077000000000000000000000000
000f0000005005009777777700000000000006600006600077555577011011006600000066600000aaa000000000000000777007000000000000000000000000
000a0000000550009999999700eee700000006600007700075777757055155000660000065666666a9aaaaaa0444448000007777000000000000000000000000
000a000000055000944494970eeeee70000060000077770077777777055155000069a00060655656a0a99a9affffffff07777171000000000000000000000000
000a000000500500999999970eeeee700006000007777770775555770551550000999a0066600505aaa00909f888888f777777e7000000000000000000000000
000a00000500005094494497eeeeeeee0060000007777a707577775705505500000499a05550000099900000ffffffff77777777000000000000000000000000
00060000050000509999999700000000060000000777a77077777777055055000000499900000000000000000000000067777777000000000000000000000000
000e0000005005009999999000000000000000000077770077777777066066000000049000000000000000000000000006777777000000000000000000000000
000000000099900000000000aaaaaaaaa000000aaaaaa000000aaaaaa000aaaaaaaaa000aaaaaaaaa000aaaaaaaaa000000aaa00000000000000000000000000
044444444444444444444400aaaaaaaaa000000aaaaaa000000aaaaaa000aaaaaaaaa000aaaaaaaaa000aaaaaaaaa000000aaa00000000000000000000000000
455555555555555555555540aaaaaaaaa000000aaaaaa000000aaaaaa000aaaaaaaaa000aaaaaaaaa000aaaaaaaaa000000aaa00000000000000000000000000
455555555555555555555540aaa000000000aaa000000000aaa000000000aaa000aaa000aaa000aaa000aaa000000000000aaa00000000000000000000000000
455555555555555555555540aaa000000000aaa000000000aaa000000000aaa000aaa000aaa000aaa000aaa000000000000aaa00000000000000000000000000
455555555555555555555540aaa000000000aaa000000000aaa000000000aaa000aaa000aaa000aaa000aaa000000000000aaa00000000000000000000000000
044499944444444499944400aaaaaa000000aaaaaaaaa000aaa000000000aaaaaaaaa000aaaaaaaaa000aaaaaa000000000aaa00000000000000000000000000
411111111111111111111140aaaaaa000000aaaaaaaaa000aaa000000000aaaaaaaaa000aaaaaaaaa000aaaaaa000000000aaa00000000000000000000000000
411111111111111111111140aaaaaa000000aaaaaaaaa000aaa000000000aaaaaaaaa000aaaaaaaaa000aaaaaa000000000aaa00000000000000000000000000
411111111111111111111140aaa000000000000000aaa000aaa000000000aaa000aaa000aaa000000000aaa00000000000000000000000000000000000000000
411111111111111111111140aaa000000000000000aaa000aaa000000000aaa000aaa000aaa000000000aaa00000000000000000000000000000000000000000
411111111111111111111140aaa000000000000000aaa000aaa000000000aaa000aaa000aaa000000000aaa00000000000000000000000000000000000000000
444444444444444444444440aaaaaaaaa000aaaaaa000000000aaaaaa000aaa000aaa000aaa000000000aaaaaaaaa000000aaa00000000000000000000000000
445555544555554455555440aaaaaaaaa000aaaaaa000000000aaaaaa000aaa000aaa000aaa000000000aaaaaaaaa000000aaa00000000000000000000000000
445999544588854453335440aaaaaaaaa000aaaaaa000000000aaaaaa000aaa000aaa000aaa000000000aaaaaaaaa000000aaa00000000000000000000000000
44599954458885445333544000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44599954458885445333544044444444444444440000000dd0000000000000000000000000000000000000000000000000000000000000000000000000000000
4455555445555544555554404444444444444444000000d11d000000000000000000000000000000000000000000000000000000000000000000000000000000
444444444444444444444440441111111111114400000d1111d00000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444044111111111111440000d111111d0000000000000000000000000000000000000000000000000000000000000000000000000000
4444444444444444444444404411111111111144000d11111111d000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeee0eeeee000000000044111111aaa1114400d1111111111d00000000000000000000000000000000000000000000000000000000000000000000000000
00ee000ee00e0e000000000044111111aad111440d111111111111d0000000000000000000000000000000000000000000000000000000000000000000000000
ee0eeeeeeee0ee000000000044111111aaa91144d11111111111111d000000000000000000000000000000000000000000000000000000000000000000000000
e0eeeeee00eeee00000000004411aaaaaaa111440d111111111111d0000000000000000000000000000000000000000000000000000000000000000000000000
0e000e00ee000e00000000004411aaaaaaa1114400d1111111111d00000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeee0eeeeee000000000044ccaaaaaaaccc44000d11111111d000000000000000000000000000000000000000000000000000000000000000000000000000
0000ee0e00ee0e000000000044c77aaaaaa77c440000d111111d0000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeee00ee000000000044ccc777777ccc4400000d1111d00000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeee000000000044cccccccccccc44000000d11d000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000044444444444444440000000dd0000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000044444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeee0000000000000000000000eeee00eee000eee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0007777777777777777777777000e00ee07770ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777777777777777777777777000e0777770e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000077775555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05777777777777777777777777777000077755555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05777777777777777777777777777000077755555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0577777777777777777777777770e00007775555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0577777777777777777777777770e000707770ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee05777777777777777777777770ee00070000eee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ee05777777777777777777777770ee00070eeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee057777777777777777777770eee00070eeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee057777777777777777777770eee00070eeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeee0577777777777777777770eeee00e00eeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeee05777777777777777770eeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeee057777777777777770eeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeee0077777777777700eeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeee055007777777700550eeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeee056550000000055770eeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeee056776555555577770eeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeee056777777777777770eeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeee056777777777777770eeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeee056777777777777770eeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeee056777777777777770eeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
