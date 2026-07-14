# Content Schema

All game content is **data-driven** and referenced by **stable string ids**.
Display names are never used as identifiers. This documents the implemented
Phase 2 data model. The definition classes themselves are the precise contract
— each one's `from_dict()` and `validate()` are the source of truth:

| Type key | Class | File |
|---|---|---|
| `card` | `CardDefinition` | `gameplay/cards/card_definition.gd` |
| — | `CardEffectDefinition` | `gameplay/cards/card_effect_definition.gd` |
| `item` | `ItemDefinition` | `gameplay/items/item_definition.gd` |
| `enemy` | `EnemyDefinition` | `gameplay/enemies/enemy_definition.gd` |
| — | `EnemyIntentDefinition` | `gameplay/enemies/enemy_intent_definition.gd` |
| `status` | `StatusEffectDefinition` | `gameplay/combat/status_effect_definition.gd` |
| `universe` | `UniverseDefinition` | `gameplay/universes/universe_definition.gd` |
| `map_node` | `MapNodeDefinition` | `gameplay/map/map_node_definition.gd` |
| `loot_table` | `LootTableDefinition` | `gameplay/progression/loot_table_definition.gd` |
| `difficulty` | `DifficultyDefinition` | `gameplay/progression/difficulty_definition.gd` |
| `tattoo` | `TattooDefinition` | `gameplay/tattoos/tattoo_definition.gd` |
| `memory` | `MemoryDefinition` | `gameplay/memories/memory_definition.gd` |
| `adaptation` | `DeathAdaptationDefinition` | `gameplay/death/death_adaptation_definition.gd` |
| `body_archetype` | `BodyArchetypeDefinition` | `gameplay/progression/body_archetype_definition.gd` |

All extend `ContentDefinition` (`gameplay/definitions/content_definition.gd`),
which owns the shared fields (`id`, `display_name`, `description`, `tags`),
the `TYPE_*` registry keys, shared vocabularies (`RARITIES`, `DAMAGE_TYPES`),
and the validation helpers.

## Golden rules

- Every entry has a unique, stable snake_case `id` (e.g. `rusted_harpoon`,
  `lovecraft_coast`). **Ids never change once shipped** — they appear in saves.
- Ids are unique within a content type; `ContentRegistry.register()` refuses
  duplicates and logs an error.
- Cross-references use ids and are validated: cards ↔ items (bidirectional),
  enemies → loot tables, loot → items/cards, universes → enemies/items,
  tattoos/memories/adaptations → items/universes, archetypes → items.
- Definitions are **pure data + validation**: `RefCounted`, no autoloads, no
  nodes. The registry is passed into `validate(registry)` and may be `null`
  (unit tests) — reference checks are skipped then.
- `from_dict()` never crashes on malformed data; bad shapes become validation
  problems instead.

## The pattern

```gdscript
var def := CardDefinition.from_dict({
	"id": "strike_harpoon",
	"display_name": "Harpoon Strike",
	"source_item_id": "rusted_harpoon",
	"card_type": "attack",            # attack/skill/power/status/curse
	"energy_cost": 1,                 # 0..9
	"targeting": "enemy",             # none/self/enemy/all_enemies/random_enemy
	"effects": [{"kind": "deal_damage", "amount": 6}],
})
var problems := def.validate(ContentRegistry)   # [] means valid
```

Effect kinds (composable; complex cards compose these — no per-card scripts):
`deal_damage, gain_block, heal, draw_cards, apply_status, remove_status,
modify_energy, add_temporary_card, exhaust_card, transform_card, modify_item,
conditional, repeat, random_target`. `conditional` nests `then`/`else` effect
lists; `repeat`/`random_target` nest `effects`; nesting is validated to depth 4.

Design-rule validations worth knowing (enforced, with tests):

- A card with no `source_item_id` must be a `status`/`curse` card or carry the
  `generated` tag — **every real card originates from a physical item**.
- An item must do something: grant cards, or carry `passive_modifiers`, or be
  a `quest` item. Consumables require `charges >= 1`.
- Every enemy needs at least one **unconditional** intent (a guaranteed legal
  move) and unique intent ids; elites and bosses are mutually exclusive flags.
- Trauma memories **require a drawback**. Adaptation triggers must name at
  least one condition (death-cause / enemy / carried-item tags, universes).
- A body archetype's starting items must fit its attunement slots.

## Authoring content

Content lives in plain data scripts under `content/` — no editor needed:

```gdscript
extends RefCounted
static func content_type() -> String:
	return "item"
static func data() -> Array[Dictionary]:
	return [ { "id": ..., ... }, ... ]
```

`ContentLoader` (`core/content/content_loader.gd`) hardcodes the script list
and registers everything at boot (idempotent). To add content: add entries to
an existing script (or add a script + list it in `ContentLoader.CONTENT_SCRIPTS`),
then run the tests — `test_sample_content.gd` re-validates the whole set.

## Validation

`ContentRegistry.validate_all()` runs every definition's `validate(self)` plus
global checks no single definition can see:

- `fixed_order_position` 1, 2, 3 each claimed by exactly one universe
  (Lovecraft → Japanese → Norse is the mandated opening order).
- At least one `playable` universe; playable universes need enemies, a boss,
  and items.
- At least one body archetype exists.

Boot calls this after loading (`GameBootstrap._validate_content`) and **fails
loudly in dev builds** when content is invalid; release builds log and continue.
