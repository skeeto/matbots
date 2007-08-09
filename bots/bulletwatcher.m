function [deltaH throttle action] = bulletwatcher(state, player, objects, req)

datafile = ['bwatcher' num2str(player{6}) '.mat'];

engine_settings;

if strcmp(req,'selfplot')
    throttle = 0;
    deltaH = 0;
    action = 0;
    return
elseif strcmp(req,'preclean')||strcmp(req,'clean')
    if exist(datafile,'file')
        delete(datafile)
    end
    if strcmp(req,'preclean')
        time = 0;
        mybullets = [];
        save (datafile,'time','mybullets')
    end
    return
end

load (datafile)

bullets = zeros(length(objects),6);

blist = [];
for i = 1:length(objects)
    if strcmp(objects{i}{1},'rifle')
       blist = [blist i];
    end
end


%% Remove bullets that I know left the map
dqueue = [];
for i = 1:size(mybullets,1)
    if mybullets(i,6)<=time
        dqueue = [dqueue; i];
        fprintf('Left Map\n')
    end
end

mybullets(dqueue,:) = [];

%% If my bulletlist is empty...
if isempty(mybullets)
    addqueue = blist;
else
    bxlist = [];
    for i = blist
        bxlist = [bxlist; objects{i}{2}];
    end
    
  %  bxlist
  %  mybullets(:,1)


    
    dqueue = [];
    for i = 1:size(mybullets,1)
        ex = mybullets(i,1) + mybullets(i,3)*(time-mybullets(i,5))
        if isempty(find(abs(ex-bxlist)<0.0001))
            dqueue = [dqueue; i];
            fprintf('Cant find one!\n')
        end
    end

    mybullets(dqueue,:) = [];
    
    addqueue = [];
    if length(blist)>size(mybullets,1)
        addqueue = blist(size(mybullets,1)+1:end);
    end
    
end


%% Add bullet...which is object #i
for i = addqueue
       etime = zeros(1,2);
       dx = rifle_speed*cos(objects{i}{4});
       dy = rifle_speed*sin(objects{i}{4});
       if sign(dx)>0
           etime(1) = (world(2)-objects{i}{2})/rifle_speed + time;
       else
           etime(1) = (objects{i}{2}-world(1))/rifle_speed + time;
       end
       if sign(dy)>0
           etime(2) = (world(4)-objects{i}{3})/rifle_speed + time;
       else
           etime(2) = (objects{i}{3}-world(3))/rifle_speed + time;
       end
       etime = min(etime);
       mybullets = [mybullets; objects{i}{2} objects{i}{3} dx dy time etime];
end


psi = (0:6:360)*pi/180;
for i = 1:size(mybullets,1)
    x0 = mybullets(i,1);
    y0 = mybullets(i,2);
    dx = mybullets(i,3);
    dy = mybullets(i,4);
    tf = mybullets(i,5);
    
    xn = x0 + dx*(time+ts-tf);
    yn = y0 + dy*(time+ts-tf);
    
    plot(xn+rifle_radius*cos(psi),yn+rifle_radius*sin(psi));
    
end
time = time+ts;

save (datafile,'time','mybullets')
throttle = 0;
action = '';
deltaH = 0;