#
# reading
#
# provides the capability to read
#

can act:read:item as actor

reacts to pre-act:read:item as actor with do
  set flag:read-item
  set flag:reading
end

reacts to post-act:read:item as actor with
  if flag:read-item then
    :"<actor:name> <read> <direct>."
    reset flag:read-item
    reset flag:reading

    Emit("env:sight", direct.detail:default:read)
  end