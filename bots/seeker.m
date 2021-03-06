% Seeker bot
% by Chris Wellons
%
% Selects a random target. Performs seek and destroy on that target until
% it is dead.
function [deltaH throttle action] = seeker(state, player, objects, req)

eval('engine_settings');

pnum = player{6};
xpos = player{1};
ypos = player{2};
hd   = player{8} - pi;

matfile = ['seeker' num2str(pnum)];

% Cleanup mode:
if (isempty(state))
    delete([matfile  '.mat']);
    return;
end

% Clear out teammates from the state list
t_list = [];
for i = 1:length(state)
    if strcmp(state{i}{5}, player{5})
        t_list = [t_list i];
    end
end
state(t_list) = [];

if exist([matfile  '.mat'], 'file')
    load(matfile);
    tnum = -1;
    for i = 1:length(state)
        if state{i}{6} == target
            tnum = i;
        end
    end
    if tnum == -1 && length(state) > 0
        if ~isempty(state)
            tnum = ceil(rand*length(state));
            target = state{tnum}{6};
            lx = state{tnum}{1};
            ly = state{tnum}{1};
        else
            deltaH = 0;
            action = 'none';
            throttle = 0;
            return;
        end
    end
else
    tnum = -1;
    if length(state) > 0
        tnum = ceil(rand*length(state));
        target = state{tnum}{6};
        wt = 0;
        lx = state{tnum}{1};
        ly = state{tnum}{1};
    end
end

% No targets left
if tnum == -1
    detlaH = 0;
    throttle = 0;
    action = 'none';
    return;
end

tx = state{tnum}{1};
ty = state{tnum}{2};

d = norm([tx-xpos ty-ypos]);
px = (tx - lx) * (1 / (rifle_speed * ts)) * d + tx;
py = (ty - ly) * (1 / (rifle_speed * ts)) * d + ty;

thd = atan2(ypos - py, xpos - px);

% Note the targets current position for next time.
lx = tx;
ly = ty;

if (abs(wrappi(thd - hd)) < pi/32)
    if  (wt > 20)
        action = 'rifle';
        wt = 0;
    else
        action = 'none';
        wt = wt + 1;
    end
    throttle = 1;
else
    wt = wt + 1;
    action = 'none';
    throttle = 0.25;
end

deltaH = thd - hd;
deltaH = wrappi(deltaH);

if d < mine_radius && mine_enable
    action = 'mine';
end

save(matfile, 'target', 'wt', 'lx', 'ly');

function out = wrappi(in)
out = mod(in + pi, 2*pi) - pi;
