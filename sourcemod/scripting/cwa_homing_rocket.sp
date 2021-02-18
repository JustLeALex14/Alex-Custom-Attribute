/**
 * Sourcemod 1.7 Plugin Template
 */
#pragma semicolon 1
#include <sourcemod>

#include <smlib/clients>

#include <tf_custom_attributes>
#include <stocksoup/tf/entity_prop_stocks>
#include <stocksoup/var_strings>

public void OnPluginStart() {}

public void OnMapStart() {}

public OnGameFrame()
{
	char attr[124];
	char Projectilename[124];
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if (IsClientInGame(i))
		{
			int weapon = TF2_GetClientActiveWeapon(i);
			if (IsValidEntity(weapon))
			{
				if (TF2CustAttr_GetString(weapon, "homing_proj_mvm", attr, sizeof(attr)))
				{
					float radius = ReadFloatVar(attr, "detection_radius", 2000.0);
					int type = ReadIntVar(attr, "homing_mode", 1);
					ReadStringVar(attr, "projectilename", Projectilename, sizeof(Projectilename), "tf_projectile_rocket");
					SetHomingProjectile( i, Projectilename, radius, type );
				}
			}
			else if (TF2CustAttr_GetString(i, "homing_proj_mvm", attr, sizeof(attr)))
			{
				float radius = ReadFloatVar(attr, "detection_radius", 2000.0);
				int type = ReadIntVar(attr, "homing_mode", 1);
				ReadStringVar(attr, "projectilename", Projectilename, sizeof(Projectilename), "tf_projectile_rocket");
				SetHomingProjectile( i, Projectilename, radius, type );
			}
		}
	}
}


stock SetHomingProjectile( client, const char[] classname, float radius, int type_a )
{
	int entity = -1; 
	while( ( entity = FindEntityByClassname( entity, classname ) )!= INVALID_ENT_REFERENCE )
	{
        int owner = GetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity" ); 
        if ( !IsValidEntity( owner ) ) continue; 
        if ( owner == client )
        {
            int Target = GetClosestTarget( entity, owner ); 
            if ( !Target ) continue; 

            float EntityPos[3], TargetPos[3]; 
            GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityPos ); 
            GetClientAbsOrigin( Target, TargetPos ); 
            float distance = GetVectorDistance( EntityPos, TargetPos ); 
            
            if( distance <= radius )
            {
                float ProjLocation[3], ProjVector[3], BaseSpeed, NewSpeed, ProjAngle[3], AimVector[3], InitialSpeed[3]; 
                
                GetEntPropVector( entity, Prop_Send, "m_vInitialVelocity", InitialSpeed ); 
                if ( GetVectorLength( InitialSpeed ) < 10.0 ) GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", InitialSpeed ); 
                BaseSpeed = GetVectorLength( InitialSpeed ) * 0.5; 
                
                GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", ProjLocation ); 
                GetClientAbsOrigin( Target, TargetPos ); 
                TargetPos[2] += ( 40.0 + Pow( distance, 2.0 ) / 10000.0 ); 
                
                MakeVectorFromPoints( ProjLocation, TargetPos, AimVector ); 
                
                if ( type_a == 0 ) GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", ProjVector ); 
                else SubtractVectors( TargetPos, ProjLocation, ProjVector ); 
                AddVectors( ProjVector, AimVector, ProjVector ); 
                NormalizeVector( ProjVector, ProjVector ); 
                
                GetEntPropVector( entity, Prop_Data, "m_angRotation", ProjAngle ); 
                GetVectorAngles( ProjVector, ProjAngle ); 
                
                NewSpeed = ( BaseSpeed * 2.0 ) + GetEntProp( entity, Prop_Send, "m_iDeflected" ) * BaseSpeed * 1.1; 
                ScaleVector( ProjVector, NewSpeed ); 
                
                TeleportEntity( entity, NULL_VECTOR, ProjAngle, ProjVector ); 
            }
        }
    }   
}
stock GetClosestTarget( entity, owner)
{
    float TargetDistance = 0.0; 
    int ClosestTarget = 0; 
    for( new i = 1; i <= MaxClients; i++ ) 
    {
        if ( !IsValidForHoming( i, owner, entity) ) continue; 
        
        float EntityLocation[3], TargetLocation[3]; 
        GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", EntityLocation ); 
        GetClientAbsOrigin( i, TargetLocation ); 
        
        Handle hTrace = TR_TraceRayFilterEx( TargetLocation, EntityLocation, MASK_SOLID, RayType_EndPoint, TraceFilterIgnoreSelf, entity ); 
        if( hTrace != INVALID_HANDLE )
        {
            if( TR_DidHit( hTrace ) )
            {
                CloseHandle( hTrace ); 
                continue; 
            }
            
            CloseHandle( hTrace ); 
            
            float distance = GetVectorDistance( EntityLocation, TargetLocation ); 
            if( TargetDistance ) {
                if( distance < TargetDistance ) {
                    ClosestTarget = i; 
                    TargetDistance = distance;          
                }
            } else {
                ClosestTarget = i; 
                TargetDistance = distance; 
            }
        }
    }
    return ClosestTarget; 
}
stock bool IsValidForHoming( client, owner, entity)
{
    if ( IsValidClient( owner ) && IsValidClient( client ) && IsValidEntity( entity ) )
    {
        float OwnerPos[3], TargetPos[3]; 
        GetClientAbsOrigin( owner, OwnerPos ); 
        GetClientAbsOrigin( client, TargetPos ); 
        float distance_d = GetVectorDistance( OwnerPos, TargetPos ); 
        if ( distance_d <= 146.0 ) return false; 
    
        int team = GetEntProp( entity, Prop_Send, "m_iTeamNum" ); 
        if ( IsPlayerAlive( client ) && client != owner && GetClientTeam( owner ) != GetClientTeam( client ) )
        {
            if ( !TF2_IsPlayerInCondition( client, TFCond_Cloaked ) && !TF2_IsPlayerInCondition( client, TFCond_Ubercharged )
                && !TF2_IsPlayerInCondition( client, TFCond_Bonked ) && !TF2_IsPlayerInCondition( client, TFCond_Stealthed )
                && !TF2_IsPlayerInCondition( client, TFCond_BlastImmune ) && !TF2_IsPlayerInCondition( client, TFCond_HalloweenGhostMode )
                && !TF2_IsPlayerInCondition( client, TFCond_Disguised ) && GetEntProp( client, Prop_Send, "m_nDisguiseTeam" ) != team )
            {
               return true;
            }
        }
    }
    
    return false; 
}

public bool TraceFilterIgnoreSelf( entity, contentsMask, any:hiok )
{
    if ( entity == hiok || entity > 0 && entity <= MaxClients ) return false; 
    return true; 
}

stock bool IsValidClient( client, bool replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsPlayerAlive( client ) ) return false; 
    return true; 
}

