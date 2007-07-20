function [deltaH throttle action] = drawbot (state, player, objects, req)

if isempty(req)
	%continue as normal
elseif strcmp(req, 'selfplot')
	deltaH = 0;
	throttle = 0;
	action = req;
	return;
else
	deltaH = 0;
	throttle = 0;
	action = '';
	return;
end
engine_settings;

throttle = 1;
action = '';
deltaH = pi/32;

px = player{1};
py = player{2};

x = [-1  1  1 -1 -1] * .125;
y = [ 1  1 -1 -1  1] * .125;

nh = player{8} + deltaH;
rot_mat = [cos(nh) -sin(nh); sin(nh) cos(nh)];
p = rot_mat * [x;y];

eplot(p(1,:) + px, p(2,:) + py, 'Color', player{9});

eplot( ...
	[px px+cos(nh) * heading_length], ...
	[py py+sin(nh) * heading_length], ...
	'Color', player{9});
