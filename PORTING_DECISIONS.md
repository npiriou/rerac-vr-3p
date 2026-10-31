# Mainline VR history review for the third-person build

This review covers every commit reachable from the mainline history after historical third-person commit `e993e8a` through `62dc122`, in chronological order. **Kept** means the behavior or fix is present in this local overlay, sometimes through a later consolidated implementation. **Excluded** means it is intentionally absent because the player uses the original follow camera and a standard PC gamepad. A change described as inherited already exists in the pinned ReRAC base; it needs no new overlay code. These are code decisions, not claims of headset validation. No game run or tests were performed for this review.

## Resulting third-person contract

- The player launcher starts at the original front end and keeps saves beside the game. Scenario presets and inventory grants are kept only in the ignored local debug checkout; they are absent from the committed overlay and player package.
- The original PC gamepad remains the only game controller. The headset adds stereo and head movement around the original third-person camera. OpenXR controller actions are not mapped to gameplay.
- The native external ship flight and authored boarding/landing shots remain visible in stereo. The extra flat screen is not drawn for `Mode::Ship`; real flat movies and menus still use their panel.
- The mode-6 Ratchet scene actor remains visible during boarding and landing. The native gameplay Ratchet and his head item are hidden during those shots; the original scene draws its own Ratchet and Clank actors. Clank's scene actor was never subject to the first-person pilot mask.
- The native desktop world and sky cameras are frozen during gameplay and ship sequences by default (`RC_VR_MIRROR_EVERY=0`). Menus and flat movies refresh the window because their panels use the native frame. The two headset eyes continue rendering every frame.
- Pipelined rendering, single-threaded camera schedules, one transparent sort, stale fullscreen-bind-group refresh, and wide headset culling are included. The old PS2 occlusion mask is disabled because it is authored for one narrow camera.
- The destination is prepared and streamed during an interplanetary flight. Mesh and image insertion, tie/shrub spawning, and old-level cleanup are spread across frames; the flight waits for GPU readiness. Native play setup, Ratchet attachments, menu models and vendor setup occur at the landing cut. A black-frame handshake covers non-flight level changes.

## Commit-by-commit decisions

| Mainline commit | Kept in third person | Excluded and reason |
| --- | --- | --- |
| `3ee729e` first-person snapshot | Original engine world, collisions and native pad path remain the foundation. | Tracked hands, room-scale movement and first-person weapons require VR controllers and would replace the requested follow-camera play. |
| `8030ed2` first-person arsenal and UI | The original weapons, gadgets, travel and save systems remain active; later native travel fixes are ported below. | Physical weapon aiming, controller haptics, spatial vendor/PDA/pause screens, hand ledges and weapon-mounted Visibomb display depend on tracked controllers or first-person placement. |
| `8bc725f` launch modes and controls | The normal front-end launch and original PC gamepad path are kept. | Debug starts, inventory grants and planet unlocks remain local only and are excluded from the player overlay. Headset-driven heading, gadgets and rail camera serve first-person play. |
| `9434681` pipelined rendering | Bevy pipelined rendering is enabled by default; `RC_VR_PIPELINED=0` remains a diagnostic opt-out. | The detailed `VR_PERF` stage logger is instrumentation rather than an FPS improvement and was not imported. |
| `761d39c` render work reduction | Frozen desktop world/sky mirror, single-threaded Core3d/Core2d camera schedules and the consolidated transparent sort are ported. | Early GPU command submission was removed upstream after headset A/B measurement showed no gain. |
| `5c423d1` deferred xrEndFrame experiment | The conclusion of its headset measurement is retained. | Deferred `xrEndFrame` made performance about 4 fps worse and was removed upstream; it is not reintroduced. |
| `bc5f0fa` final performance pass | The stale fullscreen-material bind-group fix and the measured render optimizations are ported. | Experimental submission paths and optional high-volume performance logging are left out for the reasons above. |
| `356f52a` rails, ledges and weapons | Native gamepad rail and ledge behavior is inherited. | Hand reach, support grip and physical Hyper Strike need controller poses; their camera changes serve first-person comfort. |
| `97f91ad` crank and cinematics | Native ship transition and actor progression are retained, with later loading fixes ported. | Wrench-driven cranks, first-person cutaway bypass, listener relocation and pilot-seat eye would change the requested third-person cinematics. |
| `225116e` utility gadgets | Native gamepad Trespasser and Hydrodisplacer controls, menus and item updates are inherited. | Tracked wrench return, physically plugged gadgets, panel repositioning and hand solids solve first-person interaction problems. |
| `01fe94f` loading stall and ship opening | Destination overlay/item tables are cached per level and built with the loader; spawn reads the destination level. | Physical Clank/Giant Clank, grip ledges and cockpit-seat fixes have no third-person controller or eye equivalent. |
| `81c198f` Clank, cutscene eye and mines | The Umbris mine attacker-class correction is ported; native cutscene camera and gamepad Clank remain. | Physical fists, hand-ledges, tracked wrench spin and first-person actor eye placement are excluded. |
| `cce0130` eye heights and taxis | The native carrier and ledge code remains the gamepad path. | Model-height eye offsets, two-hand pull-ups and the room-scale taxi floor sweep address first-person tracking only. |
| `4be94fc` English code policy | All new identifiers, code comments, log text and script text follow the English-only project rule. | No gameplay feature is attached to this policy commit. |
| `db5b258` headset visibility and cockpit | The render-eye culling for mobys, ties, tfrags and shrubs, including native-view union when needed, is ported; ship visibility through loading is retained. | Cockpit eye, hand-aimed turrets, Hologuise hands/salute and actor-eye cutscenes conflict with the follow camera and PC gamepad. |
| `cdb23b8` VR Options and Oltanis | Travel/attachment cleanup around streamed arrivals is retained, including the no-landing path. | Worn helmet/boots rendered around a first-person eye and the VR Options page are unnecessary in the external camera. |
| `dab5272` loading cleanup and reach | Cached destination item data, cleanup-worker disposal and level-swap phase logging are ported. | Rail-eye prediction, visor, tracked wrench reach, hand Hyper Strike and camera-flip option serve first-person play. |
| `6b12c19` movement and effects | Glow billboards use the headset render eye where the native camera differs. | Body/gaze heading, sideways VR movement, physical Walloper, controller-driven quick select and hand-wrench audio should not override native pad behavior. |
| `4f8e74f` headset button glyphs | The original menu button mapping is preserved for the PC gamepad. | Repainting PS2 icons as VR controller buttons and rebinding headset shoulders would give the wrong instructions here. |
| `acb5d6a` merge | Source history was reviewed; no independent gameplay change. | Merge/build-record metadata has no separate behavior to port. |
| `041216d` streamed destination | Prepared tfrag/tie/shrub/moby assets and entity lists, per-frame stream budgets, deferred old-level cleanup, GPU readiness and a destination warmup view are ported. | The detailed per-schedule `VR_HITCH frame` telemetry is not required for the loading behavior; stream and swap logs remain. |
| `f778161` landing setup | Gameplay, attachments, menu models and vendor setup wait for the landing cut; the departure play state continues the flight. | No first-person-only feature is needed from this commit. |
| `991a2f9` merge | The streamed-loading branch content is represented by the preceding two rows. | Merge metadata is not a second implementation. |
| `22db989` wrench recall | Original gamepad weapon selection is inherited. | Tracked wrench recall and controller-trigger quick-select paging do not exist in this mode. |
| `b8894e8` hoverboard steering | Native stick steering stays in control. | Physical side lean, headset-heading steering, VR boost and trick bindings would change normal gamepad input. |
| `a29099a` hoverboard tuning | Native board weapon and race controls remain inherited. | Lean rate, body-heading start and hand-aimed Kalebo III weapon depend on first-person tracking. |
| `af83187` board spring | The native stick spring already exists in the gamepad path. | Lean added to that spring requires physical tracked movement and is excluded. |
| `e33d92d` one-click release | The Windows player launcher, first-run ISO extraction, self-contained release zip and local build scripts are included after the local gamepad sessions. | The first-person executable, controller-specific settings and its package branding do not belong in the third-person release. |
| `78012f0` path cleanup | Local scripts resolve their own checkout and record local build hashes. | Mainline documentation/build-record rewrites do not change this overlay's behavior. |
| `3449fea` slot pointer | Original gamepad slot selection is inherited. | VR laser pointer targets and its focus fix are irrelevant without a tracked pointer. |
| `3b1d94d` death reload | Clearing stale draw callbacks on death reload is ported to prevent the Quartu crash. | No related change was excluded. |
| `cc31e9e` Giant Clank fist | Native Giant Clank combat remains active on the gamepad. | The tracked fist sweep and strike window are specific to physical punches. |
| `27e79c1` body and ship views | The native ship hull is updated with its riders; the third-person authored shots remain. | Headless player body option, neck-pivot eye, first-person menus, pointer fixes, hand actions and body-specific debug presets are not requested. |
| `53c5297` Drek arena | Native held-camera/countdown rules remain inherited. | The workaround for removing VR cinematic holds applies only to first-person tracked play; the trailer/release changes are unrelated. |
| `3340753` trailer thumbnail | No gameplay change. | Marketing art is outside this local gameplay port. |
| `8a830cb` feedback and debug level | Visible dynamic enemies use the headset render eye for activity/culling. | Direct debug planet selection remains local only. Akimbo, seated/standing VR Options, hand decoy positioning and pointer confirmation require the first-person UI. |
| `f684418` board/body options | Native board and menu layout remain. | Body-in-head rendering, side-on eye, lean reference and VR Options layout are first-person features. |
| `d05cf92` final hoverboard/turrets | Native left-stick hoverboard and turret inputs are preserved. | Tracked turret aiming and hiding first-person hands have no role in PC gamepad third person. The player package is built separately for this release. |
| `62dc122` smooth VR turning | The native right-stick follow-camera control is preserved. | Snap/smooth headset yaw, gesture-history handling and VR Options persistence belong to first-person controller turning and would interfere with ordinary gamepad camera orbit. |

## Follow-up corrections

- Boarding and landing: the first-person pilot mask also hid Ratchet's class-0 scene actor in this third-person build. The actor now follows the scene's own hidden flag, like Clank's class-10 actor. The gameplay body's head attachment is hidden while the scene actor is active, along with the other non-extra attachments; always-on extras still follow the scene actor. The ship and camera shots are unchanged.
- Turret reticle: the screen-centred HUD now faces the turret's own script-camera forward vector in the tracking root. Its position is anchored to the recentered game camera, so head rotation and small physical movements do not steer the reticle. The gamepad remains responsible for turning and firing the turret.
- The earlier debug destination-list correction is retained only in the ignored local debug checkout. The player package contains no debug launch mode or scenario presets.

## Verification boundary

The overlay applies to pinned upstream `89c87e98f9d8296187df2a6310c67b32144090d3`. Its guarded patch anchors and VR/non-VR compilation can be checked without running tests. Headset performance, the complete campaign, save/load flow, planet changes and exact cutscene appearance still require gameplay verification. The local debug sessions and previous build records are separate from the player package.
