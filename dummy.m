function [deltaH throttle action] = dummy(state, player, objects, req)

deltaH = rand*pi/4-pi/8;

if player{4}<35
    throttle = 0;
    action = 'none';
else
    throttle = 1;
    if rand<.05
        action = 'none';
    else
        action = 'none';
    end
end

