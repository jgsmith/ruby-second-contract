#
# readable
#

can act:read:item as direct

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