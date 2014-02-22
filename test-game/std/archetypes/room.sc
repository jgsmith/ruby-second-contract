based on std:item

can move:receive
can move:release

# prevents magical movement from/to rooms
can not move:receive:magic
can not move:release:magic

reacts to pre-move:receive with
  True

reacts to pre-move:release with
  True