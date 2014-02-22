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

can move:accept
can scan:brief as actor

reacts to pre-move:accept with
  True

##
# msg:sight:env
# 
# Used to report on events around that can be seen.
#
reacts to msg:sight with
  Emit("env:sight", text)

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

    Emit("env:description", $description _ ". " _ Describe(physical:environment) )
    
    # now we can list items/mobs nearby/in the scene
    True
  end