# Core 05 reactor module

Original industrial visual asset inspired by the layered industrial language visible in the official AZ3 reference. No original game logo, map geometry or extracted game asset is included. This is an artistic scene asset, not a physically certified reactor design.

## Integration

Fast path: append the `Reactor_Core` collection from `reactor.blend`. The collection center is the world origin and units are meters. The collection contains no cameras, lights, world overrides or ground plane.

Rebuild path: import `reactor_asset.py` in Blender Python and call `build_reactor()`. The function creates a new collection rather than modifying existing collections. Executing the script as the main entry clears the current scene and writes the standalone asset, so run that only in a fresh Blender process.

## Dimensions and access

- Central containment shell: about 8 m diameter, total assembly about 14.12 m high.
- Main annular service deck: top 4.5 m, outer radius 7.05 m, east and west approximately 3.2 m guard openings for hall bridge connections.
- Upper annular deck: top 10 m, outer radius 5.1 m. East-only access opening approximately 1 m, connected to a caged fixed ladder. The west side is guarded.
- Six evenly spaced shell service risers plus four larger external coolant trunks are separate systems.
- Main ring platform has radial joists and knee braces; the top level has a mounting plinth, lid, removable panels, seam details, flange bolts and small service accumulators.

Actual front, right and top images use orthographic cameras at the same 17 m view scale. `reactor_beauty.png` is an additional oblique orthographic inspection view, not a concept image. These Workbench images verify geometry/material assignments, not final scene lighting. Camera settings are in `orthographic_manifest.json`.

Source reference: https://news.xbox.com/en-us/2026/06/30/reinventing-extraction-inside-delta-forces-most-ambitious-map-yet/

No UE runtime, character traversal or collision verification has been performed. Final hall bridges must meet the main deck at Z = 4.5 m and should preserve the access clearances.

## Main-ring clearance revision

The four large coolant trunks and their elbows were moved inward to X = +/-1.4 m, Y = +/-5.15 m. Evaluated mesh vertices (not loose curve bounding boxes) establish a maximum pipe/coupling radius of 5.626244 m within Z = 4.5–7.0 m. Against the guard inner radius of 6.885 m this leaves 1.258756 m of outer passing space in the north/south coolant sectors. Upper pipe anchors were raised to Z = 12 m, giving 1.96 m underside clearance above the upper platform. See `main_route_clearance.json` and `measure_route.py`; this is geometric clearance, not a UE character or climbing test.
