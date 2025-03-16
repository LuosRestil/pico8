pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
	curs={
		pos=vec:new(64,64),
	}
	ball={
		pos=vec:new(),
		vel=vec:new(),
		acc=vec:new()
	}
end

function _update()
	if(btn(⬅️))curs.pos.x-=2
	if(btn(➡️))curs.pos.x+=2
	if(btn(⬆️))curs.pos.y-=2
	if(btn(⬇️))curs.pos.y+=2

	local dir=curs.pos-ball.pos
	dir:set_mag(0.3)
	ball.acc=dir
	ball.vel:add(ball.acc)
	ball.vel:limit(3)
	ball.pos:add(ball.vel)
end

function _draw()
	cls()
	spr(1,curs.pos.x,curs.pos.y)
	spr(2,ball.pos.x,ball.pos.y)
end
-->8
--vectors
vec={
	__add=function(v1,v2)
		return vec:new(v1.x+v2.x,v1.y+v2.y)
	end,
	__sub=function(v1,v2)
		return vec:new(v1.x-v2.x,v1.y-v2.y)
	end,
	__mul=function(lhs,rhs)
		if type(lhs)=="table" and type(rhs)=="number" then
  	return vec:new(lhs.x*rhs,lhs.y*rhs)
  elseif type(lhs) == "number" and type(rhs) == "table" then
  	return vec:new(rhs.x*lhs,rhs.y*lhs)
  else
  	add(msg,"incompatible types")
  end
	end,
	--dot product
	__pow=function(v1,v2)
		return v1.x*v2.x+v1.y*v2.y
	end,
}
vec.__index=vec

function vec:new(x,y)
	if (x==nil) x=0
	if (y==nil) y=0
	local v={x=x,y=y,isvec=true}
	setmetatable(v,vec)
	return v
end

function vec:add(v)
	self.x+=v.x
	self.y+=v.y
end

function vec:sub(v)
	self.x-=v.x
	self.y-=v.y
end

function vec:mul(s)
	self.x*=s
	self.y*=s
end

function vec:norm()
	self:mul(1/self:mag())
end

function vec:mag()
	return sqrt(self.x*self.x+self.y*self.y)
end

function vec:set_mag(m)
	self:norm()
	self:mul(m)
end

function vec:limit(l)
	if self:mag() > l then
		self:set_mag(l)
	end
end
__gfx__
00000000000000000088880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000770008888878800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000077007708888878800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000077007708888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000770008888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000088880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
