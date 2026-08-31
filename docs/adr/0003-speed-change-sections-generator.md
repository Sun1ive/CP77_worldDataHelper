# 3. Spline Speed Change Sections Generator

Date: 2026-08-30

## Status

Accepted

## Context

In Cyberpunk 2077's worldStreaming / node architecture, `worldSpeedSplineNode` uses `speedChangeSections` (`worldSpeedSplineNodeSpeedChangeSection`) to control vehicle and NPC velocity along spline trajectories.
Manually calculating meters from spline origin and entering dozens or hundreds of speed sections for complex road networks or quest paths is tedious and error-prone.

## Decision

Implement an automated **Speed Change Sections Generator** in CP77_worldDataHelper:
1. Support multiple generation strategies:
   - **Curvature Adaptive**: Automatically drops speed based on turn sharpness/angle between waypoints.
   - **Trapezoid (Ease In / Cruise / Ease Out)**: Start ramp, cruising speed, and braking zone.
   - **Linear Ramp**: Constant acceleration or deceleration.
   - **Uniform Segments**: Fixed distance or count intervals.
   - **Traffic Jitter**: Controlled random speed variations.
2. Provide an interactive ImGui table for manual inspection and fine-tuning.
3. Export directly to WolvenKit `worldSpeedSplineNodeSpeedChangeSection` JSON and clipboard.

## Consequences

- Modders can generate dozens of realistic speed sections along any recorded spline in seconds.
- Output matches WolvenKit `.streamingsector` and `worldSpeedSplineNode` schemas.
