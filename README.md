# MdlRender-MARS
A 3D polygon renderer system for the Sega 32X

Using video mode 1, 256-color indexed
Supports solid colors and textures, automaticly sorts faces using painter's algorithm

Notes:
- MASTER CPU is used for the game logic (moving the player, camera, etc.), the PWM should be driven here using an interrupt
- SLAVE CPU does all the visual work: modeling, Z sorting and drawing the polygons
- On the Genesis side: The 68K code is loaded in RAM so the SH2 doesn't "fight" for permission to access the ROM (as noted in 32X.FAQ), it only sends controller values to the very last COMM ports: 12 and 14 (since the SH2 side can't see them)

Current issues:
- Reseting the program freezes (real hardware only)
- Points outside of the camera doesn't calculate correctly, textures get messed up
- OOB face checking needs rewriting
