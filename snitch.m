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

datafile = ['snitch' team '.mat'];

if exist(datafile,'file') %if the .mat file exists
    load(datafile);
else  %initialize .mat file

end

Rstep = 0.1;
Hstep = 10*pi/180;

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
    if health<25
        action = ['HtoE-' num2str(energy_regen/health_energy_ratio)];
    else
        action = ['HtoE' num2str(health-75)];
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
            %                 R
            %                 H
            %                 Hstep
            %                 heading
            %                 xnow
            %                 ynow
            %                 hits
            %                 pause
            if ~hits   %if there are no hits, assign target position
                safe = 1;
                targetx = xnow;
                targety = ynow;

                aim = atan2(targety-ypos,targetx-xpos);
                deltaH = aim-heading;
                deltaH = mod(deltaH+pi,2*pi)-pi;
                throttle = 1;
                action = 'none';

                break
            end %if hits
            dH = dH + Hstep;
        end %while dH
        R = R+Rstep;
    end %while safe
end



end %snitch function

function out = impact(bullet,x,y)

engine_settings;

bh = bullet(3); %bullet's heading
bx = bullet(1); %bullet's x position
by = bullet(2); %bullet's y position

dist = norm([x-bx y-by]);

in = (bx>world(1))&&(bx<world(2))&&(by>world(3))&&(by<world(4));

while in
    if dist<rifle_radius
        out = 1;
        return
    end
    bx = bx + rifle_speed*ts*cos(bh);
    by = by + rifle_speed*ts*sin(bh);
    dist = norm([x-bx y-by]);
    in = (bx>world(1))&&(bx<world(2))&&(by>world(3))&&(by<world(4));
end

out = 0;
end %function