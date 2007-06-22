function [deltaH throttle action] = zombie(state, player, objects, req)

eval('engine_settings');

px = player{1};
py = player{2};
buffer = .1;

deltaH = 0;
action = 'none';
throttle = 1;

if (px < world(1) + buffer)
    deltaH = deltaH_max;
end
if (px > world(2) - buffer)
    deltaH = deltaH_max;
end
if (py < world(3) + buffer)
    deltaH = deltaH_max;
end
if (py > world(4) - buffer)
    deltaH = deltaH_max;
end
