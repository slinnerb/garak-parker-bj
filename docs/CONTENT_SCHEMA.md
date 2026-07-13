# Content Schema

All game content is **data-driven** and referenced by **stable string ids**.
Display names are never used as identifiers. This document is the contract for
those data definitions. Most are **planned** (Phase 2); the registry and id
discipline exist today.

## Golden rules

- Every content entry has a unique, stable `id` (snake_case, e.g.
  `harpoon`, `deep_one_acolyte`, `lovecraft_coast`). Ids never change once
  shipped — they appear in save files.
- Ids are unique **within a content type**. `ContentRegistry.register()`
  refuses duplicates and logs an error so bad data fails loudly.
- References between content use ids (an enemy's loot table references item
  ids; a universe references enemy ids). Validation checks these resolve.
- Required fields must be present and non-empty. Validation reports empties.

## Content registry

`ContentRegistry` (autoload) stores content as `type_name -> { id -> def }`:

```gdscript
ContentRegistry.register("item", "harpoon", harpoon_def)
var def = ContentRegistry.get_def("item", "harpoon")
var problems := ContentRegistry.validate_all()   # [] means valid
```

Validation (to be expanded as types land) will report: duplicate ids, missing
references, empty required fields, invalid costs, invalid effect data,
unreachable content, missing universe assignments, and broken loot-table
references.

## Planned definition types

These will be implemented as Godot `Resource` subclasses (or typed dictionaries
loaded from JSON) in `content/`. Fields listed are the intended shape.

### CardDefinition
`id`, `display_name`, `source_item_id`, `energy_cost`, `type`
(attack/skill/power/status/curse), `targeting`, `effects` (list of
`CardEffectDefinition`), `rarity`, `tags`, `exhaust`, `retain`, `temporary`,
`consumable`, `universe_theme`, `art_ref`.

### CardEffectDefinition
Composable effect: `kind` (deal_damage / gain_block / heal / draw /
apply_status / remove_status / modify_energy / add_temp_card / exhaust /
transform / modify_item / conditional / repeat / random_target), plus
kind-specific params. **Complex cards compose these; avoid one script per card.**

### ItemDefinition
`id`, `display_name`, `category` (weapon / defensive / tool / charm / relic /
consumable / forbidden / quest / soulbound), `slot_cost`, `granted_card_ids`,
`passive_modifiers`, `cursed`, `removable`, `charges` (for consumables),
`universe_availability`, `rarity`, `tags`, `art_ref`.

### EnemyDefinition
`id`, `display_name`, `base_hp`, `tags`, `resistances`, `weaknesses`,
`intents` (list of `EnemyIntentDefinition`), `behavior`, `loot_table_id`,
`universe_availability`, `difficulty_modifiers`, `is_elite`, `is_boss`.

### EnemyIntentDefinition
`id`, `kind` (attack/defend/buff/debuff/special), `value`, `telegraph`,
`weight` / selection rule.

### StatusEffectDefinition
`id`, `display_name`, `stacking` (intensity/duration/none), `decay`,
`hooks` (on_turn_start / on_turn_end / on_take_damage / …), `tags`.

### UniverseDefinition
`id`, `display_name`, `description`, `intro_text`, `theme_tags`,
`enemy_ids`, `elite_ids`, `boss_ids`, `item_ids`, `event_ids`, `location_ids`,
`card_theme`, `music_refs`, `difficulty_range`, `unlock_requirements`,
`base_weight`, `recent_visit_penalty`, `death_cause_weights`, `tattoo_weights`,
`awareness_modifiers`, `map_gen_settings`.

### EncounterDefinition / MapNodeDefinition
Encounter: what a node spawns (enemies, event, shop, etc.).
Map node: `type` (combat / elite / boss / item_search / event / merchant /
shrine / rest / tattoo / memory_anomaly / treasure / story), connections, weights.

### TattooDefinition
`id`, `display_name`, `soul_identity`, `functions`, `upgrade_stages`,
`universe_display_overrides`, `unlock_requirements`, `awareness_delta`.

### MemoryDefinition
`id`, `type` (instinct / technique / trauma / item), `effect`, `drawback`
(for trauma), `source_universe`, `unlock_requirements`.

### DeathAdaptationDefinition
`id`, `display_name`, `trigger` (cause-of-death tags / enemy family / carried
item), `effect`, `drawback`, `unlock_requirements`. **Adaptations are data, not
hard-coded branches in the death manager.**

### BodyArchetypeDefinition
`id`, `display_name`, `base_hp`, `base_energy`, `starting_item_loadout`,
`base_slots`.

### LootTableDefinition
`id`, weighted entries of item/card ids, guaranteed drops, universe filters.

### DifficultyDefinition
`id`, scaling modifiers, unlock requirements.
