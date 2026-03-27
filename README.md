# CopperFire

A zen painting canvas for iOS and iPad. Press and hold to ignite glowing brush strokes that shift through warm copper, deep orange, rose, violet, indigo, and deep teal.

## About

CopperFire renders overlapping radial gradients using screen blending to create luminous, additive light effects on a dark canvas. The color palette cycles through a copper-to-teal gradient based on how long you hold. Particles drift and fade around your touch point.

- **Press & hold** anywhere to paint
- **Pinch** to change brush size
- **Clear** to start over

No accounts. No tutorials. No undo. Just you and the flame.

## Requirements

- iOS 17.0+ / iPadOS 17.0+
- Xcode 15+

## Building

```bash
git clone https://github.com/thatBassetMug/CopperFire.git
cd CopperFire
open CopperFire.xcodeproj
```

Build and run on a device or simulator. No dependencies.

## Architecture

```
CopperFire/
  App/         CopperFireApp entry point, assets, privacy manifest
  Models/      CopperFireModel (drawing engine), CopperGradient (color system)
  Views/       ContentView (gestures/timer), CopperCanvasView (Canvas rendering)
```

The drawing engine uses a `CGContext` paint buffer with radial gradients stamped along the touch path. Particles are updated at 60fps and rendered with screen blend mode via SwiftUI `Canvas`.

## License

All rights reserved.

## Support

- [Report an issue](https://github.com/thatBassetMug/CopperFire/issues)
- [Buy me a coffee](https://ko-fi.com/thatbassetmug)
