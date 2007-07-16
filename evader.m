function [deltaH throttle action] = evader(state,player,objects,req)

engine_settings;

xpos = player{1};
ypos = player{2};
health = player{3};
energy = player{4};
team = player{5};
num = player{6};
name = player{7};
heading = player{8};

datafile = ['evader' team '.mat'];

if exist(datafile,'file') %if the .mat file exists
    load(datafile);
else  %initialize .mat file
    mayhem = 0;
    playerinmayhem = 0;
    target = 0;
    targetx = 0;
    targety = 0;
    targethist = [];
    nfired = 0;
    waiting = 0;
    waited = 0;
    nwait= 0;
    longdist = 0;
end

mayhem_radius = 3*rifle_radius*rifle_speed;
nothers = length(state);

bulletlist = [];
for i = 1:length(objects)
    if strcmp(objects{i}{1},'rifle')
        if ~strcmp(objects{i}{5},team)
            bulletlist = [bulletlist; objects{i}{2} objects{i}{3} objects{i}{4}];
        end
    end
end

queue = [];
for i = 1:size(bulletlist,1)
    dist = norm([bulletlist(i,1)-xpos bulletlist(i,2)-ypos]);
    mindist = abs(dist*sin(bulletlist(i,3)-atan2(bulletlist(i,2)-ypos,bulletlist(i,1)-xpos)));
    if mindist>rifle_radius
        queue = [queue i];
    end
end

bulletlist(queue,:) = [];

if isempty(bulletlist)
    throttle = 0;
    deltaH = 0;
    if health<100
        action = ['HtoE-' num2str(energy_regen/health_energy_ratio)];
    else
        action = 'none';
    end
else

    mindist = 1000;
    closest = 0;
    for i = 1:size(bulletlist,1)
        dist = norm([bulletlist(i,1)-xpos bulletlist(i,2)-ypos]);
        if dist<mindist
            mindist = dist;
            closest = i;
        end
    end
    aim = bulletlist(closest,3)+pi/2;
    deltaH = aim-heading;
    deltaH = mod(deltaH+pi,2*pi)-pi;
    action = 'none';
    throttle = 1;
end

playerlist = [];
nevaders = 1;
for i = 1:nothers
    playerlist = [playerlist state{i}{6}];
    if strcmp(name,state{i}{7})&&strcmp(team,state{i}{5});
        nevaders = nevaders + 1;
    end
end
if mayhem==1

    if isempty(playerlist)
        isthere = 0;

    else
        if target>length(playerlist)
            isthere = 0;
        else
            isthere = sum(state{target}{6}==playerlist);
        end

        isthere = isthere||sum([playerlist num]==playerinmayhem);


    end

    if ~isthere
        mayhem = 0;
        playerinmayhem = 0;
        nfired = 0;
        waiting = 0;
        longdist = 0;
        %     fprintf('He dead.  w00t\n')
    else




        aim = atan2(targety-ypos,targetx-xpos);
        deltaH = aim-heading;
        deltaH = mod(deltaH+pi,2*pi)-pi;
        

        if waiting
            action = 'none';
            throttle = 0;
        else
            if abs(deltaH)<deltaH_max
                action = 'rifle';
            else
                action = 'none';
            end
            throttle = .4;
        end

    end
end


pdist = 1000;
closest = 0;
for i = 1:nothers
    if ~strcmp(state{i}{5},team)
        dist = norm([state{i}{1}-xpos state{i}{2}-ypos]);
        if dist<pdist
            pdist = dist;
            closest = i;
        end
    end
end


if (pdist<mayhem_radius)&&((playerinmayhem==0)||(playerinmayhem==num))
    targetx = state{closest}{1};
    targety = state{closest}{2};
    target = closest;
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

    %   fprintf('Targetting player #%d\n',state{target}{6})
    %   fprintf('His health: %f\n',state{target}{3})
    %  fprintf('Shots in the air already: %d\n',nfired)
    %  fprintf('With %d of us, that will cause %f damage\n',nevaders,nevaders*nfired*rifle_damage)

    if abs(deltaH)<deltaH_max
        action = 'rifle';
    else
        action = 'none';
    end


    if waiting==0
        if (nevaders*nfired*rifle_damage)>=(state{target}{3})
            action = 'none';

            longdist = norm([targetx-xpos targety-ypos])
            for j = 1:nothers
                if strcmp(state{j}{7},'evader')&&strcmp(team,state{j}{5})
                    mydist = norm([targetx-state{j}{1} targety-state{j}{2}]);
                    if mydist>longdist
                        longdist = mydist;
                    end
                end
            end

            longdist = mydist;
            nwait = floor(longdist/rifle_speed/ts)
        end

        waiting = 1;
        waited = 0;
        %      fprintf('Oh wait... we fired enough\n')
    end
end

if waiting
    waited = waited+1;
    action = 'none';

    if waited==nwait;
        waiting = 0;
        nfired = 0;
    end
end
%      pause
throttle = .4;
mayhem = 1;
playerinmayhem = num;
if strcmp(action,'rifle')
    nfired = nfired+1
    %     fprintf('Firing!\n')
else
    %      fprintf('NOT firing\n')
end




save (datafile,'mayhem','target','targetx','targety','targethist','nfired','waiting','nwait','waited','playerinmayhem','longdist')
