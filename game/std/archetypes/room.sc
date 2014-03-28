based on std:item

can move:receive
can move:release

# prevents magical movement from/to rooms
can not move:receive:magic
can not move:release:magic

reacts to pre-scan:item as direct with
  True

can scan:item as direct
can act:move:behind as direct
can act:move:on as direct
can act:enter as direct

reacts to pre-move:receive with
  True

reacts to pre-move:release with
  True