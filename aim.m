function out = aim(pos,heading)
xpos = pos(1);
ypos = pos(2);
targetx = pos(3);
targety = pos(4);


aim = atan2(targety-ypos,targetx-xpos);

deltaH = aim-heading;

if deltaH>pi
   deltaH = deltaH-2*pi; 
elseif deltaH<-pi
   deltaH = 2*pi-deltaH;
end

if abs(deltaH)<pi/4
    action = 'rifle'
else
    action = 'none'
end

out = deltaH;

plot(xpos,ypos,'o');
hold on
plot(targetx,targety,'*')

line([xpos xpos+cos(heading)],[ypos ypos+sin(heading)])
line([xpos xpos+cos(heading + deltaH)],[ypos ypos+sin(heading+deltaH)])
axis([-5 5 -5 5])