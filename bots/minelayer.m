function [deltaH throttle action] = minelayer(state, player, objects, req)

eval('engine_settings');

% Handle matfile
pnum = player{6};
matfile = ['minelayer' num2str(pnum)];
if isempty(state)
    delete([matfile '.mat']);
end
if exist([matfile '.mat'], 'file')
    load(matfile);
else
    wt = 0;
    refill = 0;
end

[deltaH throttle action] = zombie(state, player, objects, req);

if wt <= 0 && ~refill
    action = 'mine';
    throttle = 1;
    wt = (mine_radius / ts) * 2;
else
    wt = wt - 1;
    action = 'none';
    throttle = 1;
end

if refill
    throttle = rand;
    deltaH = (rand * deltaH_max * 2) - deltaH_max;
end

if player{4} <= mine_cost
    refill = 1;
end

if player{4} > (energy_max * 0.7)
    refill = 0;
end

save(matfile, 'wt', 'refill');
