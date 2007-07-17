function [deltaH throttle action] = webbbot(state, player, objects, req)

engine_settings
%1 xpos    (double precision)
%2 ypos    (double precision)
%3 health  (double precision)
%4 energy  (double precision)
%5 team    (string)
%6 num     (integer)
%7 name    (string)
%8 heading (double precision)
%9 color   (string)

% load my info
xpos = player{1};
ypos = player{2};
health = player{3};
energy = player{4};
team = player{5};
num = player{6};
name = player{7};
heading = player{8};

% disp('state')
% for i = 1:length(state)
%     state{i}
% end

% disp('objects')
% for i = 1:length(objects)
%     objects{i}
% end

sz_obj = size(objects);
how_many_obj = sz_obj(1,2);
% keyboard
% pause

sz_state = size(state);
how_many_total = sz_state(1,2)+1;

count = 0;
who_we = 0;
for i = 1:how_many_total-1
    if strcmp(state{i}{5},team)
        count = 1+count;
        who_we(count) = i;
    end
end

if who_we == 0
    how_many_we = 1;
else
    how_many_we = length(who_we)+1;
end




deltaH = 0;
throttle = 0;
action = '';

%% IS THIS THE FIRST RUN????
if strcmp(req,'preclean')
            superduper = num2str(floor(rand*10000));
            game_step = 0;  
            filename = ['power',superduper,'.mat'];
            save(['goteam',team,'.mat'],'superduper','game_step')
            
elseif how_many_we == how_many_total %&& how_many_total > 0
    disp(['WEBB RULES'])
    throttle = 1;
    deltaH = deltaH_max;
    action = 'riffle';
    if exist(['goteam',team,'.mat'],'file')
        load(['goteam',team,'.mat'])
        filename = ['power',superduper,'.mat'];
        delete(filename)
        delete(['goteam',team,'.mat'])
    end
    
else
    
%% AM I FIRST???  ALONE???

    if how_many_we == 1 || state{who_we(1)}{6} > num
        %time to think
        
%% NOT FIRST STEP, SO SETUP STUFF
    load(['goteam',team,'.mat'])
    filename = ['power',superduper,'.mat'];
    game_step = game_step+1;
    save(['goteam',team,'.mat'],'superduper','game_step')
    if exist(filename,'file')
        load(filename);
    end
    clear target_num
    
%% WHERE ARE WE??

        if how_many_we == 1
            X_WE = xpos;
            Y_WE = ypos;
        else
            x_we = xpos;
            y_we = ypos;
            for i = 1:how_many_we-1
                which = who_we(i);
                x_we = x_we + state{which}{1};
                y_we = y_we + state{which}{2};
            end

            X_WE = x_we/how_many_we;
            Y_WE = y_we/how_many_we;
        end
        
%% WHERE IS EVERYONE ELSE???
    
%     for i = 1:how_many_total-1
%         state{i}
%     end
%     if exist('where_they_at')
%         where_they_at
%     end
    
    count = 0;
    for i = 1:how_many_total-1
        if strcmp(state{i}{5},team)
        else
            if exist('where_they_at','var')
                if game_step == 1
                    count = count +1;
                else
                    count = find(where_they_at(:,1,game_step-1) == state{i}{6});
                end
            else
                count = 1;
            end
            where_they_at(count,1,game_step) = state{i}{6};  % num of this other teams member
            where_they_at(count,2,game_step) = state{i}{1};  % x pos of this other teams member
            where_they_at(count,3,game_step) = state{i}{2}; % y pos of this other teams member
        end
    end            

%% WHO IS SHOOTING??

    count = 0;
    riflers = 0;
    for i = 1:how_many_obj
        if strcmp(objects{i}{1},'rifle')
            count = count + 1;
            teams_acting{count} =  objects{i}{5};
            riflers = 1;
        end
    end

    if riflers == 1

        teams_acting = sort(teams_acting);
        sz_teams_acting = size(teams_acting);
        how_many_acting = sz_teams_acting(1,2);

        %% WHO IS ACTING??  
        count = 1;
        who_acts{count} = teams_acting{1};
        who_acts_many(count) = 1;
        if how_many_acting > 1
            for i = 2:how_many_acting
                if strcmp(teams_acting{i},who_acts{count})
                    who_acts_many(count) = who_acts_many(count)+1;
                else
                    count = count+1;
                    who_acts{count} = teams_acting{i};
                    who_acts_many(count) = 1;
                end
            end
        end

        sz_who_acts = size(who_acts);
        how_many_dif_act = sz_who_acts(1,2);

        % don't shoot own team
        for i = 1:how_many_dif_act
            if strcmp(who_acts{i},team)
                who_acts_many(i) = 0;
            end
        end

        %who is shooting the most???
        [how_much_acts_most,i] = max(who_acts_many);
        
        if how_much_acts_most == 0
            riflers = 0;
        else    
            who_acts_most = who_acts{i};
            % do these teams shooting so much even exist?
            count = 254;
            for i = 1:how_many_total-1
                if strcmp(state{i}{5},who_acts_most)
                    count = 500;
                end
            end
            if count == 254;
                riflers = 0;
            end
        end
    end             
% pause
        
%% FIND TARGET
    if riflers == 0
        % find the closest enemy and blow chunks
        clear dist
        count = 0;
        for i = 1:how_many_total-1
            if strcmp(state{i}{5},team)
            else
                count = count + 1;
                dist(2,count) = norm([state{i}{1}-X_WE,state{i}{2}-Y_WE]);
                dist(1,count) = i;
            end
        end
        % dist = dist
        dist_target = min(dist(2,:));
        who_target = dist(1,find(dist_target == dist(2,:)));

        target_num = state{who_target}{6};

    else
        % find the nearest big threat team and blow chunks
        clear dist
        count = 0;

        for i = 1:how_many_total-1
            if strcmp(state{i}{5},who_acts_most)
                count = count + 1;
                dist(2,count) = norm([state{i}{1}-X_WE,state{i}{2}-Y_WE]);
                dist(1,count) = i;
            end
        end
        % dist
        dist_target = min(dist(2,:));
        who_target = dist(1,find(dist_target == dist(2,:)));

        target_num = state{who_target}{6};

    end


%% WRITE TO MAT FILE
           % if I want to write something this would be a good time
            save(filename,'target_num','where_they_at')

%% I AM NOT ALONE AND AM NOT FIRST
    else 
        % no thought
        % just act
        load(['goteam',team,'.mat'])
        filename = ['power',superduper,'.mat'];
        load(filename)
%         disp('idiot says')
   
    end

            [deltaH throttle action] = act_now(how_many_total,state,objects,player);
%             [deltaH throttle action] = dodgeball(how_many_total,how_many_obj,state,objects,player);
end
    

















%% ACTION JACKSON
function [deltaH throttle action] = act_now(how_many_total,state,objects,player,target_num)
engine_settings

xpos = player{1};
ypos = player{2};
health = player{3};
energy = player{4};
team = player{5};
num = player{6};
name = player{7};
heading = player{8};
load(['goteam',team,'.mat'])
filename = ['power',superduper,'.mat'];
load(filename)



%% FIND TARGET
% find target out of state

% disp(['target number from action is ',num2str(target_num)])
for i = 1:how_many_total-1
    if state{i}{6} == target_num
       who_target = i;
    end
end

where_num = find(where_they_at(:,1,game_step)==target_num);

%% IS TARGET MOVING???

if game_step == 1
    targeting = 'stationary';
else%if game_step == 2
    where_they_at(where_num,:,game_step-1:game_step);
    
    x_t_n = where_they_at(where_num,2,game_step);
    x_t_nm1 = where_they_at(where_num,2,game_step-1);
    y_t_n = where_they_at(where_num,3,game_step);
    y_t_nm1 = where_they_at(where_num,3,game_step-1);
    
    xd_t = (x_t_n-x_t_nm1)/ts;
    yd_t = (y_t_n-y_t_nm1)/ts;
%     pause
    
    if abs(xd_t) < .001 && abs(yd_t) < .001
        targeting = 'stationary';
    else        
        targeting = 'moving';
%         targeting = 'stationary';
    end
end

%% SHOOT MOVING TARGET
if strcmp(targeting,'moving')
    xdif_target = state{who_target}{1} - xpos;
    ydif_target = state{who_target}{2} - ypos;
    angle_target = atan2(ydif_target,xdif_target);
    
    targets_heading = atan2(yd_t,xd_t);
    targets_speed = norm([xd_t,yd_t]);
    dist = norm([xdif_target,ydif_target]);
    t_hit = dist/rifle_speed;
    relative_angle = pi+angle_target-targets_heading;
    
    dist_target_goes_perp = sin(relative_angle)*targets_speed*t_hit;
    
    angle_target = angle_target + atan2(dist_target_goes_perp,dist);
end

%% SHOOT STATIONARY TARGET
if strcmp(targeting,'stationary')
    xdif_target = state{who_target}{1} - xpos;
    ydif_target = state{who_target}{2} - ypos;
    angle_target = atan2(ydif_target,xdif_target);
    % pause
    
end
%% CALCUALTE DELTA_H (KILL)

if heading < 0
    heading = heading + (2*pi);
end
if angle_target < 0 
    angle_target = angle_target + (2*pi);
end

dif_head = heading-angle_target;

if dif_head < 0
    dif_head = abs(dif_head);
    sign = 1;
else
    sign = -1;
end

if dif_head < pi 
    if dif_head < deltaH_max
        deltaH = dif_head*sign;
    else
        deltaH = deltaH_max*sign;
    end
else 
    dif_head = 2*pi - dif_head;
    if dif_head < deltaH_max
        deltaH = -dif_head*sign;
    else
        deltaH = -deltaH_max*sign;
    end
end

%% KILL TARGET
int_check = game_step/15;
int_check2 = floor(int_check);
int_check3 = int_check-int_check2;

if int_check3 == 0
    if abs(dif_head) < .1
        action = 'rifle';
        throttle = 0;
    else 
        action = '';
        throttle = 0;
    end
elseif int_check3 > .7
    if abs(dif_head) < .1
        action = 'rifle';
        throttle = 0;
    else 
        action = '';
        throttle = 0;
    end
else
        [deltaH throttle action] = dodgeball(how_many_total,state,objects,player);
end











%% DODGEBALL
function [deltaH throttle action] = dodgeball(how_many_total,state,objects, player)

engine_settings

xpos = player{1};
ypos = player{2};
health = player{3};
energy = player{4};
team = player{5};
num = player{6};
name = player{7};
heading = player{8};
load(['goteam',team,'.mat'])
filename = ['power',superduper,'.mat'];
load(filename)

[how_many_obj,n] = size(objects);

%% FIND THREATS

sec_search = 3;
search_rad = rifle_speed*sec_search; %this is the radius to find all things within sec_search seconds from me

count = 1;
if ~isempty(objects)
    for i = 1:how_many_obj
        if strcmp(objects{i}{1},'rifle') && ~strcmp(objects{i}{5},team)
            if norm([objects{i}{2}-xpos,objects{i}{3}-ypos]) < search_rad %only put in imiediate threats
                bullets(count,1) = objects{i}{2}-xpos; % relitive x pos
                bullets(count,2) = objects{i}{3}-ypos; % relitive y pos
                bullets(count,3) = objects{i}{4}; %heading
                count = count+1;
            end
        end
    end
end

how_many_threats = count-1;

%% IS IT REALLY A THREAT???

if exist('bullets','var')
    for i = 1,how_many_threats;
        heading_from_bullet = atan2(-bullets(i,2),-bullets(i,1));
        if abs(heading_from_bullet-bullets(i,3)) < .1
            % run away!!! run away!!! run away!!!
            disp('its coming right at me')
            game_step
            int_check = floor(game_step/100)/2-floor(floor(game_step/100)/2)
            if  int_check == .5
                run_sign = 1;
            else
                run_sign = -1;
            end
            angle_run = heading_from_bullet+run_sign*pi/2;

%% CALCUALTE DELTA_H (RUN)
            if heading < 0
                heading = heading + (2*pi);
            end
            if angle_run < 0 
                angle_run = angle_run + (2*pi);
            end

            dif_head = heading-angle_run;

            if dif_head < 0
                dif_head = abs(dif_head);
                sign = 1;
            else
                sign = -1;
            end

            if dif_head < pi 
                if dif_head < deltaH_max
                    deltaH = dif_head*sign;
                else
                    deltaH = deltaH_max*sign;
                end
            else 
                dif_head = 2*pi - dif_head;
                if dif_head < deltaH_max
                    deltaH = -dif_head*sign;
                else
                    deltaH = -deltaH_max*sign;
                end
            end
            throttle = 1;
        else
            deltaH=0;
            throttle = 0;
        end
    end
else
    deltaH=0;
    throttle = 0;
end





action = '';
