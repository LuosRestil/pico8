pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
rects={}

function _init()
	plr=init_player()
	for i=1,10 do
		add(rects,new_rect())
	end
end

function _update()
	plr:update()
end

function _draw()
	cls(1)
	plr:draw()
	for rec in all(rects) do
		rec:draw()
		local torec=vsub(rec,plr)
		local dot=plr.heading.x*torec.x+
			plr.heading.y*torec.y
	end

end

function new_rect()
	local rec={
		x=rnd(127),
		y=rnd(127),
		w=rnd(10)+5,
		h=rnd(10)+5,
		draw=function(self)
			rectfill(
				self.x,
				self.y,
				self.x+self.w-1,
				self.y+self.h-1,
				self==zaprect and 9 or 2)
		end
	}
	rec.pts={
		{x=rec.x,y=rec.y},
		{x=rec.x+rec.w,y=rec.y},
		{x=rec.x+rec.w,y=rec.y+rec.h},
		{x=rec.x,y=rec.y+rec.h}
	}
	rec.lines={
		{p1=rec.pts[1],p2=rec.pts[2]},
		{p1=rec.pts[2],p2=rec.pts[3]},
		{p1=rec.pts[3],p2=rec.pts[4]},
		{p1=rec.pts[4],p2=rec.pts[1]}
	}
	
	return rec
end


-->8
function init_player()
	local player={
		y=128-16,
		r=7,
		angle=0,
		heading={x=0,y=0},
		update=function(self)
			if(btn(⬅️))self.angle+=0.005
			if(btn(➡️))self.angle-=0.005
			self.heading={
				x=cos(self.angle),
				y=sin(self.angle)
			}
			self.laser=nil
			zaprect=nil
			if btn(🅾️) then
				self.lasering=true
				local lline={
					p1={x=self.x,y=self.y},
					p2={
						x=self.x+self.heading.x*128,
						y=self.y+self.heading.y*128
					}
				}
				local p=nil --intersection
				local pdist=100000
				for rec in all(rects) do
					local lp=int_line_rec(lline,rec)
					if
						lp~=nil and
						(
							p==nil or 
							dist(lp,plr)<pdist
						)
					then
						p=lp
						pdist=dist(lp,plr)
						zaprect=rec
					end
				end

				self.laser={
						p1=lline.p1,
						p2=p~=nil and p or lline.p2
				}
			end
		end,
		draw=function(self)
			if self.laser~=nil then
				line(
					self.laser.p1.x,
					self.laser.p1.y,
					self.laser.p2.x,
					self.laser.p2.y,8)
			end
			circfill(self.x,self.y,
				self.r,10)
			circfill(
				self.x+self.heading.x*(self.r+2),
				self.y+self.heading.y*(self.r+2),
				3,11)
		end
	}
	player.x=64-player.r/2
	return player
end
-->8
--utils
function int_line_rec(laser,rec)
	local p=nil
	local pdist=100000
	for lline in all(rec.lines) do
		local lp=int_line_line(laser,lline)
		if
			lp~=nil and
			(
				(p==nil) or
				dist(lp,plr)<pdist
			)
		then
			p=lp
			pdist=dist(lp,plr)
		end
	end
	return p
end

function int_line_line(l1,l2)
	local a1=l1.p1
	local a2=l1.p2
	local b1=l2.p1
	local b2=l2.p2
	
	local denom=
		(a2.x-a1.x)*(b2.y-b1.y)-
		(a2.y-a1.y)*(b2.x-b1.x)
	local proga=
		(
			(b1.x-a1.x)*(b2.y-b1.y)-
			(b1.y-a1.y)*(b2.x-b1.x)
		) / denom
	local progb=
		(
			(b1.x-a1.x)*(a2.y-a1.y)-
			(b1.y-a1.y)*(a2.x-a1.x)
		) / denom
	if 
		proga>=0 and
		progb>=0 and
		proga<=1 and
		progb<=1
	then
		return {
			x=a1.x+proga*(a2.x-a1.x),
			y=a1.y+proga*(a2.y-a1.y)
		}
	else
		return nil	
	end
end

function dist(p1,p2)
	return sqrt(
		(p1.x-p2.x)*(p1.x-p2.x)+
		(p1.y-p2.y)*(p1.y-p2.y)
	)
end

function vsub(v1,v2)
	return {
		x=v1.x-v2.x,
		y=v1.y-v2.y
	}
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
