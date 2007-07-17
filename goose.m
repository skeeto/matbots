function [deltaH throttle action] = goose(state,player,objects,req)

engine_settings

num = player{6};
datafile = ['goosedat' player{5} '.mat'];



if strcmp(req,'preclean')||strcmp(req,'clean')
    sniper(state,player,objects,req)
    if exist(datafile,'file')
        delete(datafile)
    end
    linked = 0;
    dist2 = 100;
    dist3 = 100;
    leaderaction = 'none';
    leaderheading = player{8};
    leaderthrottle = [];
    target = [];
    targethist = [];
    otherfile = [];
    save (datafile,'linked','dist2','dist3','leaderaction','leaderheading','leaderthrottle','targethist','otherfile')
    return
end

load (datafile)

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

    if strcmp(state{i}{7},'goose')&&strcmp(state{i}{5},team)&&(state{i}{3}>0)
        gooselist = [gooselist state{i}{6}];
    end
end

gooselist = [gooselist num];
gooselist = sort(gooselist);

if length(gooselist)==(nothers+1)
    action = 'none';
    throttle = 0;
    deltaH = 0;
    return
end

myrank = find(gooselist==num);

R = rifle_radius*1.5; %Distance of flankers from leader
FlankAngle = 70*pi/180; %Angle behind leader

MDH = pi/25; %max delta H
MT = 0.576; %max throttle

if myrank==1
    [deltaH throttle action] = sniper(state,player,objects,req);
    leaderaction = action;
    leaderheading = heading;
    leaderthrottle = throttle;
    otherfile = ['sniper' team num2str(num) '.mat'];
    load (otherfile);

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

save (datafile,'linked','dist2','dist3','leaderaction','leaderheading','leaderthrottle','targethist','otherfile')