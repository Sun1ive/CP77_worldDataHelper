# Feature Spec: Teleport Favorite Locations

## Overview
Adds the ability to save, name, manage, and instantly teleport to favorite locations (custom coordinate waypoints and engine NodeRefs) from the Teleport tab in the Cyber Engine Tweaks UI.

## Requirements
- Persist saved locations to `teleport_favorites.json`.
- Provide default Night City presets if no file exists.
- Save either the player's current live position or custom-typed coordinates / NodeRef.
- Search and filter saved favorite locations by name or coordinates.
- Actions per favorite:
  - **Teleport**: Warp directly to the coordinates / NodeRef.
  - **Load to Form**: Populate the input fields for manual inspection and modification.
  - **Copy**: Copy `Vector4.new(x, y, z, 1.0)` to clipboard.
  - **Delete**: Remove from list and update file.

## Data Schema
```json
[
  {
    "id": "fav_timestamp",
    "name": "Location Name",
    "type": 0,
    "x": -1390.28,
    "y": 1269.95,
    "z": 122.95,
    "yaw": 0.0,
    "nodeRef": ""
  }
]
```
