function [deltaH throttle action] = goose(state,player,objects)

num = player{6};

datafile = ['goosedat.mat'];

if exist(datafile,'file') %if the .mat file exists
    load(datafile)
else  %initialize .mat file
    linked = 0;
    dist2 = 100;
    dist3 = 100;
    leaderaction = 'none';
    firecount = 0;
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
gooselist = [];
for i = 1:nothers
   if strcmp(state{i}{7},'goose')
       gooselist = [gooselist state{i}{6}];
   end
end

theleader = min([num gooselist]);

R = .05; %Distance of flankers from leader
FlankAngle = 0; %Angle behind leader

MDH = pi/25; %max delta H
MT = 0.576; %max throttle

RFvec = R*[cos(FlankAngle) sin(FlankAngle)]'; %vector from leader to right flanker
LFvec = RFvec.*[-1; 1]; %vector from leader to left flanker

RFvec = [cos(pi/2) sin(pi/2); -sin(pi/2) cos(pi/2)]*RFvec;
LFvec = [cos(pi/2) sin(pi/2); -sin(pi/2) cos(pi/2)]*LFvec;

RFvec = [cos(-h) sin(-h); -sin(-h) cos(-h)]*RFvec;
LFvec = [cos(-h) sin(-h); -sin(-h) cos(-h)]*LFvec;

%%%%%%%%%
%%%%%%%%%
RFpos = [state{theleader}{1} state{theleader}{2}]' + RFvec;
LFpos = [state{theleader}{1} state{theleader}{2}]' + LFvec;

myrank = 3 - sum(num<gooselist);

if myrank==1
    if linked
   [deltaH throttle action] = sniper(state,player,objects)
   leaderaction = action;
    else
        distA = norm([xpos-state{gooselist(1)}{1} ypos-state{gooselist(1)}{2}]);
        distB = norm([xpos-state{gooselist(2)}{1} ypos-state{gooselist(2)}{2}]);
        
        if distA>distB
            targetx = state{gooselist(1)}{1};
            targety = state{gooselist(1)}{2};
        else
            targetx = state{gooselist(2)}{1};
            targety = state{gooselist(2)}{2};
        end
        
        action = 'none';
        throttle = 0;
        
        deltaH = 0;
        
    end
elseif myrank==2
  %  fprintf('I am %d, the RF\n',num)
    lead = min(gooselist);
    targetx = RFpos(1);
    targety = RFpos(2);
    aim = atan2(targety-ypos,targetx-xpos);
    deltaH = aim-heading;
    deltaH = mod(deltaH+pi,2*pi)-pi;
    dist2 = norm([targetx targety]-[xpos ypos]);
    throttle = dist2/0.05; 
    throttle = throttle*abs(dist2-R/20);
    if throttle>1
        throttle = 1;
    end
    action = leaderaction;
elseif myrank==3
   % fprintf('I am %d, the LF\n',num)
    lead = min(gooselist);
    targetx = LFpos(1);
    targety = LFpos(2);
    aim = atan2(targety-ypos,targetx-xpos);
    deltaH = aim-heading;
    deltaH = mod(deltaH+pi,2*pi)-pi;
    dist3 = norm([targetx targety]-[xpos ypos]);
    throttle = dist3/0.05;
    throttle = throttle*abs(dist3-R/20);
    if throttle>1
        throttle = 1;
    end
    action = leaderaction;
end
    if (dist2<R*1.2)&&(dist3<R*1.2)
        linked = 1
    end
save (datafile,'linked','dist2','dist3','leaderaction','firecount')