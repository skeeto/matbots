function [deltaH throttle action] = hexabot(state,player,objects,req)

engine_settings;

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
        save (datafile,'linked','leaderaction','leaderheading','leaderdeltaH','leaderthrottle','positions','firecount','target','oldtarget','aimheading','nhexes','thecenter','targethist')
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

formationR = rifle_radius;

%% Identify and Sort All Friendly Hexabots
hexlist = [];
for i = 1:nothers
    if strcmp(state{i}{7},'hexabot')&&strcmp(state{i}{5},team)&&(state{i}{3}>0)
        hexlist = [hexlist state{i}{6}];
    end
end

hexlist = [hexlist num];
hexlist = sort(hexlist);

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

myrank = find(hexlist==num);

if myrank==1
    if nhexes~=length(hexlist)
        linked = [];
    end
    nhexes = length(hexlist);
    positions = formationR.*[ cos(linspace(0,2*pi,nhexes)') sin(linspace(0,2*pi,nhexes)') ];
    positions = positions + [ xpos*ones(nhexes,1) ypos*ones(nhexes,1)];
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

        %% End of Game Condition
        if isempty(deltaHlist)
            throttle = 0;
            deltaH = 0;
            action = 'none';
            return
        end
        %%%%%%%%%
        if strcmp(state{target}{7},'snitch')||strcmp(state{target}{7},'webbbot_NexGen')


            if oldtarget~=target
                firecount = 0;
            end

            oldtarget = target;

            %Firing Logic
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

            save (datafile,'linked','leaderaction','leaderheading','leaderdeltaH','leaderthrottle','positions','firecount','target','oldtarget','aimheading','nhexes','targethist')
            return
            %%%%%%%%%%
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
            
            save (datafile,'linked','leaderaction','leaderheading','leaderdeltaH','leaderthrottle','positions','firecount','target','oldtarget','aimheading','nhexes','targethist')
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
        save (datafile,'linked','leaderaction','leaderheading','leaderdeltaH','leaderthrottle','positions','firecount','target','oldtarget','aimheading','nhexes','targethist')
        return
    end
else
    if sum(linked==num)
        action = leaderaction;
        throttle = leaderthrottle;
        deltaH = leaderdeltaH;
        return
    else
        if norm([xpos-positions(myrank,1) ypos-positions(myrank,2)])<.00001
            if abs(leaderheading-heading)>0.00001
                aim = leaderheading;
                deltaH = aim-heading;
                deltaH = mod(deltaH+pi,2*pi)-pi;
                throttle = 0;
                action = '';
                return
            else
                linked = [linked num];
                action = leaderaction;
                throttle = leaderthrottle;
                deltaH = leaderdeltaH;
                save (datafile,'linked','leaderaction','leaderheading','leaderdeltaH','leaderthrottle','positions','firecount','target','oldtarget','aimheading','nhexes','targethist')
                return
            end
        else
            targetx = positions(myrank,1);
            targety = positions(myrank,2);
            aim = atan2(targety-ypos,targetx-xpos);
            deltaH = aim-heading;
            deltaH = mod(deltaH+pi,2*pi)-pi;
            throttle = norm([xpos-positions(myrank,1) ypos-positions(myrank,2)])/ts;
            action = '';
            return
        end

    end
end

