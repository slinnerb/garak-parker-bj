# Roadmap

Phased plan. **Do not begin mass content production until the vertical slice is
stable.** Checkboxes reflect reality.

> **Direction shift (post-v0.2.0):** combat is moving from turn-based
> (Slay-the-Spire) to **real-time, top-down action** (*Hades*-style) where your
> attuned loadout is your ability set. The turn-based engine proved every
> surrounding system; the roguelite shell (items→deck, map, death→recall→
> reincarnation, universes) is **kept unchanged**. See
> [GAME_VISION.md](GAME_VISION.md) and the **Action Combat Arc** below.

## Phase 0 — Audit & documentation ✅
- [x] Inspect machine + tooling (Godot 4.7, git, gh, dotnet, node found)
- [x] Establish engine direction (Godot 4.7 GDScript, GL Compatibility)
- [x] Create all docs (README + docs/*)

## Phase 1 — Project foundation ✅
- [x] Directory structure
- [x] Autoload services (Log, EventBus, RNG, SaveManager, ContentRegistry,
      SceneFlow, GameState, GameBootstrap, Updater)
- [x] Boot scene + scene flow
- [x] Main menu with working **Check for Updates**
- [x] Save system (atomic, versioned, 3 domains, backups, corruption handling)
- [x] Headless test runner + foundation tests (all green)
- [x] Release pipeline (`tools/release/release.ps1`)

## Phase 1.5 — Distribution hookup
- [x] Create public GitHub repo (slinnerb/garak-parker-bj); set `GITHUB_REPO`
- [x] Push code
- [x] Verify end-to-end: an older build detects a newer release (headless)
- [x] Auto-update: check on launch, changelog-driven prompt, download + self-
      replace + relaunch (`SelfUpdater`); `CHANGELOG.md` as the notes source;
      clickable version → Updates & Version History panel
- [x] Install export templates; cut the first real **`v0.1.0`** release with a
      build (public zip live; exe boots; updater verified against it)
- [x] Validate the auto-update end to end — a shipped `v0.1.0` build self-updated
      to `v0.1.2` (check → download → swap → relaunch); release pipeline hardened
      against stale/wrong-version builds (delete-before-export, blocking export,
      boot-and-verify-version guard)
- [ ] Settings screen (audio/video/accessibility) wired to `SaveManager`
- [ ] Debug panel scaffold (dev-only)

## Phase 2 — Data model ✅
- [x] `CardDefinition`, `CardEffectDefinition` (composable effects, 14 kinds)
- [x] `ItemDefinition` (categories, slot cost, granted cards, passives)
- [x] `EnemyDefinition`, `EnemyIntentDefinition`, `StatusEffectDefinition`
- [x] `UniverseDefinition` (Lovecraft full; Japanese/Norse sample) +
      `MapNodeDefinition`, `LootTableDefinition`, `DifficultyDefinition`,
      `BodyArchetypeDefinition`
- [x] `MemoryDefinition`, `TattooDefinition`, `DeathAdaptationDefinition`
- [x] Content validation (per-definition + cross-content global checks,
      fail-loud at boot in dev)
- [x] 69 sample definitions incl. the vertical-slice Lovecraft content set
      (13 items, 15 cards, 5 enemies), loaded by `ContentLoader` at boot

## Phase 3 — Combat
- [x] Player + enemy state (domain-level, headless-testable)
- [x] Deck / hand / draw / discard / exhaust (deterministic reshuffle)
- [x] Card execution via reusable effects (all 14 effect kinds, composed)
- [x] Status effects, buffs/debuffs (stacking, decay, hooks, damage modifiers)
- [x] Enemy intents (deterministic weighted/sequence AI with conditions),
      victory/defeat latching
- [x] Combat UI (Phase 3b): playable combat scene — hand, enemy intents,
      HP/block/energy, piles, log, target selection, victory/defeat overlay.
      Reachable from the main menu (demo fight until the run flow exists).

## Phase 4 — Item & deck integration
- [x] Inventory + attunement slots (capacity from archetype; multi-slot items;
      cursed items resist removal)
- [x] **Deck derived from attuned items** (attune/remove rebuilds it;
      consumables give one card per charge; passive relics collected)
- [x] Attunement screen with a live deck preview; New Life → attune → fight
- [ ] Item-search encounter, item rewards (needs the run map — Phase 5)
- [ ] Break/consume/upgrade during a fight (deck rebuild mid-combat)
- [ ] Apply passive modifiers in combat (relics collected, not yet applied)

## Phase 5 — Run structure
- [x] Seeded, validated branching map generator (logical data first;
      `MapGenerator`/`RunMap` — reachable start-to-boss DAG, deterministic)
- [x] Node traversal + encounters + rewards (`RunState`/`RunManager`: HP carries,
      items found & attuned, combats built from the run via `RunCombat`)
- [x] Rest / shrine, elite path, boss; the map screen is the run hub
      (New Life → map → encounters → boss = run complete)
- [x] Adversarial review pass: robust item-location guarantee (holds on any map
      size/seed) + universe `map_gen_settings` now drive generation
      (floors/branches/guaranteed types), with regression tests. **Shipped v0.2.0.**
- [ ] Item-search depth, merchant economy, richer events (currently light)
- [ ] Save/resume an in-progress run
- [ ] **Path-range upgrades** (fate-shaping in-run): soul unlocks that widen
      branch choices, reveal node types further ahead, and later offer a
      choice of starting region

## Phase 6 — Death & reincarnation
- [x] Death report (killer → cause tags, universe, distance, elites, carried
      items) + Remembrance calculation
- [x] Cause-of-death → adaptation eligibility (data-driven trigger matching);
      adaptations grant real combat modifiers next life
- [x] Moment of Recall + adaptation selection (records once, atomically;
      tattoo-unlock banner on the 2nd death; Reincarnate → next life)
- [x] Meta-progression persistence (Soul autoload); clear body state; increment
      life; universe history
- [x] Fixed universe order (Lovecraft → Japanese → Norse), then seeded weighted
      (no repeat, recency penalties, unlock gates, death-cause pull; falls back
      to a playable universe until Japanese/Norse have content)
- [ ] Tattoo unlock at the 2nd death opens the *system* — tattoo selection is
      Phase 7
- [ ] **Fate-shaping tiers** (see GAME_VISION): nudge weights → Remembrance
      reroll/veto at the Moment of Recall → outright universe choice (late
      unlock, limited-use so randomness stays the default)

## Phase 7 — Tattoo system
- [ ] Unlock after 2nd death; 1 slot → up to 3
- [ ] Tattoo selection, effects, persistence, basic UI
- [ ] Universe-specific display hooks

## Phase 8 — Save reliability hardening
- [x] Atomic writes, versioning, backups, corruption handling (baseline done)
- [ ] Migration path exercised with a real v1→v2 change
- [ ] Debug reset tools (run vs profile, independent)

## Phase 9 — Vertical-slice completion
- [ ] One fully playable Lovecraftian Coast run, elite + boss
- [ ] Full death loop → measurably stronger next life
- [ ] Tattoo unlock demonstration + run summary
- [ ] Debug simulate-first/second-death options

## Phase 10 — Hardening
- [ ] Expand automated tests to every core system in §20 of the master prompt
- [ ] Content validation pass; bug fixing; perf + architecture review
- [ ] Keep docs in sync with implementation

---

# Action Combat Arc (the Hades × Slay-the-Spire pivot)

Turns the proven turn-based scaffold into a **real-time + freeze-to-plan hybrid**
top-down action game: live movement/dodging, with a slow-time planning mode where
you queue card plays from your loadout. The roguelite shell (items→deck, map,
death/recall/reincarnation, universes) is reused as-is; only the combat *scene and
engine* are replaced. Built in vertical slices so there's always a playable build.

## Phase A — Action + freeze core (top-down)  🚧 first slice built
- [x] Player controller: 8-directional movement, dodge/dash (i-frames + cooldown),
      HP, cursor-aimed spirit-bolt attack — top-down 2D in an arena room
- [x] **Freeze-to-plan**: a slow-time mode gated by a **planning meter** (pure,
      unit-tested `FocusMeter`) that refills over real time; one burst per press
      with an exposed recharge window (the core risk/reward). World slows, player
      stays full-speed (bullet-time)
- [x] One enemy (The Drowned One) with a telegraphed melee (wind-up → strike →
      recover) + pursuit AI; its wind-up slows under focus, opening the dodge
- [x] Distance-based hit detection, HP, death; win = enemy unmade / lose = dragged
      back; win-lose overlay with Fight-again / Back
- [x] Reachable from the main menu's **Action Prototype (dev)** entry; verified via
      headless drive + screenshots
- [ ] Tune feel (knockback, hit-stop, dodge/attack timings) — needs hands-on play
- [ ] Enemy variety, obstacles/walls, spirit possession & ethereal abilities

## Phase B — Loadout as your hand  🚧 first slice built
- [x] A **hand of cards you queue during the freeze** (keys 1-4) that **unleash in
      a burst on release**; cards go on cooldown after use, no random draw. Pure,
      unit-tested `ActionCard` + `CardLoadout` (cooldowns)
- [x] Real-time effect kinds resolved: bolt (projectile), lash (melee), ward
      (player shield that absorbs), riptide (lunge + hit) — plus player shield/dash
- [x] Hand HUD: cards with key hints, cooldown shading, and queue-order badges;
      "PLAN — press 1-4… release to unleash" state. Verified via drive + shots
- [ ] Manual targeting in the freeze (currently auto-targets the enemy)
- [ ] Source the hand from the run's **Attunement** (items→deck), not a fixed
      default hand; ability slots from the archetype
- [ ] Port the real `CardDefinition` effect kinds (status, block, repeat, etc.)
      to real-time resolution, keeping the data-driven definitions

## Phase C — Rooms replace the combat node  🚧 first slice built
- [x] Map combat/elite/boss nodes launch the **action room** (map_screen →
      `goto_action`; the room reads `RunManager.current` + the node to build itself)
- [x] HP carries in and back out (`resolve_combat`); room clear → **Onward** to the
      map; boss clear → **Complete the run**; death → **Remember** (recall)
- [x] Enemy drawn from the universe pool by node type (normal/elite/boss),
      tier-scaled HP + threat; enemy name shown. Verified drive (win + death) + shot
- [ ] Enemy threat from real intents (currently approximated per tier); obstacles
      / walls; the standalone dev sandbox stays for tuning

## Phase D — Mid-run boons
- [ ] Boon definitions (data-driven ability modifiers) + a between-room choice
      of 1-of-N, delivered via shrine/event/merchant nodes
- [ ] Boons stack and interact; run-defining builds emerge

## Phase E — Weapon / aspect archetypes
- [ ] 2-3 distinct starting kits (base attack + starting cards + rhythm),
      unlockable as soul options

## Phase F — The hub between lives
- [ ] A between-lives hub scene; recurring NPC(s) that react to death count
- [ ] **The Mirror:** spend Remembrance on a persistent upgrade tree
- [ ] Story beats that advance across runs; Moment of Recall folds into the hub

## Phase G — Feel & content
- [x] First juice pass: **floating damage numbers** (colour-coded), **knockback**,
      **hit-stop** (enemy hitches on impact), **screen shake** on player hits — via
      `damaged` signals on player/enemy. Readable enemy telegraphs already in
- [ ] Audio, animation, dodge/dash trails, death VFX; tune the feel constants
      (needs hands-on play)
- [ ] Fill the Lovecraftian Coast with real enemies/abilities/boss patterns
- [ ] Fate-shaping tiers (nudge → reroll/veto → choice); path-range upgrades
