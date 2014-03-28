#
# massive
#
# Handles object massiveness and weight
#
# physical:mass - mass of object, not including any carried items
# physical:carried-mass - mass of all carried items
# physical:total-mass - mass + carried-mass
#

calculates physical:carried-mass with
  (0 lbs) + physical:inventory.physical:total-mass

calculates physical:total-mass with
  physical:mass + physical:carried-mass

calculates physical:weight with
  physical:total-mass * (physical.environment.physical:gravity // (9.8 m/s^2))

reacts to pre-move:receive with
  if physical:carried-mass + actor.physical:total-mass > physical:carried-mass:max then
    False
  else
    True
  end