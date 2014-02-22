# Scripting Language

Items in the game inherit data and functionality from an archetype.
Archetypes use single inheritence to inherit data and functionality from
other archetypes but may inherit functionality from multiple traits as
mixins.

Archetype definition files may start with a YAML metadata section followed 
by any number of mixin declarations, abilities, qualities, calculations, and 
event handlers.

## Archetype

When defining an archetype, you may specify a parent archetype from which data, calculations, and event handlers are inherited.

```
based on foo:bar
```

## Traits

An archetype or trait may inherit from as many traits as desired. If the
trait can not be found, then it will be considered a quality of the
archetype.

```
is possibly-living, wearable, holdable
```

## Qualities

Qualities describe how a particular item is different than another item.

```
is living if flag:living
```

## Abilities

Abilities describe ways in which an item can participate in the game
narrative. As such, abilities can be scoped to a part of speech:

- actor
- direct (object)
- indirect (object)
- instrument
- environment
- observer

If a part of speech is not specified, then the ability matches any
of the requested parts of speech.





## Defined Functions

The following functions are defined as part of the driver API.

### Describe([sense,] object)

Creates a string describing the object appropriately for the given sense (or
for 'sight' if no sense is provided) taking into account time of day and
season.

### Emit(class, text)

Sends the given text to the player controlling this character (if there is
one). The class determines in part how the player's access method shows the
content.

### MoveTo(class, relation, target [, msg_out, msg_in])
### MoveTo(class, location [, msg_out, msg_in])

Moves the current item to the designated location. The `class` is the type
of motion being undertaken (e.g., normal or magic) and can be used to prevent
certain types of movement. The `class` also provides default in/out messages.

This function returns `True` if the move was successful. As part of the move
operation, the following events are called:

- physical:location # pre-move:release
- target # pre-move:receive
- this # pre-move:accept

If any of these returns a `False` value, the move will be rejected. If all of
them return true, then the move will go forward.

As part of the move, anything in a relation with `this` that isn't 'in,'
'on,' 'worn by,' or 'held by' will be moved to having the same relationship
with the the location being left as `this` does. For example, if a bucket is
near a horse and the horse is on the floor, then when the horse leaves, the
bucket will be on the floor.

After the item being moved is in place in the new location, the following
events are called:

- (prior)physical:location # post-move:release
- (new)physical:location # post-move:receive
- this # post-move:accept

