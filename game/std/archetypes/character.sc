---
flags:
  living: true
details:
  default:
    noun:
      - human
    adjective:
      - simple
---
based on std:item
is positional, movable, gendered
is reading, smelling, viewing

can scan:brief as actor
can scan:item as actor

can move:accept
can see
can smell

reacts to pre-move:accept with
  True

reacts to post-move:accept with
  if physical:location.detail:default:position and not (physical:position & trait:allowed:positions) then
    set physical:position to physical:location.detail:default:position
  end

##
# msg:sight:env
# 
# Used to report on events around that can be seen.
#
reacts to msg:sight with
  Emit("narrative:sight", text)

##
# msg:smell:env
#
# Used to report on events around that can be smelled.
#
reacts to msg:smell with
  Emit("narrative:smell", text)