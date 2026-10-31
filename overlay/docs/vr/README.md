# Original-game VR integration

Novalis runs through `main.rs`, `level_switch::load_bundle`, and the original ReRAC plugin chain. The terrain-only application is no longer the gameplay entry point. Calibration is an explicit diagnostic mode.

`vr/game.rs` installs OpenXR cameras on the original Bevy world. Each eye has the original world materials and a sky view with the same runtime pose/projection. Both use the existing render passes, including shadows and display effects. The original mono game frame remains available for the window, menu snapshots and menus shown inside the headset.

`input_map::PadFrame` reads a conventional PC gamepad through Bevy. Gamepads identified as VR or synthetic devices are skipped, and no OpenXR controller actions are bound to gameplay. `vr/game_input.rs` tracks headset focus for recentering. The original fixed tick consumes the resulting libpad2 bytes. Hero physics, animations, enemy updates, pickups, hits, weapon use, inventory, pause and respawn are still the original game systems. Keyboard input remains available. F8 recenters the headset.

The game remains at 60 Hz. The desktop 60 fps limiter is disabled in VR and OpenXR paces headset rendering. The original shared culling/LOD/lighting systems explicitly use the main camera instead of accidentally choosing an eye, sky or menu camera. Its culling envelope is expanded for head tracking; the single-view authored PS2 occlusion mask is disabled for VR.

Head tracking is relative to the game's third-person follow camera. Initial calibration waits for headset focus. The rig uses the original camera position and yaw while physical head motion supplies pitch and roll. The PC gamepad keeps the original movement and follow-camera controls. Recenter accounts for seated/standing height and room origin without teleporting the character. Game geometry remains in original units. The tracking root converts metres to those units; default scale is provisional at one game unit per metre.

HUD textures and the original menus are reused in head-relative panels. This is an initial panel presentation, not a redesigned spatial inventory. Weapon direction and targeting are the original game's, not tracked-hand aiming. Camera travel/cuts and smooth camera rotation follow the original game and still need comfort testing. Existing unported upstream behavior is inherited.

## Verification

`Run.ps1 -DesktopPreview -SmokeTestSeconds 12` boots the ORIGINAL game and renders two offscreen world views plus both sky views. `ORIGINAL_GAME_SMOKE_PASS` requires rendered frames, active game ticks and Ratchet meshes. This does not verify physical headset output. Logs report the hero position/state and entity/view counts without Windows captures.

Use `-Scene calibration` only for the diagnostic room. Its standalone trigger/teleport math and diagnostic targets are not used for gameplay. CPU loop intervals are not GPU duration; a successful launch does not establish a compositor performance budget or full campaign playthrough.

The monitor world and sky views are frozen during gameplay and ship sequences by default (`RC_VR_MIRROR_EVERY=0`), avoiding a third full world render. Menus and flat movies keep a full-rate window frame for their headset panels. Set `RC_VR_MIRROR_EVERY=1` for a full-rate PC view. This setting does not reduce headset updates or simulation ticks. The original external ship flight and streamed planet loading are documented in `PORTING_DECISIONS.md` at the repository root.
