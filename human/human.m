function [deltaH throttle action] = human (state, player, objects, req)

% Init
px = player{1};
py = player{2};
hd = player{8};
engine_settings;

% Get joystick
sim('getjoy');

throttle = -joy_adjust(joyaxis(2));
deltaH = -joy_adjust(joyaxis(1)) * pi/16;

action = '';
if joybutton(1)
    action = 'rifle';
elseif joybutton(2)
    action = 'mine';
elseif joybutton(3)
    action = 'grenade2';
end

% Laser guide
eplot([px cos(hd + deltaH)*10 + px], [py sin(hd + deltaH)*10+py], ':m');

function v = joy_adjust(v)
v = (abs(v))^2 * sign(v);
