/**
 * Sourcemod 1.7 Plugin Template
 */
#pragma semicolon 1
#include <sourcemod>

#include <smlib/clients>

#include <sdkhooks>
#include <sdktools>
#include <tf_custom_attributes>
#include <stocksoup/tf/entity_prop_stocks>
#include <stocksoup/var_strings>

public void OnPluginStart() {}

public void OnMapStart() {}

public OnEntityCreated(int entity, const char[] classname)
{
	if (strncmp(classname, "tf_projectile_",14)==0)
	{
		SDKHook(entity, SDKHook_SpawnPost, PostPawnProjectile);
	}
}

public Action PostPawnProjectile(entity)
{
	char attr[124];
	char Projectilename[124];
	char ProjectileReplacer[124];
	char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (client!=-1)
	{
		if (IsClientInGame(client))
		{
			int weapon = TF2_GetClientActiveWeapon(client);
			if (IsValidEntity(weapon))
			{
				if (TF2CustAttr_GetString(weapon, "replace_projectile", attr, sizeof(attr)))
				{
					float Speed = ReadFloatVar(attr, "projectile_speed", 2000.0);
					ReadStringVar(attr, "projectilename_replacer", ProjectileReplacer, sizeof(ProjectileReplacer), "tf_projectile_rocket");
					ReadStringVar(attr, "projectilename_old", Projectilename, sizeof(Projectilename), "tf_projectile_rocket");
					if (StrEqual(classname, Projectilename)) 
					{
						ReplaceProjectile( client, ProjectileReplacer, Speed, entity );
					}
				}
			}
			else if (TF2CustAttr_GetString(client, "replace_projectile", attr, sizeof(attr)))
			{
				float Speed = ReadFloatVar(attr, "projectile_speed", 2000.0);
				ReadStringVar(attr, "projectilename_replacer", ProjectileReplacer, sizeof(ProjectileReplacer), "tf_projectile_rocket");
				ReadStringVar(attr, "projectilename_old", Projectilename, sizeof(Projectilename), "tf_projectile_rocket");
				if (StrEqual(classname, Projectilename)) 
				{
					ReplaceProjectile( client, ProjectileReplacer, Speed, entity );
				}
			}
		}
	}
}


stock ReplaceProjectile( client, const char[] replacer, float Speed, int entity )
{
	float position[3], angle[3], velocity[3], vBuffer[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", angle);
	GetAngleVectors(angle, vBuffer, NULL_VECTOR, NULL_VECTOR);	
	
	int proj=CreateEntityByName(replacer);
	SetVariantInt(GetClientTeam(client));
	AcceptEntityInput(proj, "TeamNum");
	SetVariantInt(GetClientTeam(client));
	AcceptEntityInput(proj, "SetTeam"); 
	SetEntPropEnt(proj, Prop_Send, "m_hOwnerEntity",client);	
	velocity[0] = vBuffer[0] * Speed;
	velocity[1] = vBuffer[1] * Speed;
	velocity[2] = vBuffer[2] * Speed;
	AcceptEntityInput(entity, "Kill");
	DispatchSpawn(proj);
	TeleportEntity(proj, position, angle,velocity);
}

