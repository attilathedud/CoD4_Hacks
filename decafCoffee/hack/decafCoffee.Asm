; A multihack for COD4 that includes a wallhack, no-recoil, nametags, and internal ui.
;
; Originally written 2010/03/21 by attilathedud.

; Include the helper functions.
include CoD4Utils.inc

.data
	menu db 0
	keydown db 0
	skeydown db 0
	rkeydown db 0
	index db 0
	wallon db 0
	recoilon db 0
	tagson db 0
	
.code
	main:
		jmp @F
			top db "decafCoffee.dll - attila",0
			on db "On >",0
			off db "Off >",0
			wallhack db "Wallhack:",0
			norecoil db "No-Recoil:",0
			nametags db "Name-Tags:",0
			select db "==",0
			x1y1 real4 130.0f
			x2y2 real4 150.0f
			y3 real4 170.0f
			y4 real4 190.0f
			x3 real4 270.0f
			ori_recoil dd 41a7b0h
			jmpback_recoil dd 457d33h
			jmpback_wallhack dd 445485h
			jmpback_tags1 dd 42e0b3h
			jmpback_tags1a dd 42deaah
			jmpback_tags2 dd 42e1b2h
			jmpback_tags2a dd 42e280h
		@@:
			; Save the current state of the stack.
			push ebp
			mov ebp,esp

			; Ensure our dll was loaded validily.
			mov eax,dword ptr ss:[ebp+0ch]
			cmp eax,1
			jnz @returnf

			; Allocate memory for the old protection type.
			; Store this location in ebx.
			push eax
			push 40h
			push 1000h
			push 4h
			push 0
			call VirtualAlloc 
			mov ebx,eax  

			; Hook the main game loop.
			push 0
			push @cg_hook
			push 6h
			push 552086h
			call @hook_function

			; Hook the recoil function.
			push 1
			push @recoil
			push 5h
			push 457d2eh
			call @hook_function

			; Hook the draw-entities function.
			push 1
			push @wall
			push 5h
			push 445480h
			call @hook_function	

			; Hook the nametag functions.
			push 1
			push @tags1
			push 6h
			push 42dea4h
			call @hook_function	
			push 1
			push @tags2
			push 6h
			push 42e1ach
			call @hook_function

			; Free the memory we allocated for our protection type.
			push 4000h
			push 4h
			push ebx
			call VirtualFree 

			; Restore eax and the stack.
			pop eax
			@returnf:
				leave
				retn 0ch

			; First tag hook checks to see if tags are enabled.
			; If so, jmp over the original instruction.	
			@tags1:
				cmp tagson,1
				jz @tags_on
				cmp byte ptr ds:[ecx+0ch],0
				jnz @tags_on
				jmp jmpback_tags1a
				@tags_on:
					jmp jmpback_tags1

			; Second tag hook checks to see if tags are enabled.
			; If so, jmp over the original instruction.		
			@tags2:
				cmp tagson,1
				jz @tags_on2
				cmp ecx,dword ptr ds:[edx+83928ch]
				jz @tags_on2
				jmp jmpback_tags2a
				@tags_on2:
					jmp jmpback_tags2
				
			; The recoil hook checks to see if no-recoil is enabled.
			; If not, call the original function and then jump back.	
			@recoil:
				cmp recoilon,1
				jz @recoil_off
				call dword ptr cs:[ori_recoil]
				@recoil_off:
					jmp jmpback_recoil
				
			; The wallhack hook checks to see if the wallhack is enabled.
			; If so, push 4 as the render_fx value to always render. If not,
			; push 3 (normal rendering mode).	
			@wall:
				cmp wallon,0
				jz @wall_off
				push 3
				jmp @wall_cont
				@wall_off:
					push 4
					@wall_cont:
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
				jz @reset_keydown
				cmp keydown,0
				jnz @draw_menu
				mov keydown,1
				xor menu,1
				jmp @draw_menu
				@reset_keydown:
					mov keydown,0			
				@draw_menu:
					; If the menu is active, draw our menu text and listen for
					; menu navigation events.
					cmp menu,1
					jnz @finish_hook
					@draw_text_fill x1y1,x1y1,top,grey,scale1,0f8d65ch
					@draw_text_fill x2y2,x2y2,wallhack,white,scale2,0f8d6ech
					@draw_text_fill x2y2,y3,norecoil,white,scale2,0f8d6ech
					@draw_text_fill x2y2,y4,nametags,white,scale2,0f8d6ech					
					push 28h
					call GetAsyncKeyState 
					test eax,eax
					jz @reset_select_keydown
					cmp skeydown,0
					jnz @draw_select_line
					mov skeydown,1
					inc index
					cmp index,3
					jl @draw_select_line
					mov index,0
					jmp @draw_select_line
					@reset_select_keydown:
						mov skeydown,0				
					@draw_select_line:
						cmp index,1
						jl @index_less
						jg @index_more
						lea ebx,y3
						jmp @draw_select_continue
						@index_less:
							lea ebx,x2y2
							jmp @draw_select_continue
						@index_more:
							lea ebx,y4				
					@draw_select_continue:
						@draw_text_fill x1y1,dword ptr ds:[ebx],select,grey,scale2,0f8d6ech			
						push 27h
						call GetAsyncKeyState 
						test eax,eax
						jz @reset_r_keydown
						cmp rkeydown,0
						jnz @wall_toggle
						mov rkeydown,1
						cmp index,1
						jl @index_less_r
						jg @index_more_r
						xor recoilon,1
						jmp @wall_toggle
						@index_less_r:
							xor wallon,1
							jmp @wall_toggle
						@index_more_r:
							xor tagson,1
							jmp @wall_toggle
						@reset_r_keydown:
							mov rkeydown,0					
						@wall_toggle:	
							cmp wallon,0
							jz @walltoggle_off
							@draw_text_fill x3,x2y2,on,green,scale2,0f8d6ech
							jmp @recoil_toggle
							@walltoggle_off:
								@draw_text_fill x3,x2y2,off,red,scale2,0f8d6ech					
						@recoil_toggle:	
							cmp recoilon,0
							jz @recoiltoggle_off
							@draw_text_fill x3,y3,on,green,scale2,0f8d6ech
							jmp @tags_toggle
							@recoiltoggle_off:
								@draw_text_fill x3,y3,off,red,scale2,0f8d6ech				
						@tags_toggle:
							cmp tagson,0
							jz @tagstoggle_off
							@draw_text_fill x3,y4,on,green,scale2,0f8d6ech
							jmp @finish_hook
							@tagstoggle_off:
								@draw_text_fill x3,y4,off,red,scale2,0f8d6ech	
					; Restore the original instruction.			
					@finish_hook:
						popad
						mov edx,dword ptr ds:[esi+0d4h]
						retn
				
	end main
	