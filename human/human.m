function [deltaH throttle action] = human (state, player, objects, req)

% Init
px = player{1};
py = player{2};
hd = player{8};
engine_settings;

% Get joystick
sim('getjoy');

throttle = -joyaxis(2);
deltaH = -joyaxis(1) * pi/16;

action = '';
if joybutton(4)
    action = 'rifle';
elseif joybutton(1)
    action = 'mine';
elseif joybutton(5)
    action = 'grenade2';
end

% Laser guide
eplot([px cos(hd + deltaH)*10 + px], [py sin(hd + deltaH)*10+py], ':m');
