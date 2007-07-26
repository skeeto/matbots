%--------------------------------------------------------------------------
% World settings
world = [0 10 0 10];
ts = 0.05;
friendly_fire = 0;
player_hide = [8 10];
group_teams = 1;
group_teams_radius = norm([world(1)-world(2) world(3)-world(4)]) / 10;

%--------------------------------------------------------------------------
% Display settings
heading_length = norm([world(1) - world(2) world(3) - world(4)])/35;
display_game = 1;
record_game = 0;
script_game = 1;
script_file = 'script_record.m';
log_game = 1;
log_file = 'game_log.mat';
explosion_steps = 5;
silent_bots = 0;

% Display bars
display_health = 1;
display_energy = 1;
bar_length = norm([world(1) - world(2) world(3) - world(4)])/30;
bar_offset = norm([world(1) - world(2) world(3) - world(4)])/60;
bar_stack_offset = norm([world(1) - world(2) world(3) - world(4)])/200;

%--------------------------------------------------------------------------
% Player settings
health_max = 100;
health_regen = 0;
energy_max = 100;
energy_regen = 0.2;
move_cost = 0.1;
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
mine_cost = 3;
mine_radius = 0.5;
mine_damage = 20;

% HtoE information
HtoE_enable = 1;
health_energy_ratio = 1;

% Self destruct information
destruct_enable = 1;
destruct_radius = 3;
destruct_time = 1;
destruct_damage = '2^(-d) * 75';
destruct_cost = 5;

% Grenade information
grenade_enable = 1;
grenade_throw_max = 2.5;
grenade_bits = 12;
grenade_speed = 5;
grenade_cost = rifle_cost * grenade_bits / 6;
