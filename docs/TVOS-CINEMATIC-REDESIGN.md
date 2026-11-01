# tvOS cinematic presentation change

Baseline: `7fbd586dca4438d4b696ec0426fb455794554e1a` (public `VortXTV/VortX` main, 2026-10-31). Development branch: `feature/tvos-cinematic-redesign`.

This change keeps the existing engine, native top tab shell, page navigation stacks, profile and account ownership, source resolver, and playback presenter. The visual direction is restrained dark chrome, bright readable text, full-bleed cached art, white primary controls, and gentle focus lift. It uses VortX artwork and system fonts; no third-party service branding or sample catalogues were added.

## Architecture from source

| Responsibility | Source and current behavior |
| --- | --- |
| App entry and state | `app/SourcesTV/VortXTVApp.swift` starts the app and bridge; `RootView` in `RootTabView.swift` keeps the shell mounted under the player and presents the profile picker as a real modal. |
| Tabs and navigation | `RootTabView.swift` owns native tvOS `TabView`: Home, Discover, Live TV, Library, Search, Add-ons, Settings. Four optional tabs retain their saved visibility preferences. Each content page owns its existing `NavigationStack` or receives the Search host stack. |
| Home/catalogues | `HomeView.swift` reads `CoreBridge` board rows, profile-aware Continue Watching, For You, Trakt/SIMKL and media-server rails, and arranged Home rows. `DiscoverView.swift` and `BrowseGridView.swift` retain real catalogue selection, filters and pagination. |
| Focus/art | `SharedUI.swift` owns the debounced `FocusedItemModel`, `BrowseHeroBackdrop`, `PosterCard`, `ProgressStripe` and cached/downsampled image loading through `PosterImageLoader`. `DetailView.swift` owns `FullBleedBackdrop`, metadata, sources and episodes. |
| Detail and streams | `DetailView.swift` contains movie, series and live layouts, `CoreSeasonedEpisodes`, `CoreEpisodeStreams`, and `CoreStreamList`. The latter merges the engine with the existing debrid, media-server and source-index contributors; its stable, bounded rows preserve focus during updates. |
| Player | `RootTabView.swift` owns `PlayerPresenter`; `TVPlayerView.swift` owns remote, source, subtitle/audio and recovery UI. `app/Sources/Player` and `VortXAetherKit` contain the player adapters. |
| Account, profile and preferences | `SourcesShared/ProfilesView.swift`, `AddonsView.swift`, `AddonStoreView.swift`, account services and `CoreBridge` retain identity and mutations. `SettingsView.swift` and `TVSettingsCategoryPolicy.swift` retain the existing `@AppStorage` keys and searchable section inventory. `Theme.swift`/`ThemeManager.swift` keep the user's appearance controls. |
| Build | `app/project.yml` defines the Full/Lite/Top Shelf targets; `scripts/generate-native-apple-project.rb` creates the approved native project spec; `.github/workflows/release-tvos.yml` documents native ABI, package and signing gates. |

## Feature preservation and screen replacement

The replacement is an in-place presentation of the same views. Rows and actions not named in the styling changes remain on their original routes.

| Existing tvOS surface | Redesign and route preserved |
| --- | --- |
| Home and Continue Watching | `HomeView` uses the same engine/profile/remote selection and arrangement. A focus-reactive hero action opens the existing detail/source path for ordinary titles. Private/remote history items retain their guarded rail route. Posters and progress remain `PosterCard`/`ProgressStripe`; long-press actions remain. |
| Discover, catalog grids and search | `DiscoverView`, `BrowseGridView` and `SearchView` retain add-on catalogue requests, type/genre chips, pagination, advanced filters, the native tvOS search host and existing provider grouping. Reusable headers and tvOS shared type/focus tokens update the presentation. |
| Library, Watchlist, collections, downloads and network shares | `LibraryView`, `TVWatchlistView`, `TVSmartCollectionsView`, `TVDownloadsView` and `TVNetworkSharesView` keep saved items, progress, sorting, filters, watched actions, device-local downloads and media-server/network routes. Headers and shared poster/focus styles change; storage/sync does not. |
| Movie, series, episode and live details | `DetailView` retains watch/resume, trailers, library/watchlist, cast, recommendations, seasons, episode progress, source list and quality/player choices. Series now uses the same resolved logo/title component as movies; episode panels use quieter solid surfaces and a white focus ring. `LiveView` and `TVLiveGuideView` retain EPG and stream routing. |
| Add-ons and store | Shared `AddonsView` and `AddonStoreView` keep installation, ordering, visibility, configuration, manifest actions and external configuration handoff. tvOS-only headers change their presentation. |
| Profiles, account, backup | `ProfilePickerView` and its edit/recovery routes keep identity, switching, PIN, sign-in and sync. `BackupExportView`/`BackupImportView` retain their transfer flow. tvOS-only heading/avatar treatment changes. |
| Settings | `SettingsView` keeps all eight `TVSettingsCategory` destinations, all `SettingsSearchSection` cases, global search, persistence keys, source/advanced controls and backup/about routes. Category cards become a spacious two-column grid. |
| Playback | `TVPlayerView` retains MPV/AVPlayer/Aether routing, seek, queues, resume, track/subtitle menus, source switching and recovery. Only skip and Up Next prompt chrome/typography changes. The player engines and request type are untouched. |

The original Full/Lite boundary remains in `project.yml`: both compile `SourcesTV` and `SourcesShared`; Full selects `VORTX_ENGINE_SERVER`, an in-process server and Top Shelf app group/extension. Lite selects `VORTX_NO_EMBEDDED_SERVER`, has no embedded torrent server or Top Shelf extension, and keeps its debrid/direct boundary. The new components contain no Full-only controls.

## Change log

- Added `CinematicUI.swift`: reusable tvOS color/spacing tokens, screen header, hero action and focus-aware button style. The hero reads the already-owned `FocusedItemModel`, so moving focus does not issue a new catalogue request or rebuild all Home rails.
- Refined tvOS typography, white/grey ink, quieter card lift, visible row focus and white primary actions in `Theme.swift`; iOS/Mac branches retain their original styling.
- Improved artwork replacement in `FullBleedBackdrop`: retain the decoded image during a new cached/downsampled request, dim during replacement, crossfade after a result, cancel stale work, and honor Reduce Motion. `BrowseHeroBackdrop` no longer forces the entire backdrop view to remount per focused ID. Its logo task ignores stale results.
- Updated Home rail hierarchy and real detail/source entry points; redesigned series title treatment and episode cards; aligned discovery, search, library, live, add-on, settings, profile, watchlist and supporting screen headings.
- Restyled player skip and Up Next prompts without changing command handling, timing or playback requests.

## Build and verification boundary

`docs/BUILDING.md` explicitly says a complete shipping app cannot be built from the public clone. `app/project.yml` links `Vendor/VortxEngine.xcframework` for both tvOS targets and uses the local `Vendor/MPVKit-DVFEL` package. The private native engine source and reviewed SDK artifacts, including its simulator/device slices, are absent here; the public player package manifest alone does not supply the verified binary slices. The release workflow builds the SDK from authorized private source, checks ABI and packaging, fetches a checksum-verified MPVKit artifact, and generates the project. An IPA is neither a legitimate replacement for those inputs nor a source of buildable private code.

| Gate | Result in this environment |
| --- | --- |
| Source changes and route review | Implemented in the public UI; routes, source selection, settings categories and target configuration inspected. |
| Whitespace/patch and project YAML | `git diff --check` passed; PyYAML confirmed both TV targets include `SourcesTV`/`SourcesShared` and retain their different compilation flags. Five mail patches applied cleanly with `git am` to a detached baseline worktree. |
| Existing native package fixture tests | `python3 scripts/tests/test_native_apple_package.py`: 31 passed. These exercise packaging proof logic, not this UI or live native binaries. |
| Swift typecheck or Full/Lite compile | Not run: Linux host has no `swiftc`, Xcode, XcodeGen or Apple SDK, and the private SDK is absent. |
| Simulator preview, focus, UI and streaming tests | Not run: no tvOS simulator or hardware. Source inspection and a development-only mock would not prove a real app build. |
| Signed IPA and hardware playback | Not produced or verified. Requires the authorized native inputs, Mac build, developer signing and device validation. |

No mock data or mock service was added to production. The repository's existing `CinemaUISmokeRenderer` fixture is not a substitute for a complete native target build.

### Reproduce on an Apple Silicon Mac with authorized inputs

1. Check out the baseline above, apply the delivered patch (or check out the branch), and use a current Xcode with tvOS 18 SDK and the XcodeGen version verified in `.github/workflows/release-tvos.yml`. Install the repository's documented toolchains and run its private-source input gates. Do not insert SDKs from unrelated revisions.
2. Obtain the reviewed `vortx-core` revision through the project's authorized channel. Build or stage `app/Vendor/VortxEngine.xcframework` and retained pre-localization archives with the repository's `scripts/build-ffi-xcframework.sh --resource-host`, then run `scripts/verify-native-engine-abi.sh` and `scripts/verify-apple-engine-artifacts.sh` as in the release workflow. Supply the release-verified MPVKit-DVFEL package including its binary artifacts and run `scripts/verify-mpvkit-dvfel-artifacts.sh`.
3. From the repository root, generate the native spec with `ruby scripts/generate-native-apple-project.rb --engine-revision <reviewed-40-hex-engine-revision> --mpvkit "$PWD/app/Vendor/MPVKit-DVFEL" --output "$PWD/app/.native-project.yml"`, then `(cd app && xcodegen generate --spec .native-project.yml)`. This step also needs Apple's `plutil`.
4. Build both targets using the release workflow's command shape: `xcodebuild -project app/VortX.xcodeproj -scheme VortXTV -configuration Release -destination 'generic/platform=tvOS' -derivedDataPath app/build/cinematic-full CODE_SIGNING_ALLOWED=NO build` and repeat for `VortXTVLite` with a separate derived-data path. Run simulator launch and remote-focus scenarios, then physical Apple TV playback, tracks, resume, profile, add-ons, settings and Full/Lite checks. Treat a build failure as a failure; do not weaken the ABI/content gates.
5. For an installable build, select your Apple development team and matching tvOS provisioning profiles in Xcode's Signing & Capabilities for the app and, for Full, its Top Shelf extension and `group.com.stremiox.tv` app-group entitlement. Archive the desired scheme for a generic tvOS device and export a Development or Ad Hoc IPA through Xcode Organizer using your account. Pair the Apple TV in Xcode Devices and Simulators, install the exported app, and verify launch/playback. Do not share passwords, certificates or private keys with this patch. The exact export/signing path depends on your team's entitlement and device registration.

The project requires a compile and device pass before describing this source change as a validated commercial release.
