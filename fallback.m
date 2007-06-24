function [deltaH throttle action] = fallback(state, player, objects, req)

px = player{1};   % Player X
py = player{2};   % Player Y
hd = player{8};   % Heading
team = player{5}; % Team name
pnum = player{6}; % Player number
name = player{7}; % Player name (should be fallback)

eval('engine_settings');
fight_frac = 3;

pthresh = .01;

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
end

% Default actions
deltaH = 0;
throttle = 0;
action = 'none';

% Create a list of enemies:
enemy = [];
for i = 1:length(state)
	if ~strcmp(state{i}{5}, team)
		enemy = [enemy state(i)];
	end
end
nenemy = length(enemy);
if nenemy == 0
	return;
end

% Create a list of cooperative friends
coop = [];
coop_list = pnum;
for i = 1:length(state)
	if strcmp(state{i}{5}, team) && strcmp(state{i}{7}, name)
		coop = [coop state(i)];
		coop_list = [coop_list state{i}{6}];
	end
end
coop_list = sort(coop_list);
ncoop = length(coop);

% Load previous settings or initialize settings
if exist(team_file, 'file')
	load(team_file);
else
	% Initialize target
	target = -1;
	
	% Choose a corner:
	% First find the center of mass of the group
	xsum = px;
	ysum = py;
	for i = 1:ncoop
		xsum = xsum + coop{i}{1};
		ysum = ysum + coop{i}{2};
	end
	xmid = xsum / (ncoop + 1);
	ymid = ysum / (ncoop + 1);
	%
	% Find closest corner
	clear c d corn_dst
	c(1,:) = [world(1) world(3)]; d(1) = 45;
	c(2,:) = [world(1) world(4)]; d(2) = -45;
	c(3,:) = [world(2) world(3)]; d(3) = 135;
	c(4,:) = [world(2) world(4)]; d(4) = -135;
	corn_dst(1) = norm([xmid-c(1,1) ymid-c(1,2)]);
	corn_dst(2) = norm([xmid-c(2,1) ymid-c(2,2)]);
	corn_dst(3) = norm([xmid-c(3,1) ymid-c(3,2)]);
	corn_dst(4) = norm([xmid-c(4,1) ymid-c(4,2)]);
	[val ind] = min(corn_dst);
	corn = c(ind(1),:);
	formH = d(ind(1)) * pi/180;
end

% Find formation position
% First, determine group
pos = find(coop_list == pnum);
fighter = 0;
nfight = (ncoop + 1)/(fight_frac);
nwall = ncoop - nfight + 1;
walld = (rifle_radius * nwall)/(0.5 * pi);
ad = (pi/2) / (nwall + 1);
adf = (pi/2) / (nfight + 1);
if walld < rifle_radius * 2
	walld = rifle_radius * 2;
end
if ((pos - 1) < (ncoop + 1)/(fight_frac))
	fighter = 1;
end

% Move to wall position
if ~fighter
	mx = corn(1) + walld * cos(formH + pi/4 - ad * (pos - nfight));
	my = corn(2) + walld * sin(formH + pi/4 - ad * (pos - nfight));
	if abs(px - mx) < pthresh && abs(py - my) < pthresh
		throttle = 0;
	else
		throttle = norm([mx-px my-py]) * -10;
		deltaH = atan2(py - my, px - mx) - hd;
		return;
	end
else
	mx = corn(1) + walld * .5 * cos(formH + pi/4 - adf * pos);
	my = corn(2) + walld * .5 * sin(formH + pi/4 - adf * pos);
	if abs(px - mx) < pthresh && abs(py - my) < pthresh
		throttle = 0;
	else
		throttle = norm([mx-px my-py]) * -10;
		deltaH = atan2(py - my, px - mx) - hd;
		return;
	end	
end

if fighter || player{4} > energy_max - rifle_cost
	[deltaH throttle action] = teamsnipe(state, player, objects, req);
end

% Find the target
%[tnum target] = find_target(enemy, target);
%tx = enemy{tnum}{1};
%ty = enemy{tnum}{2};

save(team_file, 'corn', 'formH', 'target');

%--------------------------------------------------------------------------
% Chooses a target from the list of enemies
function [target tnum] = find_target(enemy, target)

% Check existing target
tnum = -1;
for i = 1:length(enemy)
	if enemy{i}{6} == target
		tnum = i;
	end
end
if tnum == -1
	% Choose a new target
	tnum = ceil(rand * length(enemy));
end

target = enemy{tnum}{6};

