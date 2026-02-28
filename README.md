# UE 5.4 C++ Radio System Starter (UMSP-compatible)

This repository provides a code-only starter implementation for an Unreal Engine 5.4 radio system that can be dropped into an existing project (including Ultimate Multiplayer Survival Pack).

## Included gameplay features

- **Physical radio actor** (`ARadioActor`) with static mesh, radio logic component, and widget component.
- **Multiple stations** via `URadioSubsystem` and `FRadioStationDefinition`.
- **Static while tuning** through a second `UAudioComponent` in `URadioComponent`.
- **Regional + global stations**:
  - Global music and global broadcast are always audible.
  - Regional stations are only audible inside `ARadioAreaVolume`.
- **Code-driven UI** (`URadioWidget`) with:
  - next / previous station buttons
  - volume slider
  - station label updates
- **Realistic timeline behavior**:
  - stations resolve playback using world/server time, so switching back lands at where the track should currently be.
- **Vehicle-ready integration**:
  - `IRadioVehicleInterface` lets vehicles expose an onboard `URadioComponent` cleanly.

## Files

- `Source/RadioSystem/Public/RadioTypes.h`
- `Source/RadioSystem/Public/RadioSubsystem.h`
- `Source/RadioSystem/Private/RadioSubsystem.cpp`
- `Source/RadioSystem/Public/RadioAreaVolume.h`
- `Source/RadioSystem/Private/RadioAreaVolume.cpp`
- `Source/RadioSystem/Public/RadioComponent.h`
- `Source/RadioSystem/Private/RadioComponent.cpp`
- `Source/RadioSystem/Public/RadioActor.h`
- `Source/RadioSystem/Private/RadioActor.cpp`
- `Source/RadioSystem/Public/RadioWidget.h`
- `Source/RadioSystem/Private/RadioWidget.cpp`
- `Source/RadioSystem/Public/RadioVehicleInterface.h`

## Integration notes for Ultimate Multiplayer Survival Pack

1. Add these classes into your game module and include them in the module build.cs dependencies:
   - `UMG`, `Slate`, `SlateCore`, `AudioMixer`, `NetCore`.
2. Use `URadioComponent` on:
   - world props (portable or placeable radios),
   - vehicle actors (through `IRadioVehicleInterface`).
3. Replace `BuildDefaultStations()` with your own station registration and `USoundBase` assets.
4. Keep authority station switching server-driven (already set with `ServerSetStation`) so multiplayer clients stay in sync.
5. Use `ARadioAreaVolume` in level areas to gate regional station reception.

## What you still need to wire in your project

- Assign actual sound assets to station tracks.
- Set widget class on `RadioWidgetComponent` and create matching UMG controls (`BindWidget` fields).
- Hook your UMSP interaction system so players can open radio UI and toggle power.
- Optionally add battery/vehicle ignition conditions before `PowerOn(true)`.
