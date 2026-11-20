# WiZ Sync Box — Phase 4A (native iOS)

## Scope
11 living-room WiZ bulbs; manual single/multiple-bulb RGB test over local UDP 38899.
This is NOT yet camera-to-light synchronization. No paid SDK or server is used.

## Why this architecture
- `Core`: device model, eight-zone mapping, RGB and protocol payloads
- `Services`: UDP transport, persisted configuration, rate-limited coordinator
- `App`: native SwiftUI one-bulb connectivity test
- `Tests`: deterministic payload, address, and mapping checks

## Windows-only workflow
1. Create a GitHub repository (private recommended), upload ALL files preserving folders, including `.github/workflows/ios-ci.yml`.
2. Enable GitHub Actions; the macOS runner installs XcodeGen and compiles/tests the project without signing.
3. GitHub Actions success proves compilation and simulator tests only; it does NOT produce an installable signed iPhone app.
4. For physical iPhone installation, obtain Apple Developer Program membership and configure signing with a trusted hosted macOS workflow or use a Mac temporarily. Do not put certificates, provisioning profiles, API keys or Apple credentials in the repository.
5. On iPhone allow Local Network permission, connect iPhone and bulbs to same reachable Wi-Fi LAN, and set a bulb's IP in the app.
6. Enable ONLY one bulb first; tap Test Red/Green/Blue; physically verify changes.

## Protocol
Unicast UDP JSON to bulb port 38899:
`{"method":"setPilot","params":{"state":true,"r":255,"g":0,"b":0,"dimming":80}}`
A UDP send completion is NOT a device acknowledgement. Future version should add `getPilot` responses, retries, bulb capability detection, and adaptive rate limiting.

## Future Phase 4B
AVFoundation camera, quadrilateral TV calibration, eight-zone extraction, exposure/white-balance management, temporal smoothing, RGBW handling, device discovery, multicast/broadcast entitlement review, background restrictions and energy profiling.

## Notes
- Native app remains foreground while camera is active.
- Some WiZ models may not support full RGB; verify bulb capabilities.
- Reserve or DHCP-pin bulb IP addresses in router once identified.
- Avoid sending commands to all 11 at full frame rate; stagger and rate-limit.
- This code has NOT been compiled on Xcode in this environment; CI will be the first build verification.
