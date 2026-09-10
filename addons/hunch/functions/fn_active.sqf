hasInterface && {!isMultiplayer} && {HUNCH_enabled} && {!isNull player} && {alive player} &&
{lifeState player != "INCAPACITATED"} && {!(player getVariable ["ACE_isUnconscious",false])} &&
{!visibleMap} && {!dialog} && {isNull findDisplay 49} &&
{cameraOn in [player,vehicle player]} && {isNull curatorCamera} &&
{!isRemoteControlling player} && {isNull (remoteControlled player)}
