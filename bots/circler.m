function [deltaH throttle action] = circler(state, player, objects, req)

deltaH = pi/32;
action = 'none';
throttle = 1;
