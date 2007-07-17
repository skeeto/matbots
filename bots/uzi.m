function [deltaH throttle action] = uzi(state,player,objects,req)

clusternum = 1;

engine_settings

num = player{6};
datafile = ['uzi' num2str(num) '.mat'];

if isempty(state)
    if exist(datafile,'file')
        delete (datafile)
    end
end

if exist(datafile,'file') %if the .mat file exists
    load(datafile)
else  %initialize .mat file
    targethist = [];
    
end

xpos = player{1};
ypos = player{2};
health = player{3};
energy = player{4};
team = player{5};

name = player{7};
heading = player{8};
h = heading;
nothers = size(state,2);

targetlist = [];
teamlist = [];
for i = 1:nothers
    if ~strcmp(team,state{i}{5})
        targetlist = [targetlist state{i}{6}];
    else
        teamlist = [teamlist state{i}{6}];
    end
end
if isempty(targetlist)
    action = 'none';
    throttle = 0;
    deltaH =0;
    return
end
teamlist = sort([teamlist num]);

for i = 1:ceil(length(teamlist)/length(targetlist))
    targetlist = [targetlist targetlist];
end

targetlist = targetlist(1:length(teamlist));

myrank = find(teamlist==num);

if clusternum==1
    mytarget = targetlist(myrank);
else
mytarget = targetlist(floor((myrank+1)/clusternum));
end

for i = 1:length(state)
    if state{i}{6}==mytarget
        target = i;
    end
end

targetx = state{target}{1};
targety = state{target}{2};

dist = norm([state{target}{1}-xpos state{target}{2}-ypos]);


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

throttle = 0;
action = 'rifle';

save (datafile,'targethist')