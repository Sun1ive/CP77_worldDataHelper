# World Data Helper

A Cyberpunk 2077 in-game developer tool built with Cyber Engine Tweaks (CET) and Codeware for inspecting world coordinates, measuring local 3D offsets, recording navigation splines, and inspecting streamed world nodes.

## Language

**Waypoint**:
A 3D spatial coordinate recorded in game space, stored as either an absolute world position or a relative offset from an anchor point.
_Avoid_: Node, location, spot

**Spline**:
An ordered sequence of waypoints and speed change sections used by world streaming and vehicle navigation systems.
_Avoid_: Path, track, route

**Marker**:
An ephemeral in-game visual entity (mesh) spawned in the world to indicate the position of a recorded waypoint.
_Avoid_: Flag, pin, beacon, ghost

**Offset**:
The relative coordinate difference between two points calculated with respect to local quaternion rotation.
_Avoid_: Delta, distance, gap

**Streamed Node**:
An engine world object or entity reference identified by hash or NodeRef within a streaming sector.
_Avoid_: Object, sector item

**Test Actor**:
A dynamic NPC or vehicle entity spawned into the world to test and preview spline navigation.
_Avoid_: Dummy, puppet, bot, preview entity

**Spline Traversal**:
The queued sequential movement of a Test Actor across recorded waypoints using the game's AI pathing or kinematic interpolation.
_Avoid_: Path execution, route walking, patrol
