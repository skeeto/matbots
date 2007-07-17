function [deltaH throttle action] = sniper(state,player,objects,req)
% SNIPER
% coded by: Mike Abraham
% last update: 07/17/2007
%
% This was the first of my successful bots.  SNIPER targets the bot that
% requires the least change in heading to aim at.  The throttle is equal to
% the square of the distance to the target (so the bot slows as it
% approaches).  The aiming algorithm is my original first derivative
% predictor.  SNIPER waits 'firedelay' timesteps between shots.  I think
% there is still a bug that causes the bot to fire upon switching targets
% and is the cause of a few random shots every so often.  SNIPER has no
% energy management routines.

%% Load Settings/Initialize Files/Unwrap Data

engine_settings;

datafile = ['sniper' num2str(player{5}) num2str(player{6}) '.mat'];

if strcmp(req,'preclean')||strcmp(req,'clean')
    if exist(datafile,'file')
        delete(datafile)
    end
    if strcmp(req,'preclean')
    firecount = 0;
    target = 0;
    oldtarget = 0;
    targethist = [];
    save (datafile,'firecount','target','oldtarget','targethist')
    end
    return
end

load (datafile)

xpos = player{1};
ypos = player{2};
health = player{3};
energy = player{4};
team = player{5};
num = player{6};
name = player{7};
heading = player{8};

nothers = size(state,2);

%% Bot Parameters

firedelay = 5;
oktoshoot = 1;

%% Target Selection Routine
deltaHlist = [];
listindex = [];
for i = 1:nothers
    if ~strcmp(team,state{i}{5})
        targetx = state{i}{1};
        targety = state{i}{2};
        aim = atan2(targety-ypos,targetx-xpos);
        deltaH = aim-heading;
        deltaH = mod(deltaH+pi,2*pi)-pi;
        deltaHlist = [deltaHlist deltaH];
        listindex = [listindex i];
    end
end

%% End of Game Condition
if isempty(deltaHlist)
    throttle = 0;
    deltaH = 0;
    action = 'none';
    return
end

%% Target Details
whichindex = find(abs(deltaHlist)==min(abs(deltaHlist)));
target = listindex(whichindex);

targetx = state{target}{1};
targety = state{target}{2};
dist = norm([state{target}{1}-xpos state{target}{2}-ypos]);

%% Things to do when switching to a new target
if target~=oldtarget
    targethist = [targetx targety; targetx targety]; %reset target history
    firecount = firedelay;
    oktoshoot = 0;
end
oldtarget = target;

%% Aiming
targethist = [targethist; targetx targety];
if size(targethist,1)==3
    targethist(1,:) = [];
    targetvector = targethist(2,:)-targethist(1,:);
    timetotarget = dist/rifle_speed;
    newtarget=[targetx targety] + targetvector*(timetotarget/0.05);
    targetx = newtarget(1);
    targety = newtarget(2);
end

aim = atan2(targety-ypos,targetx-xpos);
deltaH = aim-heading;
deltaH = mod(deltaH+pi,2*pi)-pi;

%% Check to see if aiming is complete
if abs(deltaH)>deltaH_max
    oktoshoot = 0;
end

%% FIRE
if oktoshoot&&(firecount>=firedelay)
    action = 'rifle';
    firecount = 0;
else
    action = 'none';
    firecount = firecount+1;
end

if dist<mine_radius
    action = 'mine';
end

%% Throttle Management
throttle = (dist-rifle_radius)^2;

save (datafile,'firecount','target','targethist','oldtarget')