function [deltaH throttle action] = teamsnipe(state, player, objects)

eval('engine_settings');

pnum = player{6};
team = player{5};
matfile = ['teamsnipe-' team '.mat'];
if isempty(state)
    if exist(matfile, 'file')
        delete(matfile);
    end
    return;
end
if exist(matfile, 'file')
    load(matfile);
else
    % Initialize
    target = -1;
    action = 'none';
    lx = [];
    ly = [];
    wt = 0;
end

px = player{1};
py = player{2};
hd = player{8};

% Build list of teamsnipe teammates
t_list = pnum;
for i = 1:length(state)
    if strcmp(state{i}{5}, team) && strcmp(state{i}{7}, player{7})
        t_list = [t_list state{i}{6}];
    end
end
t_list = sort(t_list);

% Clear out teammates from the state list
td = [];
for i = 1:length(state)
    if strcmp(state{i}{5}, player{5})
        td = [td i];
    end
end
state(td) = [];

if t_list(1) == pnum
    % We are the leader (choose a target)
    tnum = get_target(state, target);
    if (tnum == -1)
        tnum = ceil(rand*length(state));
        target = state{tnum}{6};
    end
else
    % We are a follower
end

% Calculate target heading
tnum = get_target(state, target);
if (tnum ~= -1)
    tx = state{tnum}{1};
    ty = state{tnum}{2};
    
    if isempty(lx)
        lx = tx;
        ly = ty;
    end

    d = norm([tx-px ty-py]);
    hx = (tx - lx) * (1 / (rifle_speed * ts)) * d + tx;
    hy = (ty - ly) * (1 / (rifle_speed * ts)) * d + ty;

    thd = atan2(hy-py, hx-px);
    deltaH = thd - hd;

    if t_list(end) == pnum
        lx = tx;
        ly = ty;
    end
else
    deltaH = 0;
end

if t_list(1) == pnum
    if  (wt > 20)
        action = 'rifle';
        wt = 0;
    else
        action = 'none';
        wt = wt + 1;
    end
end

% finish up
deltaH = wrappi(deltaH);
throttle = 0;
save(matfile, 'target', 'action', 'wt', 'lx', 'ly');

function out = get_target(state, t)
out = -1;
for i = 1:length(state)
    if state{i}{6} == t
        out = i;
    end
end

function out = wrappi(in)
out = mod(in + pi, 2*pi) - pi;
