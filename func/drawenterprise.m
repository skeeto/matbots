function out = drawenterprise(xpos,ypos,heading,enterpriseR,color)

centerx = -194.3377;
centery = 0;
R = 143.87;
psi = (0:6:360)*pi/180;

xpoints = [-50.467742 -53.693548 -29.177419 -15.629032 1.145161 12.112903 66.951613 25.661290 -15.629032 -24.016129 -27.887097 -29.822581 -31.112903 -31.112903 -29.177419 -26.596774 -20.790323 -16.274194 203.725806 236.629032 254.693548 270.177419 277.919355 279.209677 276.629032 271.467742 254.693548 232.112903 197.919355 128.241935 45.661290 101.790323 113.403226 117.274194 117.274194]';
ypoints = [0.000000 -31.360000 -33.280000 -32.640000 -32.640000 -30.080000 -87.680000 -88.960000 -87.680000 -89.600000 -92.800000 -95.360000 -98.560000 -101.760000 -104.960000 -107.520000 -109.440000 -110.080000 -111.360000 -109.440000 -108.160000 -105.600000 -102.400000 -98.560000 -96.000000 -94.080000 -91.520000 -90.240000 -88.320000 -88.320000 -25.600000 -19.840000 -13.440000 -5.120000 0.000000]';

xpoints = [xpoints; xpoints(end:-1:1)];
ypoints = [ypoints; -ypoints(end:-1:1)];

centerx = centerx/617.4174*enterpriseR;
centery = centery/617.4174*enterpriseR;
R = R/617.4174*enterpriseR;
xpoints = xpoints/617.4174*enterpriseR;
ypoints = ypoints/617.4174*enterpriseR;

L = [ cos(heading+pi) -sin(heading+pi)  ; sin(heading+pi) cos(heading+pi)];
P = L*[xpoints'; ypoints'];

center = [centerx; centery];

center = L*center;

centerx = center(1);
centery = center(2);

hold on
eplot(xpos+P(1,:),ypos+P(2,:),'Color',color);
eplot(xpos+centerx+R*cos(psi),ypos+centery+R*sin(psi),'Color',color);
R = R/18;
eplot(xpos+centerx+R*cos(psi),ypos+centery+R*sin(psi),'Color',color);
axis equal
