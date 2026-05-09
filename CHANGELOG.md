# Changelog

## [1.1.0](https://github.com/lux-sp4rk/wrdfall/compare/v1.0.0...v1.1.0) (2026-05-09)


### Features

* add dev_mode_cheats feature flag ([#271](https://github.com/lux-sp4rk/wrdfall/issues/271)) ([5b52fba](https://github.com/lux-sp4rk/wrdfall/commit/5b52fbaff551c17f28c21cbe0b686902f6bc708f))
* add Faye and D33 pre-push hooks via lefthook ([976f76f](https://github.com/lux-sp4rk/wrdfall/commit/976f76ff1f833e7904681f945f3bf419ac332892))
* add high score celebration animation and notification ([#261](https://github.com/lux-sp4rk/wrdfall/issues/261)) ([ad13a20](https://github.com/lux-sp4rk/wrdfall/commit/ad13a20653307f88b64f3682d750100e7e331ac4))
* add PWA icons and PWA testing docs ([6747ac5](https://github.com/lux-sp4rk/wrdfall/commit/6747ac50a6a5045d6a3086a875893c43922bf118))
* add repomix config and audit script ([#239](https://github.com/lux-sp4rk/wrdfall/issues/239)) ([d453cfd](https://github.com/lux-sp4rk/wrdfall/commit/d453cfd5510a8baf49cb2da309a4874d231fd031))
* add test_flag_ping feature flag ([#272](https://github.com/lux-sp4rk/wrdfall/issues/272)) ([6edd3cb](https://github.com/lux-sp4rk/wrdfall/commit/6edd3cb71fe84d8e35d5b6494f020c34a9a5e0a9))
* add Wordfall brand assets (aqua/waterfall aesthetic) ([#240](https://github.com/lux-sp4rk/wrdfall/issues/240)) ([cf567cc](https://github.com/lux-sp4rk/wrdfall/commit/cf567ccc89f410eefe9cc4f2308446cbb7dc2bd2))
* **bdd:** add behavior specs for core game systems ([#248](https://github.com/lux-sp4rk/wrdfall/issues/248)) ([29db3f1](https://github.com/lux-sp4rk/wrdfall/commit/29db3f19ded139b37e8d69d7d101b9622aa11c0c))
* **ci:** extend test-runner-faye to run GUT tests ([#257](https://github.com/lux-sp4rk/wrdfall/issues/257)) ([94de7c4](https://github.com/lux-sp4rk/wrdfall/commit/94de7c41eaf38b1724a7604688972b0d1bd2c35f))
* **game:** add word definition lookup on tap — Issue [#59](https://github.com/lux-sp4rk/wrdfall/issues/59) ([#280](https://github.com/lux-sp4rk/wrdfall/issues/280)) ([94325ad](https://github.com/lux-sp4rk/wrdfall/commit/94325adeadd939bd68d4bb3afed9d4cc5ff2eac1))
* Pause button for seniors + Freeze powerup redesign ([#223](https://github.com/lux-sp4rk/wrdfall/issues/223)) ([#237](https://github.com/lux-sp4rk/wrdfall/issues/237)) ([45288e1](https://github.com/lux-sp4rk/wrdfall/commit/45288e134274e94b68dc1b1a54c9fa71f0c6d93c))
* **pause:** redesign pause screen with animated tiles and rotating tips ([#254](https://github.com/lux-sp4rk/wrdfall/issues/254)) ([904f3b2](https://github.com/lux-sp4rk/wrdfall/commit/904f3b2acbb0fe2828a54be0167f267e4afac110))
* PWA manifest settings, icons, and testing docs ([#88](https://github.com/lux-sp4rk/wrdfall/issues/88)) ([558bbc0](https://github.com/lux-sp4rk/wrdfall/commit/558bbc0041b1b50f968ae2b9b011af306494b4b8))
* sand timer visual component for drop timer ([#273](https://github.com/lux-sp4rk/wrdfall/issues/273)) ([d6ee952](https://github.com/lux-sp4rk/wrdfall/commit/d6ee9521e04e09a8f9a53f00b5513cb3a3ef4dd3))
* **ui:** combo streak visual build-up ([#259](https://github.com/lux-sp4rk/wrdfall/issues/259)) ([#278](https://github.com/lux-sp4rk/wrdfall/issues/278)) ([8e96822](https://github.com/lux-sp4rk/wrdfall/commit/8e96822bf1ba49cf855824bcf7f95f5ef308d745))
* **ui:** particle burst + floating score label on word scored (closes [#260](https://github.com/lux-sp4rk/wrdfall/issues/260)) ([#267](https://github.com/lux-sp4rk/wrdfall/issues/267)) ([9ebb463](https://github.com/lux-sp4rk/wrdfall/commit/9ebb46313b3f2670dfee3377efc53a396d0f70af))
* **ui:** subtle bounce animation on tile drop ([#266](https://github.com/lux-sp4rk/wrdfall/issues/266)) ([68460ac](https://github.com/lux-sp4rk/wrdfall/commit/68460ac4a3681843bae3ffa4975eb080c3815bcf)), closes [#258](https://github.com/lux-sp4rk/wrdfall/issues/258)


### Bug Fixes

* 230: Board edge clipping during gameplay ([#233](https://github.com/lux-sp4rk/wrdfall/issues/233)) ([3bd9959](https://github.com/lux-sp4rk/wrdfall/commit/3bd995920e8f9d7c8d5bed3f73252db5d08c3e4b))
* **ci:** increase Gemini workflow timeout from 7 to 15 minutes ([#279](https://github.com/lux-sp4rk/wrdfall/issues/279)) ([285ae0d](https://github.com/lux-sp4rk/wrdfall/commit/285ae0d618db740c91277769b3a0ac2e58756ec7))
* clean up SPIKE [#165](https://github.com/lux-sp4rk/wrdfall/issues/165) debug logs and fix D33 detection ([57b8e9c](https://github.com/lux-sp4rk/wrdfall/commit/57b8e9c937be4b139468eadc4409a87cee597045))
* **d33:** recognize // debug markers for console.log exemptions ([4d73d25](https://github.com/lux-sp4rk/wrdfall/commit/4d73d25196a30721eaaea1d2e9991fe4a5d7927f))
* disable React tutorial prompt modal ([#238](https://github.com/lux-sp4rk/wrdfall/issues/238)) ([5ca65c3](https://github.com/lux-sp4rk/wrdfall/commit/5ca65c363f8556a7ec94fed5b3a92c8f53ed48d4))
* disable tutorial modal temporarily ([#238](https://github.com/lux-sp4rk/wrdfall/issues/238)) ([eba5bdc](https://github.com/lux-sp4rk/wrdfall/commit/eba5bdc4319c5ccbb1f74f3c526f560807f21177))
* disable tutorial modal temporarily ([#238](https://github.com/lux-sp4rk/wrdfall/issues/238)) ([74d9f10](https://github.com/lux-sp4rk/wrdfall/commit/74d9f10cb6f39df3eebeec60f1b0aa020e0220ee))
* **docs:** audit & update How to Play player guide (fixes [#285](https://github.com/lux-sp4rk/wrdfall/issues/285)) ([#287](https://github.com/lux-sp4rk/wrdfall/issues/287)) ([e838d23](https://github.com/lux-sp4rk/wrdfall/commit/e838d232d4d35792796be20a2ce8cf666c5e87c2))
* enable rescue word in hard mode ([#190](https://github.com/lux-sp4rk/wrdfall/issues/190)) ([b091771](https://github.com/lux-sp4rk/wrdfall/commit/b0917711eff07d0f7c7db39786b2a802d2189a2d))
* enable rescue word in hard mode ([#190](https://github.com/lux-sp4rk/wrdfall/issues/190)) ([23f43b2](https://github.com/lux-sp4rk/wrdfall/commit/23f43b29ffc0851ea8d0fca6e7816f80b8e24495))
* GameSidebar blocks game buttons from responding ([#226](https://github.com/lux-sp4rk/wrdfall/issues/226)) ([698c08a](https://github.com/lux-sp4rk/wrdfall/commit/698c08a605963d16f3c4a862c7265db618287c67)), closes [#224](https://github.com/lux-sp4rk/wrdfall/issues/224)
* **gemini-triage:** add GEMINI_CLI_TRUST_WORKSPACE env var ([#286](https://github.com/lux-sp4rk/wrdfall/issues/286)) ([9b6512e](https://github.com/lux-sp4rk/wrdfall/commit/9b6512e253ecd62b3458071332884e0ad1f6094c))
* increase gemini review timeout and session turns ([#281](https://github.com/lux-sp4rk/wrdfall/issues/281)) ([55a70b8](https://github.com/lux-sp4rk/wrdfall/commit/55a70b8b1b41b671afa8893d7dae0a6f8db448fe))
* move word definition popup from game board to stats screen ([#283](https://github.com/lux-sp4rk/wrdfall/issues/283)) ([#284](https://github.com/lux-sp4rk/wrdfall/issues/284)) ([38b1c86](https://github.com/lux-sp4rk/wrdfall/commit/38b1c86577b1344db339b0e6e8ff3b60ebfa9b02))
* **sidebar:** extend overlay to span wide viewports ([#256](https://github.com/lux-sp4rk/wrdfall/issues/256)) ([8cc3f88](https://github.com/lux-sp4rk/wrdfall/commit/8cc3f8882a7dce563ba29b9c3e8c13eb3d906793)), closes [#253](https://github.com/lux-sp4rk/wrdfall/issues/253)
* use PAT to access private test-runner-faye action ([3c1a5e1](https://github.com/lux-sp4rk/wrdfall/commit/3c1a5e145fb15fb34794df01c72585d0fdbfbafe))
* **vercel:** add buildCommand so Vercel actually builds landing/ ([#231](https://github.com/lux-sp4rk/wrdfall/issues/231)) ([9fe230f](https://github.com/lux-sp4rk/wrdfall/commit/9fe230f6e82c89f223e0c83247c510a81a1e9922))

## Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- Header section - delete when release-please initializes -->
