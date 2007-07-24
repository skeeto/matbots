function out = drawhand(xpos,ypos,heading,HS,color)

HS = .5;
hh = HS;
fh = HS*.6;
fw = HS/10;
fd = HS/3
mfh = hh-fh;
th = hh/3;

xpoints = [0 5*fw 5*fw 5*fw-fw 5*fw-fw 5*fw-fw 5*fw-2*fw 5*fw-2*fw 5*fw-2*fw 5*fw-3*fw 5*fw-3*fw 5*fw-3*fw 5*fw-4*fw 5*fw-4*fw 0     0];
ypoints = [0 0  fh fh    fh-fd fh    fh      fh-fd   fh+mfh  fh+mfh  fh-fd   fh      fh      fh-th   fh-th 0];

xpoints = xpoints-5*fw/2;
ypoints = ypoints-(fh+mfh)/2;

L = [ cos(heading-pi/2) -sin(heading-pi/2)  ; sin(heading-pi/2) cos(heading-pi/2)];
P = L*[xpoints; ypoints];

eplot(xpos+P(1,:),ypos+P(2,:),'Color', color);