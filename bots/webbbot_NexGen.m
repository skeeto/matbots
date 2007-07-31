function [deltaH throttle action] = webbbot(state, player, objects, req)

engine_settings

% load my info
xpos = player{1};
ypos = player{2};
health = player{3};
energy = player{4};
team = player{5};
num = player{6};
name = player{7};
heading = player{8};
my_color = player{9};



sz_obj = size(objects);
how_many_obj = sz_obj(1,2);

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


%% IS THIS THE FIRST RUN????
if strcmp(req,'preclean')
            superduper = num2str(floor(rand*10000));
            game_step = 0;  
            filename = ['power',superduper,'.mat'];
            save(['goteam',team,'.mat'],'superduper','game_step')
elseif strcmp(req,'selfplot')
    deltaH  = 0;
    throttle = 0;
    action = req;
            
elseif how_many_we == how_many_total && isempty(req)
        disp(['WEBB RULES'])
        throttle = 0;
        deltaH = deltaH_max;
        action = '';
        plot_me(my_color,'',player,'big','')
        if how_many_we == 1 || state{who_we(1)}{6} > num
            [y,Fs,bits] = wavread('my_sounds.wav');
            hell_be_engr = y(220000:240000);
            worse_than_feared = y(1:19000);
            sound([worse_than_feared;hell_be_engr],Fs)
        end
elseif strcmp(req,'clean')
        if exist(['goteam',team,'.mat'],'file')
            load(['goteam',team,'.mat'])
            filename = ['power',superduper,'.mat'];
            delete(filename)
            delete(['goteam',team,'.mat'])
        end
        
else
    
%% AM I FIRST???  ALONE???

    if how_many_we == 1 || state{who_we(1)}{6} > num
        leader = num;
        %time to think
        
%% NOT FIRST STEP, SO SETUP STUFF
    load(['goteam',team,'.mat'])
    filename = ['power',superduper,'.mat'];
    game_step = game_step+1;
    save(['goteam',team,'.mat'],'superduper','game_step')
    if exist(filename,'file')
        load(filename);
    end
    if ~exist('our_shots_in_air','var')
        our_shots_in_air = [];
    else
        if ~isempty(our_shots_in_air)
            our_shots_in_air(:,2) = our_shots_in_air(:,2) - ts;
            our_shots_in_air(find(our_shots_in_air(:,2) < 0),:) = []; %our shots in the air is now up to date
            out_shots_in_air = sortrows(our_shots_in_air);
        end
    end

    if how_many_we ~= 1
        if game_step < 10
            eplot('text',xpos,ypos+.5*health/25,['READY ???'])
        elseif game_step > 15 && game_step <= 20
            eplot('text',xpos,ypos+.5*health/25,'LET''S DO THIS !!!!!')
        end

        if game_step == 1;
            things2say = [{'OH YEAH!!!'};...
                          {'I''M IN!!!'};...
                          {'REPORTING FOR DUTY!'};...
                          {'WHAT?!?'};...
                          {'SIR, YES, SIR!!'};...
                          {'O''DOYALE RULES!!!'};...
                          {'LET ME AT ''EM!'};...
                          {'MEEP MEEP'};...
                          {'GO TEAM!!!'}];

          for i = 1:how_many_we-1
              team_says{i,1} = state{who_we(i)}{6};
              team_says{i,2} = things2say{ceil(rand*length(things2say))};
              team_says{i,3} = ceil(rand*5);
          end
        end
    else
        team_says = [];
    end
    clear targeting_nums
    
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
        
%% FIND TARGET DISTANCES
    done_targeting = 0;
   
    clear dist
    count = 0;
    if riflers == 0 % develops list of all enemies and their distances and how many shots to kill them
        for i = 1:how_many_total-1
            if ~strcmp(state{i}{5},team)
                count = count + 1;
                dist_list(count,1) = norm([state{i}{1}-X_WE,state{i}{2}-Y_WE]); %distance
                dist_list(count,2) = state{i}{6}; %num
%           disp(['target is num ',num2str(state{i}{6}),' they are not shooting yet'])
                target_health = state{i}{3};
                if ~isempty(our_shots_in_air)
                    shots_to_hit_target = length(find(our_shots_in_air(:,1) == state{i}{6}));
                    if ~isempty(shots_to_hit_target)
                        how_many_shots_required = ceil(target_health/rifle_damage) - shots_to_hit_target;
                    else
                        how_many_shots_required = ceil(target_health/rifle_damage);
                    end
                 else
                     how_many_shots_required = ceil(target_health/rifle_damage);
                end
                dist_list(count,3) = how_many_shots_required; 
            end
        end
    else % find the nearest big threat team and blow chunks
        for i = 1:how_many_total-1
            if strcmp(state{i}{5},who_acts_most)
                count = count + 1;
                dist_list(count,1) = norm([state{i}{1}-X_WE,state{i}{2}-Y_WE]); %distance
                dist_list(count,2) = state{i}{6}; %num
%           disp(['target is num ',num2str(state{i}{6})])
                target_health = state{i}{3};
                if ~isempty(our_shots_in_air)
                    shots_to_hit_target = length(find(our_shots_in_air(:,1) == state{i}{6}));
                    if ~isempty(shots_to_hit_target)
                        how_many_shots_required = ceil(target_health/rifle_damage)+1 - shots_to_hit_target;
                    else
                        how_many_shots_required = ceil(target_health/rifle_damage)+1;
                    end
                 else
                     how_many_shots_required = ceil(target_health/rifle_damage)+1;
                end
                dist_list(count,3) = how_many_shots_required; 
            end
        end
    end
    
    dist_list(find(dist_list(:,3) <= 0),:) = []; % now how_many_shots_req will never be neg or 0
    dist_list = sortrows(dist_list);
    [list_length,fd] = size(dist_list);

%% MAKE LIST OF TEAMMATES
    targeting_nums(1,1) = num;
    targeting_nums(1,3) = energy;
    count = 2;
   
    for i = 1:how_many_we - 1
        targeting_nums(count,1) = state{who_we(i)}{6};
        targeting_nums(count,3) = state{who_we(i)}{4};
        count = count+1;
    end
        
%% SORT TEAMMATE LIST BY ENERGY
%     targeting_nums_rev = sortrows(targeting_nums,3);
%     for i = 1:how_many_we
%         targeting_nums(i,:) = targeting_nums_rev(how_many_we-i+1,:);
%     end
    who_weak_we = find(targeting_nums(:,3) < 40);
    targeting_weak = targeting_nums(who_weak_we,:);
    targeting_nums(who_weak_we,:) = [];
    targeting_nums = [targeting_nums;targeting_weak];
    


%% MAKE TARGETING LIST    
    if ~isempty(dist_list)
        i = 1;
        team_assigned = 1;
        while i <= list_length && team_assigned <= how_many_we
            for n = 1:dist_list(i,3) % 1 to total shots required to kill it
                targeting_nums(team_assigned,2) = dist_list(i,2);
                if n == dist_list(i,3)
                    targeting_nums(team_assigned,4) = 1;
                else
                    targeting_nums(team_assigned,4) = 0;
                end
                team_assigned = team_assigned+1 ;
            end
            i = i+1;
        end
    else
        targeting_nums(:,2) = 0;
    end
    

%% WRITE TO MAT FILE
           % if I want to write something this would be a good time
           save(filename,'targeting_nums','where_they_at','our_shots_in_air','leader','team_says')

%% I AM NOT ALONE AND AM NOT FIRST
    else 
        % no thought
        % just act
    end

            [deltaH throttle action] = dodgeball(how_many_total,state,objects,player);
end


%% SHOOT 'EM
function [deltaH throttle action] = act_now(how_many_total,state,objects,player)
engine_settings

xpos = player{1};
ypos = player{2};
health = player{3};
energy = player{4};
team = player{5};
num = player{6};
name = player{7};
heading = player{8};
my_color = player{9};
load(['goteam',team,'.mat'])
filename = ['power',superduper,'.mat'];
load(filename)

arm = '';


%% FIND TARGET
% find target out of state

% disp(['target number from action is ',num2str(target_num)])
my_target_num = targeting_nums(find(targeting_nums(:,1)==num),2);
if my_target_num == 0
%     disp(['no target for number ', num2str(num)])
    action = '';
    throttle = 0;
    deltaH = 0;
    words = '';
else
    for i = 1:how_many_total-1
        if state{i}{6} == my_target_num
           who_target = i;
        end
    end

    where_num = find(where_they_at(:,1,game_step)==my_target_num);

%% IS TARGET MOVING???

    if game_step == 1
        targeting = 'stationary';
        x_t_n = where_they_at(where_num,2,game_step);
        y_t_n = where_they_at(where_num,3,game_step);
        
    else%if game_step == 2
        where_they_at(where_num,:,game_step-1:game_step);

        x_t_n = where_they_at(where_num,2,game_step);
        x_t_nm1 = where_they_at(where_num,2,game_step-1);
        y_t_n = where_they_at(where_num,3,game_step);
        y_t_nm1 = where_they_at(where_num,3,game_step-1);

        xd_t = (x_t_n-x_t_nm1)/ts;
        yd_t = (y_t_n-y_t_nm1)/ts;
        targeting = 'moving';
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

%         [angle_target] = desnitcher(targeting_nums,my_target_num,dist_target_goes_perp)
        angle_target = angle_target + atan2(dist_target_goes_perp,dist);
    end

%% SHOOT STATIONARY TARGET
    if strcmp(targeting,'stationary')
        xdif_target = state{who_target}{1} - xpos;
        ydif_target = state{who_target}{2} - ypos;
        angle_target = atan2(ydif_target,xdif_target);
        dist = norm([xdif_target,ydif_target]);
        t_hit = dist/rifle_speed;
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
    words = '';
    if int_check3 < 4
            % CrossHairs
            x = -1:.01:1;
            y1 = sqrt(1-x.^2);
            y2 = -y1;
            x3 = [0,0,0];
            y3 = [0,1,-1];
            X = .5*[x,x,x3]+x_t_n;
            Y = .5*[y1,y2,y3]+y_t_n;
            eplot(X,Y,'color',my_color)
        if isempty(dif_head)
           angle_target
           ydif_target
           state{who_target}
        end
        if abs(dif_head) < .1 && energy > 2*move_cost
            action = 'rifle';
            throttle = 0;
            % save bullet information
            [total_my_shots,two] = size(our_shots_in_air);
            our_shots_in_air(total_my_shots+1,1) = my_target_num;
            our_shots_in_air(total_my_shots+1,2) = t_hit;
            save(filename,'targeting_nums','where_they_at','our_shots_in_air','leader','team_says')
            my_color = 'r';
            arm = 'shoot';
        else 
            action = '';
            throttle = 0;
        end
    else
            action = '';
            throttle = 0;
    end
end
plot_me(my_color,words,player,'',arm)

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
my_color = player{9};
load(['goteam',team,'.mat'])
filename = ['power',superduper,'.mat'];
load(filename)

[n,how_many_obj] = size(objects);

if num ~= leader && game_step < 20
    sz = size(team_says);
    for i = 1:sz(1,1)
        if team_says{i,1} == num
            my_says_num = i;
        end
    end
    time_num = team_says{my_says_num,3};
    
    if game_step > time_num+3 && game_step < time_num+8     
        eplot('text',xpos,ypos+.5*health/25,team_says{my_says_num,2})
    end
elseif num ~= leader && game_step > 18 && game_step < 25
    eplot('text',xpos,ypos+.5*health/25,['KILL ''EM!!!!!!'])
end

%% FIND THREATS

sec_search = .55;
search_rad = rifle_speed*sec_search; %this is the radius to find all things within sec_search seconds from me

count = 1;
if ~isempty(objects)
    for i = 1:how_many_obj
        if strcmp(objects{i}{1},'rifle') && ~strcmp(objects{i}{5},team)
            if norm([objects{i}{2}-xpos,objects{i}{3}-ypos]) < search_rad %only put in imiediate threats
                bullets(count,1) = objects{i}{2}; % x pos
                bullets(count,2) = objects{i}{3}; % y pos
                bullets(count,3) = objects{i}{4}; %heading
                count = count+1;
            end
        end
    end
end
how_many_threats = count-1;

%% IS IT REALLY A THREAT???

if exist('bullets','var')
   % am I safe??
   [how_safe_here,min_dist] = safety_check(bullets,how_many_threats,xpos,ypos);
   if how_safe_here == 0
        % I am safe
        % this would be a good spot to search and destroy
%         disp('I am safe and don''t need to move, I will kill')
        [deltaH throttle action] = act_now(how_many_total,state,objects,player);
   else % it is unsafe here, I should probably move
       count = 1;
       for dH = -deltaH_max:deltaH_max/8:deltaH_max
           new_xpos = xpos + 1*ts*cos(heading+dH);
           new_ypos = ypos + 1*ts*sin(heading+dH);
           if in_world(new_xpos,new_ypos) == 1
               how_safe_there(count,1) = dH;
               [how_safe_there(count,2),how_safe_there(count,3)] = safety_check(bullets,how_many_threats,new_xpos,new_ypos);
               count = count + 1;
           end
       end
       [how_dangerous,where_safe] = min(how_safe_there(:,2));
       
       if how_dangerous == 0
           just_as_dangerous = find(how_safe_there(:,2) == how_dangerous);
           safest_bets = how_safe_there(just_as_dangerous,:);
           [least_dangerous,where_least_danger] = max(safest_bets(:,3));
%            disp('I will run to safest place')
           deltaH = safest_bets(where_least_danger,1);
           throttle = 1;
           action = '';
       else
           count = 1;
           for dH = -deltaH_max:deltaH_max/8:deltaH_max
               new_xpos = xpos - 1*ts*cos(heading+dH);
               new_ypos = ypos - 1*ts*sin(heading+dH);
               if in_world(new_xpos,new_ypos) == 1
                   how_safe_thereM(count,1) = dH;
                   [how_safe_thereM(count,2),how_safe_thereM(count,3)] = safety_check(bullets,how_many_threats,new_xpos,new_ypos);
                   count = count + 1;
               else
                   how_safe_thereM(count,1) = dH;
                   how_safe_thereM(count,2) = 12342352;
                   how_safe_thereM(count,3) = .000001;
                   count = count + 1;
               end
           end
           [how_dangerousM,where_safeM] = min(how_safe_thereM(:,2));
           if how_dangerousM == 0
               just_as_dangerousM = find(how_safe_thereM(:,2) == how_dangerousM);
               safest_betsM = how_safe_thereM(just_as_dangerousM,:);
               [least_dangerousM,where_least_dangerM] = max(safest_betsM(:,3));
    %            disp('I will run to safest place')
               deltaH = safest_betsM(where_least_dangerM,1);
               throttle = -1;
               action = '';
           else
               %check your 6
               count = 1;
               for dH = deltaH_max:deltaH_max/8:2*deltaH_max
                   for sign = [1,-1]
                       new_xpos = xpos + sign*ts*cos(heading+dH);
                       new_ypos = ypos + sign*ts*sin(heading+dH);
                       if in_world(new_xpos,new_ypos) == 1
                           how_safe_thereP(count,1) = dH;
                           [how_safe_thereP(count,2),how_safe_thereP(count,3)] = safety_check(bullets,how_many_threats,new_xpos,new_ypos);
                           how_safe_thereP(count,4) = sign;
                           count = count + 1;  
                       end
                   end
               end
    %    how_safe_thereP
               [how_dangerousP,where_safeP] = min(how_safe_thereP(:,2));
               if how_dangerousP == 0
                   deltaH = deltaH_max;
                   throttle = 0;
                   action = '';
               else
                   count = 1;
                   for dH = -2*deltaH_max:deltaH_max/8:-deltaH_max
                       for sign = [1,-1]
                           new_xpos = xpos + sign*ts*cos(heading+dH);
                           new_ypos = ypos + sign*ts*sin(heading+dH);
                           if in_world(new_xpos,new_ypos) == 1
                               how_safe_thereN(count,1) = dH;
                               [how_safe_thereN(count,2),how_safe_thereN(count,3)] = safety_check(bullets,how_many_threats,new_xpos,new_ypos);
                               how_safe_thereN(count,4) = sign;
                               count = count + 1;
                           else
                               how_safe_thereN(count,1) = dH;
                               how_safe_thereN(count,2) = 45456453453;
                               how_safe_thereN(count,3) = .00001;
                               how_safe_thereN(count,4) = sign;
                               count = count + 1;
                           end
                       end
                   end
    %       how_safe_thereN
                   [how_dangerousN,where_safeN] = min(how_safe_thereN(:,2));
                   if how_dangerousN == 0
                       deltaH = -deltaH_max;
                       throttle = 0;
                       action = '';
                   else
                       %look all the way around
                       %this is now two time steps out at least
                       count = 1;
                       for dH = 2*deltaH_max:deltaH_max/8:pi
                           for sign = [1,-1]
                               new_xpos = xpos + sign*ts*cos(heading+dH);
                               new_ypos = ypos + sign*ts*sin(heading+dH);
                               if in_world(new_xpos,new_ypos) == 1
                                   how_safe_there2P(count,1) = dH;
                                   [how_safe_there2P(count,2),how_safe_there2P(count,3)] = safety_check(bullets,how_many_threats,new_xpos,new_ypos);
                                   how_safe_there2P(count,4) = sign;
                                   count = count + 1;
                               end
                           end
                       end
    %             how_safe_there2P
                       [how_dangerous2P,where_safe2P] = min(how_safe_there2P(:,2));
                       if how_dangerous2P == 0
                           deltaH = deltaH_max;
                           throttle = 0;
                           action = '';
                       else
                           count = 1;
                           for dH = -pi:deltaH_max/8:-2*deltaH_max
                               for sign = [1,-1]
                                   new_xpos = xpos + sign*ts*cos(heading+dH);
                                   new_ypos = ypos + sign*ts*sin(heading+dH);
                                   if in_world(new_xpos,new_ypos) == 1
                                       how_safe_there2N(count,1) = dH;
                                       [how_safe_there2N(count,2),how_safe_there2N(count,3)] = safety_check(bullets,how_many_threats,new_xpos,new_ypos);
                                       how_safe_there2N(count,4) = sign;
                                       count = count + 1;
                                   end
                               end
                           end
    %              how_safe_there2N
                           [how_dangerous2N,where_safe2N] = min(how_safe_there2N(:,2));
                           if how_dangerous2N == 0
                               deltaH = -deltaH_max;
                               throttle = 0;
                               action = '';
                           else
                               %there is nowhere around me that is safe, I will
                               %have to move fowards or backwards just to find a safer place
                               how_safe_there(:,4) = 1;
                               how_safe_thereM(:,4) = -1;
                               how_safe_thereT = [how_safe_there;how_safe_thereM];
                               [how_dangerousT,where_safeT] = min(how_safe_thereT(:,2));
                               just_as_dangerousT = find(how_safe_thereT(:,2) == how_dangerousT);
                               safest_betsT = how_safe_thereT(just_as_dangerousT,:);
                               [least_dangerousT,where_least_dangerT] = max(safest_betsT(:,3));
                    %            disp('I will run to safest place')
                               deltaH = safest_betsT(where_least_dangerT,1);
                               throttle = safest_betsT(where_least_dangerT,4);
                               action = '';
%                                pause
                           end
                       end
                   end
               end
           end
       end
       plot_me(my_color,'',player,'','')
       if ~exist('deltaH','var')
           deltaH = 0;
           disp('no DeltaH - not safe')
       end
   end
%    pause
%     deltaH
%     throttle

%% I AM SAFE, CALL KILL, MAKE MY DAY OR REGENERATE
else % no bullets in the air that aren't mine
    % is there anyone close to me??? 
    count = 1;
    for i = 1:how_many_total-1
        if ~strcmp(state{i}{5},team)
            enemies(count,1) = i;
            enemies(count,2) = norm([state{i}{1}-xpos,state{i}{2}-ypos]); %dist from me
            enemies(count,3) = state{i}{1}-xpos;
            enemies(count,4) = state{i}{2}-ypos;
            count = count + 1;
        end
    end

    [who_close,d] = find(enemies(:,2)< 1.75*mine_radius);

    if ~isempty(who_close)
        [deltaH throttle action] = make_my_day(who_close,enemies,heading);
        plot_me(my_color,'rrrrr',player,'','')
    elseif health <= 3*rifle_damage
        deltaH = 0;
        throttle = 0;
        action = ['HtoE-',num2str(energy/2)];
        plot_me('w','',player,'','')
    else
        [deltaH throttle action] = act_now(how_many_total,state,objects,player);
    end

end

%% HOW UNSAFE IS THAT SPOT
function [how_unsafe,min_dist] = safety_check(bullets,how_many_threats,xpos,ypos)
engine_settings
how_unsafe = 0;
dist = norm([bullets(1,1)-xpos,bullets(1,2)-ypos]);
min_dist = dist;
for i = 1:how_many_threats
    dist_nm1 = 5e23;
    dist_nm2 = 5e23;
    x_bullet = bullets(i,1);
    y_bullet = bullets(i,2);
    bullet_heading = bullets(i,3);
    while dist < dist_nm2
       dist = norm([x_bullet-xpos,y_bullet-ypos]);
       if dist <= rifle_radius
           % its gonna hit me
           how_unsafe = how_unsafe + 1;
           if dist < min_dist
               min_dist = dist;
           end
       end
       dist_nm2 = dist_nm1;
       dist_nm1 = dist;
       x_bullet = x_bullet + ts*rifle_speed*cos(bullet_heading);
       y_bullet = y_bullet + ts*rifle_speed*sin(bullet_heading);
    end
end

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

%% MAKE MY DAY
function [deltaH throttle action] = make_my_day(who_close, enemies,heading)
engine_settings

run_from_who = enemies(who_close(1),1);
run_from_x = enemies(who_close(1),3);
run_from_y = enemies(who_close(1),4);

angle_target = atan2(run_from_y,run_from_x);

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

if dif_head < .2
    throttle = -1;
    action = 'mine';
    deltaH = deltaH+ .1;
else
    throttle = 0;
    action = '';
end

%% PLOT
function plot_me(my_color,words,player,size,arm)
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


if ~strcmp(size,'big')
    scale = health/50;
    % little dude
    
    a = -pi/2:.1:3*pi/2;
    x1 = .25*cos(a);
    y1 = .25*sin(a)+.75;
    x2 = [0,0];
    y2 = [.5,-.1];
    x4 = [-.25,0,.25];
    y4 = [-1,-.1,-1];

    X = [x1,x2,x4]*scale + xpos;
    Y = [y1,y2,y4]*scale + ypos;

    eplot(X,Y,'color',my_color)

    x_e = .05*cos(a);
    y_e = .05*sin(a);
    eplot('fill',(x_e-.10)*scale + xpos,(y_e+.85)*scale + ypos,my_color)
    eplot('fill',(x_e+.10)*scale + xpos,(y_e+.85)*scale + ypos,my_color)

    a1 = -5*pi/6:.1:-pi/6;
    x_s = (.1*cos(a1))*scale + xpos;
    y_s = (.1*sin(a1)+.70)*scale + ypos;
    eplot((x_s),(y_s),'color',my_color)

    an = 0:.1:pi;
    x_n = (.03*cos(an))*scale + xpos;
    y_n = (.04*sin(an)+.725)*scale + ypos;
    eplot(x_n,y_n,'color',my_color)

    if strcmp(arm,'shoot')
        x_a1 = [0,.1, .4, .1];
        y_a1 = [0, -.3, -.3,-.3];
        x_a2 = [0,.08,.35];
        y_a2 = [0,-.35,-.35];
        X_a = [x_a1,x_a2];
        Y_a = [y_a1,y_a2];
        
        sign = 1;
        if heading > pi
            heading = heading-2*pi;
        end
        if heading < -pi
            heading = headin +2*pi;
        end
        if heading > pi/2 || heading < -pi/2
            sign = -1;
            heading = -(heading-pi);
        end
    
        rotate = [ cos(heading) -sin(heading) ; ...
                   sin(heading)  cos(heading) ];
        look = rotate*[X_a;Y_a];

        look(1,:) = scale*sign*look(1,:) + xpos;
        look(2,:) = scale*(look(2,:) + .4) + ypos;

        eplot(look(1,:),look(2,:),'color',my_color)

        x_gun = [.25,.36,.7,.75,.40,.35,.25];
        y_gun = [-.36,-.21,-.21,-.29,-.29,-.325,-.36];
        
        gun = rotate*([x_gun;y_gun]);
        gun(1,:) = scale*(sign*gun(1,:)) + xpos;
        gun(2,:) = scale*(gun(2,:) + .4) + ypos;

        eplot('fill',gun(1,:),gun(2,:),'r')
    else
        x = [0,-.25,0,.25,0,0]*scale + xpos;
        y = [.4,.25,0,.25,.4,-.1]*scale + ypos;
        eplot(x,y,'color',my_color)
    end
        
    eplot('text',xpos+.25,ypos+.25,words)
    
    
else
    scalex = (world(2)-world(1))/(2*.75*.25);
    scaley = (world(4)-world(3))/(2*.75*.25);
    xpos = (world(1)+world(2))/2;
    ypos = (world(3)+world(4))/2;
    heading = pi/2;
    line = 15;
    % my aw thing
    xpic = scalex*0.75*[-.25 -.125  0 .0625 -.0625 .0625 .125 .25];
    ypic = scaley*0.75*[ .20 -.25 .25 0     0      0   -.25  .20];
    
    rotate = [ cos(heading-pi/2) -sin(heading-pi/2) ; ...
               sin(heading-pi/2)  cos(heading-pi/2) ];
    look = rotate*[xpic;ypic];
    
    look(1,:) = look(1,:) + xpos;
    look(2,:) = look(2,:) + ypos;
 
    eplot(look(1,:),look(2,:),'color',my_color,'linewidth',line)
    
    
    eplot('text',xpos+.25,ypos+.25,words)
end







