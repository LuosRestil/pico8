pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--main
function _init()
	k,rest_len,g=0.15,60,{0,1}
	repel=false
	anc=particle:new({64,0})
	bob=particle:new({24,90})
	spring_1=spring:new(
		k,rest_len,anc,bob,repel)
end

function _update()
	spring_1:update()
	--anc:update()
	bob:update()
	
	if (btn(0)) anc.pos[1]-=3
 if (btn(1)) anc.pos[1]+=3
 if (btn(2)) anc.pos[2]-=3
 if (btn(3)) anc.pos[2]+=3
end

function _draw()
	cls()
	spring_1:draw()
	anc:draw()
	bob:draw()
end

-->8
--vectors
function add_v(v1,v2)
	return {
		v1[1]+v2[1],
		v1[2]+v2[2]
	}
end

function sub_v(v1,v2)
	return {
		v1[1]-v2[1],
		v1[2]-v2[2]
	}
end

function mul_v(v,x)
	return {x*v[1],x*v[2]}
end

function dot(v1,v2)
	return v1[1]*v2[1]+v1[2]+v2[2]
end

function dist(a,b)
	return mag(sub_v(a,b))
end

function mag(v)
	return sqrt(v[1]*v[1]+v[2]*v[2])
end

function norm(v)
 return mul_v(v,1/mag(v))
end

function cpy(v)
	return {v[1],v[2]}
end

function set_mag(v,mag)
 return mul_v(norm(v),mag)
end
-->8
-- particle
particle={
 apply_force=function(self,f)
	 	self.acc = add_v(
				self.acc,
				mul_v(f,1/self.mass)
			)
 end,
 update=function(self)
 	self:apply_force(g)
		self.vel=add_v(self.vel,self.acc)
		self.pos=add_v(self.vel,self.pos)
		self.acc={0,0}
		self.vel=mul_v(self.vel,0.99)
 end,
 draw=function(self)
  circfill(
 		self.pos[1],
 		self.pos[2],
 		self.r,
 		6)
 end
}

function particle:new(pos,mass)
	local mass=mass or 1
	local p ={
		acc={0,0},
		vel={0,0},
		pos=pos,
		mass=mass,
		r=mass*4
	}
	setmetatable(p,{__index=self})
	return p
end

-->8
--spring
spring={
 update=function(self)
 		local x=dist(
				self.p1.pos,self.p2.pos
			)-self.rest_len
			if self.repel or x>0 then
				local force=set_mag(
					sub_v(
						self.p2.pos,
						self.p1.pos
					),
					-self.k*x)
				self.p2:apply_force(force)
				self.p1:apply_force(mul_v(force,-1))
			end
 end,
 draw=function(self)
 	line(
			self.p1.pos[1],
			self.p1.pos[2],
			self.p2.pos[1],
			self.p2.pos[2],
			7)
 end
}

function spring:new(
	k,rest_len,p1,p2,repel
)
	local s={
		k=k,
		rest_len=rest_len,
		p1=p1,
		p2=p2,
		repel=repel or false
	}
	setmetatable(s,{__index=self})
	return s
end

-->8
--util
function table_dump(obj)
	if type(obj)=='table' then
		local s='{ '
 	for k,v in pairs(obj) do
 		if type(k) ~= 'number' then 
 			k='"'..k..'"'
 		end
  	s=s..'['..k..'] = '..dump(v) .. ','
		end
 	return s .. '} '
	else
 	return tostring(obj)
 end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
