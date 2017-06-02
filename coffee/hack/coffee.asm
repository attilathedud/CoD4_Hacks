; A multihack for COD4 that includes a wallhack, no-recoil, and internal ui.
;
; Originally written on 2010/03/10 by attilathedud.

; System descriptors
.386
.model flat,stdcall
option casemap:none

VirtualAlloc proto stdcall :DWORD, :DWORD, :DWORD, :DWORD
VirtualProtect proto stdcall :DWORD, :DWORD, :DWORD, :DWORD
VirtualFree proto stdcall :DWORD, :DWORD, :DWORD
GetAsyncKeyState proto stdcall :DWORD

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\user32.lib

.data
	menu db 0
	keydown db 0
	index db 0
	wallon db 0
	recoilon db 0
	
.code
	main:
		jmp @F
			top db "coffee.dll - attila",0
			on db "On",0
			off db "Off",0
			wallhack db "Wallhack:",0
			norecoil db "No-Recoil:",0
			select db "->",0
			green real4 0.0f,1.0f,0.0f,1.0f
			red real4 1.0f,0.0f,0.0f,1.0f
			grey real4 0.5f,0.5f,0.5f,1.0f
			y1 real4 130.0f
			y2 real4 150.0f
			y3 real4 170.0f
			x1 real4 130.0f
			x2 real4 150.0f
			x3 real4 270.0f
			scale1 real4 0.25f
			scale2 real4 0.30f
			ori_printtext dd 542f50h
			ori_recoil dd 41a7b0h
			jmpback_recoil dd 457d33h
			jmpback_wallhack dd 445485h
		@@:
			; Save the current state of the stack.
			push ebp
			mov ebp,esp

			; Ensure our dll was loaded validily.
			mov eax,dword ptr ss:[ebp+0ch]
			cmp eax,1
			jnz @sub_1h

			; Allocate memory for the old protection type.
			; Store this location in ebx.
			push eax
			push 40h
			push 1000h
			push 4h
			push 0
			call VirtualAlloc 
			mov ebx,eax  

			; Unprotect the memory from 552086h - 55208ch
			push ebx
			push 40h
			push 6h
			push 552086h
			call VirtualProtect

			; Create a codecave in the main game loop that will call to our hook function.
			; e8h is the opcode to call, with the address of the call being calculated by subtracting
			; the address of the function to jump to from our current location.
			mov byte ptr ds:[552086h],0e8h
			lea ecx,@cg_hook
			sub ecx,55208bh
			mov dword ptr ds:[552087h],ecx

			; Since our replaced instruction is 6 bytes long, nop the last byte
			mov byte ptr ds:[55208bh],90h

			; Reprotect the memory we just wrote.
			push 0
			push dword ptr ds:[ebx]
			push 6h
			push 552086h
			call VirtualProtect 

			; Unprotect the memory from 457d2eh - 457d3dh
			push ebx
			push 40h
			push 5h
			push 457d2eh
			call VirtualProtect

			; Create a codecave in the recoil function that will jump to our hook function.
			; e9h is the opcode to jump, with the address of the jump being calculated by subtracting
			; the address of the function to jump to from our current location.
			mov byte ptr ds:[457d2eh],0e9h
			lea ecx,@recoil
			sub ecx,457d33h
			mov dword ptr ds:[457d2fh],ecx

			; Reprotect the memory we just wrote.
			push 0
			push dword ptr ds:[ebx]
			push 5h
			push 457d2eh
			call VirtualProtect 

			; Unprotect the memory from 445480h - 445485h
			push ebx
			push 40h
			push 5h
			push 445480h
			call VirtualProtect 

			; Create a codecave in the draw_entities function that will jump to our hook function.
			; e9h is the opcode to jump, with the address of the jump being calculated by subtracting
			; the address of the function to jump to from our current location.
			mov byte ptr ds:[445480h],0e9h
			lea ecx,@wall
			sub ecx,445485h
			mov dword ptr ds:[445481h],ecx

			; Reprotect the memory we just wrote.
			push 0
			push dword ptr ds:[ebx]
			push 5h
			push 445480h
			call VirtualProtect

			; Free the memory we allocated for our protection type.
			push 4000h
			push 4h
			push ebx
			call VirtualFree 

			; Restore eax and the stack.
			pop eax
			@sub_1h:
				leave
				retn 0ch
			
			; A helper function to call the internal Draw_Text function.
			;	ebx = y(float)
			;	edx = x(float)
			;	ecx = text(pointer)
			;	eax = scale(float)
			;	esi = font(pointer)
			; 	edi = colour(pointer/structure) ? 6b4518h = white
			@draw_text:
				; To load floats on the stack, we have to use fld and then fstp to pop them off 
				; the float stack and onto the function stack. 
				fld dword ptr ds:[eax]
				push 3
				push edi
				sub esp,0ch
				fstp dword ptr ss:[esp+8]
				fld dword ptr ds:[ebx]			
				fstp dword ptr ss:[esp+4]
				fld dword ptr ds:[edx]			
				fstp dword ptr ss:[esp]
				push esi
				push 7fffffffh
				push ecx						
				push 00e34420h
				call dword ptr cs:[ori_printtext]
				add esp,24h
				retn
			
			; The recoil hook checks to see if no-recoil is enabled.
			; If not, call the original function and then jump back.
			@recoil:
				cmp recoilon,1
				jz @sub_2h
				call dword ptr cs:[ori_recoil]
				@sub_2h:
					jmp jmpback_recoil
					
			; The wallhack hook checks to see if the wallhack is enabled.
			; If so, push 4 as the render_fx value to always render. If not,
			; push 3 (normal rendering mode).
			@wall:
				cmp wallon,0
				jz @sub_3h
				push 3
				jmp @sub_4h
				@sub_3h:
					push 4
					@sub_4h:
						push ecx
						mov eax,ebx
						jmp jmpback_wallhack
						
			; CG_Hook is responsible for displaying the menu and controlling
			; navigation of the menu.
			@cg_hook:
				pushad

				; Check to see if we are pressing F3, if so, bring up the menu.
				push 72h
				call GetAsyncKeyState 
				test eax,eax
				jz @sub_5h
				cmp keydown,0
				jnz @sub_7h
				xor menu,al
				xor keydown,al
				jmp @sub_7h
				@sub_5h:
					mov keydown,0
				@sub_7h:
					; If the menu is active, draw our menu text and listen for
					; menu navigation events.
					cmp menu,1
					jnz @sub_8h
					lea ebx,y1
					lea edx,x1
					lea eax,scale1
					lea ecx,top
					mov esi,0f8d65ch
					lea edi,grey
					call @draw_text

					lea ebx,y2
					lea edx,x2
					lea eax,scale2
					lea ecx,wallhack
					mov esi,0f8d6ech
					mov edi,6b4518h
					call @draw_text

					lea ebx,y3
					lea edx,x2
					lea eax,scale2
					lea ecx,norecoil
					mov esi,0f8d6ech
					mov edi,6b4518h
					call @draw_text

					push 26h
					call GetAsyncKeyState
					test eax,eax
					jnz @sub_9h
					push 28h
					call GetAsyncKeyState 
					test eax,eax
					jz @sub_10h
					@sub_9h:
						xor index,al
					@sub_10h:
					cmp index,0
					jnz @sub_11h
					lea ebx,y2
					jmp @sub_opps
					@sub_11h:
						lea ebx,y3
						@sub_opps:
						lea edx,x1
						lea eax,scale2
						lea ecx,select
						mov esi,0f8d6ech
						lea edi,grey
						call @draw_text

						push 27h
						call GetAsyncKeyState
						test eax,eax
						jnz @sub_12h
						push 25h
						call GetAsyncKeyState 
						test eax,eax
						jz @sub_13h
						@sub_12h:
							cmp index,0
							jnz @sub_14h
							xor wallon,al
							jmp @sub_13h
							@sub_14h:
							xor recoilon,al
							@sub_13h:
					lea ebx,y2
					lea edx,x3
					lea eax,scale2
					mov esi,0f8d6ech
					cmp wallon,1
					jnz @sub_15h
					lea ecx,on
					lea edi,green
					jmp @sub_16h
					@sub_15h:
						lea ecx,off
						lea edi,red
						@sub_16h:
					call @draw_text
					lea ebx,y3
					lea edx,x3
					lea eax,scale2
					mov esi,0f8d6ech
					cmp recoilon,1
					jnz @sub_17h
					lea ecx,on
					lea edi,green
					jmp @sub_18h
					@sub_17h:
						lea ecx,off
						lea edi,red
						@sub_18h:	
							call @draw_text

				; Restore the original instruction.
				@sub_8h:
					popad
					mov edx,dword ptr ds:[esi+0d4h]
					retn
				
	end main