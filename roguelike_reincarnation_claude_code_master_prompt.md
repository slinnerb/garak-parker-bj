# MASTER CLAUDE CODE PROMPT — ROGUELIKE REINCARNATION DECKBUILDER FOUNDATION

You are the lead gameplay engineer and software architect for a new single-player roguelike deckbuilder.

Your job is to create a stable, modular, data-driven foundation that can support long-term development. Do not rush to build the entire game. Build a clean vertical slice that proves the central gameplay loop and gives future content a reliable structure.

## 1. Initial instructions

Begin by inspecting the entire project folder.

Determine:

- Whether an engine project already exists
- Which engine, language, and version are being used
- What systems or assets already exist
- Whether there are conflicting or incomplete implementations
- Whether version control is initialized
- Whether the project currently builds or runs

Do not delete or overwrite working code without documenting why.

If this is an empty project, create it using:

- Godot 4.x
- GDScript
- Desktop-first development
- Windows as the primary test platform
- Architecture that can later support Steam distribution
- A resolution-independent UI
- Placeholder visuals that can easily be replaced

Do not depend on paid assets or unnecessary plugins.

Before implementation, create:

- `README.md`
- `docs/GAME_VISION.md`
- `docs/ARCHITECTURE.md`
- `docs/CONTENT_SCHEMA.md`
- `docs/SAVE_SYSTEM.md`
- `docs/DECISIONS.md`
- `docs/CURRENT_STATE.md`
- `docs/ROADMAP.md`

Keep these files updated as development progresses.

---

# 2. Game concept

The game is a single-player roguelike deckbuilder centered entirely on death, reincarnation, survival, and retained soul progression.

Each run represents an entire life in a different universe.

The player enters a mythological universe and attempts to survive as long as possible. They explore branching locations, search for physical items, build a deck from those items, fight enemies, defeat bosses, and progress deeper into the universe.

Eventually, the current body dies.

The death is real. The body and almost everything obtained during that life are lost.

At the exact moment of death, the character temporarily regains memories of every previous incarnation. They understand the reincarnation cycle only during this death sequence.

Afterward, the soul enters the between-life progression space and reincarnates into another universe.

The new living character does not consciously remember previous lives.

The player remembers. The soul retains instincts, adaptations, tattoos, and selected item memories. The current character does not understand where these abilities came from.

## Central narrative rule

> While alive, the character forgets. At death, the soul remembers. Upon reincarnation, conscious memories disappear again.

## Central gameplay rule

> Every death should make future lives stronger, but the current run’s body, equipment, deck, and relationships are still lost.

The game should make the player think:

> “I want to survive longer, but even this death will teach my next life something.”

---

# 3. Universe progression

The first three universes occur in a fixed order.

## Life One: Lovecraftian Coastal Universe

A deteriorating coastal settlement influenced by restrained cosmic horror.

Themes:

- Flooded streets
- Fishing villages
- Abandoned lighthouses
- Cult activity
- Deep-sea creatures
- Impossible ruins
- Voices from beneath the ocean
- Reality gradually behaving incorrectly

This universe introduces:

- Exploration
- Item discovery
- Item-based cards
- Combat
- Death
- Reincarnation
- Basic soul progression

## Life Two: Japanese Mythos Universe

A haunted feudal Japanese region.

Themes:

- Samurai
- Ronin
- Yokai
- Oni
- Yūrei
- Cursed shrines
- Haunted forests
- Possessed villages
- Folklore distorted by subtle cosmic influence

This universe introduces the Memory Tattoo subsystem after the second death.

## Life Three: Norse Mythos Universe

A frozen Norse world experiencing a corrupted Ragnarök.

Themes:

- Draugr
- Frost giants
- Berserkers
- Valkyries
- Rune magic
- Broken sections of Yggdrasil
- World-serpent mutations
- Fate behaving incorrectly

This universe completes the introductory progression.

## Life Four and onward

After the first three lives, universe selection becomes weighted and randomized.

The random system must:

- Prevent the same universe twice consecutively
- Prefer universes not visited recently
- Support difficulty weighting
- Support unlock requirements
- Support death-cause influences
- Support tattoo influences
- Support deterministic seeded selection
- Be easy to expand with new universe definitions

Future universes may include:

- Gothic medieval Europe
- Ancient Egypt
- Celtic folklore
- Slavic folklore
- Ancient Greece
- Mesoamerican mythology
- Victorian occult horror
- Prehistoric cosmic horror

Do not fully implement all future universes now. Create the data architecture required to add them later.

---

# 4. Horror direction

The horror should be atmospheric and restrained.

Do not make every enemy an obvious tentacle monster.

Use subtle inconsistencies:

- The same symbol appearing across unrelated cultures
- NPCs recognizing the soul without understanding why
- Architecture that should not exist
- Ancient writing describing previous incarnations
- Foreign objects appearing in the wrong universe
- Reflections showing previous bodies
- The same melody appearing in every culture
- Gods from different universes sharing the same wound
- Enemies repeating words spoken during previous deaths

The mythology of each universe must remain recognizable and culturally distinct.

The cosmic horror connects and corrupts the universes but does not replace their mythology.

---

# 5. Item-based card system

Cards are not abstract rewards.

Every main card must originate from a physical item found, equipped, remembered, or manifested during the current life.

Examples:

- Harpoon creates an attack card
- Lantern creates a reveal or burn card
- Katana creates attack and counter cards
- Prayer beads create cleansing cards
- Round shield creates block cards
- Rune stone creates fate-manipulation cards
- Ritual knife creates blood-sacrifice cards
- Saint relic creates healing or miracle cards
- Forbidden journal creates dangerous knowledge cards

## Item categories

Support at least:

- Weapons
- Defensive equipment
- Tools
- Charms
- Relics
- Consumables
- Forbidden artifacts
- Quest items
- Soulbound items

## Attunement slots

The character may find many items, but only a limited number may be attuned for combat.

Initial design target:

- Start with 6–8 item slots
- Some items consume more than one slot
- Items may provide one or multiple cards
- Consumables may provide limited-use cards
- Cursed items may resist removal
- Passive relics may modify cards without adding cards
- Capacity may increase temporarily during a life
- Permanent progression should provide options, not unlimited capacity

The equipped item loadout generates the active combat deck.

The deck must update predictably whenever an item is equipped, removed, upgraded, broken, consumed, or transformed.

## Important design requirement

Do not create separate disconnected equipment and deckbuilding systems.

Equipment and deck construction must be two views of the same underlying system.

---

# 6. Body and soul progression

There must be a strict separation between temporary run progression and permanent meta-progression.

## Body progression

Lost when the current life ends:

- Current items
- Current active deck
- Gold
- Consumables
- Temporary card upgrades
- Current map progress
- Temporary blessings
- Relationships
- Temporary health upgrades
- Run-specific status effects
- Temporary curses unless specifically transferred

## Soul progression

Persists across reincarnations:

- Soul level or equivalent progression currency
- Unlocked universe definitions
- Unlocked item definitions
- Unlocked item-memory options
- Death adaptations
- Memory Tattoos
- Core Memories
- Lore discoveries
- Difficulty unlocks
- Previously encountered enemies
- Previously encountered bosses
- Permanent content-pool unlocks
- Selected subconscious starting advantages

Avoid large permanent numerical stat increases that trivialize future runs.

Permanent progression should primarily provide:

- More strategic options
- More starting choices
- Better information
- Specialized adaptations
- Expanded content pools
- Limited resistances
- New interactions

---

# 7. Death system

Death is the most important system in the game.

It must not be treated as a generic game-over screen.

When health reaches zero:

1. Freeze or conclude combat safely.
2. Record the cause of death.
3. Record the enemy, effect, card, environment, or decision responsible.
4. Record the current universe.
5. Record distance survived.
6. Record bosses and elites defeated.
7. Record items carried.
8. Record significant choices.
9. Record damage types suffered.
10. Record active tattoos and memories.
11. Calculate Remembrance or the permanent progression reward.
12. Enter the Moment of Recall.
13. Present memory, adaptation, and tattoo choices when applicable.
14. Save meta-progression atomically.
15. Clear temporary body state.
16. Create the next incarnation.
17. Select the next universe according to progression rules.
18. Return the player to the between-life area or next-life opening.

## Cause-of-death adaptations

The cause of death should influence future unlock options.

Examples:

Death by poison may unlock:

- Poison resistance
- Poison conversion
- Poison-related cards in future pools
- Better information about poison enemies

Death by freezing may unlock:

- Frost resistance
- Freeze recovery
- Cold-related techniques
- Defensive responses to immobilization

Death to a boss may unlock:

- Information about that boss
- Pattern prediction
- Damage bonuses against that enemy family
- A card or item inspired by the boss

Death while carrying a forbidden artifact may unlock:

- A corrupted item memory
- Increased Awareness
- A powerful adaptation with a drawback

Create a flexible data-driven adaptation system. Do not hard-code every adaptation directly into the death manager.

---

# 8. Memory system

The soul regains memories only during the death sequence.

The living incarnation does not have direct access to conscious memories.

Permanent bonuses should be described as:

- Instincts
- Echoes
- Traumas
- Adaptations
- Soulmarks
- Unexplained familiarity

## Memory types

### Instinct Memories

Passive subconscious behaviors.

Examples:

- Automatically gain block against the first attack
- Reveal one enemy intention
- Draw a card when entering critical health
- Avoid the first trap in a life

### Technique Memories

Allow a card family or technique from a previous universe to appear elsewhere.

Examples:

- A Japanese counter technique appearing in a Norse form
- A Norse shield technique appearing in a Gothic form
- A Lovecraftian lantern technique appearing as a shrine light

### Trauma Memories

Powerful adaptations associated with dangerous drawbacks.

Examples:

- Reduced fire damage but recurring nightmare cards
- Increased boss damage but bosses become more aggressive
- Better enemy prediction but increased cosmic Awareness
- Stronger forbidden cards but lower healing effectiveness

### Item Memories

Allow a limited number of important item concepts to persist between lives.

The exact physical item is normally lost. The soul remembers how to find, recreate, manifest, or use an equivalent.

Items may adapt visually to the current universe while retaining their mechanical identity.

Rare named artifacts may remain unchanged across universes to create unease.

---

# 9. Memory Tattoo subsystem

The Memory Tattoo system unlocks after the second completed death.

A Memory Tattoo is a permanent soul memory that manifests physically on every future body.

The character does not remember selecting it.

They may believe it is:

- A birthmark
- A family symbol
- A religious mark
- A curse
- A cultural tattoo
- A scar they have always possessed

## Initial rules

- Unlock the first tattoo slot after the second death
- Begin with one active tattoo slot
- Support future unlocking of additional slots
- Target a maximum of three active slots
- Tattoos persist until deliberately replaced
- Tattoos may have upgrade stages
- Tattoos may react differently to different universes
- Tattoo art presentation may change culturally while retaining the same soul identity

## Tattoo functions

A tattoo may:

- Preserve one item memory
- Guarantee an item family appears
- Provide a passive adaptation
- Unlock unique events
- Change dialogue
- Modify death rewards
- Alter universe weighting
- Increase or reduce cosmic Awareness
- Evolve after repeated related deaths

## Example tattoos

### Broken Blade

- Guarantees access to a sword-family item
- Improves the first weapon attack each combat
- Evolves through repeated weapon-related deaths

### Frozen Raven

- Reveals an enemy’s initial intent
- Provides limited frost resistance
- May reveal hidden paths

### Empty Mask

- Interacts with curses and spirits
- Provides bonuses against supernatural enemies
- Unlocks Japanese mythos events

### Drowned Eye

- Improves access to forbidden knowledge
- Reveals hidden cosmic encounters
- Adds a risk of hallucination cards

Implement tattoos as data definitions, not hard-coded condition trees.

---

# 10. Combat foundation

Combat should be turn-based, deterministic, readable, and easy to test.

The player must be able to see:

- Current health
- Maximum health
- Energy or action resource
- Hand
- Draw pile count
- Discard pile count
- Exhausted pile count
- Equipped items
- Active statuses
- Enemy health
- Enemy statuses
- Enemy intent
- Damage previews where practical

## Required combat concepts

Support:

- Drawing cards
- Playing cards
- Energy costs
- Damage
- Block
- Healing
- Status effects
- Buffs
- Debuffs
- Card exhaust
- Card retain
- Temporary cards
- Consumable cards
- Multi-target effects
- Enemy intents
- Turn start
- Turn end
- Victory
- Defeat
- Rewards
- Deterministic random targeting
- Combat logging

## Architecture rules

- Card effects must not be implemented as large UI scripts.
- Combat rules must live in domain-level gameplay code.
- UI must display state and send player commands.
- Card definitions must be data-driven.
- Complex cards should compose reusable effect definitions.
- Avoid one custom script per simple card.
- Permit custom scripts only when a card genuinely cannot use standard effects.

Suggested reusable effects:

- DealDamageEffect
- GainBlockEffect
- HealEffect
- DrawCardsEffect
- ApplyStatusEffect
- RemoveStatusEffect
- ModifyEnergyEffect
- AddTemporaryCardEffect
- ExhaustCardEffect
- TransformCardEffect
- ModifyItemEffect
- ConditionalEffect
- RepeatEffect
- RandomTargetEffect

---

# 11. Enemy AI

Enemy behavior should be intent-driven and deterministic.

Each enemy must have:

- Stable content ID
- Display name
- Base stats
- Tags
- Resistances
- Weaknesses
- Intent definitions
- Behavior state
- Possible loot
- Universe availability
- Difficulty modifiers

The player should normally see the next enemy action.

Later systems may obscure or manipulate intent, but baseline combat should remain readable.

Enemy behavior must be testable without rendering the full scene.

---

# 12. Procedural run map

Create a branching node-based run map.

Initial node types:

- Standard combat
- Elite combat
- Boss combat
- Item search
- Unknown event
- Merchant
- Shrine
- Rest location
- Tattoo interaction
- Memory anomaly
- Treasure
- Story encounter

The first vertical slice does not need an enormous map.

Build a small deterministic map generator that:

- Uses a saved seed
- Produces valid start-to-boss paths
- Prevents impossible node arrangements
- Supports universe-specific node weights
- Supports difficulty scaling
- Supports special guaranteed nodes
- Can be regenerated exactly from the same seed

Do not tightly couple map generation to UI coordinates.

Generate logical map data first, then render it.

---

# 13. Universe definition architecture

Create a data-driven `UniverseDefinition` resource or equivalent.

It should support:

- Stable ID
- Display name
- Description
- Narrative introduction
- Theme tags
- Available enemies
- Available elites
- Available bosses
- Available items
- Available events
- Available locations
- Card visual theme
- Background music references
- Difficulty range
- Unlock requirements
- Selection weighting
- Recent-visit penalties
- Death-cause weighting
- Tattoo weighting
- Corruption or Awareness modifiers
- Map-generation settings

Implement usable definitions for:

- Lovecraftian Coast
- Japanese Mythos
- Norse Mythos

Only the Lovecraftian Coast must be fully playable in the first vertical slice.

Japanese and Norse definitions may initially contain sample content and validation tests, but the architecture must support their later completion.

---

# 14. Deterministic randomness

Create a centralized seeded random-number service.

Do not use uncontrolled global random calls throughout the project.

Separate random streams where useful:

- Universe selection
- Map generation
- Combat randomness
- Loot
- Events
- Enemy decisions
- Cosmetic randomness

Store enough information to reproduce a run.

The same seed and the same player decisions should produce the same results whenever practical.

Include the run seed in debug screens and death reports.

---

# 15. Save system

The save system must be designed early, not added as an afterthought.

Use separate save domains:

## Profile save

Permanent progression:

- Soul progression
- Memories
- Tattoos
- Universe unlocks
- Item unlocks
- Lore
- Statistics
- Difficulty unlocks

## Active run save

Temporary current-life state:

- Universe
- Seed
- Current map node
- Body stats
- Equipped items
- Deck state
- Inventory
- Current health
- Run currency
- Current modifiers
- Encounter state when safely supported

## Settings save

- Audio
- Video
- Accessibility
- Input preferences
- Text speed
- Screen shake
- Reduced motion

## Save requirements

- Save version number
- Migration support
- Validation before loading
- Graceful handling of corrupt files
- Atomic save writes using temporary files
- Backup of the previous valid save
- No silent deletion of incompatible saves
- Clear logging
- Development tools to reset profile or active run independently

Document the save schema in `docs/SAVE_SYSTEM.md`.

---

# 16. Event architecture

Use a central event or signal architecture carefully.

Suggested global services:

- `GameBootstrap`
- `GameStateManager`
- `RunManager`
- `CombatManager`
- `MetaProgressionManager`
- `SaveManager`
- `ContentRegistry`
- `RNGService`
- `SceneFlowManager`
- `AudioManager`
- `GameEventBus`

Do not turn every class into a global singleton.

Only globally persistent services should be autoloaded.

Prefer explicit dependencies for local gameplay systems.

Avoid circular dependencies.

---

# 17. Data definitions

Use stable string IDs for all content.

Never use display names as identifiers.

Suggested content definitions:

- `CardDefinition`
- `CardEffectDefinition`
- `ItemDefinition`
- `UniverseDefinition`
- `EnemyDefinition`
- `EnemyIntentDefinition`
- `StatusEffectDefinition`
- `EncounterDefinition`
- `MapNodeDefinition`
- `TattooDefinition`
- `MemoryDefinition`
- `DeathAdaptationDefinition`
- `BodyArchetypeDefinition`
- `LootTableDefinition`
- `DifficultyDefinition`

Create validation tools that report:

- Duplicate IDs
- Missing references
- Empty required fields
- Invalid costs
- Invalid effect data
- Unreachable content
- Missing universe assignments
- Broken loot-table references

The game should fail loudly in development when content data is invalid.

---

# 18. Scene and UI foundation

Create a clear scene structure.

Suggested major screens:

- Boot screen
- Main menu
- Profile selection or profile management
- Between-life hub
- Reincarnation transition
- Universe introduction
- Run map
- Item-search encounter
- Combat
- Reward selection
- Inventory and attunement
- Death sequence
- Moment of Recall
- Memory selection
- Tattoo selection
- Run summary
- Settings
- Debug tools

Use placeholder art and readable typography.

Prioritize:

- Clear information hierarchy
- Reliable navigation
- Keyboard and mouse support
- Controller-ready input abstraction
- Resolution independence
- Tooltips
- Confirmation dialogs for destructive actions
- Accessibility hooks

Do not spend excessive time polishing art before the systems work.

---

# 19. Vertical slice content

Build one small but complete playable loop.

## Required playable content

### Universe

- Lovecraftian Coast

### Player

- One body archetype
- One starting item loadout
- Basic health and energy systems

### Items

Create approximately 10–15 functional sample items, including:

- Basic weapon
- Defensive item
- Utility item
- Consumable
- Healing item
- Forbidden artifact
- Cursed item
- Rare item
- Item that provides multiple cards
- Passive item that modifies another card or item

### Enemies

Create:

- Three normal enemies
- One elite
- One boss

### Map

Create:

- A small branching map
- At least one item-search node
- At least one event node
- At least one rest or shrine node
- One elite path
- One boss

### Death and reincarnation

The vertical slice must support:

- Dying in combat
- Recording cause of death
- Calculating a permanent reward
- Moment of Recall screen
- Selecting one adaptation
- Clearing temporary run state
- Incrementing life count
- Reincarnating
- Unlocking the first tattoo system after the second death
- Starting a stronger future life

For testing, include a debug option to simulate the first and second death without manually completing two full runs.

---

# 20. Testing requirements

Create automated tests for core non-visual systems.

At minimum, test:

- Seeded RNG consistency
- Deck generation from equipped items
- Equipping and removing items
- Attunement capacity
- Card draw and discard
- Damage and block calculations
- Status-effect duration
- Enemy intent selection
- Map validity
- Universe-order progression
- Random universe selection rules
- Death recording
- Cause-of-death adaptation eligibility
- Meta-progression persistence
- Tattoo unlock after the second death
- Save/load round trips
- Save migration
- Invalid content detection

If no test framework already exists, create a lightweight headless test runner.

Target a command similar to:

`godot --headless --path . --script res://tests/run_all.gd`

Document the exact test command in `README.md`.

---

# 21. Debugging tools

Create a development-only debug panel.

It should support:

- Set run seed
- View current seed
- Add item
- Remove item
- Add card
- Damage player
- Heal player
- Force death
- Set cause of death
- Add Remembrance
- Increment life count
- Unlock tattoo subsystem
- Select universe
- Jump to map node
- Start specific combat
- Validate all content
- Save active run
- Reload active run
- Reset active run
- Reset meta-progression

Debug systems must be disabled or inaccessible in release builds.

---

# 22. Logging

Create structured logging categories.

Suggested categories:

- BOOT
- SAVE
- CONTENT
- RUN
- MAP
- COMBAT
- ITEM
- CARD
- DEATH
- MEMORY
- TATTOO
- UNIVERSE
- ERROR

Logs should provide useful context without flooding normal output.

Record major state transitions:

- Run created
- Universe selected
- Item equipped
- Combat started
- Combat ended
- Death recorded
- Memory selected
- Tattoo unlocked
- Save written
- Save loaded
- Validation failed

---

# 23. Coding standards

Follow these rules:

- Use typed GDScript wherever practical
- Keep functions focused
- Avoid giant manager scripts
- Prefer composition over deep inheritance
- Keep gameplay logic separate from presentation
- Avoid hard-coded content IDs scattered across scripts
- Centralize constants
- Use enums only for truly closed sets
- Use stable string IDs for expandable content
- Document public APIs
- Add comments explaining why, not obvious syntax
- Use descriptive names
- Avoid premature optimization
- Avoid speculative abstraction that has no current use
- Do not duplicate gameplay logic
- Handle errors explicitly
- Never swallow save or content errors silently
- Keep scenes small and composable
- Do not place major game rules inside button callbacks

---

# 24. Development phases

Work in the following order.

## Phase 0: Audit and documentation

- Inspect project
- Run existing project
- Record current condition
- Create documentation
- Identify risks
- Establish technical direction

## Phase 1: Project foundation

- Directory structure
- Bootstrap
- Scene flow
- Content registry
- Event architecture
- RNG service
- Logging
- Basic test runner

## Phase 2: Data model

- Cards
- Effects
- Items
- Enemies
- Universes
- Memories
- Tattoos
- Death adaptations
- Validation

## Phase 3: Combat

- Player state
- Enemy state
- Deck
- Hand
- Card execution
- Status effects
- Enemy intents
- Victory and defeat

## Phase 4: Item and deck integration

- Inventory
- Attunement
- Item-generated cards
- Equip and remove flow
- Item rewards
- Item search encounter

## Phase 5: Run structure

- Seeded map
- Node traversal
- Encounters
- Rewards
- Rest node
- Elite
- Boss

## Phase 6: Death and reincarnation

- Death report
- Cause-of-death analysis
- Moment of Recall
- Adaptation selection
- Meta-progression
- Reincarnation
- Fixed opening universe order
- Randomized later universe selection

## Phase 7: Tattoo system

- Unlock after second death
- Tattoo selection
- Tattoo effects
- Persistence
- Basic tattoo UI
- Universe-specific display hooks

## Phase 8: Save reliability

- Profile save
- Active run save
- Settings save
- Validation
- Migrations
- Backups
- Corruption handling

## Phase 9: Vertical-slice completion

- Playable Lovecraftian Coast run
- One elite
- One boss
- Full death loop
- Stronger next life
- Tattoo unlock demonstration
- Run summary
- Debug tools

## Phase 10: Hardening

- Automated tests
- Content validation
- Bug fixing
- Documentation updates
- Performance review
- Architecture review

Do not begin mass content production until the vertical slice is stable.

---

# 25. Required directory organization

Use a structure similar to this unless the existing project requires a better compatible structure:

```text
res://
  core/
    bootstrap/
    events/
    logging/
    rng/
    save/
    scene_flow/
  gameplay/
    cards/
    combat/
    death/
    enemies/
    inventory/
    items/
    map/
    memories/
    progression/
    runs/
    tattoos/
    universes/
  content/
    cards/
    enemies/
    encounters/
    items/
    memories/
    tattoos/
    universes/
  presentation/
    audio/
    effects/
    themes/
    ui/
  scenes/
    combat/
    hub/
    map/
    menus/
    transitions/
  tests/
    unit/
    integration/
    fixtures/
  tools/
    debug/
    validation/
  docs/
```

Do not follow this blindly if the current repository already has a coherent structure. Document any deviation.

---

# 26. Definition of done for the foundation

The foundation is complete only when all of the following are true:

- The project launches without errors.
- A new profile can be created.
- The first life begins in the Lovecraftian Coast.
- A deterministic map is generated.
- The player can enter combat.
- Items generate the player’s cards.
- The player can equip and remove items within slot limits.
- The player can defeat enemies.
- The player can discover new items.
- The player can die.
- The cause of death is recorded.
- The Moment of Recall appears.
- The player can select a permanent adaptation.
- Temporary body progress is cleared.
- Permanent soul progress is retained.
- The next life becomes measurably stronger.
- The second death unlocks Memory Tattoos.
- The first three universe positions are Lovecraftian, Japanese, then Norse.
- Later universe selection supports deterministic weighted randomness.
- Save/load works for both active runs and permanent progression.
- Automated tests pass.
- Content validation passes.
- The architecture documentation matches the implementation.
- No essential system depends on placeholder hacks that must be rewritten immediately.

---

# 27. Working behavior

Work autonomously and make steady progress.

Ask only one question at a time, and only when a decision is genuinely blocking implementation.

When a reasonable assumption can be made safely:

- Make the assumption
- Record it in `docs/DECISIONS.md`
- Continue working

After every major phase:

1. Run the project.
2. Run automated tests.
3. Fix errors.
4. Update `docs/CURRENT_STATE.md`.
5. Update `docs/ROADMAP.md`.
6. Summarize what was completed.
7. List known limitations.
8. State the next highest-priority task.

Do not claim something works unless it has been run or tested.

Do not leave major systems as pseudocode unless clearly documented as future work.

Do not generate hundreds of low-quality placeholder cards.

Focus on making the underlying loop extensible, testable, and reliable.

---

# 28. First action

Start now by:

1. Inspecting the repository.
2. Reporting the current technical state.
3. Creating or updating the documentation files.
4. Proposing the exact architecture based on what is actually present.
5. Running the existing project if possible.
6. Beginning Phase 1 after resolving any genuine blockers.

The immediate goal is not to finish the entire game.

The immediate goal is to create a strong foundation capable of supporting the full reincarnation roguelike without requiring a major rewrite later.
