can act:go as actor if is living
can act:move:behind as actor if is living
can act:move:on as actor if is living
can act:enter as actor if is living

is crawling if flag:crawling

##
# pre-act:go
#

reacts to pre-act:go as actor with do
  if is standing or is crawling then
    set flag:going
  else
    uhoh "You must be standing to go somewhere. Perhaps you meant to crawl?"
  end
end

##
# post-act:go
#

reacts to post-act:go as actor with
  if flag:going then
    reset flag:going
    if MoveTo("normal", Exits(physical:location)[exit]) then
      :"<actor:name> show up somewhere new."
    else
      :"<actor:name> <try> to head " _ exit _ " but <actor:fail>."
    end
  end

##
# pre-act:move:behind
#
reacts to pre-act:move:behind as actor with
  if is standing or is crawling then
    set trait:moving-preposition to "behind"
    set flag:moving
  else
    uhoh "You must be standing to go somewhere. Perhaps you meant to crawl?"
  end

##
# pre-act:move:on
#
reacts to pre-act:move:on as actor with
  if is standing or is crawling then
    set trait:moving-preposition to "on"
    set flag:moving
  else
    uhoh "You must be standing to go somewhere. Perhaps you meant to crawl?"
  end

##
# post-act:move:*
#
reacts to post-act:move as actor with
  if flag:moving then
    reset flag:moving
    if MoveTo("normal", trait:moving-preposition, direct) then
      :("<actor:name> <move> " _ trait:moving-preposition _ " <direct>.")
    else
      :("<actor:name> <try> to move " _ trait:moving-preposition _ " <direct> but <actor:fail>.")
    end
    reset trait:moving-preposition
  end

##
# pre-act:enter
#
reacts to pre-act:enter as actor with
  if is standing or is crawling then
    if direct.detail:default:enter then
      set flag:entering
    else
      uhoh "You can't enter there."
    end
  else
    uhoh "You must be standing to go somewhere. Perhaps you meant to crawl?"
  end

##
# post-act:enter
#
reacts to post-act:enter as actor with
  if flag:entering then
    reset flag:entering
    if MoveTo("normal", direct.detail:default:enter) then
      :"<actor:name> <enter> <direct>."
    else
      :"<actor:name> <try> to enter <direct> but <actor:fail>."
    end
  end