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
is positional, movable

can scan:brief as actor
can scan:item as actor

can move:accept
can see

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
# pre-scan:item
#
reacts to pre-scan:item as actor with do
  set flag:scan-item
  set flag:scanning
end

reacts to post-scan:item as actor with
  if flag:scan-item then
    :"<actor:name> <examine> <direct>."
    reset flag:scan-item
    reset flag:scanning

    Emit("env:sight", Describe(direct))
  end

##
# pre-scan:brief
#
# We set the flag that we'll be looking around.
# This lets other things react to this.
reacts to pre-scan:brief as actor with do
  set flag:brief-scan
  set flag:scanning
end

reacts to post-scan:brief as actor with
  if flag:brief-scan then
    :"<actor:name> <look> around."
    reset flag:brief-scan
    reset flag:scanning

    Emit("env:title", ( physical:environment.detail:default:name // "somewhere" ) )

    Emit("env:sight", "You are")
    if physical:position then
      Emit("env:sight", physical:position)
    end

    set $period to ""
    if physical:location = physical:environment
      set $period to "."
    end

    if physical:location.detail:default:name
      if physical:location:relation then
        Emit("env:sight", physical:location:relation)
      end
      if physical:location.detail:default:name then
        if physical:location.detail:default:article then
          Emit("env:sight", physical:location.detail:default:article)
        end
        Emit("env:sight", physical:location.detail:default:name _ $period)
      else
        Emit("env:sight", "somewhere" _ $period)
      end
    end
    if physical:location <> physical:environment then
      Emit("env:sight", "in")
      if physical:environment.detail:default:article then
        Emit("env:sight", physical:environment.detail:default:article)
      end
      Emit("env:sight", physical:environment.detail:default:name _ ".")

      Emit("env:sight", Describe(physical:location.physical:location) )
    else
      Emit("env:sight", Describe(physical:location) )
    end
    Emit("env:exits", ItemList(Keys(Exits(physical:location))))
    # now we can list items/mobs nearby/in the scene
  end