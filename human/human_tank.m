function [deltaH throttle action] = human_tank (state, player, objects, req)

% Init
px = player{1};
py = player{2};
hd = player{8};
engine_settings;

% Get joystick
sim('getjoy');

lx = joy_adjust(-joyaxis(2));
rx = joy_adjust(-joyaxis(3));

deltaH = (rx - lx)/8;
throttle = sum(rx + lx);

action = '';
if joybutton(8)
    action = 'rifle';
elseif joybutton(7)
    action = 'mine';
elseif joybutton(9)
    action = 'grenade2';
end

% Laser guide
eplot([px cos(hd + deltaH)*10 + px], [py sin(hd + deltaH)*10+py], ':m');

function v = joy_adjust(v)
v = (abs(v))^2 * sign(v);
