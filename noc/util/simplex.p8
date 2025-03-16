pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Simplex Noise Example
-- by Anthony DiGirolamo

local Perms = {
   151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225,
   140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148,
   247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32,
   57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68,   175,
   74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111,   229, 122,
   60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54,
   65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169,
   200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64,
   52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212,
   207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213,
   119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9,
   129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104,
   218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241,
   81,   51, 145, 235, 249, 14, 239,   107, 49, 192, 214, 31, 181, 199, 106, 157,
   184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93,
   222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180
}

-- make Perms 0 indexed
for i = 0, 255 do
   Perms[i]=Perms[i+1]
end
-- Perms[256]=nil

-- The above, mod 12 for each element --
local Perms12 = {}

for i = 0, 255 do
   local x = Perms[i] % 12
   Perms[i + 256], Perms12[i], Perms12[i + 256] = Perms[i], x, x
end

-- Gradients for 2D, 3D case --
local Grads3 = {
   { 1, 1, 0 }, { -1, 1, 0 }, { 1, -1, 0 }, { -1, -1, 0 },
   { 1, 0, 1 }, { -1, 0, 1 }, { 1, 0, -1 }, { -1, 0, -1 },
   { 0, 1, 1 }, { 0, -1, 1 }, { 0, 1, -1 }, { 0, -1, -1 }
}

for row in all(Grads3) do
   for i=0,2 do
      row[i]=row[i+1]
   end
   -- row[3]=nil
end

for i=0,11 do
   Grads3[i]=Grads3[i+1]
end
-- Grads3[12]=nil

function GetN2d (bx, by, x, y)
   local t = .5 - x * x - y * y
   local index = Perms12[bx + Perms[by]]
   return max(0, (t * t) * (t * t)) * (Grads3[index][0] * x + Grads3[index][1] * y)
end

---
-- @param x
-- @param y
-- @return Noise value in the range [-1, +1]
function Simplex2D (x, y)
   -- 2D skew factors:
   -- F = (math.sqrt(3) - 1) / 2
   -- G = (3 - math.sqrt(3)) / 6
   -- G2 = 2 * G - 1
   -- Skew the input space to determine which simplex cell we are in.
   local s = (x + y) * 0.366025403 -- F
   local ix, iy = flr(x + s), flr(y + s)
   -- Unskew the cell origin back to (x, y) space.
   local t = (ix + iy) * 0.211324865 -- G
   local x0 = x + t - ix
   local y0 = y + t - iy
   -- Calculate the contribution from the two fixed corners.
   -- A step of (1,0) in (i,j) means a step of (1-G,-G) in (x,y), and
   -- A step of (0,1) in (i,j) means a step of (-G,1-G) in (x,y).
   ix, iy = band(ix, 255), band(iy, 255)
   local n0 = GetN2d(ix, iy, x0, y0)
   local n2 = GetN2d(ix + 1, iy + 1, x0 - 0.577350270, y0 - 0.577350270) -- G2
   -- Determine other corner based on simplex (equilateral triangle) we are in:
   -- if x0 > y0 then
   --    ix, x1 = ix + 1, x1 - 1
   -- else
   --    iy, y1 = iy + 1, y1 - 1
   -- end
   -- local xi = shr(flr(y0 - x0), 31) -- x0 >= y0
   local xi = 0
   if x0 >= y0 then xi = 1 end
   local n1 = GetN2d(ix + xi, iy + (1 - xi), x0 + 0.211324865 - xi, y0 - 0.788675135 + xi) -- x0 + G - xi, y0 + G - (1 - xi)
   -- Add contributions from each corner to get the final noise value.
   -- The result is scaled to return values in the interval [-1,1].
   return 70 * (n0 + n1 + n2)
end

-- 3D weight contribution
function GetN3d (ix, iy, iz, x, y, z)
   local t = .6 - x * x - y * y - z * z
   local index = Perms12[ix + Perms[iy + Perms[iz]]]
   return max(0, (t * t) * (t * t)) * (Grads3[index][0] * x + Grads3[index][1] * y + Grads3[index][2] * z)
end

--
-- @param x
-- @param y
-- @param z
-- @return Noise value in the range [-1, +1]
function Simplex3D (x, y, z)
   -- 3D skew factors:
   -- F = 1 / 3
   -- G = 1 / 6
   -- G2 = 2 * G
   -- G3 = 3 * G - 1
   -- Skew the input space to determine which simplex cell we are in.
   local s = (x + y + z) * 0.333333333 -- F
   local ix, iy, iz = flr(x + s), flr(y + s), flr(z + s)
   -- Unskew the cell origin back to (x, y, z) space.
   local t = (ix + iy + iz) * 0.166666667 -- G
   local x0 = x + t - ix
   local y0 = y + t - iy
   local z0 = z + t - iz
   -- Calculate the contribution from the two fixed corners.
   -- A step of (1,0,0) in (i,j,k) means a step of (1-G,-G,-G) in (x,y,z);
   -- a step of (0,1,0) in (i,j,k) means a step of (-G,1-G,-G) in (x,y,z);
   -- a step of (0,0,1) in (i,j,k) means a step of (-G,-G,1-G) in (x,y,z).
   ix, iy, iz = band(ix, 255), band(iy, 255), band(iz, 255)
   local n0 = GetN3d(ix, iy, iz, x0, y0, z0)
   local n3 = GetN3d(ix + 1, iy + 1, iz + 1, x0 - 0.5, y0 - 0.5, z0 - 0.5) -- G3

   -- Determine other corners based on simplex (skewed tetrahedron) we are in:
   local i1
   local j1
   local k1
   local i2
   local j2
   local k2
   if x0 >= y0 then
      if y0 >= z0 then -- X Y Z
         i1, j1, k1, i2, j2, k2 = 1,0,0,1,1,0
      elseif x0 >= z0 then -- X Z Y
         i1, j1, k1, i2, j2, k2 = 1,0,0,1,0,1
      else -- Z X Y
         i1, j1, k1, i2, j2, k2 = 0,0,1,1,0,1
      end
   else
      if y0 < z0 then -- Z Y X
         i1, j1, k1, i2, j2, k2 = 0,0,1,0,1,1
      elseif x0 < z0 then -- Y Z X
         i1, j1, k1, i2, j2, k2 = 0,1,0,0,1,1
      else -- Y X Z
         i1, j1, k1, i2, j2, k2 = 0,1,0,1,1,0
      end
   end

   local n1 = GetN3d(ix + i1, iy + j1, iz + k1, x0 + 0.166666667 - i1, y0 + 0.166666667 - j1, z0 + 0.166666667 - k1) -- G
   local n2 = GetN3d(ix + i2, iy + j2, iz + k2, x0 + 0.333333333 - i2, y0 + 0.333333333 - j2, z0 + 0.333333333 - k2) -- G2
   -- Add contributions from each corner to get the final noise value.
   -- The result is scaled to stay just inside [-1,1]
   return 32 * (n0 + n1 + n2 + n3)
end

-- black       = 0
-- dark_blue   = 1
-- dark_purple = 2
-- dark_green  = 3
-- brown       = 4
-- dark_gray   = 5
-- light_gray  = 6
-- white       = 7
-- red         = 8
-- orange      = 9
-- yellow      = 10
-- green       = 11
-- blue        = 12
-- indigo      = 13
-- pink        = 14
-- peach       = 15

heatmap_colors = {0, 1, 13, 12, 11, 10, 9, 14, 8, 2}

terrainmap_colors = {1,  1,  1,  1,  1,  1,  1, -- deep ocean
                     13, 12, 15,    -- coastline
                     11, 11, 3, 3, 3, -- green land
                     4,  5,  6,  7} -- mountains

function _init()
  cls()
  -- generate some terrain
  local noisedx = rnd(1024)
  local noisedy = rnd(1024)
  for x=0,127 do
    for y=0,127 do
      local octaves = 5
      local freq = .007
      local max_amp = 0
      local amp = 1
      local value = 0
      local persistance = .65
      for n=1,octaves do

        value = value + Simplex2D(noisedx + freq * x,
                                  noisedy + freq * y)
        max_amp += amp
        amp *= persistance
        freq *= 2
      end
      value /= max_amp
      if value>1 then value = 1 end
      if value<-1 then value = -1 end
      value += 1
      value *= #terrainmap_colors/2
      value = flr(value+.5)
      pset(x,y,terrainmap_colors[value])
    end
  end
end

offset = 47
function _update()
  -- animated noise
  for z=0,1024 do
    for x=0,32 do
      for y=0,32 do
        local i = Simplex3D(x*.05,y*.05,z*.05)
        i += 1
        -- i /= 4
        i *= #heatmap_colors/2
        i = flr(i+.5)
        pset(x+offset,y+offset,heatmap_colors[i])
      end
    end
  end
end

function _draw()
end
__gfx__
aecd7600888c00000099990000cccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
98d165000ccccc0009aa89a00ccb3110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8010500000c77cc09889aa89ccbb3131000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc77cc9aaaa999cbb31333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc77cc989a8aa9cb311331000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000c77cc099989a89cc111311000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000ccccc0009aa9a900c111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888c00000099990000c11100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000760000006000000700000700000077000000000000000000000000000000000000000000000000000000000000000000000
06600000000000000000077600007760000076000007770000770000077700007770000000000000000000000000000000000000000000000000000000000000
07766000777777760077777600777760000776000007770000777000077777007777770077777776000000000000000000000000000000000000000000000000
07777660777777607777776007777600007776000077777000777700007777700777777607777776000000000000000000000000000000000000000000000000
07777776077776007777760077777600077776000077777000777770007777760077777600777760000000000000000000000000000000000000000000000000
07777770077760000777760007777600777776000777777600777766007777600077776000077760000000000000000000000000000000000000000000000000
07777000007600000077600000776000007776000666666600776600000776000007760000007600000000000000000000000000000000000000000000000000
07700000006000000006000000066000000066000000000000660000000660000000600000000600000000000000000000000000000000000000000000000000
__label__
1110001111111111111111111111111111111111111111111111111dddddd1111cffbbcd1111dccc111111111111111111dfb3bf11dfb33bfcccfbbbbffcdcb3
c11111111111111111111111111111111ddd111111111111111111dcccd11111cfb33bc111dccccd1111111dd1111111111dbbbfd1cbb3bbffffbbbbccd11dfb
bf11111111111111111111111dcc111111dd1111111111111111ddcffcd1111dcb3333fddcfffccd11111111ddcd11111111cbbbccfbbbbfffbbb3bfcd1111cb
33f1111111111111111111111cffc1111111111111111ddd11dcfffbfc111111cfb333bfffbbfd1111111111dcffc1111111dfbbbbbbbbffbbb333bfd11111df
33bc11111111111111111111dcfbfd1111111111111ddcfcccfbbbbbbfd111111dfb33bbbbbfd11111dccc11dfbbbc111111dcbb3333bbffb3333bbcd11dddcf
333f1111111111111111ddcdccbbfd111111111111ddcffffb33333bbbfd111111dfbbbbbbfd11111dcfbfd1df333bfccccccfb333333bbb33333bfcd11dccfb
33bfd11111111111111ddccdcfbbfc11111111111dccffbbbb33333b33bfd111111dcffbbbc111111cbbbbcdcf3333bbbbbbbb33333333334433bbfc111dcfbb
33bbcd1ddd111111111dddd1dcbbbc1111111111dcffbbbbb33333bb333bfd1111111dcfbbc11111cbbbbbfccfbb333333333333333333345533bffcd111cbb3
333bfcdccd1111111dcdd11111cffc111dddcccccffbbbbbb3333bbb3333bcd11111111cffc1111cbbbbbbbbbbbbbbb33333333333333444543bffffd111dfbb
4333bfccc1111111dccd1111111dd1111ddcfbbffffbbbbbbb3bbffb333bbcd111111111ccc111dfb33333bbbbbbfbbb3333333333335655433bbbbbc111dfbb
5433bfccd1111111dcd11111111111111ddcbbbfffffffffbbbbbfb3333bffcd111111111ddd1dcbb3333333333bbbbbbb33344444457765333bbb3bbd11dcff
5433bfcdd1111111dd111111111111111ddcbbfccccccccfbb33bb33433bffffd11111111dccccffbb33333334333bb33b3334566667775433333333bc11dcff
333bfccdd111111ddd111111111111111dccffcd1dcccddcb333333443bfcfbbfc1111111dfbbffffbb3333345543333333334677777754333333333bd11dcff
333bbfcccdddccccdd111111dd1111111dccccd11cfbfccfb333334433fddcbbbfcdddddcfbbbfccffbbbb333554433333334457777653333345443bfd1dcfbb
b3333bbfcccfffffcd1111111d1110111dccccd1dfbbbccfbb3333333bcddcbbbbfcccfbbbbbbfcccffbbbb33455444433333456777533333467653bfdccfbbb
3333333bfccfffbbfc1111111111101111cfbfccfb3bfcddcffbb333bfdddcfbffcccfb3333bbcddcfffbbb333455554333334567764333335777643bfbbbbbb
3334433bfdddcfbbfc111111111111111dcbbbbbbbbfd11111dcfbbbbfccfbffcccdcfb3333bbcccfbffbbb333555554333334455554433346777643bb3333bc
4445443bfd11dfbbbc111111111111111dcbb33bbbfd11111111cfbbbccfbbfcddddcfb33333bbfbbbffbbbb3356655433333333444444444566554333333bfd
6665433bfcddcfbbbd111111111111cffccfbb3bfcd111111111dfbbfccfbbfcdddccb33333333333bbffbbb3355554433333333333333444444433333333bc1
7776433bbbffffbbfd11111111111dfbbcddcfbfcd111111111dcfbfd11cbbfcdddccbb33333333333bbfbbb33444444333333bbb33333344433333334333bfd
77753333bbbbfffccd111111111111fbbc111dccd111111111ddcffc111dfffcddddcfbbb3334444433bbbb333334444444443bbbb33333444333333344333bf
77533bbb33bbfcd111111111111111cbbc1111dd1111111111dccccd1111cffccdddcfbbbb334444433333333333334444565433b3333334443333333444433b
6533bfbb33bbcd11111dd1111111111ccd11111d111111111dcccdd11111cfbffccccfbbbb3333333333333333b333333467764333333445543333bb33444443
533bfbb33bbfc111111dcd111111111d111111dd111111111dcccdd11111cfbbbfffbbbbbb33333b333334433bbbbbb3335777655566666665433bffbb334444
33bbbb333bfcdddd1ddccd11111111111111dddd11111111dcfffcd111111fbbbbbb3333bbb33bffbb333433bfffffbb334577767777777776543bfccb333344
bbbbb333bfcdccffcccccdd111111dd1111dcccd1111111ddfbbbfd1111111fbbbb333333bbbbcccfb33333bfccffffbb33356777777777777653bfccfbb3344
cfbb3333bcddcfbbbfcdd1111111dcfd1dcfffcd11111111dfbbbfd1111111dcbbb333333bbfcd1df333333bfcfffffbbb3346766677777777643bfffbbb3345
cfb3333bfdddfbbbbbfd1111111cfbbfccfbbfd111111111dcbbbc111100111dffbbb3333bfcd11db333333bfffffcfbbb335676555566777753bbfbbbbbb345
fb33333bfccfb33bbbfcd111ddcb333bffbbbc1111111111dcfbfd111000111dcfffbb333bfcdddcb3333333bbbbfcffbb336776433445566543bcfbbbbbb335
b334333bbbbb333bbbbfcd1dcfb3333bffffcd111111111ddcffc1111111111dfffcfb333bfcccfbb3333333333bbccfbb34676543333444553bfcfb33bbb334
334433333333333bbbbbfcddcbb333bfcdccd1111111111ddcccd1111111111dfffccb3333bbbb33333333443333bfcfbb33565433333334443bfcfb33333333
33433333433333bbbbbbbfccbb3333bfcddddd111111111dddcd1111111111dcfffccb33333333344333334433333bfffbb33443333333334433ffbb3333333b
3333333555333bbfcfbbbffbbbbbbbbbfccddddd111111111ddd111111111ddcfffffbb333333345543333333333bbfccccfb33333b333333433bbb33344333b
343333356533bffcddccccfbbbbbbbbbbbfcdddd1111111111d111111111dcccfffffbbb33333345543bb333bbbbffcdd1ddfb333bbb33333333bb333344333b
554333456533bfcdd1ddccfbbbfffb333bbc11111110011111111111111dcfccfbbbbbbb33333334433bbbbbbfcdddddddddcbb33bbb333333bbb333333333bb
66643345543bbfcd11dccffffcddcb333bfd1111111001111111111111dcffffbbbbbbb33333bb33333bbffffc1111dccccccfbbbbbb33333bbfb3343333bbbb
67754345433bbffd11dcfffccd11cfbbbbc1111111111111111111111dcffffbb333bb333333bbb3333bfccccc11111cffffffbbbbbb33333bfcb334333bbbbb
7775433333bbbffcddcfbbfcdd1dcffccd1111111111111111111111dcccffbb3333bb333333bbbb33bbc11dcd11111cbbbbfffbb3bbb3333bccf33433bbbbbb
77754333333bbbbfccfbbbbbfcccffcd1111111dd11111111111111dcddcfbbb3333bb3333bbbbbb33bfd111dd11111cfbbfccfb333bb3333bcdfb33333bbbbb
77764333333333bbffbbbbbbbbbbbbfd111111dcc11111111111111dddddfbb33333bbbbbbbffffbb3bc1111d11111dcccfcdcfb333bbb333bfcfbbbb33333bb
77776333333333bbbbbbbb33bbbbbbbc11111dcfc11111111111111dd11dfbb3333bbbbbbffffffbbbbc111111111dccdddddcb3333bbb33bbffffffbb3333bb
7777743bb3333bbbbb33bbbbbbfbbbbcd1111dcc1111111111111111111dcb3333bbbbbffffbbbbbbbfc11111111dcccd11ddcb33333bbbbbbbbffccfb3333bf
7777743bbbbbbbffb3333bbffcccfbfcd111111111111111111111111111cfb333bbffcccffbbbbbbfcd11111111dcfc11ddcfb3333333bbbfffffcccb3333bf
7777633bffbbbfcfb3333bcdd11ddcdd111111111111d1111111111111111cb333bfdddddcfbbbbbbcd111111111dcccd1dfbbbb333333bffcccccccfb3333bb
776643bcdcfbbfcfb333bfc111111111111111111111d11111111111dd111db33bfd1111dcffbbbbbcd111111111dcccdcfb3333b3333bbfdd111dcfbb3333bb
77643bcd1dfbbbffb333bfd111dd111111111ddd111d111111111111dcd11dfbbbc11111ccccffbbbf11111ddcddddddcfb33333bbbbbbfcd1111dcbb3333b33
6643bfd11dbb3bbbbb3bbfd11dcc111111ddccfccddd111111111111ddd11dcfbfd1111cfffcdcbbbf1111dccccd111dcfb33333bbffcccd111111cb33333b33
543bfdd1dcbb33333bbbbfd11dccd11111dcfffffcd1d11ba99eeeee99aabbcd100000011ddddd11bf1111dccccd111dcbbb3333bbfcddd1111111db33433b33
33bcd11ddfbb333333bbbc1111ccd11111dcffbbfcd1ddda99eeeee999abbcdd10000011dccccccdbcd111ccccdd11dcfbbbbbbbbbfccd111111111db3333b33
bbc1111dcfbb333333bbfc1111cfcd11111dcfbbfc11dcf99e888ee99aabbcd11000001dcbbbbbbbbfd1ddccccccccffbbbbbbbbbbbbfcd111111111db333333
fcd1111dcbbbbb3333bbfd111dfbfcd1111dcfbbfc111cb9e88888e999abbcdd110011dcbaa999aabbcdddcccccffbbbbbbbbbbb3333bfc1111111111dbb3333
ffcd111dfb3bbfbbbbfcd1111cbbbbc111dcfbbbfd111cbee88888ee99aabbcdd1111dcba99eee99bbcdd111ddcfbbbbbbbbbb3333333bcd1111111111cbbbbb
cbbfcddcb33bfccfffd111111cb333bcdcfbbbffcd111cbee8888eeee999abbcdddddcbba9ee88eebfcd111111dcfbbb333bb333b3333bcdd111111111dfbbbb
dfbbfcfb3333bcddcd1111111df333bffbb3bbcd11111cf9eeeeeeeeeee99aabccccccba9ee88888ddd111111111dcfbb33bbbbbb333bfcd1111111111dfffcc
1cbbbbb33443bbcddd11111111cb333bbb33bfd111111df99eeeeeeeeeee99abbccccbaa9ee8888811111111111111cbb33bbbbbbbbbbcd11111111111dcfccc
1dfbbb3344433bfcccd1111111dfb3bbbbbbbf11111111da999eeee8888ee9aabbccbbaa9ee88888111111dd111111dfb33bbbbbbbbfcd1111111111111dcccc
11fb333334433bfccffc1111dddfbbbbbbbbbfd11111111baa99eee88888e9aabbccbbaa99ee888811111dcccdddddcfbbbbbbbbbfcd111111111111111ddccc
1df3334433333bcdcbbbfccccccfb33bbfcfbbbd1111111bbaa99e88888ee9abbccccbba99eeeeee11111dfffccffffbbbbbbbbbcd11111111111111111dccfb
dfb334443333bfddcbbbbbfcffbb333bbccfb33bd111111cbaa99e88888e9aabccccccbaa999eeee11111dfffffbbbbbbbbbb3bbc111111111111111111cffbb
bbb33333333bbcddcb333bfcfbb3333bbccfb33bfd11111cbaa99ee88ee99abcdddddcbbaaa9999911111dcfccfbbbbbbbffb33bc11111111111111111dffbb3
bbb333333bbbfccfb3333bfffb33333bfccfb333bc11111baa99eeeeee99bbcdd111ddcbbaaaaa9911111dccd1dcfbbbbfcfb333bd1111111111111111dcfbb3
ffbbbbbbbbbffffb333433bbb33333bbfccfb333bfd1111aa99eeeeee9aabdd111111dccbbbaaaa9d11111d11111cbb3bfccf333bcd111111111111111ddcfb3
cfbbbbffbbfccfbb334543bb33333bbffccfb333bfcdddca99eeeee99aabcd1100001ddccbbbbaa9d11111111111dfbbbfcdfb33bfd11111111111111111dcfb
cfb33bbbbbfccfbbb334433333333bfcdddcb3333bffffb9eeeeee99aabcd110000011dccbbbbaa9111111111111dcfbbfccfbbbfc111111111111111111ddcc
fb333bbbbbbffbbbbb3333333333bfcd1111dfb3bbbbbbbe888ee99aabcdd100000011dcccbbbaa911111111111dddcfcccfbbfcd11111dd111111111dddcddd
b3443bbb333bbbb3bb33333333bbbfd111111dfbbbbbbbb8888ee99abccd1100000011dcccbbbaa91111d1111111ddddddcbbbcd111111dd11111111dcfffcdd
34433bfb333333333333333333bbbcd1111111dcffbbbbf8888ee9abbccd110000001ddccbbbaa99d1ddd1111111111111cbbbc11111111d11111111dfbbbfcc
3443bfcfb33333333333bbbb3bbbfc111111111ddcbbbbf2288e99abbccd110000011dccbbbaa99eddddd1111111111111dfbbc11111111111111111cbb33bfb
3333bfcb333333b33333bfcbbbbfcd11111111111dfb3bf288ee9aabbccdd1111111ddcbbaaa999ed111111111111111111cbfd1111111111111111dcb333bb3
3333bbb333333bb33443bdddcffcd1111111111111cbbbf88ee9aaabbbcccdd111dddcbbaa9999eed111110011111111111cfcd11111111dcd1111dcfb333333
333333333333bb333543bd11dcd111111d111111111cbbfeee9aaaaaabbbccdddddccbbaa9999eee1111100011111111111dcd111111111cbfcd1dcfbb333333
3344444433bbb3334553bcd1ddd111111dd11111111dcff999aaaaaaaaabbcccccccbbaa99eeeeee111100001111111111ddd111111111dfbbbfccfbbb333333
335665543bbbb33345433bcddccd11111dd11111111dcffaaaaaa9999aaabbcccccbbaa99eeeeeee11111011111111111dcd111111111dcfb3bbfffbb3333333
335666433bffbb3333333bfccfffd11111111111111dfffbbbbaa999999aabbbccbbbaa9eeeeee99d1111111111111111dcd111111dcccccfbbbfffb3333333b
33566543bfccfbbb33333bcddfbbf111111111ddd11dfbfccbbba9eee99aabbbbbbbba99eeeee999d111111111dd111111d111111dcfffcddcffcccb333333bb
335665433bffffffbb33bfd1dfbbbcd111111cfcd11dfbbdccbaaeeeee99aabbbbbbba999eee99aad111111111ccd111111111111dcffccdddccddcb33333bbb
3456665433bbffffbbbbbc111cbbbfccd111dfbbfdddfbbddcbaaeeeee99aabbccbbbaa999999aab11ddd11111cbfd1111111111dcccccccccccddcb3333bbbb
5555665433bbbbbbbbbbfd111dccffffcd111fb3bfccfbb1dcba9e88ee99abbcccccbbaa999aaabb11dccd1111cbbc1111111111dddddcffffffcccbb3bbbbb3
6666555433bbbbbbbbbffcddddddccbbfc111f333bbffbb1dcba9e88ee99abcccccccbbaaaaabbccddcccd1111dccd1111111111d1111cbbbbbbfffbbbbfbb33
7776554333bbbb33bbfffffffccccfbbbcd1dfb33bbffbbddcba9eeeee9aabcdddddccbbaabbbccccccccd11111111111111111111111dbbbbbbbbbbbbffb333
666654333bbbbbbbfcdcfbbbbbbfffbbbfcddcbb3bbffbb33bbffffb3333bfd1111111111dffbbbbfccdd111111111111111111111111dfbbbbbbbbbfffb3355
5566553333bfccccdddcbb33bbbbbbbbbfccccbbbbfccfb33bfcddcfb3333bcd111111111cbbbbbbbfcd11111111111111111111111111cffbbbbbffffb33566
34566654333bc11111dfb333b3bbbbbbbbfcccbb3bfccfb33bcd11dfb333bbfc11111111cfbbbbbbfcdd11111111111111111111111111dcffbbfcdddfb34666
34577775443bc1111dcb333bbbbbbbbbbbffcfbb3bbcdcbbbbfddddfb333bbbfc1111111cfbbbbffccdd11111ddd1111111111111111111cffffc111dfb33566
445777765543bd111dfb33bfccccfbbbbffccfbb33bcdccffffccddcfbbbbbbbfd111111dcfbbfcddddd1111dccccd11111111111111111cffcd11111cfb3356
555677665543bfd1dcfbbbcd1111cfffccccfbbb3bbfcccccccccddddcccccfffd1111111dcffc1111dd1111dcffcdd1111111111111111cffc11111dcfffb35
655544443443bfdddccffcd11111dccd11dfbbbbbbffffcd111d11111111111dd111111111dccd1111d11111dcfcccd1111111111dd1111dccd1111dcffcfb35
544333333333bcdddccccdddd111111111cb333bbcccffc11111111111111111111111111ddd1111111111111dcccddd1111111dccd1111dcd11111cfbbffb34
433333b3333bfd111ddddccffcdd11111dfb333bfd1dccc1111111111111111111111111ddd11111111111111dcccdd11111111dcd11111dcdd1111cbbbbbb33
3333bbb333bfd1111111dcfbbbfcd1111cb3333bc1111dd1111111111111111111111111dd111111111ddd111dcccd11111111111111111cffccdddcfbbbbb33
333bbb3333bd111111111dfbbbffcd111cbbbbbbc111111111111111111111111111111ddd111111111dcd1111ccd11111111111111111dfbbbbfcddcbbbbbb3
3bbbb333bbd1111111111ddccffffc111dcfffffc11111111111111111111111111111ddd1111111111cfcd111dcd11111111111111111fbbbbbbfcddcbbbfbb
3bbb333bfd11111111111dd11dfbbcd11ddcddccd11111111111111111111111111ddcccdd111dd111dcffc11dddd1111111111001111dfbfffbbfd11cfbfccb
3bb333bfd11111111111dcd11dfbbfcd1dddddddddd1111111111dccd111111111dcffffcccccccd11dcfffcddddd1111111111111111dccdddccd111cbbfccf
3bb333bc11111111111dfffcddfbbbfcdccccdd111dddd1111111dcfcd111111111cfffffbbbbbfcdddcfbbfcddccd111111111111111111111ddd11dfbbbccc
3bbb3bfd111111d1111dbbbfccbb3bbfccffffc111dddddd11111cffc11111111111dccffbb3bbbcd11dfbbfcddcfc111111111111111111111ddd11dfbbbffc
bffffcd111111111111dbbbbbbb333bbfcfbbbc111ddd1111111dfffc1111111111111dcfbbb3bbfd111cffcd1dcffd1111111111111111111dcfcccfbb33bbf
fd111111111111111111fbbbbb3333bbfcfbbbfd111d11111111cfffc11111111111111dcfbbbbbfd111dcd1111cbbc11111111111111111dcfbbffffb3333bf
d1111111111111111111cfbbb3333bbbfcfbbbfd111111111111dcffcd1111111111111dccccfb3bf1111111111fbbfc1111111111111111cfbbbfffbb3333bf
d1111111111111111111dfbbbb3bbffffffbbbfd111111111111ddcddddddd11111111dcfcddfb33bc11111111db33bfd11111111111111dcfbbfccfb33333fd
c1111111111111111111dfbbbbbfcddcffffbfc1111111111111111dddcccd1111111dcffcddcb33bfd1111111fb33bbfd1111111111111dccffcdcbb3333bc1
fd111111111111111111dfbbfcd111dfbbfffcd1111111111dd1111dcffffd111111dcfbbfddcfb3bfd111111dfbbbbbffccd11111111dccccccccfb3333bfd1
fcd11111111111111111cfbfc11111dbbbfcccd111111111dccddddcfbbbfc11111dcfbbbfcdccfffc1111111dcffbbffffccd111dddcfbbfcdccfb3333bfcdd
ddd1111111111111111dcfbfd11111cbbfd11dd111111111ddddcffbbbbbfc11111cfbbbbbfcccd111111111dcddccfffbfcd1111cfbbb3bfcdcfbb333bfcddc
111111111111111111ccfffd111111cffd1111d1111111111111cbb3bbbbfc11111cbb33bbfffc11111111dcfccddccfbbbc11111cbb333bbfccfbb33bfddddf
1111111ddd1111111dcffffd111111dd11111111111111111111cb333bbfcd1111dfb3333bbbbfd1111111cffffffffbbbbc111111fbb333bffffcffbfcdddcb
1111111dcdddddddccfffffc1111111111111111111111111111db33bbfcdd1111df3333bbffbfc111111dcfffbbbbbbbbfd111111cbbbb3bbbbfdddcccccffb
111111dccccccfffffffbbffcd11111111111111110011111111dfb3bffccd1111db3333bcdcffc11111ddddcfbbbbbbbfc1111111dffbbbb333bcd1dfbbbbbb
11111ddcccffbbbbbbbbbbbbbffcd111111111111100011111111cbbffccccdd1dcb333bc11dccd11111ddd11dcfbbbbfcd1111111dcffbb33333bcdcbb3333b
11111dccccfbbbbb333333bbbbbfcd11111111111100011111111dccccccfffcccfbbbbfd111d11111111d11111dcfffcd111dd111cffbb3335543bbbb33333b
11111dfffcffbbbb333333bbbbffcc11111111111111111111111ddddccfffbbbbbbbbfcd1dd11111111111111111dccccddcffccccbb33334676533333333bb
11111dfbffccffbb333333bfccccfcd1111111111111111111ddddddcfffbbbbbbbffccddcfcd11110011111111111dcffffbbfcddfb334556777643333333bf
01111dbbbfcccfbb33333bbfcddcccd1111111111111111111dddddcfbbbbbbbbbfcddddcbbbd111100011111111111dfbbbbbfd11cb345677777754444333bb
00111cbbbbfffbb33bbbbbbbfcdddd11111111111111111111111dcfbb3bbccfffcd111dfbbbc1111110111111111111cbbbfcd111cb345777777754333333bb
01111cbbbbbbbb333bffbbbbbfcd111111dccd111111ddd111111dcbb33bfdddccdd1ddcbb3bfd111111111111111111cfbfcd1111cb33467777775333bbbbbb
11111cb333bbb3333bfcfb33bfd111111dcfcd111111dcc111111cbbbbbfcddccccddcfbb333bfdddd11111111111111dcffcd111cbbb334677765433bffffff
11111cb333bbb3333bfcfbbbbf1111111cfbfdd1111dccc11111dbb33bbfcccfbfcccfbbb3333bbbbfd11111111111111dccccccfb33bb3356554333bfcccddd
11111cb333bbfb33bbccccffcd111111dfbbfcddddddccd111dcbb33bbbfffbbbbcdcfbbb334333bbfd11111111111111ddccffbb33333334443333bfcddd111
11111cb333bffbb3bbccdd1111111111cfbbbfccccddd1111dfbb33bbfffbbb3bfd11dffb3344433bc1111111111ddd1111dcfbb33554434443333bbcdddd11d
d11ddcbb3bbffbbbbbccd111111111dcffbbbbbbbfcd11111cbb33bbfcfbbb3bbc1111dcfb334433bd111111111dcccd1111dcfb33566555543333bbc111ddcf
dcccffbbbbfcfbbbbbfcd11111111dfbfffbbb333bc111111fb33bbfccfbbbbbfd11111ddfb3333bfd111111111dccd111111dcb346766555433333bfd1dccfb
dcfffffffccccfbbbfcccddd1111dcbbfccfb3333bc11111dfb333bbffbbbfccdd1111dddcfb333bfd11111111ddcd1111111dfb35676666533bb333bfccfbbb
dccffbbfcd1ddcccccccccccd11dcfffcccfb3343bf11111cb33333bbb33bfd1dddddcccccfb333bfd1111111dddd1111111dcb357765566533bb3333bbbbb33
11ddfbbfd111111111ddccccd11dcfffccfbb33433fd11dcfb334433bb33bc111dcfffffffbb3333bc111111dccdd11111dddf3477754456533bbb3333bb3333
1111cbbfd111111111dcccd1111dcbbffbbb333333bcddcfbb34443bbbbbfd111dcfffbbbbbb3333bc11111dcffcd111dccccf3577543345533bb33333bb3333
1111dbbbc111111111cfcd11111dfbbbbb33333333bfdccbb33333bfffbbc11111dcffbbbbbb3333bc1111dcfbbfcddcfbbfff3455333335543333333bbbb333
1111dbbbfd1111111cbbfd11111dfbbbbb3333bbbbbfddfb33333bfddcfcd111111dccfbbfffb333bcdddccfbbbbfccfb33bbb33433bb33555445433bbbbbbb3
d111cbbbfc111111dfbbc111111dfbffffbbbbbffbfcddfb3333bfdddccd1111111ddccffcdcb333bfcdcffbb33bbccfb333bbb333bbb33566666543bbbbffbb

