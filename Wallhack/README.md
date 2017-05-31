An internal wallhack for CoD4 that alters the render_fx of the engine's CG_AddRefEntity function.

The hack was written in mASM and needs to be linked as a dll. To do this:
```
\masm32\bin\ml /c /coff Wallhack.asm
\masm32\bin\Link /SUBSYSTEM:WINDOWS /DLL Wallhack.obj
```

![Hack Screenshot](screenshot.jpg?raw=true "Screenshot Hack")

Originally written 2009/05/17 by attilathedud.
