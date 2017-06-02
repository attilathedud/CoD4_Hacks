# CoD4_Hacks

A collection of hacks for CoD4 v1.7

## Esp

An ESP for COD4 that uses a hook in R_EndFrame and uses an external method of calculating 3D to 2D coordinates to display tags over all drawn entities.

![Hack Screenshot](Esp/screenshot.jpg?raw=true "Screenshot Hack")

## Nametag_Esp

A POC that alters the internal function for displaying nametags on hover to display all nametags regardless of team.

## Print_Text

A POC that uses a hook in COD4's main game loop to call the internal print_text function and display the string "hello" on the screen.

![Hack Screenshot](Print_Text/screenshot.jpg?raw=true "Screenshot Hack")

## Wallhack

A POC that uses a hook in COD4's main game loop to call the internal print_text function and display the string "hello" on the screen.

![Hack Screenshot](Wallhack/screenshot.jpg?raw=true "Screenshot Hack")

## coffee

A multihack for COD4 that includes a wallhack, no-recoil, and internal ui.

Injector:

![Injector Screenshot](coffee/screenshot_i.png?raw=true "Screenshot Injector")

Hack:

![Hack Screenshot](coffee/screenshot_h.jpg?raw=true "Screenshot Hack")

## decafCoffee

A multihack for COD4 that includes a wallhack, no-recoil, nametags, and internal ui.

Injector:

![Injector Screenshot](decafCoffee/screenshot_i.png?raw=true "Screenshot Injector")

Hack:

![Hack Screenshot](decafCoffee/screenshot_h.jpg?raw=true "Screenshot Hack")

## Some notes

### No-spread
```
00416C70
```

### No-Recoil
```
00457D2E
```

### Draw players
```
004354C9
```

### Draw crosshair
```
0042F6B5     E8 E61A0000    CALL iw3mp.004311A0
```

### Draw HUD
```
0042F703     E8 C8531200    CALL iw3mp.00554AD0 - draw hud
```

### Text Calls
```
00422C90 - ammo left
0042D412 - chat text
00443BE9 - press space to text
00448770   CALL iw3mp.00542F50				- name and rank on scoreboard
0045A85F   CALL iw3mp.00542F50				-amount of ammo on nades
005520C1   CALL iw3mp.00542F50				-text on bottom of hud
004319BC   CALL iw3mp.00542F50         -debug info
```