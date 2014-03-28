#
# Add positioning
#

can act:sit as actor if is living
can act:stand as actor if is living
can act:kneel as actor if is living
can act:crouch as actor if is living

can sit if physical:position <> "sitting"
can stand if physical:position <> "standing"
can kneel if physical:position <> "kneeling"
can crouch if physical:position <> "crouching"

is standing if physical:position = "standing"
is kneeling if physical:position = "kneeling"
is sitting if physical:position = "sitting"
is crouching if physical:position = "crouching"

validates physical:position with
  if value & trait:allowed:positions then
    True
  else
    False
  end

calculates trait:allowed:positions with do
  set $prop to "default:allowed-relations:" _ physical:location:relation
  if physical:location.detail:$prop then
    physical:location.detail:$prop & ([ "standing", "sitting", "kneeling", "crouching" ])
  else
    ([ "standing", "sitting", "kneeling", "crouching" ])
  end
end

reacts to change:physical:position with
  if value = "standing" then
    :"<this:name> <stand> up."
  elsif value = "sitting" then
    :"<this:name> <sit> down."
  elsif value = "crouching" then
    :"<this:name> <crouch>."
  elsif value = "kneeling" then
    :"<this:name> <kneel>."
  end

reacts to pre-act:sit as actor with
  if is sitting then
    uhoh "You are already sitting."
  elsif can sit as actor then
    if "sitting" & trait:allowed:positions then
      set flag:is-about-to-sit
    else
      uhoh "You can't sit there."
    end
  else
    uhoh "Something prevents you from sitting."
  end

reacts to post-act:sit as actor with
  if flag:is-about-to-sit then
    reset flag:is-about-to-sit
    set physical:position to "sitting"
  end

reacts to pre-act:crouch as actor with
  if is crouching then
    uhoh "You are already crouching."
  elsif can crouch as actor then
    if "crouching" & trait:allowed:positions then
      set flag:is-about-to-crouch
    else
      uhoh "You can't crouch there."
    end
  else
    uhoh "Something prevents you from crouching."
  end

reacts to post-act:crouch as actor with
  if flag:is-about-to-crouch then
    reset flag:is-about-to-crouch
    set physical:position to "crouching"
  end

reacts to pre-act:kneel as actor with
  if is kneeling then
    uhoh "You are already kneeling."
  elsif can kneel then
    if "kneeling" & trait:allowed:positions then
      set flag:is-about-to-kneel
    else
      uhoh "You can't kneel there."
    end
  else
    uhoh "Something prevents you from kneeling."
  end

reacts to post-act:kneel as actor with
  if flag:is-about-to-kneel then
    reset flag:is-about-to-kneel
    set physical:position to "kneeling"
  end

reacts to pre-act:stand as actor with
  if is standing then
    uhoh "You are already standing."
  elsif can stand then
    if "standing" & trait:allowed:positions then
      set flag:is-about-to-stand
    else
      uhoh "You can't stand there."
    end
  else
    uhoh "Something prevents you from standing."
  end

reacts to post-act:stand as actor with
  if flag:is-about-to-stand then
    reset flag:is-about-to-stand
    set physical:position to "standing"
  end