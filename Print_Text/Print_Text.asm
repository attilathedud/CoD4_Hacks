; A POC that uses a hook in COD4's main game loop to call the internal print_text function
; and display the string "hello" on the screen.
;
; Originally written on 2009/09/16 by attilathedud.

; System descriptors
.386
.model flat,stdcall
option casemap:none

VirtualAlloc proto stdcall :DWORD, :DWORD, :DWORD, :DWORD
VirtualProtect proto stdcall :DWORD, :DWORD, :DWORD, :DWORD
VirtualFree proto stdcall :DWORD, :DWORD, :DWORD

includelib \masm32\lib\kernel32.lib
	
.code
	main:
		jmp @F
			text db "Hello",0
			ori_printtext dd 542f50h
			coord real4 100.0
			scale real4 0.25
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
		lea ecx,@draw_text
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
			
		; Our draw_text codecave saves all registers, calls the engine's print_text
		; routine, and then restores the original function. The print_text function prototype
		; is:
		; print_text( unknown, text, unknown, unknown, x, y, scale, RGBA, 3 )
		@draw_text:
			pushad
			
			; To load floats on the stack, we have to use fld and then fstp to pop them off 
			; the float stack and onto the function stack. 
			fld dword ptr ds:[scale]
			mov eax,6b4518h
			push 3
			push eax
			mov eax,0f8d65ch
			sub esp,0ch
			fstp dword ptr ss:[esp+8]
			fld dword ptr ds:[coord]
			fstp dword ptr ss:[esp+4]
			fld dword ptr ds:[coord]
			fstp dword ptr ss:[esp]
			push eax
			push 7fffffffh
			lea ecx,text
			push ecx
			push 00e34420h
			call dword ptr cs:[ori_printtext]
			add esp,24h
			popad

			; The original instruction
			mov edx,dword ptr ds:[esi+0d4h]
			retn
			
	end main