# Source controls and noise

Source revisions are pinned in assets/source_controls.json and THIRD_PARTY_NOTICES.md.
Defaults come from saved ShaderMaterial values, rather than uninitialized shader declarations. Original startup scripts sometimes randomize these values; the saved scene gives a reproducible baseline here.

| Control | Source | Current policy |
|---|---|---|
| Planet pixels | GUI.gd input clamp 12..5000, initial 100 | Same |
| Sky sampling pixels | GUI output dimensions 100..3000, initial 200 | Same numeric range; cubic face resolution is a separate new setting |
| Rotation | Shader 0..6.28 radians; scenes 0 or 0.2 | Radians, same per-type scene defaults |
| Surface/cloud/nebula/dust OCTAVES | Shader hint_range 0..20 | Same, shader loop actually supports 20 |
| Cloud threshold | Cloud shader 0..1 | Same threshold direction: larger hides more cloud |
| Cloud stretch | Cloud shader 1..3 | Same bounds and per-type scene values |
| Cloud curve | Cloud shader 1..2 | Same bounds and per-type scene values; spatial bend adapted to 3D |
| Land threshold | LandMasses 0..1, scene .633 | Same |
| Lake threshold | IceWorld 0..1, scene .55 | Same values; 3D lake field differs |
| Noise size | No hint_range in original shaders | Original per-type scene defaults; numeric entry with no invented min/max |
| Nebula/dust layers | Nebulae.tres 3 / StarStuff.tres 8 | Same |

Planet source defaults (ordered as the type selector):

| Type | Surface size | Surface octaves | Cloud size | Cloud octaves | Cloud threshold | Stretch | Curve |
|---|---:|---:|---:|---:|---:|---:|---:|
| Rivers | 4.6 | 6 | 7.315 | 2 | .47 | 2 | 1.3 |
| DryTerran | 8 | 3 | - | - | - | - | - |
| LandMasses | 4.292 | 6 | 7.745 | 2 | .415 | 2 | 1.3 |
| NoAtmosphere | 8 | 4 | - | - | - | - | - |
| GasPlanet | 9 | 5 | 9 | 5 | .538 | 1 | 1.3 |
| GasPlanetLayers | 10.107 | 3 | 10.107 | 3 | .61 | 2.204 | 1.376 |
| IceWorld | 10 | 3 | 4 | 4 | .546 | 2.5 | 1.3 |
| LavaWorld | 10 | 3 | - | - | - | - | - |

The defaults/reset controls follow the selected type. A slider can put an interior default at its midpoint without changing the actual source values or endpoints. Boundary defaults remain boundary values. Fields with no authored limits use numeric entry.

## Explicit adaptations, not false one-to-one matches

The 3D generator combines layers that had separate materials in the source. It does not yet reproduce every original material or expose every original shader uniform separately. River width, crater field/depth, polar ice, gas stripe count/warp, ring geometry width, 3D dithering, global seed and per-layer offsets use this generator's algorithms. They are not claimed to have original defaults. In particular the source ring width is a 2D shader thickness, not a mesh radius ratio; source Galaxy swirl is not gas stripe distortion. Geometry, real-time lighting, voxel resolution, cloud height and animation controls are new.

## Where noise comes from

There is no noise PNG to reuse or replace. noise_core.gdshaderinc contains shared procedural code: seed-dependent lattice values, interpolation, then multiple noise layers (fBm). Surface, cloud, gas and nebula use different positions, scales, offsets, branches and palettes. Sharing this code does not mean sharing an identical noise pattern. stars-special.png is a bright-star sprite atlas, not a noise texture.

The current spatial noise is 3D value noise; original tools generally evaluate 2D noise. Copying their tuning values does not prove identical visual results in 3D. Animation changes the sampling coordinates with periodic time functions. Preview, frame export and copied implementation context use the same core shader and parameters.

## Voxel cloud clearance

Cloud shell radius uses the actual farthest surface vertex plus the configured height. It also accounts for the shell triangles lying slightly inside their vertex radius. This keeps cloud triangles outside voxel corners, including coarse voxels. test_cloud_bounds.gd verifies the minimum height at voxel diameters 12, 32 and 64.

## Shared pixel / voxel density

The `pixels` value now controls cube count across the planet diameter in voxel mode, including odd numbers. The separate `voxel_size` field is retired; old configurations can still be loaded, but its value is ignored in favor of `pixels`. Surface and ring meshes omit hidden neighbor faces. Every face of one cube has the same base color. Dynamic materials sample noise at the cube center instead of painting detail across a face. Real-time lighting still shades faces according to their normals.

Clouds and rings are also voxel meshes in voxel mode, with the same cell edge length `2 * radius / pixels`. Cloud cubes remain entirely outside the surface envelope plus cloud height. Cloud geometry retains all six faces, including initially transparent cells, so animation can reveal a whole cube and its sides later. Their vertex-color alpha clips the static GLB at time zero; animated integration must update per-cell color and alpha as described by the shared noise contract. Rings form a one-cell-thick annulus and keep the configured tilt, gaps and palette. These additional real cubes increase mesh/export size.

The present mesh builder supports voxel density through 256. Larger requested values report an explicit error rather than silently lowering density; sphere pixel density retains its original range. Preview, export, and implementation context share the same density and per-cell sampling rule. Run `--script res://tests/test_voxel.gd` with a real graphics renderer to check odd/even geometry and uniform per-cell animated colors.
