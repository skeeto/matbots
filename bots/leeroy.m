% The Leeroy Jenkins bot. Charges at the enemy firing chaotically. Self
% destructs if he gets close enough to his target.
function [deltaH throttle action] = leeroy (state, player, objects, req)

pnum = player{6};
team = player{5};
name = player{7};
datafile = [name '-' num2str(pnum) '.mat'];

deltaH = 0;
throttle = 0;
action = '';

spray_radius = pi/32;

if isempty(req)
    % Continue as normal
elseif strcmp(req, 'clean')
    % Cleanup
    if exist(datafile, 'file')
        delete(datafile);
    end
    return;
elseif strcmp(req, 'preclean')
    % Initialize
    lx = -1;
    ly = -1;
    save (datafile, 'lx', 'ly');
    return;
elseif strcmp(req, 'selfplot');
    action = req;
    return;
else
    % Unknown request
    return;
end

load (datafile);
px = player{1};
py = player{2};
hd = player{8};

engine_settings;

coop = pnum;
ncoop = 1;
enemy = [];
nenemy = 0;
for i = 1:length(state)
    if ~strcmp(state{i}{5}, team)
        enemy = [enemy i];
        nenemy = nenemy + 1;
    elseif strcmp(state{i}{7}, name)
        ncoop = ncoop + 1;
        coop = [coop i];
    end
end
if nenemy == 0
    % We win!
    return;
end
enemy = sort(enemy);
coop = sort(coop);
tind = enemy(1);

tx = state{tind}{1};
ty = state{tind}{2};

if lx == -1
    lx = tx;
    ly = ty;    
end

[indanger deltaH throttle]= dodge_bullets(player, objects);
if indanger
    lx = ty;
    ly = ty;
    save (datafile, 'lx', 'ly');
    % Self plot
    px = px + cos(hd+deltaH)*throttle*ts;
    py = py + sin(hd+deltaH)*throttle*ts;
    draw_me(px, py, hd+deltaH, player{9}, 10);
    return;
end

d = norm([ tx - px ty - py  ]);

if player{4} > destruct_cost + rifle_cost + move_cost
    sx = (tx - lx) * (1 / (rifle_speed * ts)) * d + tx;
    sy = (ty - ly) * (1 / (rifle_speed * ts)) * d + ty;
    
    thd = atan2 (sy - py, sx - px) + rand * 2 * spray_radius - spray_radius;
    action = 'rifle';
else
    thd = atan2 (ty - py, tx - px);
end

deltaH = thd - hd;

if d < .5
    action = 'destruct';
elseif d < 1
    eplot('text', px+.5, py+.5, 'LEERROOOY JEENKINS!!!');
end

lx = tx;
ly = ty;

throttle = 1;

% Self plot
px = px + cos(hd+deltaH)*throttle*ts;
py = py + sin(hd+deltaH)*throttle*ts;
draw_me(px, py, hd+deltaH, player{9}, d);

save (datafile, 'lx', 'ly');

%--------------------------------------------------------------------------
% Self drawing functions
function draw_me(px, py, hd, pcolor, d)
engine_settings;

% Start to "blow up" as we approach the target.
if d < destruct_radius
    ex = (destruct_radius - d)*.2 + 1;
else
    ex = 1;
end

ys = 0.75;

x = [1  1 -1.5 -0.5 -0.5 -1.5 1] * .125 * ex;
y = [1 -1 -1.5 -0.5  0.5    1.5 1] * .125 * ys * ex;

lex = [0.75 0.25] * .125 * ex;
ley = [0.75 0.25] * .125 * ys * ex;
rex = [0.75 0.25] * .125 * ex;
rey = [-0.75 -0.25] * .125 * ys * ex;

plot_rot(x, y,     hd, px, py, pcolor);
plot_rot(rex, rey, hd, px, py, pcolor);
plot_rot(lex, ley, hd, px, py, pcolor);

function plot_rot (x, y, hd, px, py, pcolor)

rot_mat = [cos(hd) -sin(hd); sin(hd) cos(hd)];
p = rot_mat * [x;y];

eplot(p(1,:) + px, p(2,:) + py, 'Color', pcolor);
