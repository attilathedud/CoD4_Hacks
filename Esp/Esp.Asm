; An ESP for COD4 that uses a hook in R_EndFrame and uses an external method of calculating
; 3D to 2D coordinates to display tags over all drawn entities.
;
; Originally written on 2011/01/01 by attilathedud.

; System descriptors
.386
.model flat, stdcall
option casemap: none

VirtualAlloc proto stdcall :DWORD, :DWORD, :DWORD, :DWORD
VirtualProtect proto stdcall :DWORD, :DWORD, :DWORD, :DWORD
VirtualFree proto stdcall :DWORD, :DWORD, :DWORD

includelib \masm32\lib\kernel32.lib

.data
	ori_print_text  dd 		5f6b00h
	x				real4	0.0f
	y				real4	300.0f
	negate			real4	-1.0f
	
.code
	_main:
		; Save the current state of the stack.
		push ebp
		mov ebp, esp

		; Ensure our dll was loaded validily.
		mov eax, dword ptr ss:[ ebp + 0ch ]
		cmp eax, 1
		jnz @DLL_NOT_ATTACH

		; Allocate memory for the old protection type.
		; Store this location in ebx.
		push eax
		push 40h
		push 1000h
		push 4
		push 0
		call VirtualAlloc 
		mov ebx, eax

		; Unprotect the memory from 42c011h - 42c016h
		push ebx
		push 40h
		push 5
		push 42c011h
		call VirtualProtect 

		; Create a codecave in R_EndFrame that will call to our hook function.
		; e8h is the opcode to call, with the address of the call being calculated by subtracting
		; the address of the function to jump to from our current location.
		mov byte ptr ds:[ 42c011h ], 0e8h
		lea ecx, @R_EndFrame_Hook
		sub ecx, 42c016h
		mov dword ptr ds:[ 42c012h ], ecx

		; Reprotect the memory we just wrote.
		push ebx
		push dword ptr ds:[ ebx ]
		push 5
		push 42c011h
		call VirtualProtect

		; Free the memory we allocated for our protection type.
		push 4000h
		push 4
		push ebx
		call VirtualFree	

		; Restore eax and the stack.
		pop eax
		@DLL_NOT_ATTACH:
			leave
			retn 0ch

		; A wrapper function for COD4's native Draw_Text function
		;	eax = x
		;	push y on stack
		;	edx = text
		; The print_text function prototype is:
		; __fastcall void print_text(e34420h, char* text, 7fffffffh, *font, DWORD scale, DWORD x, DWORD y, RGBA colour, 3);
		@draw_text:
			push 0
			push 0
			sub esp, 10h

			; To load floats on the stack, we have to use fld and then fstp to pop them off 
			; the float stack and onto the function stack. 
			fld1
			fst dword ptr ss:[ esp + 0ch ]
			fstp dword ptr ss:[ esp + 8 ]
			fld dword ptr ds:[ ebx ]
			fstp dword ptr ss:[ esp + 4 ]
			fld dword ptr ds:[ eax ]
			fstp dword ptr ss:[ esp ]
			mov ecx, dword ptr ds:[ 84cd8ch ]
			push ecx
			push 7fffffffh
			push edx
			mov ecx, 6b4498h
			call dword ptr cs:[ ori_print_text ]
			add esp, 24h
			retn

		; Helper function to convert a 3D origin to 2D coordinates.
		;	edi = player origin
		;
		;	Returns 2D X value in variable X.
		@WorldToScreen:
			sub esp, 2ch
			; vAbsDistance = VectorSubtract( vWorldOrigin, refdef->Vieworg )			
			fld dword ptr ds:[ edi ]
			fsub dword ptr ds:[ 797618h ]
			fstp dword ptr ds:[ esp ]
			fld dword ptr ds:[ edi + 4 ]
			fsub dword ptr ds:[ 79761ch ]
			fstp dword ptr ds:[ esp + 4 ]
			fld dword ptr ds:[ edi + 8 ]
			fsub dword ptr ds:[ 797620h ]
			fstp dword ptr ds:[ esp + 8 ]

			; vRightView = refdef->Viewaxis[ 1 ]
			; vRightView[ 0 ] *= -1
			; vRightView[ 1 ] *= -1
			; vRightView[ 2 ] *= -1
			fld dword ptr ds:[ 797630h ]
			fmul dword ptr ds:[ negate ]
			fstp dword ptr ss:[ esp + 0ch ]
			fld dword ptr ds:[ 797634h ]
			fmul dword ptr ds:[ negate ]
			fstp dword ptr ss:[ esp + 10h ]
			fld dword ptr ds:[ 797638h ]
			fmul dword ptr ds:[ negate ]
			fstp dword ptr ss:[ esp + 14h ]

			; vRightTransform = DotProduct( vAbsDistance, vRightView )
			fld dword ptr ds:[ esp ]
			fmul dword ptr ss:[ esp + 0ch ]
			fstp dword ptr ss:[ esp + 18h ]
			fld dword ptr ds:[ esp + 4 ]
			fmul dword ptr ss:[ esp + 10h ]
			fstp dword ptr ss:[ esp + 1ch ]
			fld dword ptr ds:[ esp + 8 ]
			fmul dword ptr ss:[ esp + 14h ]
			fstp dword ptr ss:[ esp + 20h ]

			fld dword ptr ss:[ esp + 18h ]
			fld dword ptr ss:[ esp + 1ch ]
			fadd
			fld dword ptr ss:[ esp + 20h ]
			fadd
			fstp dword ptr ss: [ esp + 24h ]

			; vForwardTransform = DotProduct( vAbsDistance, refdef->Viewaxis[ 0 ] )
			fld dword ptr ds:[ esp ]
			fmul dword ptr ds:[ 797624h ]
			fstp dword ptr ss:[ esp + 18h ]
			fld dword ptr ds:[ esp + 4 ]
			fmul dword ptr ds:[ 797628h ]
			fstp dword ptr ss:[ esp + 1ch ]
			fld dword ptr ds:[ esp + 8 ]
			fmul dword ptr ds:[ 79762ch ]
			fstp dword ptr ss:[ esp + 20h ]

			fld dword ptr ss:[ esp + 18h ]
			fld dword ptr ss:[ esp + 1ch ]
			fadd
			fld dword ptr ss:[ esp + 20h ]
			fadd
			fstp dword ptr ss:[ esp + 28h ]

			; if( vForwardTransform < 0 )
			; return
			fldz
			fcomp dword ptr ss:[ esp + 28h ]
			fstsw ax
			test ah, ah
			jnz @continue
			add esp, 2ch
			retn

			@continue:
				; int centerX = refdef->Width / 2
				mov eax, dword ptr ds:[ 797608h ]
				cdq
				sub eax, edx
				sar eax, 1
				mov dword ptr ss:[ esp + 20h ], eax

				; x = centerX + ( ( centerX * vRightTransform ) / ( vForwardTransform * refdef->Fovx ) )
				fild dword ptr ss:[ esp + 20h ]
				fmul dword ptr ss:[ esp + 24h ]
				fstp dword ptr ss:[ esp + 18h ]
				fld dword ptr ss:[ esp + 28h]
				fmul dword ptr ds:[ 797610h ]
				fstp dword ptr ss:[ esp + 1ch ]

				fld dword ptr ss:[ esp + 18h ]
				fld dword ptr ss:[ esp + 1ch ]
				fdiv
				fild dword ptr ss:[ esp + 20h ]
				fadd
				fstp dword ptr ds:[ x ]
				add esp, 2ch
				retn

		; The display hook to R_EndFrame is responsible to iterating through all entities,
		; calculating their x values and displaying their name on screen.
		@R_EndFrame_Hook:
			pushad

			; Move cg_entities[ 0 ].lerpOrigins in edi
			mov edi, 84f2f4h

			; Move clientinfo[ 0 ].name into edx
			mov edx, 83927ch

			; Iterate through all the players, calculating their 2D coordinates and
			; displaying them to the screen.
			xor esi, esi
			entities_loop:
				; edi + 1a4h holds 1 if alive, 0 if dead.
				cmp dword ptr ds:[ edi + 1a4h ], 0
				jz @not_valid_entity

				; Compare the current clientNum with our player. Only display if they
				; are not the same.
				mov eax, dword ptr ds:[ edi + 0b0h ]
				cmp eax, dword ptr ds:[ 74e338h ]
				jz @not_valid_entity

				; Calculate and draw our esp.
				push edx
				call @WorldToScreen
				pop edx
				lea eax, x
				lea ebx, y
				push edx
				call @draw_text
				pop edx

				; Advance to the next player.
				@not_valid_entity:
					add edx, 4cch
					add edi, 1dch
					inc esi

					; Check if we are less than cg->maxPlayers.
					cmp esi, dword ptr ds:[ 74aa48h ]
					jl entities_loop

				; Restore the stack and original instruction.
				popad
				mov eax, dword ptr ds:[ 8c63b8h ]
				retn

	end _main