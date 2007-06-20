function [deltaH throttle action] = seeker(state, player, objects)

pnum = player{6};
xpos = player{1};
ypos = player{2};

if exist(['seeker' num2str(pnum) '.mat'], 'file')
    load(['seeker' num2str(pnum)]);
    for i = 1:length(state)
        
    end
else
    tnum = ceil(rand*length(state));
    target = state{tnum}{6};
    save(['seeker' num2str(pnum)], 'target');
end

tx = state{tnum}{1};
ty = state{tnum}{1};

