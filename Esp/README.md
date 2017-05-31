An ESP for COD4 that uses a hook in R_EndFrame and uses an external method of calculating 3D to 2D coordinates to display tags over all drawn entities.

The hack was written in mASM and needs to be linked as a dll. To do this:
```
\masm32\bin\ml /c /coff Esp.asm
\masm32\bin\Link /SUBSYSTEM:WINDOWS /DLL Esp.obj
```

![Hack Screenshot](screenshot.jpg?raw=true "Screenshot Hack")

Originally written on 2011/01/01 by attilathedud.
