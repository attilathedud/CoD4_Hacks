A POC that alters the internal function for displaying nametags on hover to display all nametags regardless of team.

The hack was written in mASM and needs to be linked as a dll. To do this:
```
\masm32\bin\ml /c /coff Nametag_Esp.asm
\masm32\bin\Link /SUBSYSTEM:WINDOWS /DLL Nametag_Esp.obj
```

![Hack Screenshot](screenshot.jpg?raw=true "Screenshot Hack")

Originally written on 2009/09/23 by attilathedud.
