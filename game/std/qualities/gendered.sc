#
# gendered
#

validates physical:gender with
   if value & %w(male female neuter none) then
    True
  else
    False
  end