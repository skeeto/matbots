function [deltaH throttle action] = goose(state,player,objects,req)
% GOOSE
% coded by: Mike Abraham
% last update: 07/19/2007
%
% This was my first bot with team cooperation capability.  I jumped
% immediately into a large level of complexity.  The GOOSE bot travls in
% formation with the rest of the geese on its team.  The GOOSE with the
% highest player number is the leader and calls SNIPER.  The other geese
% calculate their rank based upon their player number and task to a
% specific point in a "flying V" type formation behind the lead bot.  The
% follower geese will fire at the same target that the lead goose fires
% upon IF they can turn quick enough.  If not, they don't waste energy on a
% stray bullet.  The GOOSE bot will also quack occasionally.

engine_settings

datafile = ['goosedat' player{5} '.mat'];

if strcmp(req,'selfplot')
    throttle = 0;
    deltaH = 0;
    action = req;
    return
elseif strcmp(req,'preclean')||strcmp(req,'clean')
    sniper(state,player,objects,req)
    if exist(datafile,'file')
        delete(datafile)
    end
    if strcmp(req,'preclean')
        linked = 0;
        dist2 = 100;
        dist3 = 100;
        leaderaction = 'none';
        leaderheading = player{8};
        leaderthrottle = [];
        target = [];
        targethist = [];
        otherfile = [];
        whoquacks = 0;
        quackcount = 0;
        save (datafile,'linked','dist2','dist3','leaderaction','leaderheading','leaderthrottle','targethist','otherfile','whoquacks','quackcount')
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
h = heading;

nothers = size(state,2);

%% Identify and Sort All Friendly Geese
gooselist = [];
for i = 1:nothers
    if strcmp(state{i}{7},'goose')&&strcmp(state{i}{5},team)&&(state{i}{3}>0)
        gooselist = [gooselist state{i}{6}];
    end
end

gooselist = [gooselist num];
gooselist = sort(gooselist);

%% Check for end of game condition
if length(gooselist)==(nothers+1)
    action = 'none';
    throttle = 0;
    deltaH = 0;
    return
end

%% Randomly Quack
if quackcount==0
    if rand<.01
        quackcount = 10;
        whoquacks = num;
    end
end

if quackcount>0
    if num==whoquacks
        quackcount = quackcount-1;
        text(xpos,ypos+.3,'quack')
    end
end

%% Determine my rank
myrank = find(gooselist==num);

%% Bot Parameters
R = rifle_radius*1.5; %Distance of flankers from leader
FlankAngle = 70*pi/180; %Angle behind leader
MDH = pi/25; %max delta H
MT = 0.576; %max throttle

%% Lead Goose Actions
if myrank==1
    [deltaH throttle action] = sniper(state,player,objects,req);
    leaderaction = action;
    leaderheading = heading;
    leaderthrottle = throttle;
    otherfile = ['sniper' team num2str(num) '.mat'];
    load (otherfile);

%% Right Flanker Actions
elseif mod(myrank,2)
    load (otherfile)
    theleader = gooselist(floor(myrank/2));

    for i = 1:nothers
        if state{i}{6}==theleader
            whichstate = i;
        end
    end

    action = leaderaction;

    if strcmp(action,'rifle')
        dist = norm([state{target}{1}-xpos  state{target}{2}-ypos]);

        targetx = state{target}{1};
        targety = state{target}{2};
        targetvector = targethist(2,:)-targethist(1,:);
        timetotarget = dist/rifle_speed;
        newtarget=[targetx targety] + targetvector*(timetotarget/0.05);
        targetx = newtarget(1);
        targety = newtarget(2);

        aim = atan2(targety-ypos,targetx-xpos);
        deltaH = aim-heading;
        deltaH = mod(deltaH+pi,2*pi)-pi;
        throttle = leaderthrottle;
        if abs(deltaH)>deltaH_max
            action = 'none';
        end
    else

        RFvec = R*[cos(FlankAngle) sin(FlankAngle)]';
        RFvec = [cos(pi/2) sin(pi/2); -sin(pi/2) cos(pi/2)]*RFvec;
        RFvec = [cos(-h) sin(-h); -sin(-h) cos(-h)]*RFvec;
        RFpos = [state{whichstate}{1} state{whichstate}{2}]' + RFvec;

        targetx = RFpos(1);
        targety = RFpos(2);

        aim = atan2(targety-ypos,targetx-xpos);
        deltaH = aim-heading;
        deltaH = mod(deltaH+pi,2*pi)-pi;
        dist2 = norm([targetx targety]-[xpos ypos]);

        throttle = dist2^4;
    end

%% Left Flanker Actions
elseif ~mod(myrank,2)
    load (otherfile)
    theleader = gooselist(floor(myrank/2));
    for i = 1:nothers
        if state{i}{6}==theleader
            whichstate = i;
        end
    end

    action = leaderaction;

    if strcmp(action,'rifle')

        dist = norm([state{target}{1}-xpos  state{target}{2}-ypos]);

        targetx = state{target}{1};
        targety = state{target}{2};
        targetvector = targethist(2,:)-targethist(1,:);
        timetotarget = dist/rifle_speed;
        newtarget=[targetx targety] + targetvector*(timetotarget/0.05);
        targetx = newtarget(1);
        targety = newtarget(2);

        aim = atan2(targety-ypos,targetx-xpos);
        deltaH = aim-heading;
        deltaH = mod(deltaH+pi,2*pi)-pi;
        throttle = leaderthrottle;
        if abs(deltaH)>deltaH_max
            action = 'none';
        end
    else
        LFvec = R*[-cos(FlankAngle) sin(FlankAngle)]';
        LFvec = [cos(pi/2) sin(pi/2); -sin(pi/2) cos(pi/2)]*LFvec;
        LFvec = [cos(-h) sin(-h); -sin(-h) cos(-h)]*LFvec;
        LFpos = [state{whichstate}{1} state{whichstate}{2}]' + LFvec;

        targetx = LFpos(1);
        targety = LFpos(2);

        aim = atan2(targety-ypos,targetx-xpos);
        deltaH = aim-heading;
        deltaH = mod(deltaH+pi,2*pi)-pi;

        dist3 = norm([targetx targety]-[xpos ypos]);
        throttle = dist3^4;

    end

end

if (dist2<R*1.2)&&(dist3<R*1.2)
    linked = 1;
end

xdraws = [.125 -.125 -.125/3 -.125 .125];
ydraws = [0 .125 0 -.125 0];

L = [ cos(heading+deltaH) -sin(heading+deltaH)  ; sin(heading+deltaH) cos(heading+deltaH)];
P = L*[xdraws; ydraws];

if abs(throttle)>1
    throttle = throttle/abs(throttle);
end

eplot(xpos+ts*throttle*cos(heading+deltaH)+P(1,:),ypos+ts*throttle*sin(heading+deltaH)+P(2,:),'Color', player{9});

save (datafile,'linked','dist2','dist3','leaderaction','leaderheading','leaderthrottle','targethist','otherfile','whoquacks','quackcount')