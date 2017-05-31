A POC that uses a hook in COD4's main game loop to call the internal print_text function and display the string "hello" on the screen.

The hack was written in mASM and needs to be linked as a dll. To do this:
```
\masm32\bin\ml /c /coff Print_Text.asm
\masm32\bin\Link /SUBSYSTEM:WINDOWS /DLL Print_Text.obj
```

![Hack Screenshot](screenshot.jpg?raw=true "Screenshot Hack")

Originally written on 2009/09/16 by attilathedud.
