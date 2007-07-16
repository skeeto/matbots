function [deltaH throttle action] = snitch(state,player,objects,req)
load snitchtimer
btime = cputime;

engine_settings;

xpos = player{1};
ypos = player{2};
health = player{3};
energy = player{4};
team = player{5};
num = player{6};
name = player{7};
heading = player{8};

% datafile = ['snitch' team '.mat'];
% 
% if exist(datafile,'file') %if the .mat file exists
%     load(datafile);
% else  %initialize .mat file
%     counter = 0;
% end
% counter = counter + 1;
% 
% save(datafile,'counter')
% 
% if counter>55
%     action = 'suicide';
%     throttle = 0;
%     deltaH = 0;
%     return
% end

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
        
        snitch_time = snitch_time + cputime-btime;
        save snitchtimer impact_time snitch_time
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
                throttle = 1;
                
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

snitch_time = snitch_time + cputime-btime;
save snitchtimer impact_time snitch_time
end %snitch function

function out = impact(bullet,x,y)
load snitchtimer
btime = cputime;
engine_settings;

bh = bullet(3); %bullet's heading
bx = bullet(1); %bullet's x position
by = bullet(2); %bullet's y position

dist = norm([x-bx y-by]);

in = (bx>world(1))&&(bx<world(2))&&(by>world(3))&&(by<world(4));

while in
    if dist<rifle_radius
        out = 1;
        impact_time = impact_time + cputime-btime;
        save snitchtimer impact_time snitch_time
        return
    end
    bx = bx + rifle_speed*ts*cos(bh);
    by = by + rifle_speed*ts*sin(bh);
    dist = norm([x-bx y-by]);
    in = (bx>world(1))&&(bx<world(2))&&(by>world(3))&&(by<world(4));
end

out = 0;

        impact_time = impact_time + cputime-btime;
        save snitchtimer impact_time snitch_time
end %function