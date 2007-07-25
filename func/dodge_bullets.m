% Relatively quick bullet dodging function. Pass in player and objects
% state vectors. It returns information on when to dodge and where to
% dodge.
function [indanger deltaH throttle] = dodge_bullets(player, objects)

% Initialize
deltaH = 0;
throttle = 0;
engine_settings;
px = player{1};
py = player{2};
hd = player{8};
team = player{5};

danger = [];
indanger = 0;
for i = objects
    % Filter out non rifle and non dangerous
    if ~strcmp(i{1}{1}, 'rifle')
        continue;
    end
    if ~friendly_fire && strcmp(i{1}{5}, team)
        continue;
    end
    i = i{1};
    
    % Angle to bullet
    a = atan2(py - i{3}, px - i{2});
    a = awrap(a) + 2*pi;
    
    % Distance from bullet
    d = norm([px - i{2} py - i{3}]);
    
    % Danger angle
    offset = atan(rifle_radius/d);
    
    % Movement danger angle
    moveo = atan(rifle_radius+(d*ts)/d);
    
    % Bullet heading
    bhd = awrap(i{4}) + 2*pi;
    
    addit = 0;
    if bhd > a - offset && bhd < a + offset
        % We are in danger!
        indanger = 1;
        addit = 1;
    else
        if bhd > a - moveo && bhd < a + moveo
            % This bullet may hurt us if we move
            addit = 1;
        end
    end
    
    if addit
        i{end + 1} = a;
        i{end + 1} = d;
        danger = [danger {i}];
    end
end

%eplot('text', px, py - .5, num2str(length(danger)));

if indanger
    % Weighted heading average
    dhd_list = [];
    d = 0;
    for i = danger
        i = i{1};
        dhd_list(end + 1, :) = [i{end-1} i{end}];
        d = d + wfunc(i{end});
    end
    dhd = 0;
    for i = 1:size(dhd_list, 1)
        dhd = dhd + dhd_list(i, 1) * wfunc(dhd_list(i, 2))/d;
    end
    dhd = awrap(dhd);
    %eplot([px 10*cos(dhd+pi)+px], [py 10*sin(dhd+pi)+py]);
    
    % Go perpendicular to this heading
    lthd = awrap(dhd + pi/2);
    rthd = awrap(dhd - pi/2);
    
    % Which direction is safer?
    ld = check_danger(px + cos(lthd)*ts, py + sin(lthd)*ts, ...
        objects, rifle_radius);
    rd = check_danger(px + cos(rthd)*ts, py + sin(rthd)*ts, ...
        objects, rifle_radius);
    
    thd = lthd;
    if ld > rd
        throttle = -1;
    else
        throttle = 1;
    end
    
    deltaH = thd - hd;
end

% Count number of bullets that endanger this position
function numd = check_danger(px, py, objects, rifle_radius)
numd = 0;
for i = objects
    if ~strcmp(i{1}{1}, 'rifle')
        continue;
    else
        i = i{1};
    end
    a = atan2(py - i{3}, px - i{2});
    a = awrap(a) + 2*pi;
    d = norm([px - i{2} py - i{3}]);
    offset = atan(rifle_radius/d);
    bhd = awrap(i{4}) + 2*pi;
    
    if bhd > a - offset && bhd < a + offset
        % We are in danger!
        numd = numd + 1;
    end
end

% Wrap a value
function out = awrap(a)
out = mod(a + pi, 2*pi) - pi;

% Weight function
function v = wfunc(v)
v = 1/(v^2);
