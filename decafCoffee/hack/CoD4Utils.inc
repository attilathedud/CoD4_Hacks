; An include file that encapsulates hooking and drawing text. Includes common library calls.
;
; Originally written 2010/03/21 by attilathedud.

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

; A macro for Draw_Text that fills the appropriate structures and calls the original function.
@draw_text_fill macro x, y, text, colour, scale, font
	lea edx,x
	lea ebx,y
	lea ecx,text
	lea edi,colour
	lea eax,scale
	mov esi,font
	call @draw_text
endm	

.data
	ori_printtext dd 542f50h
	green real4 0.0f,1.0f,0.0f,1.0f
	red real4 1.0f,0.0f,0.0f,1.0f
	grey real4 0.5f,0.5f,0.5f,1.0f
	white real4 1.0f,1.0f,1.0f,1.0f
	blue real4 0.0f,0.0f,1.0f,1.0f
	scale1 real4 0.25f
	scale2 real4 0.30f

.code
		; A helper function to make detours. 
		;
		;	ebx = Old protection location.
		;	ebp+8h = Address to hook.
		;	ebp+ch = amount of bytes of original function(must be 5 or 6, 
		;			six means extra instruction is nop'd after)
		;	ebp+10h = New function
		;	esp+14h = jmpback = 1/callback = 0
		@hook_function:
			; Save the current state of the stack.
			push ebp
			mov ebp,esp

			; Unprotect the memory location.
			push ebx
			push 40h
			push [ebp+0ch]
			push [ebp+8h]
			call VirtualProtect 

			; Write a jmp or call opcode into the first byte of address given.
			mov eax,[ebp+8h]
			mov ecx,[ebp+14h]
			cmp ecx,1
			jnz @callback
			mov byte ptr ds:[eax],0e9h
			jmp @cont_hook
			@callback:
				mov byte ptr ds:[eax],0e8h

				; Get the address of the call being calculated by subtracting the address 
				; of the function to jump to from our current location.
				@cont_hook:
					mov ecx,[esp+10h]
					add eax,5h
					sub ecx,eax
					sub eax,4h
					mov dword ptr ds:[eax],ecx
					dec eax
					mov ecx,[ebp+0ch]
					cmp ecx,5h

					; If we have a 6 byte instruction, nop out the final byte.
					jle @nmtof
					add eax,5h
					mov byte ptr ds:[eax],90h
					sub eax,5h

					; Reprotect the memory.
					@nmtof:
						push 0
						push dword ptr ds:[ebx]
						push [ebp+0ch]
						push eax
						call VirtualProtect
						leave
						retn 10h
			
		; The wrapper around the internal Draw_Text function.
		; 
		;	ebx = y (float)
		;	edx = x (float)
		;	ecx = text (pointer)
		;	eax = scale (float)
		;	esi = font (pointer)
		; 	edi = colour (pointer/structure) ? 6b4518h = white
		@draw_text:
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
			