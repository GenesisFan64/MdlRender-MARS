# MdlRender-MARS
3D renderer for the Sega 32X

Stable, supports Z sorting (painter's algorithm)

Notes:
- MASTER CPU will be used for the game logic (moving the player, camera, etc.)
- SLAVE CPU does all the visual work: modeling, Z sorting and drawing the polygons
- 68K code is loaded in RAM so the SH2 doesn't "fight" for permission to access the ROM (as noted in 32X.FAQ), currently it only sends controller values to the COMM ports (since the SH2 side can't see them)

Current TODOs:
- Fix RESET freeze (real hardware only)



