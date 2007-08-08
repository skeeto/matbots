function [deltaH throttle action] = hexabot(state,player,objects,req)
% HEXABOT
% coded by: Mike Abraham
% last update: 08/07/2007
%
% This bot has potential.  Unfortunately, there are still several design
% flaws.  HEXABOT is a team bot.  All of a team's HEXABOTs form together at
% the beginning of the game and then move around as a unit... basically,
% they become one large bot.  Once they are in formation, they all do
% EXACTLY the same thing.  The bot in the center is the leader.  If a
% HEXABOT dies, the team reforms immediately.  Also, the HEXABOT group
% changes its shooting strategy based upon what type of bot it is
% attacking.  They use a sweep-style shooting logic when going after bots
% that can dodge bullets.

engine_settings;
%% Datafile initialization, preclean, clean
datafile = ['hexabotdat' player{5} '.mat'];

if strcmp(req,'selfplot')
    throttle = 0;
    deltaH = 0;
    action = 0;
    return
elseif strcmp(req,'preclean')||strcmp(req,'clean')
    sniper(state,player,objects,req);
    uzi(state,player,objects,req);
    if exist(datafile,'file')
        delete(datafile)
    end
    if strcmp(req,'preclean')
        linked = [];
        leaderaction = 'none';
        leaderheading = player{8};
        leaderdeltaH = 0;
        leaderthrottle = 0;
        positions = [];
        firecount = 0;
        target = 0;
        oldtarget = -1;
        aimheading = 0;
        nhexes = 0;
        thecenter = [];
        targethist = [];
        firstrun = 1;
        xcg = [];
        ycg = [];
        save (datafile,'linked','leaderaction','leaderheading','leaderdeltaH','leaderthrottle','positions','firecount','target','oldtarget','aimheading','nhexes','thecenter','targethist','firstrun','xcg','ycg')
    end
    return
end

%% Load Datafile, unwrap state vector
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
formationR = rifle_radius;

%% Identify and Sort All Friendly Hexabots
hexlist = [];
hexlistx = [];
hexlisty = [];
for i = 1:nothers
    if strcmp(state{i}{7},'hexabot')&&strcmp(state{i}{5},team)&&(state{i}{3}>0)
        hexlist = [hexlist state{i}{6}];
        hexlistx = [hexlistx state{i}{1}];
        hexlisty = [hexlisty state{i}{2}];
    end
end

hexlist = [hexlist num];
hexlist = sort(hexlist);

%% Initial formation calculations for firstrun
if firstrun&&isempty(xcg)
    
    xcg = mean(hexlistx);
    ycg = mean(hexlisty);
    
  %  dist2center = [];
  %  for i = 1:length(hexlist)
  %      dist2center = [dist2center norm([xcg-xs(i) ycg-ys(i)])];
  %  end
  %  leader = hexlist(min(find(dist2center==min(dist2center))));
end

%% If I'm the last player, I'm a snitch
if length(hexlist)==1;
    [deltaH throttle action] = snitch(state,player,objects,req);
end

%% Check for end of game condition
if length(hexlist)==(nothers+1)
    action = 'none';
    throttle = 0;
    deltaH = 0;
    return
end

%% Establish my rank
myrank = find(hexlist==num);

%% If I am the leader
if myrank==1
    
%% If someone has died, we are not linked
    if nhexes~=length(hexlist)
        linked = [];
    end
    nhexes = length(hexlist);
 
%% Define formation positions
    if firstrun
    positions = formationR.*[ cos(linspace(0,2*pi,nhexes)') sin(linspace(0,2*pi,nhexes)') ];
    positions = positions + [ xcg*ones(nhexes,1) ycg*ones(nhexes,1)];
    else
    positions = formationR.*[ cos(linspace(0,2*pi,nhexes)') sin(linspace(0,2*pi,nhexes)') ];
    positions = positions + [ xpos*ones(nhexes,1) ypos*ones(nhexes,1)];
    end
%% If We ARE linked
    if length(linked) == (length(hexlist) - 1)
        
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
        whichindex = find(abs(deltaHlist)==min(abs(deltaHlist)));
        target = listindex(whichindex);
        target = min(target);

%% Target Details

        targetx = state{target}{1};
        targety = state{target}{2};
        dist = norm([xpos-targetx ypos-targety]);
        aim = atan2(targety-ypos,targetx-xpos);
        deltaH = aim-heading;
        deltaH = mod(deltaH+pi,2*pi)-pi;
        theta = atan2(3*rifle_radius,dist);
        theta = [-theta*.75 theta*.75 -theta*.75/2 theta*.75/2 0];

%% End of Game Condition Again
        if isempty(deltaHlist)
            throttle = 0;
            deltaH = 0;
            action = 'none';
            return
        end
        
%% If I am shooting at a snitch or a webbbot        
        if strcmp(state{target}{7},'snitch')||strcmp(state{target}{7},'webbbot_NexGen')

            if oldtarget~=target
                firecount = 0;
            end

            oldtarget = target;

%% Firing Logic
            if firecount==0
                if (abs(deltaH)<=deltaH_max)&&(energy>=rifle_cost)
                    aimheading = aim;
                    action = 'rifle';
                    firecount = firecount+1;
                else
                    action = 'none';
                    firecount = 0;
                end
            else
                if (energy>=rifle_cost)
                    aim = aimheading+theta(firecount);
                    deltaH = aim-heading;
                    deltaH = mod(deltaH+pi,2*pi)-pi;
                    action = 'rifle';
                    firecount = firecount+1;
                    if firecount==6
                        firecount = 0;
                    end
                else
                    action = '';
                    firecount = 0;
                end
            end
            throttle = (dist - mine_radius - 3*rifle_radius)/ts;
            leaderdeltaH = deltaH;
            leaderthrottle = throttle;
            leaderaction = action;
            leaderheading = heading;

            save (datafile,'linked','leaderaction','leaderheading','leaderdeltaH','leaderthrottle','positions','firecount','target','oldtarget','aimheading','nhexes','targethist','firstrun','xcg','ycg')
            return
            
%% If I am firing at anyone else
        else
            targethist = [targethist; state{target}{1} state{target}{2}];
            
            if size(targethist,1)==3;
                targethist(1,:) = [];
            end
            
            if oldtarget~=target
                firecount = 0;
            end
            oldtarget = target;

            [targetx, targety] = aim1deriv(xpos,ypos,targethist);

            aim = atan2(targety-ypos,targetx-xpos);
            deltaH = aim-heading;
            deltaH = mod(deltaH+pi,2*pi)-pi;

            if firecount==5
                action = 'rifle';
                firecount = 0;
            else
                firecount = firecount+1;
                action = 'none';
            end


            dist = norm([xpos-targetx ypos-targety]);
            throttle = (dist - mine_radius - 3*rifle_radius)/ts;
            
            leaderaction = action;
            leaderheading = heading;
            leaderdeltaH = deltaH;
            leaderthrottle = throttle;
            
            save (datafile,'linked','leaderaction','leaderheading','leaderdeltaH','leaderthrottle','positions','firecount','target','oldtarget','aimheading','nhexes','targethist','firstrun','xcg','ycg')
            return

        end
%% If we are NOT linked up and I am the leader
    else
        if firstrun
            targetx = xcg;
            targety = ycg;
            if norm([xpos-targetx ypos-targety])>0.0001
                aim = atan2(targety-ypos,targetx-xpos);
                deltaH = aim-heading;
                deltaH = mod(deltaH+pi,2*pi)-pi;
                throttle = norm([xpos-targetx ypos-targety])/ts;
                if abs(deltaH)>deltaH_max
                   throttle = 0;
                end
                action = '';
                save (datafile,'linked','leaderaction','leaderheading','leaderdeltaH','leaderthrottle','positions','firecount','target','oldtarget','aimheading','nhexes','targethist','firstrun','xcg','ycg')
                return
            else
                action = '';
                throttle = 0;
                deltaH = 0;
                firstrun = 0;
                save (datafile,'linked','leaderaction','leaderheading','leaderdeltaH','leaderthrottle','positions','firecount','target','oldtarget','aimheading','nhexes','targethist','firstrun','xcg','ycg')
                return
            end
        else
        deltaH = 0;
        throttle = 0;
        action = '';
        leaderdeltaH = deltaH;
        leaderthrottle = throttle;
        leaderaction = action;
        leaderheading = heading;
        save (datafile,'linked','leaderaction','leaderheading','leaderdeltaH','leaderthrottle','positions','firecount','target','oldtarget','aimheading','nhexes','targethist','firstrun','xcg','ycg')
        return
        end
    end
else
%% If we ARE linked and I am not the leader    
    if sum(linked==num)
        action = leaderaction;
        throttle = leaderthrottle;
        deltaH = leaderdeltaH;
        return
    else
%% If we are NOT linked up and I am not the leader
        if norm([xpos-positions(myrank,1) ypos-positions(myrank,2)])<.00001
            if abs(leaderheading-heading)>0.00001
%% If I am in place, but not facing the right way               
                aim = leaderheading;
                deltaH = aim-heading;
                deltaH = mod(deltaH+pi,2*pi)-pi;
                throttle = 0;
                action = '';
                return
            else
%% If I am in place AND facing the right way
                linked = [linked num];
                action = leaderaction;
                throttle = leaderthrottle;
                deltaH = leaderdeltaH;
                save (datafile,'linked','leaderaction','leaderheading','leaderdeltaH','leaderthrottle','positions','firecount','target','oldtarget','aimheading','nhexes','targethist','firstrun','xcg','ycg')
                return
            end
        else
%% If I am not in place yet
            targetx = positions(myrank,1);
            targety = positions(myrank,2);
            aim = atan2(targety-ypos,targetx-xpos);
            deltaH = aim-heading;
            deltaH = mod(deltaH+pi,2*pi)-pi;
            throttle = norm([xpos-positions(myrank,1) ypos-positions(myrank,2)])/ts;
            if abs(deltaH)>deltaH_max
                throttle = 0;
            end
            action = '';
            return
        end

    end
end

end %function

function [targetx, targety] = aim1deriv(xpos, ypos, targethist)

engine_settings;

if size(targethist,1) == 1
    targetx = targethist(1);
    targety = targethist(2);
    return
end

x0 = targethist(end,1);
y0 = targethist(end,2);

x_1 = targethist(end-1,1);
y_1 = targethist(end-1,2);

target_vector = [x0-x_1 y0-y_1];
target_speed = norm(target_vector)/ts;
h = atan2(target_vector(2),target_vector(1));


time = norm([xpos-x0 ypos-y0])/rifle_speed;
dB = rifle_speed*time;
dT = norm([x0+target_speed*cos(h)*time-xpos y0+target_speed*sin(h)*time-ypos]);
deltime = ts/25;
counter = 0;
while abs(dB-dT)>0.00001
    dB2 = rifle_speed*(time+deltime);
    dT2 = norm([x0+target_speed*cos(h)*(time+deltime)-xpos y0+target_speed*sin(h)*(time+deltime)-ypos]);
    slope = ( (dB2-dT2) - (dB-dT) )/deltime;
    time = time - (dB-dT)/slope;
    dB = rifle_speed*time;
    dT = norm([x0+target_speed*cos(h)*time-xpos y0+target_speed*sin(h)*time-ypos]);
    counter = counter+1;
    if counter>10
        targetx = x0;
        targety = y0;
        return
    end
end

targetx = x0 + time*target_speed*cos(h);
targety = y0 + time*target_speed*sin(h);

end %function
