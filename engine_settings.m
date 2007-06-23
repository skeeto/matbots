%--------------------------------------------------------------------------
% World settings
world = [0 10 0 10];
ts = 0.05;
friendly_fire = 0;
player_hide = [8];
group_teams = 1;
group_teams_radius = norm([world(1)-world(2) world(3)-world(4)]) / 10;

%--------------------------------------------------------------------------
% Display settings
heading_length = norm([world(1) - world(2) world(3) - world(4)])/35;
record_game = 1;
display_game = record_game || 1;

% Display bars
display_health = 1;
display_energy = 1;
bar_length = norm([world(1) - world(2) world(3) - world(4)])/30;
bar_offset = norm([world(1) - world(2) world(3) - world(4)])/60;
bar_stack_offset = norm([world(1) - world(2) world(3) - world(4)])/200;

%--------------------------------------------------------------------------
% Player settings
energy_max = 100;
energy_regen = 0.2;
move_cost = 0.1;
health_max = 100;
deltaH_max = pi/4;

%--------------------------------------------------------------------------
% Actions

% Rifle information
rifle_enable = 1;
rifle_cost = 5;
rifle_speed = 10;
rifle_radius = rifle_speed * ts / 2;
rifle_damage = 10;

% Mine information
mine_enable = 1;
mine_cost = 10;
mine_radius = 0.5;
mine_damage = 10;
