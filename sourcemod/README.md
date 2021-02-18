# Attribute Usage:

## Change Projectiles:

Example:

`"replace_projectile" "projectilename_replacer=tf_projectile_rocket projectilename_old=tf_projectile_jar projectile_speed=2000.0"`


Arguments:

`"projectilename_replacer": New projectile`

`"projectilename_old": Old projectile`

`"projectile_speed": New projectile speed`

## Homing Projectiles:

* Example:

"homing_proj_mvm"	"detection_radius=500.0 homing_mode=1 projectilename=tf_projectile_rocket"


* Arguments:

`"detection_radius": Self explain, detection radius for player`

`"homing_mode": 0=totally homing and 1=soft homing`

`"projectilename": Projectile's name for homing`

## BlackHole Projectiles:

* Example:

`"blackhole_proj" "projectilename=tf_projectile_pipe hole_duration=20.0 hole_duration=2.0  player_radius=500.0 damages_radius=100 damage=10 player_push_force=200 work_on_projectile=1 projectile_radius=1000 projectile_push_force=1000 projectile_change_owner_radius=200"`


* Arguments:

`"projectilename": Projectile name for blackhole, works with all, like pipes and jarate (not cleaver)`

`"hole_duration": Blackhole duration`

`"player_radius": Radius where a player was push/attract by the blackhole`

`"damages_radius": Radius where player takes damage`

`"damage": Damage number per game tick`

`"player_push_force": Force attract/push, make negative values for push`

`"work_on_projectile": 0 = no and 1 = yes`

`"projectile_radius": Same for player but for projectile`

`"projectile_push_force": Same for player but for projectile`

`"projectile_change_owner_radius": Projectile was changed in this radius`


# Other change:

Fix some minor bugs for blackhole
