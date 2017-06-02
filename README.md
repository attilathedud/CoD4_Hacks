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

### Reversed Text Call
```

00431962     D94424 0C      FLD DWORD PTR dS:[557b530]		;esp=dfdc0(00 00 80 3e)
								
00431982     B8 18456B00    MOV EAX,iw3mp.006B4518	        ;rgba colour struct (00 00 80 3F)

0043198B     6A 03          PUSH 3				            ;?
0043198D     50             PUSH EAX				        ;colour				
0043198E     A1 0007AF0C    MOV EAX,0F8D65C			        ;font structure
00431993     83EC 0C        SUB ESP,0C				        ;esp=dfdac
00431996     D95C24 08      FSTP DWORD PTR SS:[ESP+8]       ;esp+8=.25=000DFDB4  00 04 00 00 
0043199A     D94424 1C      FLD DWORD PTR SS:[ESP+1C]       ;y 9a 99 3d 43 = 189.6
0043199E     D95C24 04      FSTP DWORD PTR SS:[ESP+4]           
004319A2     D94424 18      FLD DWORD PTR SS:[ESP+18]       ;0(x)
004319A6     D91C24         FSTP DWORD PTR SS:[ESP]             
004319A9     50             PUSH EAX                        ;font
004319AA     68 FFFFFF7F    PUSH 7FFFFFFF                   ;7FFFFFFF

004319AF     B9 00B07100    MOV ECX,iw3mp.0071B000

004319B5     51             PUSH ECX				        ;text
004319B6     68 2044E300    PUSH iw3mp.00E34420

004319BC     E8 8F151100    CALL iw3mp.00542F50             ;draw_text        
004319C1     83C4 24        ADD ESP,24
004319C4  \. C3             RETN
```