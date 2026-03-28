# Nabla Path Tracer runtime compare from Nsight Graphics

This directory contains one paired `Nsight Graphics` `GPU Trace` probe for Nabla Path Tracer.

Protocol:
- `1` run per variant
- same capture point: `frame 1000`
- same effective render path:
  - geometry: `sphere`
  - effective method: `solid angle`
- runtime numbers below come directly from `Nsight Graphics` exports:
  - `FRAME.xls`
  - `GPUTRACE_FRAME.xls`
- measurement machine:
  - [`measurement_machine.md`](measurement_machine.md)

## Variant matrix

| Case | Checkout source | Nabla | DXC | SPIRV-Headers | SPIRV-Tools | Mode |
| --- | --- | --- | --- | --- | --- | --- |
| `master_source_off` | `master_runcheck` local worktree | [`e11b118dd2e80393b5b7eb309c6abb25f51a818c`](https://github.com/Devsh-Graphics-Programming/Nabla/commit/e11b118dd2e80393b5b7eb309c6abb25f51a818c) | [`d76c7890b19ce0b344ee0ce116dbc1c92220ccea`](https://github.com/Devsh-Graphics-Programming/DirectXShaderCompiler/commit/d76c7890b19ce0b344ee0ce116dbc1c92220ccea) | [`057230db28c7f7d1d571c9e61732da44815f2891`](https://github.com/Devsh-Graphics-Programming/SPIRV-Headers/commit/057230db28c7f7d1d571c9e61732da44815f2891) | [`91ac969ed599bfd0697a5b88cfae550318a04392`](https://github.com/Devsh-Graphics-Programming/SPIRV-Tools/commit/91ac969ed599bfd0697a5b88cfae550318a04392) | local `Release`, `SOURCE`, runtime `builtins OFF` |
| `devshfixes_upstream` | `unroll_dxc_df_upstream_check` local worktree | [`c13c33662c3733b54d9014988a5ac602ab0c3245`](https://github.com/Devsh-Graphics-Programming/Nabla/commit/c13c33662c3733b54d9014988a5ac602ab0c3245) | [`74d6fbbad7388813c65ae269b20f15b4e971df9c`](https://github.com/Devsh-Graphics-Programming/DirectXShaderCompiler/commit/74d6fbbad7388813c65ae269b20f15b4e971df9c) | [`10b37414a3c9269b9bd8861cc759bd7fdf09760d`](https://github.com/Devsh-Graphics-Programming/SPIRV-Headers/commit/10b37414a3c9269b9bd8861cc759bd7fdf09760d) | [`2c75d08e3b31a673726ce6be80ab528250247064`](https://github.com/Devsh-Graphics-Programming/SPIRV-Tools/commit/2c75d08e3b31a673726ce6be80ab528250247064) | local `Release`, `SOURCE`, runtime `builtins OFF` |
| `unroll_artifact` | CI install artifact from [`run 23599197849`](https://github.com/Devsh-Graphics-Programming/Nabla/actions/runs/23599197849) | [`262a8b72f295ec95d3cf83170f1768a43972c9ab`](https://github.com/Devsh-Graphics-Programming/Nabla/commit/262a8b72f295ec95d3cf83170f1768a43972c9ab) | [`07f06e9d48807ef8e7cabc41ae6acdeb26c68c09`](https://github.com/Devsh-Graphics-Programming/DirectXShaderCompiler/commit/07f06e9d48807ef8e7cabc41ae6acdeb26c68c09) | [`c141151dd53cbd5b1ced0665ad95ae3e91e8f916`](https://github.com/Devsh-Graphics-Programming/SPIRV-Headers/commit/c141151dd53cbd5b1ced0665ad95ae3e91e8f916) | [`2a730e127a32ac8b0713f5e1490d7b9be9d1cc9a`](https://github.com/Devsh-Graphics-Programming/SPIRV-Tools/commit/2a730e127a32ac8b0713f5e1490d7b9be9d1cc9a) | CI `Release install` artifact |

## Main Nsight result

| Variant | GPU frame ms | Dispatch count | Compute active | SM throughput | PCIe write GB/s |
| --- | ---: | ---: | ---: | ---: | ---: |
| `master_source_off` | `21.4304` | `2` | `83.2501%` | `35.5388%` | `2.62710` |
| `devshfixes_upstream` | `19.6157` | `2` | `82.9923%` | `38.2916%` | `2.64694` |
| `unroll_artifact` | `21.5935` | `2` | `83.9945%` | `34.3346%` | `2.62212` |

### Runtime deltas

| Comparison | Delta ms | Delta % |
| --- | ---: | ---: |
| `devshfixes_upstream` vs `master_source_off` | `-1.8147` | `-8.47%` |
| `unroll_artifact` vs `master_source_off` | `+0.1631` | `+0.76%` |
| `unroll_artifact` vs `devshfixes_upstream` | `+1.9778` | `+10.08%` |

## Main conclusion

The measured `latest upstream refresh` baseline is faster than `master_source_off` in this probe. At the same time `unroll_artifact` is effectively at parity with `master_source_off` here at only `+0.76%`, while the remaining gap appears only against `devshfixes_upstream`.

Taken together, the measured runtime cost points at the `unroll` side of the experiment, not at the generic `DXC/SPIRV-Tools upstream refresh`. That tradeoff is also aligned with the intent of the experiment: reduce shader build time aggressively while accepting a small runtime cost.

In practice this is also a strong argument for a development-oriented DXC optimization profile, for example an `-O1`-style mode. For the Nabla Path Tracer builds behind this comparison the shader-build wall time is about `10x` worse without that profile, while the measured runtime delta stays at `+0.76%` against `master_source_off` in this probe and at `+10.08%` against `devshfixes_upstream`; on other machines a simpler `average FPS` check across multiple methods, modes, and shapes placed the same runtime cost in the `5-8%` range. That is exactly the profile proposed in the paired PRs: for development use it delivers a major build-time win while keeping runtime impact effectively negligible in practice.

## Deeper Nsight signals from the same exports

Frame-level exports also show:
- `dispatch_count = 2` and `gr__ctas_launched_queue_sync.sum = 14401` in all three variants
- `unroll_artifact` has lower `SM throughput` than `devshfixes_upstream`
- `unroll_artifact` also shows higher total executed instructions and much higher `L1/LSU/shared` pressure than `devshfixes_upstream`

This points at a `compute-side codegen / execution-mix` difference with higher `L1/LSU/shared` pressure on the `unroll` side.

## Directory map

### Runtime stats
- [`master_source_off/stats.json`](master_source_off/stats.json)
- [`devshfixes_upstream/stats.json`](devshfixes_upstream/stats.json)
- [`unroll_artifact/stats.json`](unroll_artifact/stats.json)

### Machine spec
- [`measurement_machine.md`](measurement_machine.md)

### Executable locations
- `master_source_off`: [`runnable/master_source_off_minimal/31_hlslpathtracer.exe`](runnable/master_source_off_minimal/31_hlslpathtracer.exe)
- `devshfixes_upstream`: [`runnable/devshfixes_upstream_minimal/31_hlslpathtracer.exe`](runnable/devshfixes_upstream_minimal/31_hlslpathtracer.exe)
- `unroll_artifact`: [`runnable/unroll_artifact_minimal/31_hlslpathtracer.exe`](runnable/unroll_artifact_minimal/31_hlslpathtracer.exe)

### Capture files
- [`master_source_off/run01/master_source_off_frame1000_run01.ngfx-capture`](master_source_off/run01/master_source_off_frame1000_run01.ngfx-capture)
- [`devshfixes_upstream/run01/devshfixes_upstream_frame1000_run01.ngfx-capture`](devshfixes_upstream/run01/devshfixes_upstream_frame1000_run01.ngfx-capture)
- [`unroll_artifact/run01/unroll_artifact_frame1000_run01.ngfx-capture`](unroll_artifact/run01/unroll_artifact_frame1000_run01.ngfx-capture)

### Raw Nsight exports
- [`master_source_off/run01/gpu-trace/BASE/FRAME.xls`](master_source_off/run01/gpu-trace/BASE/FRAME.xls)
- [`master_source_off/run01/gpu-trace/BASE/GPUTRACE_FRAME.xls`](master_source_off/run01/gpu-trace/BASE/GPUTRACE_FRAME.xls)
- [`devshfixes_upstream/run01/gpu-trace/BASE/GPUTRACE_FRAME.xls`](devshfixes_upstream/run01/gpu-trace/BASE/GPUTRACE_FRAME.xls)
- [`unroll_artifact/run01/gpu-trace/BASE/GPUTRACE_FRAME.xls`](unroll_artifact/run01/gpu-trace/BASE/GPUTRACE_FRAME.xls)

### Startup logs
- [`startup_devshfixes_upstream/stats.json`](startup_devshfixes_upstream/stats.json)
- [`startup_unroll_artifact/stats.json`](startup_unroll_artifact/stats.json)
