; A POC that alters the internal function for displaying nametags on hover to display
; all nametags regardless of team.
;
; Originally written on 2009/09/23 by attilathedud.

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

		; Unprotect the memory from 42dea4h - 42dea9h
		push ebx
		push 40h
		push 5h
		push 42dea4h
		call VirtualProtect	

		; Enemy vs. Friendly nametags are determined by a jnz at 42dea4h. By changing this
		; to a jmp, both friendly and enemy names will be displayed.			
		mov byte ptr ds:[42dea4h],0e9h
		mov dword ptr ds:[42dea5h],0000020ah

		; Since a short jnz is 6 bytes and a short jmp is 5, nop out the remaining byte.
		mov byte ptr ds:[42dea9h],90h

		; Reprotect the memory we just wrote.
		push 0
		push dword ptr ds:[ebx]
		push 5h
		push 442dea4h
		call VirtualProtect 	

		; Unprotect the memory from 42e1ach - 42e1b2h
		push ebx
		push 40h
		push 6h
		push 42e1ach
		call VirtualProtect 

		; The code at 42e1ach determines whether or not the cursor is hovered over an
		; entity. By nopping it, it will display all nametags. A loop is used to nop out
		; the 6 bytes.
		xor ecx,ecx
		@@:
			mov byte ptr ds:[42e1ach+ecx],90h
			inc ecx
			cmp ecx,6
			jl @b

		; Reprotect the memory we just wrote.
		push 0
		push dword ptr ds:[ebx]
		push 6h
		push 42e1ach
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
	end main