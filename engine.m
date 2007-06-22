function out = engine(player_list_file)

if exist('player_list_file', 'var')
    playerdata = get_playerdata(player_list_file);
else
    playerdata = get_playerdata('player_list.txt');
end

%1 xpos
%2 ypos
%3 health
%4 energy
%5 team
%6 num
%7 name
%8 heading
%9 color
%
% deltaH
% throttle
% action
%
% rifle
% mine
% shotgun
% ping
% suicide

eval('engine_settings');

term = 0;
nplayers = size(playerdata,1);

dplist = []; %dead player list
state = [];
objects = [];

colorlist = [{[1 0 0]} {[0 0 1]} {[0 .5 0]} {[1 0 1]} {[0 0 0]} {[.5 .5 1]} ...
    {[.5 .5 0]} {[.5 .5 1]} {[.5 0 .5]} {[.5 .5 .5]}];

% Build a team list
teams = [];
for i = 1:nplayers
    teams = [teams playerdata(i,2)];
end
teams = unique(teams);

% Select team start areas.
team_zone = [];
for i = 1:length(teams)
    team_zone{i} = [rand*(world(2)-world(1)) rand*(world(4)-world(3))];
end

for i = 1:nplayers
    team = find(~cellfun('isempty', regexp(teams, ['^' playerdata{i,2} '$'])));
    if group_teams
        player{1} = team_zone{team}(1) + ...
            (2 * rand * group_teams_radius) - group_teams_radius;
        player{2} = team_zone{team}(2) + ...
            (2 * rand * group_teams_radius) - group_teams_radius;
    else
        player{1} = rand*(world(2)-world(1));
        player{2} = rand*(world(4)-world(3));        
    end
    player{3} = health_max;
    player{4} = energy_max;
    player{5} = playerdata{i,2};
    player{6} = i;
    player{7} = playerdata{i,1};
    player{8} = rand*2*pi;
    player{9} = colorlist{mod(team - 1, length(colorlist)) + 1};
    state = [state {player}];
end

t = 0;
watch = [];
while ~term
    t = t+1;
    if display_game
        clf;
    end
    dpqueue = [];
    for i = 1:nplayers
        if state{i}{3}>0
            state{i}{4} = state{i}{4} + energy_regen;
            if state{i}{4}>energy_max
                state{i}{4} = energy_max;
            end
            
            ostate = [];
            for j = 1:nplayers
               if state{i}{6} == state{j}{6}
                   pstate = state{j};
               else
                   if state{j}{3} > 0
                       ostate = [ostate state(j)];
                       ostate{end}(player_hide) = {[]};
                   end
               end
                
            end
            
            [deltaH throttle action] = feval(state{i}{7},ostate,pstate,[], []);
            if abs(deltaH)>deltaH_max
                deltaH = deltaH_max*sign(deltaH);
            end
            
            %Change heading
            state{i}{8} = mod(state{i}{8}+deltaH + pi, 2*pi) - pi;
            
            %Add rifle shot
            if strcmp(action,'rifle') && rifle_enable
                if rifle_cost <= state{i}{4}
                rifle = { 'rifle' ; state{i}{1} ; state{i}{2} ; ...
                    state{i}{8} ; state{i}{5} };
                objects = [objects {rifle}];
                state{i}{4} = state{i}{4}-rifle_cost;
                end
            end

            %Add mine
            if strcmp(action,'mine') && mine_enable
                if mine_cost <= state{i}{4}
                    mine = { 'mine' ; state{i}{1} ; state{i}{2} ; ...
                        state{i}{5} ; state{i}{6} ; {[]} ; ...
                        get_player_val(state, state{i}{6}, 9) };
                    objects = [objects {mine}];
                    state{i}{4} = state{i}{4} - mine_cost;
                end
            end

             %Move Player
             if abs(throttle)>1
                throttle = sign(throttle);
             end
            if throttle*move_cost<=state{i}{4}
                state{i}{1} = state{i}{1}+throttle*cos(state{i}{8})*ts;
                state{i}{2} = state{i}{2}+throttle*sin(state{i}{8})*ts;
                state{i}{4} = state{i}{4}-move_cost*throttle;
            end
            
            %Check boundary
            [valid state{i}{1} state{i}{2}] = ...
                checkbounds(state{i}{1},state{i}{2},world);
            
            if (display_game || record_game)
                plot(state{i}{1},state{i}{2},'o','color',state{i}{9});
                line([state{i}{1} state{i}{1} + cos(state{i}{8}) * heading_length], ...
                    [state{i}{2} state{i}{2} + sin(state{i}{8}) * heading_length], ...
                    'Color', state{i}{9});
            end
            
            hold on

        else %if health<=0
            dpqueue = [dpqueue i];
        end %if health
    end %for players

    dplist = [dplist state(dpqueue)];
    state(dpqueue)=[];
    nplayers = length(state);

    % Iterate through object list
    delqueue = [];
    for i = 1:size(objects,2)
        
        % Rifle rounds
        if strcmp(objects{i}{1}, 'rifle')
            objects{i}{2} = objects{i}{2}+cos(objects{i}{4})*rifle_speed*ts;
            objects{i}{3} = objects{i}{3}+sin(objects{i}{4})*rifle_speed*ts;

            for j = 1:nplayers
                hit = 0;
                d = norm([ state{j}{1}-objects{i}{2}  state{j}{2}-objects{i}{3} ]);
                if d <= rifle_radius
                    if (friendly_fire)
                        hit = 1;
                    else
                        if ~strcmp(objects{i}{5}, state{j}{5})
                            hit = 1;
                        end
                    end
                end
                if hit
                    state{j}{3} = state{j}{3} - rifle_damage;
                    if (display_game)
                        plot(state{j}{1},state{j}{2},'r*');
                    end
                    delqueue = [delqueue i];
                end
            end

            valid = checkbounds(objects{i}{2},objects{i}{3},world);
            if ~valid
                delqueue = [delqueue i];
            else
                if display_game
                    plot(objects{i}{2},objects{i}{3},'.')
                end
            end
        end
        
        % Mines
        if strcmp(objects{i}{1}, 'mine')
            for j = 1:nplayers
                hit = 0;
                d = norm([ state{j}{1}-objects{i}{2}  state{j}{2}-objects{i}{3} ]);
                if d <= mine_radius
                    if (friendly_fire)
                        if objects{i}{5} ~= state{j}{6}
                            hit = 1;
                        end
                    else
                        if ~strcmp(objects{i}{4}, state{j}{5})
                            hit = 1;
                        end
                    end
                end
                if hit
                    state{j}{3} = state{j}{3} - mine_damage;
                    if display_game
                        plot(state{j}{1},state{j}{2},'r*')
                    end
                    delqueue = [delqueue i]; 
                end
            end
            
            if display_game
                plot(objects{i}{2}, objects{i}{3}, '+', ...
                    'Color', objects{i}{7});
            end
        end
    end

    objects(delqueue) = [];

    axis equal
    axis(world)
    
    if (record_game)
        watch = [watch getframe];
    else
        if (display_game)
            watch = getframe;
        end
    end

    check_teams = [];
    for i = 1:nplayers
        check_teams = [check_teams state{i}(5)];
    end
    check_teams = unique(check_teams);
    if length(check_teams) == 1
        % Only one team left.
        term = 1;
        out = check_teams{1};
    end

end

% Ask each bot to clean up.
dplist = [dplist state];
for i = 1:length(dplist)
    for j = 1:length(dplist)
       warning off
        if dplist{i}{6} == dplist{j}{6}
            pstate = dplist{j};
        end
        warning on
    end
    try
        feval(dplist{i}{7},[],pstate,[],'clean');
    catch
    end
end

if (record_game)
    save gamemovie watch
    disp ('Saved movie to "gamemovie.mat".')
end

if ~exist('out', 'var')
    out = '';
end

end %while

function [valid xnew ynew] = checkbounds(x,y,world)
xnew = x;
ynew = y;
valid = 1;
if x<world(1)
    xnew = world(1);
    valid = 0;
end
if x>world(2)
    xnew = world(2);
    valid = 0;
end

if y<world(3)
    ynew = world(3);
    valid = 0;
end
if y>world(4)
    ynew = world(4);
    valid = 0;
end

end

% Load player list from file
function playerdata = get_playerdata(file)

fid = fopen(file, 'r');
plist = textscan(fid, '%s %s');

playerdata = [];
for i = 1:length(plist{1})
    playerdata = [playerdata; plist{1}(i) plist{2}(i)];
end

end

% Get a player's value
function out = get_player_val(state, player, pval)
out = [];
for i = 1:length(state)
    if state{i}{6} == player
        out = state{i}{pval};
    end
end

end
