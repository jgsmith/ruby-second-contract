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

reacts to pre-act:sit as actor with
  if physical:position <> "sitting" then
    set flag:is-about-to-sit
  else
    uhoh "You are already sitting."
  end

reacts to post-act:sit as actor with
  if flag:is-about-to-sit then
    :"<actor:name> <sit> down."
    reset flag:is-about-to-sit
    set physical:position to "sitting"
  end

reacts to pre-act:crouch as actor with
  if physical:position <> "crouching" then
    set flag:is-about-to-crouch
  else
    uhoh "You are already crouching."
  end

reacts to post-act:crouch as actor with
  if flag:is-about-to-crouch then
    :"<actor:name> <crouch> down."
    reset flag:is-about-to-crouch
    set physical:position to "crouching"
  end

reacts to pre-act:kneel as actor with
  if physical:position <> "kneeling" then
    set flag:is-about-to-kneel
  else
    uhoh "You are already kneeling."
  end

reacts to post-act:kneel as actor with
  if flag:is-about-to-kneel then
    :"<actor:name> <kneel> down."
    reset flag:is-about-to-kneel
    set physical:position to "kneeling"
  end

reacts to pre-act:stand as actor with
  if physical:position <> "standing" then
    set flag:is-about-to-stand
  else
    uhoh "You are already standing."
  end

reacts to post-act:stand as actor with
  if flag:is-about-to-stand then
    :"<actor:name> <stand> up."
    reset flag:is-about-to-stand
    set physical:position to "standing"
  end