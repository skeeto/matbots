function [deltaH throttle action] = shooter(state,player,objects,req)
% SHOOTER
% coded by: Mike Abraham
% last update: 07/17/2007
%
% This is the newer and improveder version of SNIPER.  Not much is
% different other than the aiming routine.  Here, aiming is done with the
% help of a function that fits an nth order polynomial to the history of
% the target's motion.  Tests have shown, unfortunately, that anything
% higher than a 1st order polynomial performs quite poorly...so, this bot
% is essentially SNIPER.

engine_settings;

datafile = ['shooter' player{5} num2str(player{6}) '.mat'];

if strcmp(req,'preclean')
    if exist(datafile,'file')
        delete(datafile)
    end
    targethist = [];
    oldtarget = 0;
    firecount = 0;
    save (datafile,'targethist','oldtarget','firecount')
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
oktoshoot = 1;
firedelay = 10;
maxhist = 100;


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

%Position of target bot at current time:
xt = state{target}{1};
yt = state{target}{2};

%Distance to target bot at current time:
dist = norm([xt-xpos yt-ypos]);

%% Things to do when switching to a new target
if target~=oldtarget
    targethist = []; %reset target history
    firecount = firedelay;
    oktoshoot = 0;
end

%% Update Target History
targethist = [targethist; xt yt];
if size(targethist,1)>maxhist
    targethist(1,:) = [];
end

%% AIM
[targetx, targety] = aimnderiv(xpos,ypos,targethist,1);

%% Produce deltaH
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

throttle = norm([xpos-targetx ypos-targety]).^2;

%% Update oldtarget
oldtarget = target;

save (datafile,'targethist','oldtarget','firecount')

end %function shooter

function [targetx, targety] = aimnderiv(xpos,ypos,targethist,n)

engine_settings;
if size(targethist,1)<n+1
    while size(targethist,1)<n+1
        targethist = [targethist; targethist];
    end
elseif size(targethist,1)>n+1
    while size(targethist,1)>n+1
        targethist(1,:) = [];
    end
end

nhist = size(targethist,1);

xhist = targethist(:,1)';
yhist = targethist(:,2)';
dhist = sqrt((xhist-xpos).^2+(yhist-ypos).^2);

thist = ts*(-(nhist-1):0);
bhist = thist*rifle_speed;

xpoly = polyfit(thist,xhist,n);
ypoly = polyfit(thist,yhist,n);

impactpoly = polyfit(thist,dhist-bhist,n);

impactroots = roots(impactpoly);
realroots = impactroots(  find(imag(impactroots)==0)  );
nonnegroots = realroots( find(realroots>=0) );

impacttime = min(nonnegroots);

targetx = polyval(xpoly,impacttime);
targety = polyval(ypoly,impacttime);

if isempty(impacttime)
    fprintf('WTF, dude!?\n')
    n = n-1;
    [targetx, targety] = aimnderiv(xpos,ypos,targethist,n);
end

if isempty(impacttime)
    [targetx, targety] = targethist(size(targethist,1),:);
end

% if ~isempty(impacttime)
% figure
% plot(xhist,yhist,'r.')
% hold on
% plot(polyval(xpoly,thist),polyval(ypoly,thist));
% newt = linspace(0,impacttime,25);
% plot(polyval(xpoly,newt),polyval(ypoly,newt),'g')
% plot(targetx,targety,'b*')
% axis equal
% 
% pause
% close gcf
% end

end %function aim