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
    target = 0;
    targetx = 0;
    targety = 0;
    targethist = [];
end

mayhem_radius = rifle_radius*rifle_speed;
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
for i = 1:nothers
    playerlist = [playerlist state{i}{6}];
end

if mayhem==1
    isthere = sum(target==playerlist);
    if ~isthere
        mayhem = 0;
    else
        aim = atan2(targety-ypos,targetx-xpos);
        deltaH = aim-heading;
        deltaH = mod(deltaH+pi,2*pi)-pi;
        action = 'rifle';
        throttle = 1;
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

if pdist<mayhem_radius 
   targetx = state{closest}{1};
   targety = state{closest}{2};
   
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
   action = 'rifle';
   throttle = -1;
   mayhem = 1
   target = closest;
end

save (datafile,'mayhem','target','targetx','targety','targethist')
