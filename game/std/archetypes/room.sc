based on std:item

can move:receive
can move:release

# prevents magical movement from/to rooms
can not move:receive:magic
can not move:release:magic

reacts to pre-scan:item as direct with
  True

reacts to pre-act:read:item as direct with
  if detail then
    set $prop to detail _ ":read"
    if detail:$prop then
      True
    else
      False
    end
  else
    if detail:default:read then
      True
    else
      False
    end
  end

can scan:item as direct
can act:read:item as direct
can act:move:behind as direct
can act:move:on as direct
can act:enter as direct

reacts to pre-move:receive with
  True

reacts to pre-move:release with
  True