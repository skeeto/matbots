function [deltaH throttle action] = human_hdcmd (state, player, objects, req)

% Init
px = player{1};
py = player{2};
hd = player{8};
engine_settings;

% Get joystick
sim('getjoy');

y = -joy_adjust(joyaxis(2));
x = joy_adjust(joyaxis(1));
throttle = -joy_adjust(joyaxis(3));

if norm([x y]) > .75
    aim = atan2(y,x);
    deltaH = aim-hd;
    deltaH = mod(deltaH+pi,2*pi)-pi;
else
    deltaH = 0;
end

action = '';
if joybutton(8)
    action = 'rifle';
elseif joybutton(7)
    action = 'mine';
elseif joybutton(9)
    action = 'grenade2';
elseif joybutton(11)
    pause
end

% Laser guide
eplot([px cos(hd + deltaH)*10 + px], [py sin(hd + deltaH)*10+py], ':m');

function v = joy_adjust(v)
v = (abs(v))^2 * sign(v);
