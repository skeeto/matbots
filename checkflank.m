function out = checkflank(x,y,h)

heading = h;

R = 0.1; %Distance of flankers from leader
FlankAngle = -pi/6; %Angle behind leader

MDH = pi/25; %max delta H
MT = 0.576; %max throttle

RFvec = R*[cos(FlankAngle) sin(FlankAngle)]'; %vector from leader to right flanker
LFvec = RFvec.*[-1; 1]; %vector from leader to left flanker

RFvec = [cos(pi/2) sin(pi/2); -sin(pi/2) cos(pi/2)]*RFvec;
LFvec = [cos(pi/2) sin(pi/2); -sin(pi/2) cos(pi/2)]*LFvec;

RFvec = [cos(-h) sin(-h); -sin(-h) cos(-h)]*RFvec;
LFvec = [cos(-h) sin(-h); -sin(-h) cos(-h)]*LFvec;

plot(x,y,'o')
hold on
line([x x+cos(h)],[y y+sin(h)])

RFpos = [x y]' + RFvec;
LFpos = [x y]' + LFvec;

plot(RFpos(1),RFpos(2),'*')
plot(LFpos(1),LFpos(2),'*')

out = 1;
