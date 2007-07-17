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

engine_settings;

eplot('init');

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
arc_d = 2*pi / length(teams);
world_center = [world(2) - world(1) world(4) - world(3)] / 2;
arc_rad = min(world_center - [world(1) world(3)]) - group_teams_radius;
for i = 1:length(teams)
    team_zone{i} = [ ...
        world_center(1) + cos(arc_d * i - pi/4)*arc_rad ...
        world_center(2) + sin(arc_d * i - pi/4)*arc_rad];
end
team_zone = team_zone(randperm(length(team_zone)));

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

% Have each bot prepare its files.
for i = 1:length(state)
    for j = 1:length(state)
        if state{i}{6} == state{j}{6}
            pstate = state{j};
        end
    end
    try
        feval(state{i}{7},[],pstate,[],'preclean');
    catch
    end
end

t = 0;
while ~term
    t = t+1;
    eplot('clearframe'); % Clear the frame
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

            [deltaH throttle action] = feval(state{i}{7},ostate,pstate,objects, []);
            deltaH = mod(deltaH + pi, 2*pi) - pi;
            if abs(deltaH)>deltaH_max
                deltaH = deltaH_max*sign(deltaH);
            end

            %Change heading
            state{i}{8} = mod(state{i}{8}+deltaH + pi, 2*pi) - pi;

            %Add rifle shot
            if strcmp(action,'rifle') && rifle_enable
                if rifle_cost <= state{i}{4}
                    rifle = { 'rifle' ; state{i}{1} ; state{i}{2} ; ...
                        state{i}{8} ; state{i}{5} ; state{i}{6} ; ...
                        state{i}{9} };
                    objects = [objects {rifle}];
                    state{i}{4} = state{i}{4}-rifle_cost;
                end
                %Add mine
            elseif strcmp(action,'mine') && mine_enable
                if mine_cost <= state{i}{4}
                    mine = { 'mine' ; state{i}{1} ; state{i}{2} ; ...
                        state{i}{5} ; state{i}{6} ; {[]} ; ...
                        get_player_val(state, state{i}{6}, 9) };
                    objects = [objects {mine}];
                    state{i}{4} = state{i}{4} - mine_cost;
                end
                % Health to Energy
            elseif ~isempty(regexp(action, '^HtoE')) && HtoE_enable
                amt = str2num(action(5:end));
                if amt > 0
                    hamt = min([ ...
                        amt ...
                        state{i}{3} ...
                        (energy_max-state{i}{4})*health_energy_ratio]);
                    eamt = -hamt * 1/health_energy_ratio;
                else
                    eamt = min([ ...
                        -amt/health_energy_ratio ...
                        state{i}{4} ...
                        (health_max-state{i}{3})/health_energy_ratio]);
                    hamt = -eamt*health_energy_ratio;
                end
                state{i}{3} = state{i}{3} - hamt;
                state{i}{4} = state{i}{4} - eamt;
                eplot(state{i}{1}, state{i}{2}, 'x', 'Color', [0 1 0]);
                % self-destruct
            elseif strcmp(action, 'destruct') && destruct_enable
                if destruct_cost <= state{i}{4}
                    destruct = { 'destruct' ; state{i}{1} ; state{i}{2} ; ...
                        state{i}{5} ; state{i}{6} ; destruct_time ; ...
                        get_player_val(state, state{i}{6}, 9) };
                    objects = [objects {destruct}];
                    state{i}{4} = state{i}{4} - destruct_cost;
                    state{i}{3} = 0;
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

            eplot(state{i}{1},state{i}{2},'o','color',state{i}{9});
            eplot([state{i}{1} state{i}{1} + cos(state{i}{8}) * heading_length], ...
                [state{i}{2} state{i}{2} + sin(state{i}{8}) * heading_length], ...
                'Color', state{i}{9});
            
            if display_health
                f = bar_stack_offset * display_energy;
                eplot([state{i}{1}-0.5*bar_length ...
                    state{i}{1}+(state{i}{3}/health_max - 0.5)*bar_length], ...
                    [state{i}{2}+bar_offset+f state{i}{2}+bar_offset+f],...
                    'Color', [1 0 0]);
            end
            if display_energy
                eplot([state{i}{1}-0.5*bar_length ...
                    state{i}{1}+(state{i}{4}/energy_max - 0.5)*bar_length], ...
                    [state{i}{2}+bar_offset state{i}{2}+bar_offset],...
                    'Color', [0 0 1]);
            end

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
                    eplot(state{j}{1} ,state{j}{2}, 'r*');
                    delqueue = [delqueue i];
                end
            end

            valid = checkbounds(objects{i}{2},objects{i}{3},world);
            if ~valid
                delqueue = [delqueue i];
            else
                eplot(objects{i}{2}, objects{i}{3}, '.', ...
                    'Color', objects{i}{7})
            end
        end

        % Mines
        if strcmp(objects{i}{1}, 'mine')
            eplot(objects{i}{2}, objects{i}{3}, '+', 'Color', objects{i}{7});
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
                    eplot(state{j}{1},state{j}{2},'r*')
                    delqueue = [delqueue i];
                    explosion = { 'explosion' ; objects{i}{2} ; objects{i}{3} ; ...
                        mine_radius ; objects{i}{7} ; explosion_steps};
                    objects = [objects {explosion}];
                end
            end
        end

        % Self destruct
        if strcmp(objects{i}{1}, 'destruct')
            if objects{i}{6}/ts < 5 && objects{i}{6} >= 0
                r = (5 - objects{i}{6}/ts)/5 * destruct_radius;
                eplot(...
                    sin(0:.1:3*pi)*r+objects{i}{2}, ...
                    cos(0:.1:3*pi)*r+objects{i}{3}, ...
                    'Color', objects{i}{7});
            end
            if objects{i}{6} <= 0
                for j = 1:nplayers

                    hit = 0;
                    d = norm([ state{j}{1}-objects{i}{2}  state{j}{2}-objects{i}{3} ]);
                    if d <= destruct_radius
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
                        state{j}{3} = state{j}{3} - eval(destruct_damage);
                        eplot(state{j}{1},state{j}{2},'r*')
                    end
                    delqueue = [delqueue i];
                end
            end
            objects{i}{6} = objects{i}{6} - ts;

            eplot(objects{i}{2}, objects{i}{3}, 'p', ...
                'Color', objects{i}{7});
        end

        % Explosion
        if strcmp(objects{i}{1}, 'explosion')
            % 1 explosion
            % 2 x
            % 3 y
            % 4 radius
            % 5 color
            % 6 timer
            if objects{i}{6} >= 0
                r = (explosion_steps - objects{i}{6}) ...
                    / explosion_steps * objects{i}{4};
                eplot(...
                    sin(0:.1:3*pi)*r+objects{i}{2}, ...
                    cos(0:.1:3*pi)*r+objects{i}{3}, ...
                    'Color', objects{i}{5});
            else
                delqueue = [delqueue i];
            end
            objects{i}{6} = objects{i}{6} - 1;
        end

    end

    objects(delqueue) = [];

    % Dont plotting durrent frame
    eplot('setframe');

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

eplot('finish');

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

function eplot(varargin)
engine_settings;
global watch;
global script_fid;

if length(varargin) == 1
    if strcmp(varargin{1}, 'init')
        if record_game
            watch = [];
        end
        if script_game
            script_fid = fopen(script_file, 'wt');
            fprintf(script_fid, '% Settings:\n');
            fprintf(script_fid, 'record_game = 0;\n');
            fprintf(script_fid, 'watch = [];\n\n');
        end
    elseif strcmp(varargin{1}, 'finish')
        if script_game
            fclose(script_fid);
        end
        if record_game
            save('gamemovie', 'watch');
            disp('Saved movie to "gamemovie.mat".')
        end
    elseif strcmp(varargin{1}, 'clearframe')
        if display_game || record_game
            clf;
            hold on;
        end
        if script_game
            fprintf(script_fid, 'clf;\nhold on;\n');
        end
    elseif strcmp(varargin{1}, 'setframe')
        if display_game || record_game
            axis('equal');
            axis(world);
            drawnow;
        end
        if record_game
            watch = [watch getframe];
        end
        if script_game
            fprintf(script_fid, 'axis(''equal'');\n');
            fprintf(script_fid, ['axis([' num2str(world) ']);\n']);
            fprintf(script_fid, 'drawnow;\n');
            fprintf(script_fid, 'if record_game\n');
            fprintf(script_fid, '  watch = [watch getframe];\n');
            fprintf(script_fid, 'end\n');
        end
    end
    return;
end

% Avoid evaling a string
done_plot = 0;
if display_game || record_game
    if nargin == 3
        plot(varargin{1}, varargin{2}, varargin{3});
        done_plot = 1;
    elseif nargin == 4
        plot(varargin{1}, varargin{2}, varargin{3}, varargin{4});
        done_plot = 1;
    elseif nargin == 5
        plot(varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5});
        done_plot = 1;
    end
end

% Build plot string
if (~done_plot && (display_game || record_game)) || script_game
    plot_cmd = 'plot(';
    for i = varargin
        i = i{1};
        if isnumeric(i)
            plot_cmd = [plot_cmd '[' num2str(i) '], '];
        else
            plot_cmd = [plot_cmd '''' i ''', '];
        end
    end
    plot_cmd(end-1:end) = [];
    plot_cmd = [plot_cmd ');'];
end

if ~done_plot && (display_game || record_game)
    eval(plot_cmd);
end
if script_game
    fprintf(script_fid, '%s\n', plot_cmd);
end

end
