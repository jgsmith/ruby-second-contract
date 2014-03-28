#
# smelling
#
# provides the capability to read
#

can act:smell:item as actor

reacts to pre-act:smell:item as actor with do
  set flag:smell-item
  set flag:smelling
end

reacts to post-act:smell:item as actor with
  if flag:smell-item then
    :"<actor:name> <sniff> <direct>."
    reset flag:smell-item
    reset flag:smelling

    Emit("env:smell", direct.detail:default:smell)
  end