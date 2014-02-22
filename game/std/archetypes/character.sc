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

    if physical:position then
      set $description to "You are " _ physical:position
    else
      set $description to "You are"
    end
    if physical:location.detail:default:name
      if physical:location:relation then
        set $description to $description _ " " _ physical:location:relation
      end
      if physical:location.detail:default:name then
        if physical:location.detail:default:article then
          set $description to $description _ " " _ physical:location.detail:default:article
        end
        set $description to $description _ " " _ physical:location.detail:default:name
      else
        set $description to $description _ " somewhere"
      end
    end
    if physical:location <> physical:environment then
      set $description to $description _ " in"
      if physical:environment.detail:default:article then
        set $description to $description _ " " _ physical:environment.detail:default:article
      end
      set $description to $description _ " " _ physical:environment.detail:default:name
    end

    Emit("env:sight", $description _ ". " _ Describe(physical:environment) )
    Emit("env:exits", ItemList(Keys(Exits(physical:location))))
    # now we can list items/mobs nearby/in the scene
  end