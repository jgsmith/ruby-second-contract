# Item Properties

Items and archetypes have properties managed by a number of game systems.
These properties are accessed using the system name as a prefix. For example,
the value of the `foo` trait is accessed by `trait:foo`.

## Counters

Counters are general numeric trackers that are not skills, resources, or
traits. Counters are not ephemeral or temporary, are not inherited from 
an archetype, and are not subject to calculation overrides except for the
counter maximum. Counters may have debt which must be repaid before the
counter will increase again. However, this debt must be explicitely set.
Simply subtracting from a counter will not set the debt.

When a counter hits or passes its maximum, the system triggers an event
for the item to handle (e.g., allowing accumulated experience to trigger
a level increase for player characters).

Counters may not be negative.

The following counters are expected for other game systems.

| Property | Meaning | Value |
| -------- | ------- | ----- |
| counter:level | The level of the character or npc | 0.. |
| counter:level:max | The maximum level of a character or npc | 5 |
| counter:experience | The accumulated experience of the character or npc | 0.. |
| counter:experience:debt | Optional experience debt due to deaths or other events | 0.. |
| counter:experience:max  | Maximum experience for a given level | 0.. |

## Details

## Physicals

Physical properties are managed by the game system, though some allowance is
made for custom properties.

| Property | Meaning | Value |
| -------- | ------- | ----- |
| physical:environment | The item that can be considered the container | another item (scene, path, etc.) |
| physical:mass | The mass of the item | >= 0 kilogram |
| physical:mass:base | The basic unit of mass | 0 kilogram |
| physical:mass:capacity | The maximum mass this item can contain | >= 0 kilogram |
| physical:volume | The volume of the item | >= 0 liter |
| physical:volume:base | The basic unit of volume | 0 liter |
| physical:volume:capacity | The maximum volume this item can contain | >= 0 liter |
| physical:amount | The amount of an item | >= 0 units |
| physical:amount:base | The basic unit of amount | 0 units |
| physical:amount:capacity | The maximum amount of this item as a single item | >= 0 units |

Note that the units for physical:amount is determined by the item. Typically
this will be inherited from the archetype. Possible units are defined in the
game configuration file. The physical:amount:capacity is the maximum amount
of this item that can be contained within a single item (e.g., the maximum
amount of carpet in a roll of carpet might be 500 sq. ft. with any more than
that requiring more than one roll of carpet).

## Resources

Resources are general numeric trackers that are not skills or traits.
Resource values are not inherited from archetypes, though calculations
of resource properties such as a maximum may be.

When a resource hits zero, the system triggers an event for the item to
handle (e.g., when health reaches zero).

Resources may not be negative.

## Skills

Skills are used to judge how well a character does a task. Skill names can
be arbitrary except that they should not contain a colon (:). Skill
information is structured, so each skill has a maximum, bonus, etc.
according to the following structure.

| Property | Meaning | Values |
| -------- | ------- | ------ |
| skill:foo | The level of skill in "foo" | 0..skill:foo:max |
| skill:foo:max | The maximum level to which skill:foo can be set | 0.. |
| skill:foo:class | The class of skill "foo" (0 indicates a primary class) | 0..4 |
| skill:foo:points | The accumulated experience in this skill | 0.. |

When skill:foo:points reaches its maximum, the character will increase
skill:foo by a level unless it is already maximized. The value of
skill:foo:max depends on skill:foo:class and counters:level. This maximum may
be modified through an overriding calculation, but such an override must be
explicitely coded for each skill for which it applies.

Skills may be added at any time by archetypes or traits. Simply referencing
the relevant skill property is enough.

## Traits

Traits are a general catch-all for transient information about an item.
Traits are useful when coordinating event handlers that change the state
of an item. For example, the pre-event handler can set a trait that lets
other event handlers know that the item is transitioning. If the trait
remains set for the post-event handler, then the item can complete the
transition and provide related narrative.

No traits are predefined. The trait name is arbitrary and the values can
be numeric, string, or boolean. Units or other special types are not
handled by the system.