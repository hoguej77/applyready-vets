# Apple platform integration plan

Updated July 30, 2026 for the iOS 27-only source and the Xcode 27 beta toolchain.

This plan turns “Siri, widgets, NFC, and 3D Touch” into supported Apple features without overstating what iOS permits or
putting veteran information on exposed system surfaces.

## Current build

| Apple surface | Current source status | Privacy boundary |
| --- | --- | --- |
| Siri, Spotlight, Shortcuts, and supported Action button flows | Implemented through App Intents for starting an application, opening Truth Lock, opening the LinkedIn builder, and saving a user-supplied job URL | Spoken responses never contain resume text, service history, disability information, clearance details, or job evidence |
| Share Sheet and AirDrop | Implemented with `ShareLink` for verified resume text/files and LinkedIn material | The veteran chooses the destination; copies that leave the app are controlled by the receiving app/service |
| Receive from Safari and job apps | Implemented through the `Save to ApplyReady Vets` URL/text Share Extension | Bounded protected inbox; unsafe URLs are rejected; existing job material is not replaced without approval |
| Haptic feedback | Implemented for successful copy actions | Confirmation only; no private content is encoded in the feedback |
| Haptic Touch / long-press context menu | Implemented on the final application handoff card | Offers open, copy, and system share actions; it does not submit or sign into another service |
| Automated platform QA | Siri metadata is extracted in Release builds; the UI suite runs Apple’s accessibility audit on welcome and import screens | The test launch deletes only the test Simulator workspace |
| Core Spotlight | Opt-in role/employer/platform/status/deadline indexing with direct navigation to the matching tracker record | Off by default; no resume text, notes, evidence, job-ad text, or files are indexed |
| WidgetKit | Small and medium next-application widget backed by a minimal App Group snapshot | Active count is minimal; role, employer, status, and deadline enter the snapshot only after a separate Settings opt-in, and privacy redaction replaces details while locked |

Apple’s current integration layer is
[App Intents](https://developer.apple.com/documentation/appintents). Apple describes it as the bridge to Siri,
Spotlight, Shortcuts, widgets, controls, and other system experiences. The current source uses that bridge without marketing the
app as “powered by Siri” or “powered by Apple Intelligence.”

## Widget design

The protected tracker now has real deadlines and statuses, so the safe first widget is implemented:

1. **Next Application** — shows active count in small and medium Home Screen families. It shows the next
   role/employer, status, and deadline only after the veteran separately opts in to application details in Settings.

Later candidates are Continue Application and Start a Packet after interactive intent/deep-link testing.

Widget privacy rules:

- Default to generic content on the Lock Screen.
- Never show resume bullets, military units, clearance status, disability/benefits information, contact details, job
  descriptions, employer correspondence, or Truth Lock evidence.
- Store only the minimum widget snapshot in the shared App Group, separately from the full protected workspace.
- Redact widget content when device protection or app privacy settings require it.
- Test every widget family, Dynamic Type, tinted rendering, StandBy, Smart Stack relevance, and stale/deleted workspaces.

The widget target and minimal snapshot contract now compile. Signed App Group behavior, stale/deleted records, tinted
rendering, both supported families, and physical-device privacy remain release gates.

## NFC boundary

Core NFC supports reading and writing compatible NFC tags; it is not the general iPhone-to-iPhone document transfer
channel for an ordinary App Store app. ApplyReady Vets must not place a resume or private application packet in an NFC
tag.

Permitted future NFC use, only if user research shows real value:

- Scan an ApplyReady Vets event/resource tag that contains a public HTTPS universal link.
- Write a public landing-page or organization referral link to a compatible tag after explicit confirmation.
- Resolve the link in-app and show its domain before opening it.

Not permitted in this product design:

- resume/job packet payloads on a tag;
- VA records, disability information, military identifiers, clearance data, or access tokens on a tag;
- claims that tapping two iPhones transfers the file through Core NFC;
- background tracking or silent tag collection.

For files, the supported route remains the system Share Sheet, AirDrop, Files, Mail, Messages, and user-approved
receiving apps. For an in-person handoff, a short-lived QR/universal link may be evaluated only after authenticated
hosting, expiration, deletion, and abuse controls exist.

Apple’s [Core NFC documentation](https://developer.apple.com/documentation/corenfc) defines the tag-reading/writing
surface and its entitlement requirements.

## “3D Touch” on modern iPhones

The product should use the modern interaction model rather than advertise 3D Touch hardware:

- Haptic Touch context menus for common actions.
- Home Screen quick actions such as **Start application**, **Save job link**, and **Open Truth Lock**.
- previews where they prevent opening the wrong document;
- swipe actions in a future application tracker;
- drag and drop on iPad where it improves document intake;
- restrained success/warning haptics;
- full keyboard and pointer support on iPad.

The current source includes the first useful context menu and copy-confirmation haptics. Home Screen quick actions remain a
physical-device milestone because Apple delivers cold- and warm-launch actions through scene lifecycle callbacks; they
must be implemented and tested end-to-end rather than added as nonfunctional menu entries.

Apple’s [Home Screen quick-action guidance](https://developer.apple.com/documentation/uikit/add-home-screen-quick-actions)
uses touch-and-hold on iOS 13 and later, with pressure input only on older 3D Touch hardware.

## Release order

1. Physically validate the existing App Intents, Share Extension, Share Sheet/AirDrop, context menu, and haptics.
2. Validate the implemented tracker, per-job workspaces, deadlines, packet versions, and privacy-safe widget App Group
   snapshot on signed devices.
3. Add user-approved local notifications and optional calendar handoff only after permission, interruption, and stale
   deadline testing.
4. Add fully routed Home Screen quick actions and physical-device cold/warm launch tests.
5. Evaluate public-link NFC/QR only after production universal links, authentication, expiration, deletion, and abuse
   controls exist.

NFC file transfer, exposed Lock Screen resume data, silent cross-app automation, and untested quick-action entries are
not on the roadmap.
