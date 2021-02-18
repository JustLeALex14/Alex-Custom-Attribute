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

public void OnMapStart() {
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strncmp(classname, "tf_projectile_",14)==0 && !(!strcmp(classname, "tf_projectile_pipe") || 
	!strcmp(classname, "tf_projectile_pipe_remote") || 
	!strcmp(classname, "tf_projectile_jar") || 
	!strcmp(classname, "tf_projectile_cleaver") || 
	!strcmp(classname, "tf_projectile_stun_ball") || 
	!strcmp(classname, "tf_projectile_spellmeteorshower") || 
	!strcmp(classname, "tf_projectile_spellbats") || 
	!strcmp(classname, "tf_projectile_jar_milk") || 
	!strcmp(classname, "tf_projectile_jar_gas") ||
	!strcmp(classname, "tf_projectile_balloffire") ||
	!strcmp(classname, "tf_projectile_ball_ornament")))
	{
		SDKHook(entity, SDKHook_StartTouchPost, OnEntityTouch);
	}
}

public OnEntityDestroyed(entity)
{
	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));	
	if (strncmp(classname, "tf_projectile_",14)==0 && HasEntProp(entity,Prop_Data,"m_hThrower"))
	{
		int client = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
		
		int weapon = TF2_GetClientActiveWeapon(client);
		if (IsValidEntity(weapon))
		{
			char attr[1024];
			char Projectilename[124];
			if (TF2CustAttr_GetString(weapon, "blackhole_proj", attr, sizeof(attr)))
			{
				ReadStringVar(attr, "projectilename", Projectilename, sizeof(Projectilename), "tf_projectile_rocket");
				if ((1 <= client <= MaxClients) && IsClientInGame(client) && !strcmp(classname, Projectilename))
				{
					float Pos[3];
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);
					CreateBlackHole(client, Pos, attr);
				}
			}
		}
	}
	
}

public Action OnEntityTouch(int entity)
{
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	char cClassname[32];
	GetEntityClassname(entity, cClassname, sizeof(cClassname));	
	int weapon = TF2_GetClientActiveWeapon(client);
	if (IsValidEntity(weapon))
	{
		char attr[1024];
		char Projectilename[124];
		if (TF2CustAttr_GetString(weapon, "blackhole_proj", attr, sizeof(attr)))
		{
			ReadStringVar(attr, "projectilename", Projectilename, sizeof(Projectilename), "tf_projectile_rocket");
			if ((1 <= client <= MaxClients) && IsClientInGame(client) && !strcmp(cClassname, Projectilename))
			{
				float Pos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);
				CreateBlackHole(client, Pos, attr);
				return Plugin_Continue;
			}
		}
	}
		
	return Plugin_Continue;
}



stock Action CreateBlackHole( int client, float pos[3], const char[] attr )
{
	float fDuration = ReadFloatVar(attr, "hole_duration", 5.0);
	
	int Iparticle;
	
	Iparticle = CreateEntityParticle("eb_tp_vortex01", pos);
	SetEntitySelfDestruct(Iparticle, fDuration);
	
	Iparticle = CreateEntityParticle(TF2_GetClientTeam(client) == TFTeam_Red ? "raygun_projectile_red_crit" : "raygun_projectile_blue_crit", pos);
	SetEntitySelfDestruct(Iparticle, fDuration);
	
	Iparticle = CreateEntityParticle(TF2_GetClientTeam(client) == TFTeam_Red ? "eyeboss_vortex_red" : "eyeboss_vortex_blue", pos);
	SetEntitySelfDestruct(Iparticle, fDuration);
	
	
	DataPack pPack;
	CreateDataTimer(0.1, Timer_Pull, pPack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	pPack.WriteFloat(GetEngineTime() + fDuration);
	pPack.WriteString(attr);
	pPack.WriteFloat(pos[0]);
	pPack.WriteFloat(pos[1]);
	pPack.WriteFloat(pos[2]);
	pPack.WriteCell(client);
	
	
	return Plugin_Handled;
}

public Action Timer_Pull(Handle timer, DataPack pack)
{
	pack.Reset();
	
	if (GetEngineTime() >= pack.ReadFloat())
	{
		return Plugin_Stop;
	}
	
	char attr[1024];
	pack.ReadString(attr, sizeof(attr));
	
	float pos[3];
	pos[0] = pack.ReadFloat();
	pos[1] = pack.ReadFloat();
	pos[2] = pack.ReadFloat();
	
	int attacker = pack.ReadCell();
	
	float fRadius = ReadFloatVar(attr, "player_radius", 1000.0);
	float fDamageRadius = ReadFloatVar(attr, "damages_radius", 100.0);
	float fDamage = ReadFloatVar(attr, "damage", 5.0);
	float fForce = ReadFloatVar(attr, "player_push_force", 100.0);
	int iProjectile = ReadIntVar(attr, "work_on_projectile", 1);
	float fProjRadius = ReadFloatVar(attr, "projectile_radius", 1000.0);
	float fProjForce = ReadFloatVar(attr, "projectile_push_force", 100.0);
	float fProjExplosion = ReadFloatVar(attr, "projectile_change_owner_radius", 100.0);
	
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i)) 
			continue;
			
		float cpos[3];
		GetClientAbsOrigin(i, cpos);
		
		float Distance = GetVectorDistance(pos, cpos);
		
		if (attacker == i)
			continue;
			
		if (TF2_GetClientTeam(i) == TF2_GetClientTeam(attacker))
			continue;
		
		if (Distance <= fRadius) 
		{
			float velocity[3];
			MakeVectorFromPoints(pos, cpos, velocity);
			NormalizeVector(velocity, velocity);
			ScaleVector(velocity, -fForce);
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, velocity);
		}
		
		if (Distance <= fDamageRadius)
		{
			
			SDKHooks_TakeDamage(i, attacker, attacker, fDamage, DMG_REMOVENORAGDOLL); 
			
			if (!IsPlayerAlive(i))
			{
				int ragdoll = GetEntPropEnt(i, Prop_Send, "m_hRagdoll");
				
				if (!IsValidEntity(ragdoll))
					continue;
					
				AcceptEntityInput(ragdoll, "kill");
			}
		}
	}
	if (iProjectile == 1)
	{
		for(new ient=1; ient<=2048; ient++) // 2048 = Max entities
		{
			if (IsValidEdict(ient) && IsValidEntity(ient))
			{
				char sClassname[64];
				GetEdictClassname(ient, sClassname, sizeof(sClassname));
				if (strncmp(sClassname, "obj_",4)==0 || strncmp(sClassname, "tf_projectile_",14)==0)
				{
					float fPosEnt[3];
					GetEntPropVector(ient, Prop_Send, "m_vecOrigin", fPosEnt);
					float Distance = GetVectorDistance(pos, fPosEnt);
					if (Distance <= fProjRadius && ((GetEntProp(ient, Prop_Send, "m_iTeamNum")!=GetClientTeam(attacker) && iProjectile==1) || (iProjectile==2)))
					{
						float velocity[3];
						float flAng[3];
						MakeVectorFromPoints(pos, fPosEnt, velocity);
						NormalizeVector(velocity, velocity);
						ScaleVector(velocity, -fProjForce);
						GetVectorAngles(velocity, flAng);
						TeleportEntity(ient, NULL_VECTOR, flAng, velocity);
						if (Distance <= fProjExplosion)
						{
							int iTeam = GetClientTeam(attacker);
							SetVariantInt(iTeam);
							AcceptEntityInput(ient, "SetTeam");
							SetEntPropEnt(ient, Prop_Send, "m_hOwnerEntity", attacker);
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

stock int CreateEntityParticle(const char[] sParticle, const float[3] pos)
{
	int entity = CreateEntityByName("info_particle_system");
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(entity, "effect_name", sParticle);
	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "start");
	return entity;
}

stock void SetEntitySelfDestruct(int entity, float duration)
{
	char output[64]; 
	Format(output, sizeof(output), "OnUser1 !self:kill::%.1f:1", duration);
	SetVariantString(output);
	AcceptEntityInput(entity, "AddOutput"); 
	AcceptEntityInput(entity, "FireUser1");
}
