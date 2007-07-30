function [deltaH throttle action] = hit_this(state, player, objects, req)

engine_settings

if ~isempty(req)
%     if strcmp(req,'selfplot')
%     deltaH  = 0;
%     throttle = 0;
%     action = req;
%     end
    if strcmp(req,'preclean')
        game_step = 0;
        history = 0;
        run = 0;
        around = 0;
        save('hit_this','game_step','history','run','around')
    elseif strcmp(req,'clean')
        delete('hit_this.mat')
        deltaH  = 0;
        throttle = 0;
        action = '';
    end
    
else
    load('hit_this')
    game_step = game_step+1;
    
%% load my info
    xpos = player{1};
    ypos = player{2};
    health = player{3};
    energy = player{4};
    team = player{5};
    num = player{6};
    name = player{7};
    heading = player{8};

%     deltaH  = 2*deltaH_max*rand-deltaH_max;
    deltaH = 0;
    throttle = 1;
    action = '';

    [d,sz]= size(state);
    how_many_total = sz +1;
%% MAKE HISTORY
    for i = 1:sz
        count = state{i}{6};
        history(game_step,1,count) = state{i}{1}; %xpos of bot
        history(game_step,2,count) = state{i}{2}; %ypos of bot
    end
    count = num;
    history(game_step,1,count) = player{1}; %xpos of me
    history(game_step,2,count) = player{2}; %ypos of me

    count = 1;
    for i = 1:how_many_total-1
        if ~strcmp(state{i}{5},team)
            enemies(count,1) = i;
            enemies(count,2) = norm([state{i}{1}-xpos,state{i}{2}-ypos]); %dist from me
            count = count + 1;
        end
    end
%% SAVE STUFF
    save('hit_this','game_step','history','run','around')

%% ENEMY LIST
    count = 1;
    for i = 1:how_many_total-1
        if ~strcmp(team,state{i}{5})
            enemies(count,1) = state{i}{6}; % number
            enemies(count,2) = state{i}{1}; % xpos
            enemies(count,3) = state{i}{2}; % ypos
            enemies(count,4) = norm([state{i}{1}-xpos,state{i}{2}-ypos]); %dist from me
            count = count + 1;
        end
    end
    
%%  TEXT
    place = mod(game_step,30);
    if place < 10
        eplot('text',xpos,ypos+.5,'Go ahead...')
    elseif place < 20
        eplot('text',xpos,ypos+.5,'hit me!!!')
    end  
%% DO STUFF    
    if count == 2 % there is only one bad guy
        my_speed = 1;
        if enemies(1,4)*my_speed/rifle_speed > 2*rifle_radius
            run = 0;
            around = 0;
        end
        
        if enemies(1,4)*my_speed/rifle_speed > 1.1*rifle_radius && run == 0     
            N = floor((enemies(1,4)/(rifle_speed) - 1*rifle_radius/my_speed)/ts)+ 5;
            if mod(game_step,N) >= N/2
                sign = 1;  
                if energy+health >= 180
                    offset = 2*pi/6;
                else
                    offset = pi/2;
                end
            else
                sign = -1;  
                if energy+health >= 185
                    offset = 4*pi/6;
                else
                    offset = pi/2;
                end
            end
            throttle = sign*my_speed;
            angle_target = point2shoot(enemies(1,1),num);
            deltaH = turn(angle_target+offset,heading);
            if health < 100 && energy > 20
                action = 'HtoE-5';
            end
        else
            run = 1;
            angle_target = point2shoot(enemies(1,1),num);
            deltaH = turn(angle_target,heading);
            throttle = -1;
            if mod(game_step,3) >= 1
                if deltaH <.1
                    action = 'rifle';
                else
                    action = '';
                end
            elseif enemies < 2*mine_radius
                action = 'mine';
            else
                action = 'rifle';
            end
                
        end
        save('hit_this','game_step','history','run','around')

    else
        throttle = 0;
        deltaH = 0;
        action = '';
    end
























end


%% turn
function [deltaH] = turn(angle_target,heading)
% By inputing the angle to the target this will output the angle needed to
% turn.
engine_settings;
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

%% point2shoot
function [angle_target] = point2shoot(target_num,num)
load('hit_this')
engine_settings;

xpos = history(game_step,1,num);
ypos = history(game_step,2,num);

x_t_n = history(game_step,1,target_num);
y_t_n = history(game_step,2,target_num);

if game_step == 1
    x_t_nm1 = history(game_step,1,target_num);
    y_t_nm1 = history(game_step,2,target_num);
else
    x_t_nm1 = history(game_step-1,1,target_num);
    y_t_nm1 = history(game_step-1,2,target_num);
end
N = 10;
if game_step < N+1
    xd_t = (x_t_n-x_t_nm1)/ts;
    yd_t = (y_t_n-y_t_nm1)/ts;
else 
    x_t_nm5 = history(game_step-N,1,target_num);
    y_t_nm5 = history(game_step-N,2,target_num);
    
    xd_t = (x_t_n-x_t_nm5)/(N*ts);
    yd_t = (y_t_n-y_t_nm5)/(N*ts);
end
    

xdif_target = x_t_n - xpos;
ydif_target = y_t_n - ypos;
angle_target = atan2(ydif_target,xdif_target);

targets_heading = atan2(yd_t,xd_t);
targets_speed = norm([xd_t,yd_t]);
dist = norm([xdif_target,ydif_target]);
t_hit = dist/rifle_speed;
relative_angle = pi+angle_target-targets_heading;

dist_target_goes_perp = sin(relative_angle)*targets_speed*t_hit;

angle_target = angle_target + atan2(dist_target_goes_perp,dist);

%% AM I INBOUNDS???
function [inbounds] = in_world(x,y)
% this will tell me if I will be in the world or not.

engine_settings

inbounds = 1;
if x < world(1)
    inbounds = 0;
elseif x > world(2)
    inbounds = 0;
elseif y < world(3)
    inbounds = 0;
elseif y > world(4)
    inbounds = 0;
end