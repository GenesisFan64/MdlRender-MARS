# MdlRender-MARS

**OBSOLETE, Restarted as Shinrinx-MARS https://github.com/GenesisFan64/Shinrinx-MARS **

A 3D polygon renderer system for the Sega 32X

Using video mode 1, 256-color indexed, supports triangles and quads simultaneously, materials supported are: solid colors and textures mixed, textures have unlimited width and height, the only limit is the ROM size

Automaticly sorts faces using painter's algorithm

Notes:
- MASTER CPU is used for the game logic (moving the player, camera, etc.), for the sound: the PWM should be driven here using an interrupt
- SLAVE CPU is totally busy doing all the visual work: modeling, sorting and drawing the polygons
- On the Genesis side: The 68K code is loaded in RAM so the SH2 doesn't "fight" for permission to access the ROM (as noted in 32X.FAQ), it only sends controller values to the very last COMM ports: 12 and 14 (since the SH2 side can't see them)

Current issues:
- Reseting freezes the program (Real hardware only)
- Some models might crash all the system, needs checking (Real hardware only)
