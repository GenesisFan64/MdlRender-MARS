# MdlRender-MARS
3D Model renderer for the Sega 32X

Very minimal, supports Z sorting (painter's algorithm)

Notes:
- Game logic moved to the SH2, MASTER CPU

- MD code is loaded in RAM so the SH2 doesn't "fight" for permission to access the ROM (as noted in 32X.FAQ), now it only sends controller values to the COMM ports (because the SH2 side can't see them)

- Now the SLAVE CPU is doing all the work: modeling, sorting and drawing the polygons

Current TODOs:
- Fix RESET freezes (real hardware only)
- LINE FILL needs rewriting
- Optimize the texture drawing method



