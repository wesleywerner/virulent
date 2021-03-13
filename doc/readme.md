# Virulent Design Document

This document lists the variables and values used in the code for the game. They were documented in the source, but grew beyond the limitations of pico-8, so now they live here for your perusal.

## End Conditions

The game can end in one of these ways:

1. When the number of turns for the game reaches zero.
2. When all countries are cured.
3. When all countries are destroyed.

- The number of turns varies by the skill being played, and is calculated in the `max_turns()` function.
- The cured and destroyed conditions make it possible to end a game ahead of time.

### infection levels

- 0: clear
- 1: stasis
- 2: mild
- 3: serious
- 4: critical
- 5: pneumonic
- 6: destroyed

Stasis means that the level of infection does not grow, it won't spread to other countries, and population loss is limited. There is also a 30% chance a remedy will fail to have any effect.

### countries

-  1: Canada
-  2: US
-  3: Mexico
-  4: Latin America
-  5: Greenland
-  6: Scandinavia
-  7: Western Europe
-  8: Eastern Europe
-  9: Africa
- 10: Middle East
- 11: Russia
- 12: Indian Subcontinent
- 13: East Asia
- 14: Australia
- 15: South Africa
- 16: Southeast Asia
- 17: Madagascar

### Remedies

Remedies come in two types - normal and anti-pneumonic (APR). For a full list see the `remlut` table below. For their effectiveness see the `neff` and `peff` tables below.

## Lookup Tables

### curelev

The minimum level reached for a country to be cured. Lists each level per skill `1` through `5`.

|Game Skill|1|2|3|4|
|-----------|-|-|-|-|
|Cured Below Level|.8|.7|.6|.5|

### gstats

List of game statistics gathered while playing, each entry is a table of:

| Index | Value                                                 |
|-------|-------------------------------------------------------|
| 1     | Counter added during play. Zeroed in `reset_game()`   |
| 2     | Score multiplier                                      |

The list of statistics that make up `gstats` is defined as:

| Index | Description                               |
|-------|-------------------------------------------|
|  1    | Countries cured                           |
|  2    | Countries destroyed                       |
|  3    | Total deaths                              |
|  4    | Missiles fired                            |
|  5    | Missiles that hit asteroids               |
|  6    | Asteroid impacts on land                  |
|  7    | Infection spreads between countries       |
|  8    | Remedies applied (both n-type and p-type) |
|  9    | APR remedies succeeded                    |
| 10    | APR remedies failed                       |
| 11    | Turns remaining at game end               |
| 12    | End Condition Code                        |

- For `11` see **End Conditions**.

### keymap

List of countries to focus with the d-pad/arrow keys on the Command screen. The index relates to the country ID, each entry being a table of:

| Index | Value               |
|-------|---------------------|
| 1     | Country ID on UP    |
| 2     | Country ID on DOWN  |
| 3     | Country ID on LEFT  |
| 4     | Country ID on RIGHT |

A `nil` value does nothing, a `0` will focus the toolbar.

### neff

Normal remedy effectiveness lookup. Lists Reduction % for each `n1` through `n8`, as a series of up to 5 weeks.

Duration of a remedy is determined by the number of elements in its series.

||Week 1|Week 2|Week 3|Week 4|Week 5|
|----|-|-|-|-|-|
|n1   |.25|   |   |   |   |
|n2   |.05|.3 |   |   |   |
|n3   |.10|.25|.12|   |   |
|n4   |.12|.15|.28|.15|   |
|n5   |.28|.18|.05|.05|   |
|n6   |.16|.05|.03|.22|.30|
|n7   |.05|.14|.30|.21|.08|
|n8   |  0|  0|  0|.35|.38|

### peff

Pneumonic remedy effectiveness lookup. Lists each `p1` through `p4`, as `{% Success, % Reduction}`.

P-type remedies always take 1 week, there is no time component.

| |% Success|Reduction %|
|-|---------|-----------|
|p1|.8      |.6         |
|p2|.6      |.7         |
|p3|.4      |.8         |
|p4|.2      |.9         |

### remlut

List of remedy codes and names.

| code | name              |
|------|-------------------|
| n1   | interferon        |
| n2   | vaccine           |
| n3   | x-rays            |
| n4   | martial law       |
| n5   | gamma globulin    |
| n6   | back fire         |
| n7   | clean suits       |
| n8   | gene splice       |
| p1   | cloud seeding     |
| p2   | microwaves        |
| p3   | fire storms       |
| p4   | killer satellites |

### roids

List of asteroids in orbit, each being a table of:

| Index | Value                        |
|-------|------------------------------|
| 1     | X Position                   |
| 2     | Y Position                   |
| 3     | Angle of Movement            |
| 4     | Altitude                     |
| 5     | Targeted by missile (truthy) |

### worldspr

List of sprites of each country, Index relates to the Country ID, and each entry being a table of:

| Index      | Sprite Index | Width (in sprites) | Height (in sprites) | X draw offset | Y draw offset |
|------------|--------------|--------------------|---------------------|---------------|---------------|
| 1          |0             | 4                  | 2                   | 2             | 6             |
| 2          |32            | 4                  | 2                   | 1             | 17            |
| 3          |64            | 2                  | 2                   | 2             | 26            |
| 4          |96            | 3                  | 5                   | 16            | 38            |
| 5          |4             | 3                  | 2                   | 34            | 0             |
| 6          |36            | 2                  | 1                   | 58            | 6             |
| 7          |7             | 2                  | 2                   | 51            | 11            |
| 8          |9             | 2                  | 2                   | 62            | 12            |
| 9          |67            | 4                  | 5                   | 47            | 23            |
| 10         |38            | 2                  | 2                   | 71            | 22            |
| 11         |40            | 8                  | 3                   | 67            | 3             |
| 12         |11            | 2                  | 2                   | 85            | 23            |
| 13         |87            | 4                  | 3                   | 88            | 14            |
| 14         |13            | 3                  | 2                   | 07            | 49            |
| 15         |66            | 1                  | 1                   | 64            | 55            |
| 16         |91            | 4                  | 3                   | 98            | 33            |
| 17         |82            | 1                  | 1                   | 75            | 50            |

### stats

List of pertinent country data, Index relates to the Country ID, and each entry being a table of:

| Index | Stores                                                              | `load_stats()` Variable |
|-------|---------------------------------------------------------------------|-------------------------|
| 1     | Country name                                                        | `cname`                 |
| 2     | Souls (starting population)                                         | `csouls`                |
| 3     | Table of neighboring country IDs                                    | `clinks`                |
| 4     | Current Population                                                  | `cpop`                  |
| 5     | Level of infection                                                  | `clev`                  |
| 6     | PETA, turns until pneumonic                                         | `peta`                  |
| 7     | DETA, turns until destruction. Considered pneumonic while this > 0. | `deta`                  |
| 8     | Active remedy index, 1-8 for normal, 9-12 for APR, or 0 for none.   | `rem`                   |
| 9     | CETA, turns until the remedy concludes                              | `ceta`                  |
| 10    | Table of remedy history, eg a histogram.                            | `remhist`               |
| 11    | (Reserved)                                                          |                         |
| 12    | (Reserved)                                                          |                         |
| 13    | (Reserved)                                                          |                         |
| 14    | (Reserved)                                                          |                         |
| 15    | Index of country which infection has spread from. Zero for none.    | `spreadfrom`            |
| 16    | New population, set in `end_turn()`                                 | `npop`                  |
| 17    | New infection level, set in `end_turn()` and `infect()`             | `nlev`                  |
| 18    | New PETA, set in `end_turn()` and `infect()`                        | `npeta`                 |
| 19    | New DETA, set in `end_turn()`                                       | `ndeta`                 |
| 20    | New CETA, set in `set_remedy()` and `end_turn()`                    | `nceta`                 |
| 21    | New Remedy (when cleared)                                           | `nrem`                  |
| 22    | APR success flag                                                    | `aprsuc`                |

## Variable Catalogue

All game screens use a common set of variables to maximize recyclability.

### game state

These variables control the life cycle of the game, or each game state.

- `actno`: count of actions the player has remaining, per turn. resets in `end_turn()`.
- `turnno`: counts the number of game turns passed.
- `skill`: game difficulty from lowest `1` to highest `4`.
- `state`: stores the current displayed screen.
- `done`: indicates the current state is done and allows the player to move to the next state.
- `redraw`: determines selective screen updates.

_auxiliary functions_

- `can_redraw()`: returns `true` when `redraw` is truthy, and toggles `redraw` falsey upon calling.
- `set_redraw()`: toggles `redraw` truthy

### country variables

These variables are loaded in `load_stats()`.

- `ceta`: remedy concludes eta
- `ci`: index
- `ccol`: color
- `cdead`: number of deaths
- `cdeadtxt`: deaths as formatted text
- `clev`: infection level
- `clevname`: infection name
- `clevtxt`: "level:name"
- `clinks`: neighbor links
- `cname`: name
- `cpop`: population
- `cpoptxt`: population as formatted text
- `csouls`: initial pop
- `cstat`: stats table
- `deta`: destruction eta
- `ispne`: infection is pneumonic
- `instasis`: infection level is in stasis
- `peta`: pneumonic eta
- `rem`: remedy index
- `remcode`: remedy code (n1..n8, p1..p4)
- `remname`: remedy name
- `remhist`: remedy histogram
- `remtxt`: remedy "code:name"
- `isptype`: remedy is anti-pneumonic type
- `isntype`: remedy is normal type

### recyclable variables

The reusable pattern is to initialize these in the `init()` method of each state.

**positional**

- `_x`
- `_y`
- `_o`
- `_p`

**counters:**

- `_c`
- `_i`
- `_l`

_auxiliary functions_

- `shift_clip()`: adds to `_c` and returns `_c<127`
- `shift_lerp()`: adds to `_l` and returns `_l<1`
- `dec_p()`: reduces `_p` and returns `_p>0`

**timers:**

- `_t`

_auxiliary functions_

- `dec_timer()`: reduces `_t` and returns `_t>0`

## The Toolbar

The toolbar has two modes of operation:

- dynamic, which allows the state to handle its own keys in addition to the toolbar.
- locked, in which the toolbar is the only element which has focus

**dynamic setup**

```
function state.init()
 toolbar={{sprite index,"title",callback},...}
end

function state.update()
 if update_tb() then
  --nop
 elseif btnp(1) then
  focus_tb()
 elseif btnp(2️) then
  -- handle state key presses
 end
end

function state.draw()
 draw_tb()
end
```

- Call `focus_tb()` when you want to give control
- Function `update_tb()` returns `true` while the toolbar has focus, thus you can skip state related key handling.
- The toolbar releases its focus when the `up` key is pressed.

**locked setup**

```
function state.init()
 toolbar={{sprite index,"title",callback},...}
 lock_tb()
end

function state.update()
 update_tb()
end

function state.draw()
 draw_tb()
end
```

- Call `lock_tb()` giving it focus, and it won't release for `up` key presses.
- To release the lock, call `unlock_tb()`.

# Known Bugs

There are no known bugs at this time `:)`

# Not Implemented

- Codeword & Nuke action

# Changelog

**2020/08/09 - First Release**

# Debugging

Debugging function codes.

tab 0 debug print function:
```
function printw(m,a,b)
 if not wizard then return end
 if m==1 then
  printw("---> 𝘨𝘢𝘮𝘦 𝘴𝘵𝘢𝘳𝘵")
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
  printw("     npop="..tostr(npop)..
         " nlev="..tostr(nlev)..
         " npeta="..tostr(npeta)..
         " ndeta="..tostr(ndeta)..
         " nceta="..tostr(nceta)..
         " nrem="..tostr(nrem))
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
```

Command screen init() wizard:

```
 if wizard then
  add(toolbar,{227,"𝘦𝘯𝘥 𝘨𝘢𝘮𝘦",
   function()
    turnno=14
    actno=0
   end})
  add(toolbar,{227,"𝘥𝘦𝘴𝘵𝘳𝘰𝘺 𝘢𝘭𝘭",
   function()
    for s in all(stats) do
     s[4]=0
     s[5]=6
    end
   end})
  add(toolbar,{227,"𝘩𝘦𝘢𝘭 𝘢𝘭𝘭",
   function()
    for s in all(stats) do
     if s[5]>0 then
      s[5]=0.1
     end
    end
    actno=0
   end})
 end
```

# TODO

- Auto end turn if no untargeted asteroids, or all infected countries have remedies+ceta>0.
- Review game score totals
- Must recognize APR remedy set for auto turn end