pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
rects={}

function _init()
	plr=init_player()
	ps=newps()
	for i=1,10 do
		add(rects,new_rect())
	end
end

function _update()
	plr:update()
	ps:update()
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
	ps:draw()
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
			ps.active=false
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
						ps.x=p.x
						ps.y=p.y
						ps.active=true
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
-->8
function newps()
	local ps={
		x=0,
		y=0,
		active=false,
		ps={},
		t=1,
		maxp=10,
		update=function(self)
			for p in all(self.ps) do
				if(p.dead)goto continue
				p.x+=p.vx
				p.y+=p.vy
				p.t+=1
				if p.t>p.lt then
					p.dead=true
				end
				::continue::
			end
			
			if self.active then
				for i=1,2 do
					self.ps[self.t]={
						x=self.x,
						y=self.y,
						vx=rnd()*(rnd()<0.5 and -1 or 1)*3,
						vy=rnd()*(rnd()<0.5 and -1 or 1)*3,
						t=0,
						lt=rnd(2)+2,
						dead=false
					}
					self.t+=1
					if self.t>self.maxp then
						self.t=1
					end
				end
			end
		end,
		draw=function(self)
			for p in all(self.ps) do
				if not p.dead then
					pset(p.x,p.y,7)
				end
			end
		end
	}
	for i=1,ps.maxp do
		ps[i]={
			x=ps.x,
			y=ps.y,
			vx=rnd()*(rnd()<0.5 and -1 or 1)*3,
			vy=rnd()*(rnd()<0.5 and -1 or 1)*3,
			t=0,
			lt=rnd(2)+2,
			dead=false
		}
	end
	return ps
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
