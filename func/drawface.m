function out = drawface(xpos,ypos,eyeheading,faceR,color)
eyeR = faceR/3;
eyeH = faceR/3;
eyeW = faceR/1.5;
mouthH = faceR/2;
mouthW = faceR/2;
pupilR = eyeR/2;
psi = (0:6:360)*pi/180;
eplot(xpos+faceR*cos(psi),ypos+faceR*sin(psi),'Color',color)
hold on
eplot(xpos+[-mouthW/2 mouthW/2],ypos+[-mouthH -mouthH],'Color',color)
eplot(xpos-eyeW/2+eyeR*cos(psi),ypos+eyeH+eyeR*sin(psi),'Color',color)
eplot(xpos+eyeW/2+eyeR*cos(psi),ypos+eyeH+eyeR*sin(psi),'Color',color)
eplot(xpos-eyeW/2+(eyeR-pupilR)*cos(eyeheading)+pupilR*cos(psi),ypos+eyeH+(eyeR-pupilR)*sin(eyeheading)+pupilR*sin(psi),'Color',color)
eplot(xpos+eyeW/2+(eyeR-pupilR)*cos(eyeheading)+pupilR*cos(psi),ypos+eyeH+(eyeR-pupilR)*sin(eyeheading)+pupilR*sin(psi),'Color',color)
out = 1;