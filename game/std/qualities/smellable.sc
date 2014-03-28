#
# smellable
#

can act:smell:item as direct

reacts to pre-act:smell:item as direct with
  if detail then
    set $prop to detail _ ":smell"
    if detail:$prop then
      True
    else
      False
    end
  else
    if detail:default:smell then
      True
    else
      False
    end
  end