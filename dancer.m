function [deltaH throttle action] = dancer(state, player, objects, req)

px = player{1};   % Player X
py = player{2};   % Player Y
hd = player{8};   % Heading
team = player{5}; % Team name
pnum = player{6}; % Player number
name = player{7}; % Player name (should be shield)
engine_settings;

% Initialize
deltaH = 0;
throttle = 0;
action = 'none';

team_file = [name '-' team '.mat'];

% Handle requests
if isempty(req)
	% Continue as normal
elseif strcmp(req, 'preclean') || strcmp(req, 'clean')
	% Remove files we want to use
	if exist(team_file, 'file')
		delete(team_file);
	end
	return;
else
	% Ignore (unknown request)
    return;
end

get_hd = (px, py, objects);

function [minhd maxhd] = get_hd(px, py, objects)
engine_settings;

minhd = [];
maxhd = [];

for i = 1:length(objects)
    if ~strcmp(objects{i}{1}, 'bullet')
        continue;
    end
    
    bx = objects{i}{2};
    by = objects{i}{3};
    M = atan2(py - by, px - bx);
    t = norm([px-bx py-by]) / rife_speed; % time to impact
    d = t; % distance to travel before impact

    % Solve quadratic
    a = 1 - M^2;
    b = -2 * px - 2 * py * M;
    c = -(d^2) + px^2 + py^2;
    if (b^2 - 4 * a * c) >= 0
        x1 = (-b + sqrt(b^2 - 4 * a * c))/(2 * a);
        x2 = (-b - sqrt(b^2 - 4 * a * c))/(2 * a);
    else
        % Can do nothing about this bullet. Ignore it.
        continue;
    end
    
    y1 = x1 * M;
    y2 = x2 * M;
    
end
