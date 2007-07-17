function [deltaH throttle action] = snitch(state,player,objects,req)

engine_settings;

xpos = player{1};
ypos = player{2};
health = player{3};
energy = player{4};
team = player{5};
num = player{6};
name = player{7};
heading = player{8};

Rstep = 0.1;
Hstep = 10*pi/180;

Hlist = 0;
for i = Hstep:Hstep:pi
    Hlist = [Hlist i -i i+pi -i+pi];
end

%%Put together list of all bullets on the map
bulletlist = [];
for i = 1:length(objects)
    if strcmp(objects{i}{1},'rifle')
        if ~strcmp(objects{i}{5},team)
            bulletlist = [bulletlist; objects{i}{2} objects{i}{3} objects{i}{4}];
        end
    end
end

queue = [];
for i = 1:size(bulletlist,1)
    dist = norm([bulletlist(i,1)-xpos bulletlist(i,2)-ypos]);
    mindist = abs(dist*sin(bulletlist(i,3)-atan2(bulletlist(i,2)-ypos,bulletlist(i,1)-xpos)));
    if mindist>rifle_radius
        queue = [queue i];
    end
end

bulletlist(queue,:) = [];

if isempty(bulletlist)
    throttle = 0;
    deltaH = 0;
    action = 'none';
    if health<50
        action = ['HtoE-' num2str(energy_regen/health_energy_ratio)];
    end
    
    if energy<90
        action = ['HtoE' num2str(health-25)];
    end
    
    if (energy>90)&&(health<90)
        action = ['HtoE-' num2str(3*energy_regen/health_energy_ratio)];
    end
    
    if (energy>50)&&(health>75)
        [deltaH throttle action] = sniper(state,player,objects,req);
        if abs(deltaH)<=deltaH_max
            action = 'rifle';
        end
    end
    
else
    R = 0;
    H = 0;
    hits = 0;
    for i = 1:size(bulletlist,1)
        hits = hits+impact(bulletlist(i,:),xpos,ypos);
    end
    safe = ~sign(hits);

    if safe
        [deltaH throttle action] = uzi(state,player,objects,req);
        
        if strcmp(action,'rifle')
            if abs(deltaH)>=deltaH_max
                action = 'none';
            end
        end
        
        return
    end

    while ~safe


        dH = 0;
        while abs(dH<2*pi)
            H = heading + dH;

            xnow = xpos + R*cos(H);
            ynow = ypos + R*sin(H);
            %%%%%%%%%%%Checking the safety of position xnow, ynow
            hits = 0;
            for i = 1:size(bulletlist,1)
                hits = hits+impact(bulletlist(i,:),xnow,ynow);      
            end
          
            if ~hits   %if there are no hits, assign target position
                safe = 1;
                targetx = xnow;
                targety = ynow;

                aim = atan2(targety-ypos,targetx-xpos);
                deltaH = aim-heading;
                deltaH = mod(deltaH+pi,2*pi)-pi;
                
                dist = norm([xpos-targetx ypos-targety]);
                
                throttle = dist/(ts);
                
                if abs(deltaH)>pi/2
                    deltaH = deltaH+pi;
                    throttle = -throttle;
                end
                
                action = 'none';

                break
            end %if hits
            dH = dH + Hstep;
        end %while dH
        R = R+Rstep;
    end %while safe
end

end %snitch function

function out = impact(bullet,xpos,ypos)

engine_settings;

bh = bullet(3); %bullet's heading
bx = bullet(1); %bullet's x position
by = bullet(2); %bullet's y position

%Handle vertical trajectories:
if abs(bh)==pi/2;
    if sign(bh)>0
        if ypos<by-rifle_radius
            out = 0;
            return
        else
            if (xpos<bx+rifle_radius)&&(xpos>bx-rifle_radius)
                out = 1;
                return
            else
                out = 0;
                return
            end
        end
    else
        if ypos>by+rifle_radius
            out = 0;
            return
        else
            if (xpos<bx+rifle_radius)&&(xpos>bx-rifle_radius)
                out = 1;
                return
            else
                out = 0;
                return
            end
        end
    end
end
%end of handling vertical trajectories

%Check to see if bullet has already passed by
if (bx-rifle_radius>xpos)&&(cos(bh)>0)
    out = 0;
    return
end
if (bx+rifle_radius<xpos)&&(cos(bh)<0)
    out = 0;
    return
end
if (by-rifle_radius>ypos)&&(sin(bh)>0)
    out = 0;
    return
end
if (by+rifle_radius<ypos)&&(sin(bh)<0)
    out = 0;
    return
end
%end of checking to see if bullet has already passed by

%Check only two closest bullet locations
bxstep = rifle_speed*ts*cos(bh);
adjustfactor = mod(bx,bxstep);

lower_circle_x = bxstep*floor((xpos-adjustfactor)/bxstep)+adjustfactor;
upper_circle_x = bxstep*ceil((xpos-adjustfactor)/bxstep)+adjustfactor;

dx = cos(bh);
dy = sin(bh);
slope = dy/dx;
intercept = by - slope*bx;

bpoly = [slope intercept];

lower_circle_y = bpoly*[lower_circle_x 1]';
upper_circle_y = bpoly*[upper_circle_x 1]';

dist_lower = norm([xpos-lower_circle_x ypos-lower_circle_y]);
dist_upper = norm([xpos-upper_circle_x ypos-upper_circle_y]);

out = (dist_lower<=rifle_radius)||(dist_upper<=rifle_radius);

end %function