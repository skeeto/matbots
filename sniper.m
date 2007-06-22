function [deltaH throttle action] = sniper(state,player,objects)

engine_settings;

num = player{6};

datafile = ['sniper' num2str(num) '.mat'];

if exist(datafile,'file')
   load (datafile)
   oldtarget = target;
else
    firenumber = 0;
    target = 0;
    oldtarget = 0;
    targethist = [];
end

xpos = player{1};
ypos = player{2};
health = player{3};
energy = player{4};
team = player{5};

name = player{7};
heading = player{8};

nothers = size(state,2);

dist = 10000;
for i = 1:nothers
    if ~strcmp(team,state{i}{5})
    if norm([state{i}{1}-xpos  state{i}{2}-ypos])<dist
        target = i;
        dist = norm([state{i}{1}-xpos  state{i}{2}-ypos]);
    end
    end
end

if target~=oldtarget
    firenumber = 0;
end

targetx = state{target}{1};
targety = state{target}{2};

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

if abs(deltaH)<pi/4
    if firenumber==0
        action = 'rifle';
        firenumber = firenumber+1;    
    else
        action = 'none';
        firenumber = firenumber+1;
    end
else
    action = 'none';
end

if firenumber == 20;
   firenumber = 0;
end

if dist<.05
    action = 'mine';
end

%pause

throttle = (dist-rifle_radius)^2;

save (datafile,'firenumber','target','targethist')