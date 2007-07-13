function [deltaH throttle action] = shield(state, player, objects, req)

px = player{1};   % Player X
py = player{2};   % Player Y
hd = player{8};   % Heading
team = player{5}; % Team name
pnum = player{6}; % Player number
name = player{7}; % Player name (should be shield)

% Initialize
deltaH = 0;
throttle = 0;
action = 'none';

engine_settings;

% Circle radius unit
circ_rad = rifle_radius * 1.25;
fudge_factor = 2;
cruise_speed = 0.5;

team_file = [name '-' team '.mat'];

% Handle requests
if isempty(req)
	% Continue as normal
elseif strcmp(req, 'preclean') || strcmp(req, 'clean')
	% Remove files we want to use
	if exist(team_file, 'file')
		delete(team_file);
	end
	teamsnipe(state, player, objects, req);
	return;
else
	% Ignore (unknown request)
end

% Get list of teammates
teamlist = pnum;
for i = 1:length(state)
    if strcmp(state{i}{5}, team) && strcmp(state{i}{7}, name)
        teamlist = [teamlist state{i}{6}];
    end
end
teamlist = sort(teamlist);

if exist(team_file, 'file')
    load(team_file);
else
    % Initialize

    % Find the center of mass
    xsum = px;
    ysum = py;
    tcnt = 1;
	for i = 1:length(state)
        if strcmp(state{i}{5}, team) && strcmp(state{i}{7}, name)
            xsum = xsum + state{i}{1};
            ysum = ysum + state{i}{2};
            tcnt = tcnt + 1;
        end
	end
	center_x = xsum / tcnt;
	center_y = ysum / tcnt;
end

% Determine radius
c = length(teamlist) * circ_rad * fudge_factor;
r = c / (2 * pi);
sa = (180 - (2*pi) / length(teamlist)) / 2;

% If number 1, check current position
if teamlist(1) == pnum
    d = norm([px-center_x py-center_y]);
    if abs(d - r) <= ts
        % Circle
        new_hd = atan2(center_y - py, center_x - px) + pi/2;
        deltaH = new_hd - hd;
        throttle = cruise_speed;
    else
        % Go to radius
        deltaH = atan2(center_y - py, center_x - px) - hd;
        throttle = (d - r)/ts;
    end
    plot(center_x+cos(0:.1:3*pi)*r,center_y+sin(0:.1:3*pi)*r);
else
    % Follow the leader
    
    % Find your personal leader
    ldr = teamlist(find(teamlist == pnum) - 1);
    lx = get_sp(state, ldr, 1);
    ly = get_sp(state, ldr, 2);    
    
    % follow heading
    new_hd = atan2(center_y - ly, center_x - lx) - pi/2;
    fhd = atan2(center_y - ly, center_x - lx) - sa;
    tx = lx + cos(fhd) * circ_rad;    
    ty = ly + sin(fhd) * circ_rad;
    
    % Where to task 
    d = norm([tx-px ty-py]);
    if d > 0
        % Get into the circle
        new_hd = atan2(ty - py, tx -px);
        throttle = 1;
    else
        throttle = cruise_speed;
    end
    deltaH = new_hd - hd;
end

save(team_file, 'center_x', 'center_y');

function val = get_sp(state, player, ind)
for i = 1:length(state)
    if state{i}{6} == player
        val = state{i}{ind};
        return;
    end
end

