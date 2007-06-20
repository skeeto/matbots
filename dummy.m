function [deltaH throttle action] = dummy(state,player,objects)

deltaH = rand*pi/4-pi/8;

if player{4}<35
    throttle = 0;
    action = 'none';
else
    throttle = 1;
    if rand<.2
        action = 'rifle';
    else
        action = 'none';
    end
end

