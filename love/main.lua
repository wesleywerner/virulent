-- virulent
-- by Wesley Werner Copyright 2020, 2021
--
-- ╒═══════════════════════════════════════════════════════════════════════════╕
-- │ LICENSE                                                                   │
-- ├───────────────────────────────────────────────────────────────────────────┤
-- │ This is a remake of the Atari game "Epidemic!" by Steven Faber (1982).    │
-- │ This code, the game art, the music and screen layouts are my own work.    │
-- │                                                                           │
-- ├───────────────────────────────────────────────────────────────────────────┘
-- │ This program is free software; you can redistribute it and/or modify
-- │ it under the terms of the GNU General Public License as published by
-- │ the Free Software Foundation; either version 2 of the License, or
-- │ (at your option) any later version.
-- │
-- │ This program is distributed in the hope that it will be useful,
-- │ but WITHOUT ANY WARRANTY; without even the implied warranty of
-- │ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- │ GNU General Public License for more details.
-- │
-- │ You should have received a copy of the GNU General Public License
-- │ along with this program; if not, write to the Free Software
-- │ Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
-- │ MA 02110-1301, USA.                                                     ┌─┐
-- ╘═════════════════════════════════════════════════════════════════════════╧═╛
--
-- ╒═══════════════════════════════════════════════════════════════════════════╕
-- │ PROGRAMMER'S PROLOGUE                                                     │
-- ├───────────────────────────────────────────────────────────────────────────┘
-- │ In July of 2020 I started work on the remake in Pico-8. It took
-- │ four weekends to complete. For those not familiar with Pico-8, it is a
-- │ fantasy console for making small games using Lua 5.2 as the interpreter.
-- │ Pico-8 has a built-in sprite and music editor, the latter akin to mod
-- │ trackers of ye olde days.
-- │
-- │ Pico games are shared as cartridges in the form of a PNG file, the code
-- │ is encoded within the image data, which is a screen grab of your game.
-- │
-- │ Pico has "harsh limitations" such as:
-- │
-- │   - 128x128 display resolution
-- │   - fixed 16 colour palette
-- │   - 6 buttons (arrows, X, Z)
-- │   - 128 8x8 sprites
-- │   - upper limit of 32k cartridge size (includes code, sprites and music)
-- │   - 8192 token limit; a token is a variable, operator, string or
-- │     a pair of brackets.
-- │
-- │ To meet those limitations I recycled variables and documented their usage,
-- │ game logic and lookup table definitions in a separate file.
-- │ Find it in the "doc" directory and online at
-- │ https://gist.github.com/wesleywerner/7eb03373f0d7b8c9125a4d557ee7e777
-- │
-- │ I updated the world data to reflect modern country names and statistics,
-- │ and added three new countries: Madagascar, Southeast Asia and South Africa.
-- │
-- │ The code in this file is the ported version of my Pico-8 implementation.
-- │ The goal was to change as little of the original as possible.
-- │ To achieve this I wrote a compatibility layer that provides all the
-- │ Pico API methods needed, and emulate them through the LÖVE API.
-- │ Technical notes about each implementation appear in the code.
-- │
-- │ The palette swapping routine was a nice challenge, and a rewarding one
-- │ to achieve when I saw the first colours swap on-screen.
-- │
-- │  Though one were to live a hundred years lazy and effortless, the
-- │  life of a single day is better if one makes a real effort.
-- │   -- Dhammapada verse 112
-- │                                                                         ┌─┐
-- ╘═════════════════════════════════════════════════════════════════════════╧═╛
--
-- ╒═══════════════════════════════════════════════════════════════════════════╕
-- │ PICO-8 COMPATIBILITY LAYER                                                │
-- ├───────────────────────────────────────────────────────────────────────────┘
-- │ Not all Pico methods are implemented, or fully implemented.
-- │ Only those used by Virulent are.
-- │ Each method is annotated where functionality is amiss, and remains
-- │ as an exercise for the reader.
-- │                                                                         ┌─┐
-- ╘═════════════════════════════════════════════════════════════════════════╧═╛

-- Pico's print() method displays text on-screen.
-- We store a reference to the Lua print method for debugging purposes.
print_console = print

-- Helper method sets the drawing colour from palette index c.
-- We +1 as Pico's palette is zero based, while our palette is 1 based.
-- Defaults to black if no c is given.
function setPalette(c)
 love.graphics.setColor(palette[math.floor(c or 0)+1])
end

-- Clear the screen with the given colour c.
function cls(c)
 rectfill(0,0,127,127,c)
end

-- Set draw clipping region.
-- Clears previously set region if parameters not given.
-- Note: clip_previous not implemented
function clip(x, y, w, h, clip_previous)
 if not x then
  love.graphics.setScissor()
 else
  love.graphics.setScissor(x, y, w, h)
 end
end

-- Draw rectangle with colour c.
function rect(x0, y0, x1, y1, c)
 setPalette(c)
 love.graphics.rectangle("line", x0, y0, x1-x0, y1-y0)
end

-- Fill rectangle with colour c.
function rectfill(x0, y0, x1, y1, c)
 setPalette(c)
 love.graphics.rectangle("fill", x0, y0, x1-x0+1, y1-y0+1)
end

-- Draw pixel of colour c.
function pset(x, y, c)
 setPalette(c)
 love.graphics.points(x, y)
end

-- Draw circle of radius r with colour c.
function circ(x, y, r, c)
 setPalette(c)
 love.graphics.circle("line", x, y, r)
end

-- Draw line with colour c.
-- Note: not implemented: if x1,y1 are not given the end of the last line is used
function line(x0, y0, x1, y1, c)
 setPalette(c)
 love.graphics.line(x0, y0, x1, y1)
end

-- Stretch rectangle from sprite sheet (sx, sy, sw, sh)
-- and draw in rectangle (dx, dy, dw, dh).
-- Source quads are cached as they are expensive.
-- Note: flip_x, flip_y not implemented.
function sspr(sx, sy, sw, sh, dx, dy, dw, dh, flip_x, flip_y)
 local key = sx .. sy .. sw .. sh
 if not sprite_stack[key] then
  local q = love.graphics.newQuad(sx, sy, sw, sh, 128, 128)
  sprite_stack[key] = q
 end
 love.graphics.setColor(1,1,1)
 love.graphics.draw(spritesheet, sprite_stack[key], dx, dy, 0, dw/sw, dh/sh)
end

-- Draw sprite n at position x, y.
-- Uses palette lookups to swap colours, as set in method pal().
-- Note: w, h, flip_x, flip_y not implemented.
function spr(n, x, y, w, h, flip_x, flip_y)

 -- Position in the sprite sheet
 local sprite_x = (n % 16) * 8
 local sprite_y = math.floor(n / 16) * 8

 -- Draw each 8x8 sprite pixel
 for yoffset = 0, 7 do
  for xoffset = 0, 7 do
   -- Lookup pixel colour index
   local index = spritesheet_map[sprite_x + xoffset][sprite_y + yoffset]
   -- Swap the palette
   if palette_swap then
    index = palette_swap[index] or index
   end
   -- Draw non-transparent colours
   if index > 1 then
    love.graphics.setColor(palette[index])
    love.graphics.points(x+xoffset+1, y+yoffset+1)
   end
  end
 end

end

-- Get colour index of sprite sheet pixel x, y.
function sget(x, y)
 return spritesheet_map[x][y]
end

-- Set drawing translation offset.
-- Empty parameters clear the effect.
function camera(x, y)
 if not x then
  love.graphics.origin()
 else
  love.graphics.translate(-x, -y)
 end
end

-- Print text of colour c on screen.
-- Note: variant signature (text, c) not implemented.
function print(text, x, y, c)
 setPalette(c)
 love.graphics.print(text, x, y)
end

-- Play music track n.
-- Negative one stops music.
-- Note: fade_len not implemented.
function music(n)
 if n == 0 then
  love.audio.play(game_music)
 elseif n == -1 then
  love.audio.stop()
 end
end

-- Play sound effect n.
-- Note: negative values of n, note offset and length are not implemented.
function sfx(n)
 if game_sfx[n] then
  game_sfx[n]:seek(0)
  love.audio.play(game_sfx[n])
 end
end

-- Test button was pressed in the current game loop.
-- Note: player (p) not implemented.
function btnp(i, p)
 return buttonstack[i]
end

-- Test button is held down.
-- Note: player (p) not implemented.
function btn(i, p)
 return love.keyboard.isDown(i)
end

-- Get random value.
-- * x not given: get number between 0..1
-- * x is number: get number n where 0 <= n < x
-- * x is table: get random item from x[1]..x[#x]
function rnd(x)
 if type(x) == "table" then
  return x[1+math.floor(love.math.random()*#x)]
 else
  return love.math.random() * (x or 1)
 end
end

-- Get lower integer.
function flr(x)
 return math.floor(x)
end

-- Get higher integer.
function ceil(x)
 return math.ceil(x)
end

-- Get positive integer.
function abs(x)
 return math.abs(x)
end

-- Get square root of x.
function sqrt(x)
 return math.sqrt(x)
end

-- Get inverse tangent of point.
function atan2(dx, dy)
 return math.atan2(dy, dx)
end

-- Get inverse cosine of x.
function cos(x)
 return math.cos(x)
end

-- Get inverse sine of x.
function sin(x)
 return math.sin(x)
end

-- Get minimum of x or y.
function min(x, y)
 return math.min(x, y)
end

-- Get maximum of x or y.
function max(x, y)
 return math.max(x, y)
end

-- Add v to table t at position i.
function add(t, v, i)
 if type(i) == "number" then
  table.insert(t, i, v)
 else
  table.insert(t, v)
 end
end

-- Remove first instance of v from table t.
function del(t, v)
 for i,b in ipairs(t) do
  if b==v then
   table.remove(t,i)
   return
  end
 end
end

-- Remove item at index i from table t.
function deli(t, i)
 table.remove(t, i)
end

-------------------------------------------------------------------[ Globals   ]
-- TODO refactor globals into tables of config, data

-- Limit updates to 30 frames per second, to match the original game's speed.
fpslimit = 1/30
fpscounter = 0

-- Simulate the button press function (btnp) by storing key presses.
-- These are cleared at the end of the update frame.
buttonstack = {}

-- All draw operations happen on a canvas.
-- This allows us to use the original game code, which targets a 128x128 screen.
-- We scale the canvas up as needed to fit the display.
-- A canvas allows us to emulate how Pico does not clear the display each draw.
screen_canvas = nil

-- The ratio to scale the canvas by.
DEFAULT_RENDER_SCALE = 6

-- The variable ratio, which is adjusted to fit the display on full screen toggle.
RENDER_SCALE = DEFAULT_RENDER_SCALE

-- Offset canvas to display for full screen centering
RENDER_LEFT = 0

-- Flag tracks full screen mode - toggle with Alt+Return
is_full_screen = false

-- Spritesheet storage
spritesheet = nil

-- Quad cache for calls to spr()
sprite_stack = {}

-- Music and Sounds
game_music = nil
game_sfx = nil

-- Track the quit game prompt
quit_game_prompt = false

----------------------------------------------------------[ Palette Swapping   ]
-- │ I achieved this by predefining the RGB components of the 16 colors used in
-- │ the sprite sheet, and generate a palette lookup table to easily find the
-- │ color index of a RGB combination. I then generate a map of the sprite sheet
-- │ which stores the color index for each pixel. While processing this pixel map
-- │ I sneakily update the alpha value in the sprite sheet image data so that
-- │ the `sspr` drawing function knows about transparency.
-- │ Finally in the sprite drawing function `spr` I perform a color conversion
-- │ if a palette swap table is set for the drawing operation.
-- │ You can find these functions, and some commented code, under the
-- │ "Palette Swapping" code.

function round(num, numDecimalPlaces)
 local mult = 10^(numDecimalPlaces or 0)
 return math.floor(num * mult + 0.5) / mult
end

-- Normalize palette values, build palette swap lookup tables.
function setup_palette()

 -- Normalize palette values to reduce error.
 -- index   r       g       b
 -- 1       0       0       0
 -- 2       0.11    0.17    0.33
 -- 3       0.49    0.15    0.33
 -- 4       0       0.53    0.32
 -- 5       0.67    0.32    0.21
 -- 6       0.37    0.34    0.31
 -- 7       0.76    0.76    0.78
 -- 8       1       0.95    0.91
 -- 9       1       0       0.3
 -- 10      1       0.64    0
 -- 11      1       0.93    0.15
 -- 12      0       0.89    0.21
 -- 13      0.16    0.68    1
 -- 14      0.51    0.46    0.61
 -- 15      1       0.47    0.66
 -- 16      1       0.8     0.67
 for k, v in ipairs(palette) do
  local r, g, b = unpack(v)
  r, g, b = round(r,2), round(g,2), round(b,2)
  palette[k] = { r, g, b }
 end

 -- Build a lookup table for fast color indexing.
 -- The sparse table structure maps to the red, green and blue color components.
 -- Finding the index of a color is thus as easy as palette_lookup[r][g][b]
 local palette_lookup = {}
 for k, v in ipairs(palette) do
  local r, g, b = unpack(v)
  palette_lookup[r] = palette_lookup[r] or {}
  palette_lookup[r][g] = palette_lookup[r][g] or {}
  palette_lookup[r][g][b] = k
 end

 -- Scan the spritesheet to build a map of each pixel and it's color index.
 -- This allows quick color lookup without repeat calls to getPixel().
 spritesheet_map = {}
 local width, height = spritesheetdata:getDimensions()
 for y = 0, height-1 do
  for x = 0, width-1 do

   -- Get the pixel components
   local r, g, b = spritesheetdata:getPixel(x, y)

   -- Round their values
   r, g, b = round(r,2), round(g,2), round(b,2)

   -- Create the X component map
   spritesheet_map[x] = spritesheet_map[x] or {}

   -- Look up this RGB palette color equivalent
   local cindex = palette_lookup[r][g][b]

   -- Store the index for this pixel
   spritesheet_map[x][y] = cindex

   -- Write this pixel in imagedata as transparent
   -- so that calls to sspr() works as expected.
   -- color 1 is black/transparent.
   if cindex == 1 then
    spritesheetdata:setPixel(x, y, 1, 1, 1, 0)
   end

  end
 end

end

-- Set palette swap values.
-- Compensate for Pico-8's 0 based color indexing.
function pal(a, b)
 -- Clear the palette swap table
 if not a or not b then
  palette_swap = nil
  return
 end
 -- Create a new palette swap table, preserving existing
 palette_swap = palette_swap or {}
 -- Store the palette swap color indexes
 -- Note: The Pico-8 pal() method can also receive a table of mappings.
 -- This is not implemented as this game did not use that method signature.
 -- This is left as an exercise for the reader.
 palette_swap[a+1] = b+1
end


----------------------------------------------------------[ Lookup Tables      ]
-->8

-- The color palette
palette = {
 {  0/255,   0/255,   0/255}, -- 0 Black
 { 29/255,  43/255,  83/255}, -- 1 Midnight Blue
 {126/255,  37/255,  83/255}, -- 2 Maroon
 {  0/255, 135/255,  81/255}, -- 3 Forest Green
 {171/255,  82/255,  54/255}, -- 4 Brown
 { 95/255,  87/255,  79/255}, -- 5 Midnight Gray
 {194/255, 195/255, 199/255}, -- 6 Silver
 {255/255, 241/255, 232/255}, -- 7 White
 {255/255,   0/255,  77/255}, -- 8 Red
 {255/255, 163/255,   0/255}, -- 9 Orangie
 {255/255, 236/255,  39/255}, -- 10 Yellow
 {  0/255, 228/255,  54/255}, -- 11 Bright Green
 { 41/255, 173/255, 255/255}, -- 12 Sky Blue
 {131/255, 118/255, 156/255}, -- 13 Mauve
 {255/255, 119/255, 168/255}, -- 14 Pink
 {255/255, 204/255, 170/255} -- 15 Beige
}

stats={
  {"CANADA",         37,   {2, 5}},
  {"UNITED STATES",  327,  {1, 3}},
  {"MEXICO",         126,  {2, 4}},
  {"LATIN AMERICA",  640,  {3}},
  {"GREENLAND",      65,   {1, 6}},
  {"SCANDINAVIA",    21,   {5,7,8,11}},
  {"WESTERN EUROPE", 196,  {6,8,9}},
  {"EASTERN EUROPE", 147,  {6,7,10,11}},
  {"AFRICA",         1274, {7,10,15,17}},
  {"MIDDLE EAST",    219,  {8,9,11,12}},
  {"RUSSIA",         146,  {6,8,10,12,13}},
  {"INDIAN SUBCON",  1816, {10,11,13}},
  {"EAST ASIA",      1678, {11,12,16}},
  {"AUSTRALIA",      25,   {16}},
  {"SOUTH AFRICA",   68,   {9,17}},
  {"SOUTHEAST ASIA", 668,  {13,14}},
  {"MADAGASCAR",     28,   {9,15}}
}

-- up  dn  lt  rt
keymap={
 {nil,  2, 11,  5}, --1  can
 {  1,  3, 11,  7}, --2  us
 {  2,  4, 13,  9}, --3  mex
 {  3,  0, 14, 15}, --4  sa
 {nil,  1,  1,  6}, --5  green
 {nil,  8,  5, 11}, --6  scan
 {  6,  9,  2,  8}, --7  w eu
 {  6,  9,  7, 10}, --8  e eu
 {  8, 15,  3, 10}, --9  af
 { 11,  9,  8, 12}, --10 mid e
 {nil, 10,  8,  2}, --11 rus
 { 11, 16, 10, 13}, --12 ind
 { 11, 16, 12,  2}, --13 e asia
 { 16,  0, 17,  4}, --14 au
 {  9,  0,  4, 17}, --15 za
 { 13, 14, 17,  3}, --16 se asia
 {  9, 15, 15, 14}, --17 mada
}

roids={}

-- [map sprites]
-- spr w  h  x   y
worldspr={
  {0,  4, 2, 2,  6  },
  {32, 4, 2, 1,  17 },
  {64, 2, 2, 2,  26 },
  {96, 3, 5, 16, 38 },
  {4,  3, 2, 34, 0  },
  {36, 2, 1, 58, 6  },
  {7,  2, 2, 51, 11 },
  {9,  2, 2, 62, 12 },
  {67, 4, 5, 47, 23 },
  {38, 2, 2, 71, 22 },
  {40, 8, 3, 67, 3  },
  {11, 2, 2, 85, 23 },
  {87, 4, 3, 88, 14 },
  {13, 3, 2,107, 49 },
  {66, 1, 1, 64, 55 },
  {91, 4, 3, 98, 33 },
  {82, 1, 1, 75, 50 }
}

remlut={
 {"n1", "interferon"},
 {"n2", "vaccine"},
 {"n3", "x-rays"},
 {"n4", "martial law"},
 {"n5", "gamma globulin"},
 {"n6", "back fire"},
 {"n7", "clean suits"},
 {"n8", "gene splice"},
 {"p1", "cloud seeding"},
 {"p2", "microwaves"},
 {"p3", "fire storms"},
 {"p4", "killer satellites"}
}

neff={
   {.25                },
   {.05,.3             },
   {.10,.25,.12        },
   {.12,.15,.28,.15    },
   {.28,.18,.05,.05    },
   {.16,.05,.03,.22,.30},
   {.05,.14,.30,.21,.08},
   {  0,  0,  0,.35,.38}
}

peff={
 {.8, .6},
 {.6, .7},
 {.4, .8},
 {.2, .9}
}

curelev={.8,.7,.6,.5}

gstats={
 {1,  250},
 {2, -550},
 {3,  -.5},
 {4,   25},
 {5,   75},
 {6, -100},
 {7,  -60},
 {8,   25},
 {9,  150},
 {10,   0},
 {11, 250},
 {12,   0}
}

---------------------------------------------------------[ Debugging Functions ]

function rotate_debug_logs()
 love.filesystem.createDirectory("logs")
 local logs = love.filesystem.getDirectoryItems("logs")
 for _, filename in ipairs(logs) do
  print_console("found log",filename)
  -- seconds since then
  print_console(os.difftime(os.time(), 1615640963))
 end
end

----------------------------------------------------------[ Love               ]
function love.load()

 -- Set image interpolation to aliased
 love.graphics.setDefaultFilter("nearest", "nearest")

 -- Draw lines aliased
 love.graphics.setLineStyle("rough")

 -- Set up the display
 WINDOW_W, WINDOW_H = 128*RENDER_SCALE, 128*RENDER_SCALE
 love.window.setMode(WINDOW_W, WINDOW_H)

 -- Load the font
 smallfont = love.graphics.newFont("PICO-8 mono.ttf", 4, "mono")
 largefont = love.graphics.newFont("PICO-8 mono.ttf", 20, "mono")
 love.graphics.setFont(smallfont)

 -- Load the spritesheet image data
 spritesheetdata = love.image.newImageData('spritesheet.png')

 -- Set up palette rotation tables. Alter spritesheet data to be transparent.
 setup_palette()

 -- Create the spritesheet image from altered image data
 spritesheet = love.graphics.newImage(spritesheetdata)

 -- Allocate the off-screen drawing canvas
 screen_canvas = love.graphics.newCanvas(128, 128)

 -- Load game music and sound effects
 game_music = love.audio.newSource("virulent.ogg", "stream")
 game_sfx = {}
 game_sfx[0] = love.audio.newSource("sfx0.ogg", "static")
 game_sfx[1] = love.audio.newSource("sfx1.ogg", "static")
 game_sfx[2] = love.audio.newSource("sfx2.ogg", "static")
 game_sfx[3] = love.audio.newSource("sfx3.ogg", "static")
 game_sfx[4] = love.audio.newSource("sfx4.ogg", "static")
 game_sfx[5] = love.audio.newSource("sfx5.ogg", "static")
 game_sfx[6] = love.audio.newSource("sfx6.ogg", "static")
 game_sfx[7] = love.audio.newSource("sfx7.ogg", "static")

 -- Enable key press repeating
 love.keyboard.setKeyRepeat(true)

 -- Print debug information
 printw(1)

 -- Reset game state
 reset_game()

 -- Switch to the intro screen
 switch(intro_screen)

 -- Debug: show menu
 --goto_menu()

end

function love.update(dt)

 -- Pause updates while prompting to quit
 if quit_game_prompt then
  return
 end

 -- Update limiter
 fpscounter = fpscounter + dt
 if fpscounter < fpslimit then
  return
 end

 -- Resume counting the amount over the limit
 fpscounter = fpslimit - fpscounter

 -- Update the game state
 if state then
  state.update()
 end

 -- Clear the button pressed stack
 buttonstack = {}
end

function love.draw()

  -- State drawing is paused while quit_game_prompt
 if not quit_game_prompt then

  -- Scope drawing to canvas
  love.graphics.setCanvas(screen_canvas)

  -- Draw the game state
  if state then
   state.draw()
  end

 end

 -- Render canvas to display
 love.graphics.setCanvas()
 love.graphics.setColor(1,1,1)
 love.graphics.setBlendMode("alpha", "premultiplied")
 love.graphics.draw(screen_canvas, RENDER_LEFT, 0, 0, RENDER_SCALE, RENDER_SCALE)
 love.graphics.setBlendMode("alpha", "alphamultiply")

 if quit_game_prompt then
  love.graphics.setColor(0,0,0,0.7)
  love.graphics.rectangle("fill",RENDER_LEFT,0,WINDOW_W, WINDOW_H)
  love.graphics.setColor(1,0,0)
  love.graphics.print("Quit? [Y/N]", RENDER_LEFT + (WINDOW_W/2)-100, (WINDOW_H/2))
 end

end

function love.keypressed(key, scancode, isrepeat)

 -- Handle quit keys
 if quit_game_prompt then
  if key == "y" then
   love.event.quit()
  elseif key == "n" or key == "escape" then
   quit_game_prompt = false
   love.graphics.setFont(smallfont)
  end
  -- Stop processing further keys
  return
 end

 -- capture key presses
 buttonstack[key] = true

 if key == "escape" then
  quit_game_prompt = true
  love.graphics.setFont(largefont)
 elseif key == "printscreen" then
  love.graphics.captureScreenshot('virulent_' .. os.time() .. '.png')
 elseif key == "return" then
  if love.keyboard.isDown("ralt") then
   toggle_fullscreen()
  end
 end
end

function toggle_fullscreen()
 is_full_screen = not is_full_screen
 if is_full_screen then
  -- Fetch flags of current display where our game is running
  local _, _, flags = love.window.getMode()
  -- Fetch the display size
  local disp_w, disp_h = love.window.getDesktopDimensions(flags.display)
  -- Estimate the nominal scale given the native display size
  RENDER_SCALE = math.floor(disp_h/128)
  -- Estimate the left offset for center translation
  RENDER_LEFT = (disp_w/2) - ((128*RENDER_SCALE)/2)
  WINDOW_W, WINDOW_H = 128*RENDER_SCALE, 128*RENDER_SCALE
  -- Make it so!
  love.window.setMode(WINDOW_W, WINDOW_H, {fullscreen=true})
  -- hide cursor
  love.mouse.setVisible(false)
 else
  -- Restore default render scale and window
  RENDER_LEFT = 0
  RENDER_SCALE = DEFAULT_RENDER_SCALE
  WINDOW_W, WINDOW_H = 128*RENDER_SCALE, 128*RENDER_SCALE
  love.window.setMode(WINDOW_W, WINDOW_H, {fullscreen=false})
  -- show cursor
  love.mouse.setVisible(true)
 end
 -- force redraw the current state
 if state then
  set_redraw()
 end
end

-----------------------------------------------------[ Virulent: State Control ]

function can_redraw()
 if redraw then
  redraw=false
  return true
 end
end

function set_redraw()
 redraw=true
end

function switch(s,arg)
 -- params
 --  :new state
 --  :opt arguments
 -- Since switch() is called from an update(), the canvas is not yet set.
 love.graphics.setCanvas(screen_canvas)
 s.init(arg)
 -- Pop it since the pump can't work with an active canvas.
 love.graphics.setCanvas()
 state=s
end

function goto_menu()
 switch(menu_screen)
end

function goto_command()
 switch(command_screen)
end

function goto_radar()
 switch(radar_screen,true)
end

function goto_region()
 switch(region_screen)
end

function goto_report()
 switch(report_screen)
end

function printh(text)
 love.filesystem.append("debug.txt", text.."\n")
end

function printw(m,a,b)
 if m==1 then
  printw("---> START GAME")
  for n=1,#stats do
   printw(n..") "..stats[n][1])
  end
 elseif m==2 then
  printw("  load_stats(): ci="..ci..
  " lev="..clev..
  " cpop="..cpop..
  " cdead="..cdead..
  " rem="..rem..
  " ceta="..ceta..
  " peta="..peta..
  " deta="..deta)
  printw("     npop="..tostring(npop)..
         " nlev="..tostring(nlev)..
         " npeta="..tostring(npeta)..
         " ndeta="..tostring(ndeta)..
         " nceta="..tostring(nceta)..
         " nrem="..tostring(nrem))
 elseif m==3 then
  printw("   infected "..a..(b and " spread from "..b or ""))
 elseif m==4 then
  printw(" set remedy "..a.." for ci "..b)
 elseif m==5 then
  printw("[turn no "..turnno.."]")
 elseif m==6 then
  printw(" turn for country "..ci)
 elseif m==7 then
  printw("  *level increased to "..clev)
 elseif m==8 then
  printw("  *decrease ceta to "..ceta)
 elseif m==9 then
  printw("  *remedy is n"..rem)
 elseif m==10 then
  printw("   -reduced level to "..clev)
  printw("   -remedy day="..a.." factor="..b)
 elseif m==11 then
  printw("  *remedy is p"..(rem-8).." chance="..a.." effect="..b)
 elseif m==12 then
  printw("  *apr success, level reduced to "..clev)
 elseif m==13 then
  printw("  *arp failed")
 elseif m==14 then
  printw("  *country is cured")
 elseif m==15 then
  printw("  *decrease peta to "..peta)
 elseif m==16 then
  printw("  *l4 risk lowered peta again to "..peta)
 elseif m==17 then
  printw("  *became pneumonic due to peta")
 elseif m==18 then
  printw("  *reduced peta to 0 because level reached 5")
 elseif m==19 then
  printw("  *decrease deta to "..deta)
 elseif m==20 then
  printw("  *destroyed via deta")
 elseif m==21 then
  printw("  *start deta counter")
 elseif m==22 then
  printw("  *decrease pop by factor "..a..", now at "..cpop)
 elseif m==23 then
  printw("  *destroyed via zero population")
 elseif m==24 then
  printw("[report phase]")
 elseif m==25 then
  printw(" missile hit % "..a)
 elseif m==26 then
  printw("[radar phase]")
 elseif m==27 then
  printw("[command phase]")
 elseif m==28 then
  printw("[region phase]")
 elseif m==29 then
  printw(" viewing country "..ci)
 elseif m==30 then
  printw("[apply remedy screen]")
 elseif m==31 then
  printw("[game completed]")
  printw(" skill: "..skill)
  printw(" gstat dump:")
  for i=1,#gstats do
   printw(" "..i.."="..gstats[i][1])
  end
 else
  printh(m, "debug")
 end
end

---------------------------------------------------------[ Virulent: World Map ]
-->8
-- world map

function draw_map(spal)
 -- params
 --  :opt palette swop table
 for i=1, #worldspr do
  draw_con(i,spal)
 end
end

function draw_con(i,spal,x,y)
 -- params
 --  :country index
 --  :opt palette swop table
 --  :opt x draw position
 --  :opt y draw position
 local dat=worldspr[i]

 if spal then
  for _, p in ipairs(spal) do
   pal(p[1],p[2])
  end
 else
  pal(1, get_level_color(stats[i][5],stats[i][7]))
  pal(7, 5)
 end

 -- position override
 x=x or dat[4]
 y=y or dat[5]

 for iy=0,dat[3]-1 do
  for ix=0,dat[2]-1 do
   spr(
    dat[1]+(iy*16)+ix,
    x+(ix*8),
    y+(iy*8))
  end
 end
 pal()
end

-- pixel perfect land hit
function landhit(x,y)
 -- params
 --  :x/y *screen* coordinates
 -- returns
 --  :country index of impact
 for i,dat in pairs(worldspr) do
  -- point in country bounds?
  local dx=dat[4] --draw offset
  local dw=dx+(dat[2]*8) --width
  local dy=dat[5] --draw offset
  local dh=dy+(dat[3]*8) --height
  if x>dx and x<dw and y>dy and y<dh then
   -- translate pos rel to origin
   local cx=x-dx
   local cy=y-dy
   -- pos in spritesheet
   cx=flr(cx+(dat[1]%16)*8)
   cy=flr(cy+flr(dat[1]/16)*8)
   -- test pixel color: a hit is any but transparent
   if sget(cx,cy)>1 then
    return i
   end
  end
 end
end

--------------------------------------------------------[ Virulent: Game Logic ]
-->8
-- game logic

function setstat(i,v)
 gstats[i][1]=v
end

function addstat(i)
 gstats[i][1]=gstats[i][1]+1
end

function getstatv(i)
 -- raw value
 return gstats[i][1]
end

function getstatm(i)
 -- value * multiplier
 if i==11 and getstatv(2)==#stats then
  -- turns remain &
  -- total destruction
  return 0
 end
 return ceil(gstats[i][1]*gstats[i][2])
end

function game_score()
 _l=0
 for i=1,#gstats do
  _l=_l+getstatm(i)
 end
 return _l
end

function load_stats(i)
 ci=i
 cstat=stats[i]

 cname,
 csouls,
 clinks,
 cpop,
 clev,
 peta,
 deta,
 rem,
 ceta,
 remhist,
 _,
 _,
 _,
 _,
 spreadfrom,
 npop,
 nlev,
 npeta,
 ndeta,
 nceta,
 nrem,
 aprsuc=unpack(cstat)

 cdead=csouls-cpop
 ispne=deta>0
 ccol=get_level_color(clev,deta)
 clevname=get_level_name(clev,deta)
 clevtxt=max(1,flr(clev))..":"..clevname
 cpoptxt=human_num(cpop,ci==5)
 cdeadtxt=human_num(cdead,ci==5)
 isntype=rem>0 and rem<9 and ceta>0
 isptype=rem>8 and ceta>0
 instasis=clev<2

 -- PostPicoFix: no infection level text
 if clev == 0 then
  clevtxt = "NONE"
 end

 if rem==0 then
  remcode=""
  remname=""
  remtxt="NONE"
 else
  remcode=remlut[rem][1]
  remname=remlut[rem][2]
  remtxt=remcode..":"..remname
 end

 petatxt=human_time(peta)
 detatxt=human_time(deta)
 cetatxt=human_time(ceta)
end

function reset_game()
 ci=9
 skill=skill or 1
 allot_actions()
 turnno=0
 roids={}
 -- country stats
 for _, con in ipairs(stats) do
  con[4]=con[2]
  con[5]=0
  con[6]=-1
  con[7]=-1
  con[8]=0
  con[9]=0
  for n=10,22 do
   con[n]=false
  end
  --con[15]=0
  con[18]=-1
  con[19]=-1
  con[20]=-1
 end
 -- starting infections
 _o=2+flr(rnd(2))
 if skill>=3 then
  _o=_o+flr(rnd(2))
 end
 _i=0
 while _i<_o do
  _c=1+flr(rnd(#stats))
  if stats[_c][5]==0 then
   infect(_c)
   _i=_i+1
  end
 end
 -- game stats
 for _, n in ipairs(gstats) do
  n[1]=0
 end
end

function infect(i,neig)
 -- params
 --  :country index
 --  :opt from neighbor
 local nlev=2+rnd(1)
 local npeta=4+flr(rnd(4))
 stats[i][5]=nlev
 stats[i][17]=nlev
 stats[i][6]=npeta
 stats[i][18]=npeta
 stats[i][15]=neig or false
 printw(3,i,neig)
 return nlev
end

function set_remedy(i,r)
 -- params
 --  :country index
 --  :remedy index
 stats[i][8]=r
 -- set ceta
 if r<9 then
  -- n-type
  stats[i][9]=#neff[r]
 else
  -- apr
  stats[i][9]=1
 end
 -- clear histogram
 stats[i][10]={}
 actno=actno-1
 addstat(8)
 printw(4,r,i)
end

function get_level_name(l,d)
 -- params
 --  :level of infection
 --  :deta
 -- notes
 --  p 0 while pneumonic (nil otherwise)
 if (d and d>0) then
  return "PNEUMONIC"
 elseif l==6 then
  return "DESTROYED"
 elseif l>=4 then
  return "CRITICAL"
 elseif l>=3 then
  return "SERIOUS"
 elseif l>=2 then
  return "MILD"
 elseif l>0 then
  return "IN STASIS"
 else
  return "CURED"
 end
end

function get_level_color(l,d)
 -- params
 --  :level of infection
 --  :deta
 if (d and d>0) then
  -- pneumonic
  return 8
 elseif l>=6 then
  -- desroyed
  return 0
 elseif l>=4 then
  -- critical
  return 2
 elseif l>=3 then
  -- serious
  return 14
 elseif l>=2 then
  -- mild
  return 10
 elseif l>0 then
  -- stasis
  return 11
 else
  -- clear
  return 3
 end
end

function max_turns(s)
 return 10+(s*5)
end

function end_condition()
 -- returns
 --  1:time out
 --  2:all cured
 --  3:all destroyed
 local curedc,popd=0,0
 for i,c in pairs(stats) do
  if c[5]==0 then
   curedc=curedc+1
  end
  if i~=5 then
   popd=popd+c[2]-c[4]
  end
 end
 gstats[3][1]=popd
 setstat(11,max_turns(skill)-turnno)
 local code=false
 if turnno==max_turns(skill) then
  code=1
 elseif curedc==#stats-gstats[2][1] then
  code=2
 elseif gstats[2][1]==#stats then
  code=3
 end
 setstat(12,code)
 return code
end

function allot_actions()
 actno=(skill>2) and 2 or 3
end

function end_turn()
 turnno=turnno+1
 printw(5)
 allot_actions()
 for i=1,#stats do
  cturn(i)
 end
end

function cturn(i)
 -- params
 --  :country index
 load_stats(i)
 -- not infected
 if clev==0 then return end
 -- already destroyed
 if clev==6 then return end
 printw(6)
 printw(2)

 -- increase level by 15%
 -- and up to 0.75%
 -- based on difficulty
 -- dif--------------incr
 --  1 = 0.001875 = .19%
 --  2 = 0.00375  = .38%
 --  3 = 0.005625 = .56%
 --  4 = 0.0075   = .75%
 if not instasis then
  clev=min(5,clev*1.15+(0.001875*skill))
  printw(7)
 end

 -- reduce remedy conclusion
 if ceta>0 then
  ceta=ceta-1
  printw(8)
 end

 -- apply remedy
 if isntype then
  printw(9)
  -- remedy factor for ceta
  local rday=#neff[rem]-ceta
  local fact=neff[rem][rday] or 0
  -- vary the amount -15% to 15%
  fact=fact+rnd({-1,1})*rnd(0.15)
  -- clamp to 40%
  fact=max(0,min(0.4,fact))
  -- 30% chance of no effect
  if instasis and rnd()<0.3 then
   fact=0
  end
  -- apply factor
  clev=clev-(clev*fact)
  -- record factor history
  add(remhist,fact)
  printw(10,rday,fact)
 elseif isptype then
  local pchance=peff[rem-8][1]
  local peffect=peff[rem-8][2]
  printw(11,pchance,peffect)
  if rnd()<pchance then
   -- success
   clev=clev-(clev*peffect)
   aprsuc=true
   addstat(9)
   printw(12)
  else
   -- failure
   aprsuc=false
   addstat(10)
   printw(13)
  end
 else
  -- not ntype nor ptype. clear:
  rem=0
  -- histogram
  stats[i][10]=false
  aprsuc=0
 end

 -- re-evaluate
 instasis=clev<2

 -- is cured?
 if clev<curelev[skill] then
  clev=0
  rem=0
  ceta=0
  peta=-1
  deta=-1
  printw(14)
  addstat(1)
 end

 -- clear countdowns
 if instasis then
  peta=-1
  deta=-1
 end

 -- becomes pneumonic via:
 --  1) peta counter reaches 0
 --  2) level reaches 5
 if peta>0 then
  peta=peta-1
  printw(15)
  -- 4+ carries a risk
  -- of expiditing pne
  if clev>4 and rnd(1)<0.05 then
   peta=max(0,peta-1)
   printw(16)
  end
  if peta==0 then
   -- became pneumonic
   clev=5
   rem=0
   ceta=0
   printw(17)
  end
 end

 -- reached level 5
 if clev==5 and peta>0 then
  peta=0
  printw(18)
 end

 -- test destruction
 if deta>0 then
  deta=deta-1
  printw(19)
  if deta==0 then
   clev=6
   printw(20)
   addstat(2)
  end
 end

 -- start deta counter
 if peta==0 then
  peta=-1
  deta=5
  printw(21)
 end

 -- population loss %
 local loss=clev*0.0314
 -- stasis locked at 3%
 if instasis then
  loss=.0314
 end
 cpop=flr(cpop-(cpop*loss))
 printw(22,loss)
 if (cpop==0 and clev<6) then
  -- destroyed
  clev=6
  printw(23)
  addstat(2)
 end

 -- clear flags on destroy
 if clev==6 then
  peta=-1
  deta=-1
  ceta=-1
  rem=0
  cpop=0
 end

 -- spread infection
 if turnno>4 and clev>3 and rnd()<0.20 then
  local ni=clinks[1+flr(rnd()*#clinks)]
  if stats[ni][5]==0 then
   infect(ni,i)
   addstat(7)
  end
 end

 -- persist new values
 cstat[16]=cpop
 cstat[17]=clev
 cstat[18]=peta
 cstat[19]=deta
 cstat[20]=ceta
 cstat[21]=rem
 cstat[22]=aprsuc

end

------------------------------------------------------[ Virulent: Intro State ]
-->8
-- intro screen
intro_screen={}

local function exit_screen()
 music(-1,500)
 clip()
 camera()
 goto_menu()
end

local function curtains(d,t,l,bt)
 if not t then
  print("x:skip",1,122,13)
  if d.f then
   print("x:skip",1,122,12)
  end
  -- disabled curtain clipping, does not work in the intro
  --clip(0,64-d.z,128,d.z*2)
  --rectfill(0,0,127,127,0)
 elseif t==0 then
  d.z=0
 elseif bt(1,70) then
  -- open
  d.z=l(0,32)
  -- flash
  d.f=t>40 and flr(t)%2==0
 elseif bt(70,72) then
  -- close
  d.z=l(32,0)
 elseif bt(72,73) then
  exit_screen()
 end
end

local function stars(d,t,l,bt)
 if not t then
  camera(0,d.cy)
  for _, r in ipairs(d.s) do
   pset(r[1],r[2],r[3])
  end
  camera()
 elseif t==0 then
  d.cy,d.s=0,{}
  local heat={1,5,7}
  for i=1,30 do
   add(d.s,{
    flr(rnd()*127),
    flr(32+rnd()*64),
    heat[1+flr(rnd()*#heat)]})
 end
 elseif bt(1,20) then
  -- move stars
  for _, r in ipairs(d.s) do
   -- print(r[1], r[3])
   r[1]=(r[1]+r[3]*0.05)%127
  end
 elseif bt(20,25) then
  -- exit screen
  d.cy=l(0,-128,2)
 elseif bt(30,34) then
  --reshow
  d.cy=l(128,0,4)
 elseif bt(34,80) then
  for _, r in ipairs(d.s) do
   r[1]=(r[1]+r[3]*0.05)%127
  end
 end
end

local function earth(d,t,l,bt)
 if not t then
  --earth
  sspr(96,64,16,16,64,d.y,d.s,d.s)
 elseif t==0 then
  d.y,d.s=64,0
 elseif bt(6,20) then
  -- scale
  d.s=l(0,16,4)
 elseif bt(20,22) then
  -- exit screen
  d.y=l(64,128,2)
 end
end

local function asteroid(d,t,l,bt)
 if not t then
  sspr(120,40,8,8,d.x,d.y,d.s,d.s)
  if d.i>0 then
   circ(d.x,d.y,d.i,5)
  end
 elseif t==0 then
  d.x,d.y=128,128
  d.s=64
  d.i=0
 elseif bt(14,17) then
  d.x=l(128,64,3)
  d.y=l(96,48,3)
 elseif bt(17,19) then
  d.x=l(64,72,2)
  d.y=l(48,71,2)
  d.s=l(64,0,2)
 elseif bt(19,20) then
  d.i=l(0,10)
 end
end

local function worldmap(d,t,l,bt)
 if not t then
  camera(0,d.y)
  draw_map()--{{1,3}})
  camera()
 elseif t==0 then
  d.y=64
  --clear infections
  for i=1,#stats do
   stats[i][5]=0
  end
 elseif bt(20,24) then
  -- enter
  d.y=l(64,-32,2)
 elseif bt(24,30) then
  -- fake infect
  local f=l(1,6,3)
  for i=1,#stats do
   stats[1+flr(t*10)%#stats][5]=f
  end
 elseif bt(30,40) then
  -- exit
  d.y=l(-32,-128,3)
 end
end

function intro_screen.init()
 add(cmk,curtains)
 add(cmk,stars)
 add(cmk,earth)
 add(cmk,asteroid)
 add(cmk,worldmap)
 cmk:init()
 music(0,2000)
end

function intro_screen.draw()
 cls(0)
 cmk:draw()
end

function intro_screen.update()
 cmk:update()
 if btnp("x") then
  exit_screen()
 end
end

---------------------------------------------------[ Virulent: Game Menu State ]
-->8
-- menu screen
menu_screen={}

local function goto_help()
 switch(help_screen,menu_screen)
end

local function start_game()
 skill=_i
 reset_game()
 goto_report()
end

function menu_screen.init()
 -- _i:toolbar index
 toolbar={
  {224,"easy game",start_game},
  {225,"medium game",start_game},
  {226,"hard game",start_game},
  {227,"difficult game",start_game},
  {245,"help",goto_help}}
 lock_tb()
 -- last selected
 _p=0
 -- key hint timer
 _t=90
 -- rock position
 --_x,_y,_l=0,64,0
end

function menu_screen.draw()
 if can_redraw() then
  cls(1)
  print("VIRULENT",50,1,0)
  print("VIRULENT",51,2,15)
  line(0,8,128,8,13)
  camera(0,-20)
  draw_map({{7,5},{1,3}})
  camera()
  if _i<5 then
   rectfill(0,113,128,120,13)
   print(max_turns(_i).." turns",2,114,15)
   print(((_i>2) and 2 or 3).." actions",90,114,15)
  end
 end
 _i=draw_tb()
 if _p~=_i then
  set_redraw()
  _p=_i
 end
 -- keys hint
 if _t>0 then
  print("arrows + x",45,90,5+(love.timer.getTime()%2))
 end
 -- floating rock
 --pal(1,5)
 --spr(95,_x,_y)
end

function menu_screen.update()
 update_tb()
 dec_timer()
end

---------------------------------------[ Virulent: Turn / Country Report State ]
-->8
-- report screen
report_screen = {}

local function prepare_report()
 -- report items={ci, level}
 _p = {}
 for i,v in pairs(stats) do
  -- has infection &
  -- not destroyed
  if v[5]>0 and v[5]<6 then
   add(_p,{i,v[5],v[7],v[6]})
  end
 end
 -- order priority
 --  1) deta ASC
 --  2) peta ASC
 --  1) level DESC
 insort(_p,function(a,b)
   -- deta
   local adeta,bdeta=a[3],b[3]
   if adeta>=0 and bdeta==-1 then
    return true
   elseif adeta==-1 and bdeta>=0 then
    return false
   elseif adeta>=0 and bdeta>=0 then
    return adeta<bdeta
   end
   -- peta
   local apeta,bpeta=a[4],b[4]
   if apeta>=0 and bpeta==-1 then
    return true
   elseif apeta==-1 and bpeta>=0 then
    return false
   elseif apeta>=0 and bpeta>=0 then
    return apeta<bpeta
   end
   -- level
   return a[2]>b[2]
  end)
end

local function reposition()
 if _x==0 then
  _x=65
 else
  _x=0
  _y=_y+25
 end
end

local function compare_stats()
 -- update country stats
 cstat[4]=npop or cpop
 cstat[5]=nlev or clev
 cstat[6]=npeta or peta
 cstat[7]=ndeta or deta
 cstat[8]=nrem or rem
 cstat[9]=nceta or ceta

 -- clear spread from flag
 cstat[15]=false
 --cstat[22]=0

 -- infection spread
 if type(spreadfrom)=="number" then
  tickmsg("infection has spread")
  tickmsg("from "..stats[spreadfrom][1])
  tickmsg("to "..cname)
 end

 -- apr outcome
 if rem>8 then
  if aprsuc==true then
   tickmsg("APR success in "..cname)
  elseif aprsuc==false then
   tickmsg("APR failed in "..cname)
  end
 end

 -- level change
 local new_levname=get_level_name(nlev,ndeta)
 if new_levname~=clevname then
  tickmsg(cname.." is now "..new_levname)
  -- inc timer
  _t=_t+20
 end

 clev=flr(clev)
 nlev=flr(nlev)
 if nlev>clev then
  if nlev==6 then
   -- destroyed
   sfx(2)
  else
   -- increase
   sfx(0)
  end
 elseif nlev<clev then
  -- decrease
  sfx(1)
 end
end

local function draw_card()
 -- params
 --  :country index
 rectfill(_x,_y,_x+62,_y+23,15)
 rectfill(_x,_y,_x+62,_y+11,12)
 print(cname,_x+1,_y+1,7)
 -- destroyed color
 if clev==6 then ccol=5 end
 -- cured
 if clev==0 then
  print("cured",_x+1,_y+6,ccol)
 else
  print(clevname,_x+1,_y+6,ccol)
  -- display lowest value of 1
  print("L"..max(1,flr(clev)),_x+55,_y+6,ccol)
 end
 print("pop",_x+1,_y+12,13)
 print(flr((cpop/csouls)*100).."%",_x+1,_y+18,13)
 -- destroyed...
 if clev==6 then return end
 print("remedy",_x+18,_y+12,5)
 if rem>0 then
  print(remcode,_x+18,_y+18,5)
  if ceta==0 then
   print("end",_x+30,_y+18,5)
  else
   print(" T-"..ceta,_x+24,_y+18,5)
  end
 end
 if deta>=0 then
  print("deta",_x+47,_y+12,8)
  print(deta,_x+47,_y+18,8)
 elseif peta>=0 then
  print("peta",_x+47,_y+12,13)
  print(peta,_x+47,_y+18,13)
 end
end

local function draw_report_items()
 if #_p==0 then return end
 _x=0
 _y=0
 for n=1,_i do
  ci=_p[n][1]
  load_stats(ci)
  draw_card()
  reposition()
 end
end

local function next_item()
 if _o==1 then
  -- draw up to item _i
  _i=_i+1
  _o=2
 else
  -- update item _i stats
  _o=1
  ci=_p[_i][1]
  load_stats(ci)
  printw(2)
  compare_stats()
  done=_i==#_p
 end
  -- rewind timer
 _t=_t+20
end

function report_screen.init()
 end_turn()
 printw(24)
 done=false
 set_redraw()
 -- camera scroll
 _c=-10
 -- _o, mode
 --  1:draw current stats
 --  2:draw new stats
 _o=1
 -- count items drawn
 _i=0
 _t=30
 clear_ticker()
 prepare_report()
end

function report_screen.draw()
 if can_redraw() then
  -- print title
  cls(1)
  print_title("COUNTRY REPORT",12,"WEEK "..turnno)
  -- clip scrollable content
  clip(0,10,128,110)
  camera(0,_c)
  rectfill(0,0,127,256,1)
  draw_report_items()
  camera()
  clip()
 end
 draw_ticker()
 if done then
  print("press x",1,116,13)
 end
end

function report_screen.update()
 update_ticker()
 if (not done and not dec_timer()) then
  next_item()
  set_redraw()
  if _i<3 then
   --reset scroll
   _c=-10
  end
 end
 if btnp("x") then
  -- skip delay
  _t=0
  if done then
   if end_condition() then
    printw(31)
    switch(end_screen)
   else
    switch(radar_screen)
   end
  end
 elseif btn("up") then
  _c=max(-10,_c-2)
  set_redraw()
 elseif btn("down") then
  _c=_c+2
  set_redraw()
 end
end

-----------------------------[ Virulent: Radar Tracking / Missile Launch State ]
-->8
-- radar screen
radar_screen = {}

function rock_impact(x,y)
 -- params
 --  :x/y impact point
 sfx(2)
 tickmsg("asteroid impact detected")
 _c=landhit(x,y)
 if not _c then
  tickmsg("in the ocean")
  return
 end
 load_stats(_c)
 tickmsg("in "..cname)
 if clev==0 then
  infect(_c)
  tickmsg("and is now infected")
  gstats[6][1]=gstats[6][1]+1
 elseif clev==6 then
  tickmsg("but there is nobody left")
 else
  tickmsg("but is already infected")
 end
end

local function missile_hit()
 local hs=0.3
 --+20% for good health of
 -- us, russia & west europe
 hs=hs+((stats[2][5]<3) and 0.2 or 0)
 hs=hs+((stats[7][5]<3) and 0.2 or 0)
 hs=hs+((stats[11][5]<3) and 0.2 or 0)
 printw(25,hs)
 if rnd()<hs then
  tickmsg("missile hit success!")
  return true
 else
  if hs>=0.9 then
   tickmsg("tragically")
   tickmsg("the missile missed")
  elseif hs>=0.7 then
   tickmsg("tragically")
   tickmsg("missile guidance failed")
  elseif hs>=0.5 then
   tickmsg("ill missile ops staff")
   tickmsg("failed to launch")
  else
   tickmsg("sick missile ops staff")
   tickmsg("failed to launch")
  end
 end
end

local function move_rocks()
 if done then return end

 -- next rock
 if not dec_p() then
  _i=_i+1
  _p=20
  _t=20
  return
 end

 -- no moves left
 if _i>#roids then
  done=true
  return
 end

 -- move
 _o=roids[_i]
 _o[1]=2*cos(_o[3])+_o[1]
 _o[2]=2*sin(_o[3])+_o[2]
 sfx(3)

 -- reduce altitude
 _o[4]=_o[4]-2

 -- 0 altitude
 if _o[4]<=0 then
  del(roids,_o)
  -- targeted
  if _o[5] and missile_hit() then
   sfx(2)
   gstats[5][1]=gstats[5][1]+1
  else
   rock_impact(_o[1],_o[2])
  end
  -- clear step counter
  _p=0
  -- next rock
  _i=_i-1
  -- rewind timer
  _t=60
 end

end

local function check_orbit()

 -- max targets
 local maxt=skill*2
 if #roids>=maxt then return end

 -- for chance
 if #roids>0 and rnd(1)>0.5 then return end

 -- x or y
 _x=rnd()<0.5 and flr(rnd(120)) or 0
 _y=_x==0 and flr(rnd(100)) or 0

 -- flip axis
 _x=_x==0 and rnd()<.5 and 120 or _x
 _y=_y==0 and rnd()<.5 and 100 or _y

 -- distance table
 local lands={}
 for i,l in pairs(worldspr) do
  -- dist to center
  local cx=l[4]+(l[2]*8)/2
  local cy=l[5]+(l[3]*8)/2
  dist=sqrt((abs(cx-_x)^2)
           +(abs(cy-_y)^2))
  -- keep long range
  if dist>70 then
   add(lands,{i,dist,cx,cy,0})
  end
 end

 -- pick target
 _c=lands[flr(rnd(#lands)+1)]
 if _c then
  local alt=flr(_c[2]*max(0.75,rnd(1)))
  local ang=atan2(_c[3]-_x,_c[4]-_y)
  add(roids,{_x,_y,ang,alt})
 end
end

local function launch()
 if _i==0 or roids[_i][5] or actno==0 then
  -- no target
  -- already targeted
  -- no actions
  sfx(6)
 else
  sfx(1)
  roids[_i][5]=true
  actno=actno-1
  gstats[4][1]=gstats[4][1]+1
 end
end

function radar_screen.init(lm)
 -- params
 --  :launch missile mode
 -- _o used in move_rocks()
 printw(26)
 -- launch mode
 _l=lm
 if _l then
  -- selected rock
  _i=#roids
  -- pick timer
  _t=165
  toolbar={
   {242,"close",goto_command},
   {243,"z:launch missile ",launch}}
  done=true
  lock_tb()
 else
  done=false
  -- rock index
  _i=0
  -- stepped movement
  _p=0
  -- timer
  _t=15
  clear_ticker()
  check_orbit()
  check_orbit()
 end
end

function radar_screen.draw()
 cls(1)
 print_title("RADAR TRACKING",11,"WEEK "..turnno)
 if _l then
  draw_tb(11)
  if turnno<3 and _t>0 then
   print("up/dn",60,114,5+(love.timer.getTime()%2))
  end
 else
  if done then
   print("press x",1,116,11)
  end
  draw_ticker()
 end

 camera(0,-20)
 draw_map({{1,0},{7,11}})
 pal()

 for i,r in pairs(roids) do
  spr(95,r[1]-3,r[2]-3)
  if _l then
   -- mark selected
   if _i==i then
    if r[5] then
     pal(10,8)
     print("<target locked>",1,-10,8)
    end
    spr(127,r[1]-3,r[2]-3)
    pal()
   end
  else
   -- mark tracked
   if r[5] then
    pal(10,8)
    spr(127,r[1]-3,r[2]-3)
    pal()
   end
   if i==_i then
    print("altitude: "..r[4],42,90,11)
   end
  end
 end
 camera()
 pal()
end

function radar_screen.update()
 if _l then
  update_tb()
  dec_timer()
  _i=rot_sel(_i,#roids)
  if btnp("z") then
   launch()
  end
 else
  update_ticker()
  if not dec_timer() then
   _t=3
   move_rocks()
  end
  if done and btnp("x") then
   goto_command()
  elseif btnp("x") then
   -- skip delay
   _t=0
  end
 end
end

---------------------------------------------[ Virulent: Command Station State ]
-->8
-- command screen
command_screen={}

local function goto_help()
 switch(help_screen,command_screen)
end

local function navto(b)
 if b==0 then
  -- default
  ci=9
 else
  local i=keymap[ci][b]
  if i==0 then
   focus_tb()
  elseif i then
   ci=i
   sfx(4)
  end
 end
 load_stats(ci)
 set_redraw()
end

local function check_done()
 done=true
 for _, c in ipairs(stats) do
  if c[5]>0 and c[5]<6 and c[9]<1 then
   done=false
  end
 end
 for _, r in ipairs(roids) do
  if not r[5] then
   done=false
  end
 end
end

function command_screen.init()
 printw(27)
 toolbar={
  {241,"end turn",goto_report},
  {245,"help",goto_help}}
 if actno>0 then
  add(toolbar,{243,"launch missile",goto_radar},1)
 end
 navto()
 unlock_tb()
 check_done()
end

function command_screen.draw()
 if actno==0 then
  return
 end
 if can_redraw() then
  cls(1)
  print_title("COMMAND STATION",12,"WEEK "..turnno)
  rectfill(0,8,128,14,2)
  print(cname,4,9,1)
  camera(0,-20)
  draw_map()
  draw_con(ci,{{1,ccol},{7,7}})
  camera()
  pal()
  rectfill(95,101,128,128,1)
  draw_histogram(96,102,true)
 end
 draw_tb()
 if done then
  print("z:end turn",43,110,12)
 end
end

function command_screen.update()
 if update_tb() then
  --nop
 elseif btnp("left") then
  navto(3)
 elseif btnp("right") then
  navto(4)
 elseif btnp("up") then
  navto(1)
 elseif btnp("down") then
  navto(2)
 elseif btnp("x") then
  goto_region()
 elseif actno==0 or (done and btnp("z")) then
  goto_report()
 end
end

-----------------------------------------------[ Virulent: Regional Info State ]
-->8
-- regional screen
region_screen={}

local function needs_remedy()
 -- 1) no active remedy
 -- 2) active remedy concluded
 return (clev>0 and clev<6)
        and (rem==0 or
            (rem>0 and ceta==0))
end

function draw_histogram(x,y,mini)
 if rem==0 or rem>8 then return end
 local cw=15 -- cell width
 local h=30  -- total height
 local gc=13 -- grid color
 local ec=2  -- estimated effectiveness color
 local ac=9  -- actual effectiveness color

 if mini then
  cw=6
  h=16
 end

 remedy_chart(rem,x,y,cw,h)
 if remhist then
  -- first point at origin
  local px,py=x,y+h
  -- plot
  for d=1,#remhist do
   -- effective %
   local ep=remhist[d] or 0
   -- scale ep to the 40% box
   ep=ep*2.4
   -- cell x
   local cx=x+(d*cw)
   -- cell y relative to eff
   local cy=y+h-h*ep
   -- draw from previous point
   line(px,py,cx,cy,ac)
   -- store this point
   px=cx
   py=cy
  end
 end
 if not mini then
  print("estimated",x,y-6,ec)
  print("vs",x+41,y-6,gc)
  print("actual",x+53,y-6,ac)
 end
end

local function printline(k,v)
 print(k,1,_i,7)
 print(v,127-(#v*4),_i,7)
 line(1,_i+6,126,_i+6,6)
 _i=_i+8
end

local function print_stats()
 pal()
 clip(0,0,_c,127)
 _i=20
 printline("DEATHS",cdeadtxt)
 if clev==6 then
  clip()
  return
 end
 printline("POPULATION",cpoptxt)
 printline("INFECTION LEVEL",clevtxt)

 if deta>0 then
  printline("DESTRUCTION ETA",detatxt)
 elseif peta>0 then
  printline("PNEUMONIC ETA",petatxt)
 end

 if rem>0 and ceta==0 then
  printline("CONCLUDED",remtxt)
 else
  printline("REMEDY",remtxt)
 end
 if ceta>0 then
  printline("REMEDY CONCLUDES IN",cetatxt)
 end

 draw_histogram(26,76)

 clip()
end

local function calc_land_anim(no_anim)
 local sd=worldspr[ci]
 _x=sd[4]
 _y=sd[5]+20
 _o=64-(sd[2]*4) -- top middle
 _p=10
 -- clear flags
 _c=0
 _l=0
 if no_anim then
  _x,_y=_o,_p
  _l=0.9
 end
end

local function goto_remedy()
 switch(remedy_screen)
end

function region_screen.init(no_anim)
 printw(28)
 sfx(5)
 cls(0)
 load_stats(ci)
 calc_land_anim(no_anim)
 toolbar={{242,"close",goto_command}}
 if needs_remedy() and actno>0 then
  add(toolbar,{244,"z:apply remedy ",goto_remedy})
 end
 printw(29)
 print_title(cname,9)
 lock_tb()
end

function region_screen.draw()
 -- Port note: the original code tied shift_lerp() and shift_clip() to
 -- this draw method. Löve's high frame rate caused these effects to
 -- happen much too quickly. Moving these calls to the update method
 -- and testing _l and _c in this draw fixed the problem.
 if _l<1 then
  rectfill(0,10,128,110,0)
  draw_con(ci,nil,
    lerp(_x,_o,_l),
    lerp(_y,_p,_l))
 elseif _c<127 then
  print_stats()
 elseif can_redraw() then
  -- Port addition: redraw on toggle full-screen
  calc_land_anim(true)
  print_title(cname,9)
 end
 draw_tb()
end

function region_screen.update()
 if not shift_lerp() then
  shift_clip()
 end
 update_tb()
 if btnp("z") and needs_remedy() then
  goto_remedy()
 end
end

--------------------------------------------[ Virulent: Remedy Selection State ]
-->8
-- remedy screen
remedy_screen={}

local function is_avail(i)
 if ispne then
  return true
 else
  -- no time limit (stasis)
  if peta==-1 then return true end
  -- specified or selected
  i=i or _i
  -- only if dur <= eta
  return #neff[i]<=peta
 end
end

local function list_ntype()
 _y=16
 print(" TYPE DUR NAME",10,14,6)
 print(" ---- --- ----",10,18,6)
 for i=1,8 do
  if is_avail(i) then
   _p=(_i==i) and 11 or 7
  else
   _p=(_i==i) and 9 or 5
  end
  _y=_y+6
  print(remlut[i][1],18,_y,_p)
  print(#neff[i],38,_y,_p)
  print(remlut[i][2],50,_y,_p)
 end
 rectfill(0,80,127,108,0)
 remedy_chart(_i,40,80,8,16)
 if _l==3 then
  print("% reduction per week",23,104,14)
  print("1 2 3 4 5",43,98,9)
  print("0%",83,92,9)
  print("40%",83,80,9)
 elseif not is_avail() then
  print("N/A: DUR>ETA",36,104,14)
 end
end

local function list_ptype()
 _y=16
 print("TYPE S% R% NAME",4,14,6)
 print("---- -- -- ----",4,18,6)
 for i=1,4 do
  _p=(_i==i) and 11 or 7
  _y=_y+6
  local succ=ceil(peff[i][1]*100)
  local redu=ceil(peff[i][2]*100)
  print(remlut[i+8][1],8,_y,_p)
  print(succ,24,_y,_p)
  print(redu,36,_y,_p)
  print(remlut[i+8][2],48,_y,_p)
 end
end

local function close_screen()
 switch(region_screen,true)
end

local function apply_remedy()
 if is_avail() then
  sfx(1)
  if ispne then
   set_remedy(ci,_i+8)
  else
   set_remedy(ci,_i)
  end
  close_screen()
 else
  sfx(6)
 end
end

local function print_eta()
 if deta>0 then
  rectfill(0,112,128,118,2)
  print("destruction in",1,113,8)
  print(detatxt,100,113,8)
 elseif peta>0 then
  rectfill(0,112,128,118,12)
  print("pneumonic in",1,113,7)
  print(petatxt,100,113,7)
 end
end

function remedy_screen.init()
 printw(30)
 cls(0)
 print_title(cname,9)
 -- _c used in list_ntype/list_ptype
 -- _l toggles chart labels
 -- selection index
 _i=1
 -- max selection
 _o=ispne and 4 or 8
 -- clip
 _c=0
 toolbar={
  {242,"close",close_screen},
  {246,"z:apply ",apply_remedy}}
 if not ispne then
  add(toolbar,{248,"show labels",nil})
 end
 lock_tb()
end

function remedy_screen.update()
 update_tb()
 if btnp("up") or btnp("down") then
  _i=rot_sel(_i,_o)
  set_redraw()
 elseif btnp("left") or btnp("right") then
  set_redraw()
 elseif btnp("z") then
  apply_remedy()
 end
end

function remedy_screen.draw()
 _l=draw_tb()
 if shift_clip() or can_redraw() then
  clip(0,0,128,_c)
  if ispne then
   -- pneumonic
   list_ptype()
  else
   list_ntype()
  end
  print_eta()
  clip()
 end
end

--------------------------------------------[ Virulent: End Game / Score State ]
-->8
--end game screen
end_screen={}

local function prln(k,v,sc)
 print(k,1,_y,5)
 if v then
  print(v,80,_y,5)
 end
 if sc and sc~=0 then
  print(sc,127-(#tostring(sc)*4),_y,5)
 end
 line(1,_y+6,126,_y+6,6)
 _y=_y+8
end

function end_screen.init()
 _o=end_condition()
 _l=game_score()
 toolbar={
  {247,"summary",nil},
  {247,"country statistics",nil},
  {243,"play again",goto_menu},
  }
 lock_tb()
 cls(15)
 print_title("END GAME REPORT",1)
 -- camera scroll
 _c=0
 set_redraw()
end

function end_screen.draw()
 _i=draw_tb()
 if not can_redraw() then
  return
 end
 rectfill(0,10,127,20,15)
 if _i==1 then
  print("score",108,10,4)
 elseif _i==2 then
  print("health",4,10,4)
  print("souls",35,10,4)
  print("deaths",70,10,4)
 end
 clip(0,20,128,100)
 camera(0,_c)
 -- fixed header
 rectfill(0,0,127,300,15)
 _y=22
 if _i==1 then
  prln("countries cured",getstatv(1),getstatm(1))
  prln("countries destroyed",getstatv(2),getstatm(2))
  prln("total deaths (mil)",getstatv(3),getstatm(3))
  prln("missiles fired",getstatv(4),getstatm(4))
  prln("missile hits",getstatv(5),getstatm(5))
  prln("missile misses",getstatv(4)-getstatv(5))
  prln("asteroid hits",getstatv(6),getstatm(6))
  prln("infection spreads",getstatv(7),getstatm(7))
  prln("remedies applied",getstatv(8),getstatm(8))
  prln("apr successes",getstatv(9),getstatm(9))
  prln("apr failures",getstatv(10),getstatm(10))
  if getstatv(11)>0 and getstatv(2)<#stats then
   prln("early end bonus",getstatv(11),getstatm(11))
  end
  prln("total score",nil,_l)
 elseif _i==2 then
  for i=1,#stats do
   _y=6+i*16
   load_stats(i)
   line(0,_y-4,127,_y-4,6)
   print(cname,2,_y,0)
   _y=_y+6
   rectfill(2,_y,30,_y+2,3)
   local lost=csouls-cpop
   _x=max(2,flr((cpop/csouls)*30))
   if lost>0 then
    rectfill(_x,_y,30,_y+2,8)
   end
   print(human_num(cpop,i==5),35,_y,3)
   if lost>0 then
    print(human_num(lost,i==5),70,_y,8)
   end
  end
 elseif _i==3 then
  camera(0,-20)
  draw_map()
  camera()
  if getstatv(2)==#stats then
   pal(10,8)
   sspr(112,64,16,16,110,100)
   pal()
   print("earth classification:",1,100,8)
   print("global biological hazard",1,106,8)
  end
 end
 camera()
 clip()
end

function end_screen.update()
 update_tb()
 if btn("up") then
  _c=max(0,_c-3)
  set_redraw()
 elseif btn("down") then
  _c=min(200,_c+3)
  set_redraw()
 elseif btn("left") or btn("right") then
  set_redraw()
  _c=0
 end
end

-------------------------------------------------[ Virulent: Help Screen State ]
-->8
-- help screen
help_screen={}

local function head(m)
 _y=_y+10
 print(m,1,_y,14)
 _y=_y+6
end

local function par(m,c,n)
 print(m,4,_y,c or 15)
 _y=_y+5+(n or 0)
end

function help_screen.init(return_to)
 pal()
 cls(0)
 -- page height
 _p=760
 -- scroll
 _i=0
 _o=return_to
 set_redraw()
end

function help_screen.draw()
 if can_redraw() then
  cls(1)
  clip(0,0,128,120)
  camera(0,_i)
  print("VIRULENT",50,1,0)
  print("VIRULENT",51,2,15)
  line(0,8,128,8,13)
  _y=2

  head"THE STORY SO FAR"
  par"a deadly virus brought by"
  par"asteroids is threatening"
  par"the world. you are chosen"
  par"by the top nations to lead"
  par"a task force to eradicate"
  par"the dreaded disease."
  par"good luck."

  head"HOW TO PLAY"
  par"the game takes place over"
  par"multiple turns, and in each"
  par"you get some action points"
  par"to manage the viral outbreak."
  par"how you spend those points"
  par"is up to you."
  par"the goal is to eradicate"
  par"infections by applying"
  par"remedies to infected countries,"
  par"and shooting down asteroids"
  par"before they hit and cause new"
  par"infections."
  par""
  par"a turn has three phases."

  head"REPORT PHASE"
  par"the infection report lists"
  par"all infected countries, and"
  par"displays any change in their"
  par"status."

  head"RADAR TRACKING PHASE"
  par"asteroids in earth's orbit are"
  par"shown in this phase, you"
  par"are notified immediately if"
  par"a country was hit by"
  par"an asteroid."

  head"COMMAND PHASE"
  par"in this phase you get to"
  par"make the life-saving"
  par"choices."

  _y=_y+7
  sspr(120,48,8,8,50,_y,24,24)
  print("THE C-VIRUS",45,_y+25,13)
  _y=_y+40

  par"select a country and press x"
  par"to open the regional update."
  par"in this screen you see"
  par"country statistics and"
  par"apply remedies."
  par""
  par"to launch a missle:"
  par"from the command screen press"
  par"down until you focus the"
  par"command toolbar. select"
  par"the `launch missle` option"
  par"and press x."

  head"END OF TURN"
  par"when your alotted actions are"
  par"spent, the turn ends. infection"
  par"levels are adjusted, remedies"
  par"applied and population tallied."
  par"you are then shown the next"
  par"turn report."

  head"INFECTION LEVELS"
  par"levels range from mild to"
  par"critical, with a special"
  par"level for pneumonic."
  par""
  par"when the estimated time until"
  par"pneumonic (peta) reaches zero"
  par"the country enters this deadly"
  par"level. this starts the"
  par"estimated time until"
  par"destruction (deta) count-down,"
  par"and when zero, the country is"
  par"completely and irrevocably"
  par"destroyed."

  head"REMEDIES"
  par"apply remedies to infected"
  par"countries to reduce levels."
  par""
  par("NORMAL REMEDIES",7)
  par"are effective 1-5 weeks,"
  par"they reduce infection levels"
  par"each turn until the course"
  par"concludes."
  par""
  par(" TYPE DUR DESCRIPTION",10,1)
  par(" ---- --- -----------",10,1)
  for i=1,8 do
   par("  "..remlut[i][1]..
       "   "..#neff[i]..
       "  "..remlut[i][2],10,1)
  end
  par""
  par("anti-pneumonic remedies",7)
  par"with a duration of one week,"
  par"they yield much higher"
  par"reduction factors at the cost"
  par"of success. because of their"
  par"extreme nature, these remedies"
  par"can only be applied to"
  par"pneumonic infection levels."
  par""
  par(" TYPE SUC RED DESCRIPTION",10,1)
  par(" ---- --- --- -----------",10,1)
  for i=1,4 do
   par("  "..remlut[8+i][1]..
       "  "..ceil(peff[i][1]*100)..
       "% "..ceil(peff[i][2]*100)..
       "% "..remlut[8+i][2],10,1)
  end

  head"ABOUT THIS GAME"
  par"this is a remake of an atari"
  par"game 'epidemic!'"
  par"by steven faber 1982."
  par""
  par"the code, art, music and screen"
  par"layouts are my own work."
  par"i included countries not"
  par"present in the original."

  head"I DEDICATE THIS GAME"
  par"to every person who has been"
  par"seperated from their family or"
  par"loved ones during the tragic"
  par"corona virus outbreak of 2020."
  par""
  par"we miss you dearly"
  head""
  par("WEZ",7)
  spr(249,16,_y-7) --print("♥",16,_y-4,8)

  camera()
  clip()
  rectfill(0,120,127,127,13)
  print("up/dn scroll",1,121,1)
  print("x:close",96,121,1)
  -- progress
  line(0,128,(_i/_p)*127,128,10)
 end
end

local function scroll_help(n)
 _i=max(0, min(_p,_i+n))
 set_redraw()
end

function help_screen.update()
 if btn("down") then
  scroll_help(4)
 elseif btnp("right") then
  scroll_help(64)
 elseif btn("up") then
  scroll_help(-4)
 elseif btnp("left") then
  scroll_help(-64)
 elseif btnp("x") then
  clip()
  switch(_o)
 end
end

------------------------------------------[ Virulent: Common Utility Functions ]
-->8
-- utilities

function dec_timer()
 _t=max(0,_t-1)
 return _t>0
end

function dec_p()
 _p=max(0,_p-1)
 return _p>0
end

function shift_lerp()
 _l=min(1,_l+0.05)
 return _l<1
end

function shift_clip(n)
 _c=min(127,_c+(n or 6))
 return _c<127
end

function insort(t,cmp)
 for n=2,#t do
  local i=n
  while i>1 and not cmp(t[i-1],t[i]) do
   t[i],t[i-1]=t[i-1],t[i]
   i=i-1
  end
 end
end

function lerp(a,b,t)
 return ((1-t)*a)+(t*b)
end

function human_num(n,isgl)
 -- params
 --  :num
 --  :is greenland (low pop)
 if isgl then
  if n>1 then
   return flr(n).." k"
  else
   return flr(n*1000)..""
  end
 else
  if n>1 then
   return flr(n).." mil"
  elseif n>0.001 then
   return flr(n*1000).." k"
  else
   return flr(n*1000)..""
  end
 end
end

function human_time(n)
 if n<=0 then return "" end
 return n.." week"..(n>1 and "s" or "")
end

function remedy_chart(i,x,y,cw,h)
 -- params
 --  :remedy index
 --  :x,y position
 --  :cell width
 --  :chart height
 -- charts 0-40% in 10% increments
 -- of estimated effectiveness,
 -- which is color filled.
 -- ----------------<days
 -- |40|  |  |  |  |
 -- |30|  |  |  |  |
 -- |20|  |  |  |  |^percent
 -- |10|  |  |  |  |
 -- ----------------
 local gc=13 -- grid color
 local ec=2  -- est eff color

 -- bg
 pal()
 rectfill(x,y,x+(cw*5)-1,y+h-1,1)

 -- fill est eff %
 -- weeks 1-5
 for d=1,5 do
  -- eff %
  local ep=neff[i][d] or 0
  -- scale ep to max 40%
  ep=ep*2.4
  -- cell x
  local cx=x+((d-1)*cw)
  -- cell y relative to eff
  local cy=y+h-h*ep
  rectfill(cx,
           cy,
           cx+cw-1,
           y+h-1,ec)
  -- week column
  rect(cx,y,cx+cw,y+h,gc)
 end

 -- 10% guidelines
 for n=1,3 do
  local ly=y+n*(h/4)
  line(x,ly,x+cw*5,ly,gc)
 end

end

function print_title(m,c,s)
 -- params
 --  :text
 --  :col
 --  :opt subtitle
 print(m,1,1,c)
 line(0,7,128,7,c)
 if s then
  print(s,127-(#s*4),1,c)
 end
end

function rot_sel(i,m,b)
 -- params
 --  :current index
 --  :max items
 --  :{dec btn, inc btn}
 if i==0 then
  return i
 end
 b=b or {"up","down"}
  i=(i+(btnp(b[1]) and -1 or btnp(b[2]) and 1 or 0))%m
 return i==0 and m or i
end

------------------------------------------------------[ Virulent: The Toolbar ]
-->8
-- components
-- toolbar
local focus,lock=false,false

function focus_tb()
 focus=1
 lock=false
end

function lock_tb()
 focus_tb()
 lock=true
end

function unlock_tb()
 lock=false
 focus=false
end

function draw_tb(bc)
 -- params
 --  :opt color
 if not toolbar then return end
 bc=bc or 12
 camera(0,-120)
 rectfill(0,0,127,7,focus and 1 or bc)
 for i,t in pairs(toolbar) do
  local x=(i-1)*8
  if focus==i then
   pal(12,bc)
   spr(240,x,0)
   pal()
   print(t[2],128-(#t[2]*4),2,bc)
  end
  spr(t[1],x,0)
 end
 if not focus then
  print("ACTIONS:"..actno,90,2,15)
 end
 camera()
 return focus
end

function update_tb()
 if not focus then return end
 if btnp("left") then
  focus=max(1,focus-1)
  sfx(4)
 elseif btnp("right") then
  focus=min(#toolbar,focus+1)
  sfx(4)
 elseif btnp("up") then
  if not lock then
   focus=false
  end
 elseif btnp("x") then
  local f=toolbar[focus][3]
  if type(f)=="function" then
   sfx(5)
   f()
   if not lock then
    focus=false
   end
  end
 end
 return true
end

-- message ticker
local ticker,tickpos=nil,nil

function tickmsg(m)
 add(ticker,m)
 printw(" msg: "..ticker[#ticker])
end

function clear_ticker()
 ticker={}
 tickpos=nil
end

function update_ticker()
 if not ticker then return end
 if tickpos then
  tickpos=tickpos-10
  if tickpos>0 then
   sfx(7)
  end
  if tickpos<-300 then
   tickpos=nil
   del(ticker, ticker[1])
  end
 else
  if #ticker>0 then
   tickpos=128
  end
 end
end

function draw_ticker()
 rectfill(0,122,128,128,0)
 if not ticker or not tickpos then return end
 local msg=ticker[1]
 if not msg then return end
 print(msg,max(1,tickpos),123,10)
 if tickpos<0 and #ticker>1 then
  print("..",120,122,5)
 end
end

--< cinematik >--
cmk={}
function cmk.init(c,f)
 c.t,c.r,c.d=0,{},{}
 c.spf=(f and 15 or 30)/1000
 for i=1,#cmk do
  c.d[i]={}
  c[i](c.d[i],0,c.lerp,c.between)
 end
end
function cmk.clear()
 while #cmk>0 do
  deli(cmk,1)
 end
end
function cmk.update(c)
 c.t=c.t+c.spf
 for i=1,#cmk do
  cmk.br=false
  c.r[i]=c[i](c.d[i],c.t,c.lerp,c.between) or cmk.br
 end
end
function cmk.draw(c)
 for i=1,#cmk do
  if c.r[i] then
   c[i](c.d[i])
  end
 end
end
function cmk.lerp(a,b,m)
 local t=cmk.t-cmk.ba
 m=m or 1
 m=m-0.1
 t=t/m
 t=max(0,min(1,t))
 return lerp(a,b,t)
end
function cmk.between(a,b)
 cmk.br=cmk.t>a and cmk.t<b
 cmk.ba,cmk.bb=a,b
 return cmk.br
end

-- ╒═══════════════════════════════════════════════════════════════════════════╕
-- │                                                                           │
-- ├───────────────────────────────────────────────────────────────────────────┘
-- │
-- │
-- │
-- │
-- │
-- │
-- │
-- │
-- │
-- │
-- │
-- │
-- │
-- │                                                                         ┌─┐
-- ╘═════════════════════════════════════════════════════════════════════════╧═╛
--
