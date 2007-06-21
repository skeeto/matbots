function [deltaH throttle action] = sniper(state,player,objects)

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

%fprintf('I am: %d \n',num)
%fprintf('I see %d other players.\n',nothers)
%fprintf('They are: ')
%for i = 1:nothers
%    fprintf('%d ',state{i}{6})
%end
%fprintf('\n')

dist = 10000;
for i = 1:nothers
    if ~strcmp(team,state{i}{5})
    if norm([state{i}{1}-xpos  state{i}{2}-ypos])<dist
        target = i;
        dist = norm([state{i}{1}-xpos  state{i}{2}-ypos]);
    end
    end
end

sweep = atan2(10/dist,dist);

if target~=oldtarget
    firenumber = 0;
end

%fprintf('I am targeting %d \n',state{target}{6})

targetx = state{target}{1};
targety = state{target}{2};

targethist = [targethist; targetx targety];
if size(targethist,1)==3
    targethist(1,:) = [];
    targetvector = targethist(2,:)-targethist(1,:);
    timetotarget = dist/10;
    newtarget=[targetx targety] + targetvector*(timetotarget/0.05);
    targetx = newtarget(1);
    targety = newtarget(2);
end



%fprintf('I am at [%f %f]\n',xpos, ypos)
%fprintf('%d is at [%f %f]\n',state{target}{6},targetx,targety)

aim = atan2(targety-ypos,targetx-xpos);

%fprintf('My current heading is: %f deg\n',180/pi*heading)
%fprintf('To hit %d I should aim at %f deg\n',state{target}{6},aim*180/pi)

deltaH = aim-heading;

deltaH = mod(deltaH+pi,2*pi)-pi;

%fprintf('I am changing my heading by %f deg\n',deltaH*180/pi)

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

%pause
throttle = 1;

save (datafile,'firenumber','target','targethist')