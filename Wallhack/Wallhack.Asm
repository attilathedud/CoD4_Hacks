; An internal wallhack for CoD4 that alters the render_fx of the engine's CG_AddRefEntity function.
;
; Originally written 2009/05/17 by attilathedud.

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

		; Unprotect the memory at 445481
		push ebx
		push 40h
		push 1h
		push 445481h
		call VirtualProtect	

		; The original call to CG_AddRefEntity in-engine looks like:
		; CG_AddRefEntity(&bone_origin, &cent, 0, 4, 5);
		; With the 4 being the render_fx value. By changing this to 3, we render entities
		; through walls.
		mov byte ptr ds:[445481h],03h

		; Reprotect the memory we just wrote.
		push 0
		push dword ptr ds:[ebx]
		push 1h
		push 445481h
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