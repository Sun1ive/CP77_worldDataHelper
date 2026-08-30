# 2. Test Actor Spawning and AI Spline Traversal

Spline testing uses Cyberpunk 2077's native `PreventionSpawnSystem` and `AIHumanComponent` / `AIMoveToCommand` queues directly via CET Lua rather than custom Redscript dependencies. This keeps spline preview self-contained within CET while accurately testing navigation on the game's native navmesh.
