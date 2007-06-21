% World settings
world = [0 20 0 20];
ts = 0.05;

% Display settings
heading_length = norm([world(1) - world(2) world(3) - world(4)])/35;

% Player settings
energy_max = 100;
energy_regen = 0.1;
move_cost = 0.1;
health_max = 100;
deltaH_max = pi/4;

% Rifle information
rifle_cost = 5;
rifle_speed = 10;
rifle_radius = rifle_speed * ts / 2;
rifle_damage = 100;

