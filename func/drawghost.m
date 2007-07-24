function out = drawghost(xpos,ypos,heading,ghostR,color)

heading = mod(heading+pi,2*pi)-pi;

bodyx = [0 -6 -6 -11 -11 -17 -17 -23 -23 -36 -36 -42 -42 -36 -36 -30 -30 -24 -24 -11 -11 0 0 11 11 24 24 30 30 36 36 42 42 36 36 23 23 17 17 11 11 6 6 0];
bodyy = [0 0 7 7 12 12 7 7 0 0 8 8 50 50 68 68 74 74 80 80 85 85 85 85 80 80 74 74 68 68 50 50 8 8 0 0 7 7 12 12 7 7 0 0];
eyex = [ -36   -30   -30   -18   -18   -12   -12   -18   -18   -30   -30   -36 ];
eyey = [ 44    44    38    38    44    44    62    62    68    68    62    62 ];
pupilx = [0 12 12 0];
pupily = [0 0 12 12];

if (-pi<=heading)&&(heading<-2*pi/3)
    eye1x = -36;
    eye2x = 0;
    pupilx1 = pupilx+eye1x;
    pupilx2 = pupilx+eye2x;
    pupily = pupily+44;
elseif (-2*pi/3<=heading)&&(heading<-pi/3)
     eye1x = -30;
     eye2x = 30-24;
     pupilx1 = pupilx+eye1x+6;
     pupilx2 = pupilx+eye2x+6;
     pupily = pupily+38;
elseif (-pi/3<=heading)&&(heading<0)
     eye1x = 0-24;
     eye2x = 36-24;
     pupilx1 = pupilx+eye1x+24-12;
     pupilx2 = pupilx+eye2x+24-12;
     pupily = pupily+38+6;
elseif (0<=heading)&&(heading<pi/3)
     eye1x = -24;
     eye2x = 36-24;
     pupilx1 = pupilx+eye1x+24-12;
     pupilx2 = pupilx+eye2x+24-12;
     pupily = pupily+62-12;
elseif (pi/3<=heading)&&(heading<2*pi/3)
     eye1x = -30;
     eye2x = 6;
     pupilx1 = pupilx+eye1x+6;
     pupilx2 = pupilx+eye2x+6;
     pupily = pupily+68-12;
else 
     eye1x = -36;
     eye2x = 0;
     pupilx1 = pupilx+eye1x;
     pupilx2 = pupilx+eye2x;
     pupily = pupily+62-12;
end

eye1x = eye1x+eyex+36;
eye2x = eye2x+eyex+36;

bodyx = bodyx/84*2*ghostR;
bodyy = (bodyy-85/2)/85*2*ghostR;
eye1x = eye1x/84*2*ghostR;
eye2x = eye2x/84*2*ghostR;
eyey = (eyey-85/2)/85*2*ghostR;
pupilx1 = pupilx1/84*2*ghostR;
pupilx2 = pupilx2/84*2*ghostR;
pupily = (pupily-85/2)/84*2*ghostR;

eplot('fill',xpos+bodyx,ypos+bodyy,color)
hold on
eplot('fill',xpos+eye1x,ypos+eyey,'w')
eplot('fill',xpos+eye2x,ypos+eyey,'w')
eplot('fill',xpos+pupilx1,ypos+pupily,'k')
eplot('fill',xpos+pupilx2,ypos+pupily,'k')


