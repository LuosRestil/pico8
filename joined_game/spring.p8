pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--main
function _init()
	k,rest_len,g=0.15,60,{0,1}
	repel=false
	anc=new_particle({64,0})
	bob=new_particle({24,90})
	spring=new_spring(
		k,rest_len,anc,bob,repel)
	assert(spring ~= nil)
end

function _update()
	update_spring(spring)
	--update_particle(anc)
	update_particle(bob)
	
	if btn(0) then anc.pos[1]-=3 end
 if btn(1) then anc.pos[1]+=3 end
 if btn(2) then anc.pos[2]-=3 end
 if btn(3) then anc.pos[2]+=3 end
end

function _draw()
	cls()
	draw_spring(spring)
	draw_particle(anc)
	draw_particle(bob)
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
function new_particle(pos,mass)
	local p = {}
	p.acc={0,0}
	p.vel={0,0}
	p.pos=pos
	p.mass=mass or 1
	p.r=p.mass*4
	return p
end

function apply_force(p,f)
	p.acc = add_v(
		p.acc,
		mul_v(f,1/p.mass)
	)
end

function update_particle(p)
	apply_force(p,g)
	p.vel=add_v(p.vel,p.acc)
	p.pos=add_v(p.vel,p.pos)
	p.acc={0,0}
	p.vel=mul_v(p.vel,0.99)
end

function draw_particle(p)
 circfill(
 	p.pos[1],
 	p.pos[2],
 	p.r,
 	6)
end
-->8
--spring
function new_spring(
	k,rest_len,p1,p2,repel
)
	local s={}
	s.k=k
	s.rest_len=rest_len
	s.p1=p1
	s.p2=p2
	s.repel=repel or false
	return s
end

function update_spring(s)
	local x=dist(
		s.p1.pos,s.p2.pos
	)-s.rest_len
	if s.repel or x>0 then
		local force=set_mag(
			sub_v(s.p2.pos,s.p1.pos),
			-s.k*x)
		apply_force(s.p2,force)
		apply_force(s.p1,mul_v(force,-1))
	end	
end

function draw_spring(s)
	line(
		s.p1.pos[1],
		s.p1.pos[2],
		s.p2.pos[1],
		s.p2.pos[2],
		7)
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
