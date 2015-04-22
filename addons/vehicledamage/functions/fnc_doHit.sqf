#define DEBUG_MODE_FULL
#include "script_component.hpp"

#define __PROJECTILE_CLASS configFile >> "CfgAmmo" >> (_ammo select 4)

private["_impactSurfaceType", "_isDirectHit"];
private["_penetrationOrthogonalDepth", "_penetrationAngleDepth", "_penetrationCosAngle", "_projectileCaliber", "_projectileDensity", "_projectileLength", "_armorDensity"];
EXPLODE_9_PVT((_this select 0),_unit,_shooter,_projectile,_impactPosition,_projectileVelocity,_selection,_ammo,_surfaceDirection,_radius);
_impactSurfaceType = (_this select 0) select 9;
_isDirectHit = (_this select 0) select 10;
TRACE_2("",_impactSurfaceType,_isDirectHit);

_penetrationData = [_impactSurfaceType] call FUNC(getPenetrationData);
TRACE_1("", _penetrationData);
if(isNil "_penetrationData") exitWith {
    diag_log text format["[ACE] - ERROR - ace_vehicledamage: Invalid penetration surface"];
    false
};

// @TODO: Skip surface thickness discovery, use armor thickness for now
if( (_penetrationData select 0) <= 0) exitWith { 
    diag_log text format["[ACE] - @TODO variable thickness surfaces are not yet supported"];
    false
};

// Skip it if the surface cant be penetrated
if( (_penetrationData select 4) <= 0 && {(_penetrationData select 5) <= 0}) exitWith { 
    diag_log text format["[ACE] - Superman surface"];
    false 
};

// Determine the actual penetration through density first, 
// then check thickness to see if we can go far enough
// 8600 is our base density for steel, 11500 for lead
_armorDensity = _penetrationData select 1;
_armorThickness = _penetrationData select 0;

_projectileDensity = getNumber (__PROJECTILE_CLASS >> "ace_penetration_density");
_projectileCaliber = getNumber (__PROJECTILE_CLASS >> "caliber");

// Small arms bullet penetration
if((_ammo select 4) isKindOf "BulletBase") then {
    TRACE_1("Beginning bullet penetration", (_ammo select 4));
    _projectileLength = 13 * _projectileCaliber; // Length in mm, 1 caliber = 55.6 = ~13mm length round

    // depth = length * ( projectileDensity / armorDensity ), in high velocity scenarios velocity doesnt matter
    // http://en.wikipedia.org/wiki/Impact_depth

    _penetrationOrthogonalDepth = _projectileLength * (_projectileDensity / _armorDensity);
    
    TRACE_4("ortho", _penetrationOrthogonalDepth, _projectileLength, _projectileDensity, _armorDensity);

    // Calculate the angle only if our penetration depth is at least half the material thickness
    // Half is a perfect angular shot, any lower wont make it through
    if( _penetrationOrthogonalDepth < _armorThickness * 0.5) exitWith { false };

    // Now calculate actual penetration depth based on angle
    _penetrationCosAngle = ( (vectorNormalized _surfaceDirection) vectorDotProduct ( vectorNormalized _projectileVelocity ) );
    _penetrationAngleDepth = _armorThickness /  _penetrationCosAngle;
    //TRACE_3("angle", _penetrationAngleDepth, _armorThickness, _penetrationCosAngle);
};


if((_ammo select 4) isKindOf "ShellBase") then {
    TRACE_1("Beginning shell penetration", (_ammo select 4));
    _projectileLength = 13 * _projectileCaliber; // Length in mm, 1 caliber = 55.6 = ~13mm length round

    // depth = length * ( projectileDensity / armorDensity ), in high velocity scenarios velocity doesnt matter
    // http://en.wikipedia.org/wiki/Impact_depth

    _penetrationOrthogonalDepth = _projectileLength * (_projectileDensity / _armorDensity);
    TRACE_4("ortho", _penetrationOrthogonalDepth, _projectileLength, _projectileDensity, _armorDensity);

    // Calculate the angle only if our penetration depth is at least half the material thickness
    // Half is a perfect angular shot, any lower wont make it through
    if( _penetrationOrthogonalDepth < _armorThickness * 0.5) exitWith { false };

    // Now calculate actual penetration depth based on angle
    _penetrationCosAngle = ( (vectorNormalized _surfaceDirection) vectorDotProduct ( vectorNormalized _projectileVelocity ) );
    _penetrationAngleDepth = _armorThickness /  _penetrationCosAngle;
    TRACE_3("angle", _penetrationAngleDepth, _armorThickness, _penetrationCosAngle);
};