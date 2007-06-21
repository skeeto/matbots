function  out = engine(playerdata)

%1 xpos
%2 ypos
%3 health
%4 energy
%5 team
%6 num
%7 name
%8 heading
%9 color
%
% deltaH
% throttle
% action
%
% rifle
% mine
% shotgun
% ping
% suicide

eval('engine_settings');

term = 0;
nplayers = size(playerdata,1);

dplist = []; %dead player list
state = [];
objects = [];

colorlist = [{[1 0 0]} {[0 1 0]} {[0 0 1]} {[1 0 1]} {[0 0 0]} {[.5 .5 1]}];

for i = 1:nplayers
    player{1} = rand*(world(2)-world(1));
    player{2} = rand*(world(4)-world(3));
    player{3} = health_max;
    player{4} = energy_max;
    player{5} = playerdata{i,2};
    player{6} = i;
    player{7} = playerdata{i,1};
    player{8} = rand*2*pi;
    player{9} = colorlist{mod(i, length(colorlist)) + 1};
    state = [state {player}];
end

t = 0;
clear watch
while ~term
    t = t+1;
    clf
    dpqueue = [];
    for i = 1:nplayers
        if state{i}{3}>0
            state{i}{4} = state{i}{4} + energy_regen;
            if state{i}{4}>energy_max
                state{i}{4} = energy_max;
            end
            
            ostate = [];
            for j = 1:nplayers
               if state{i}{6} == state{j}{6}
                   pstate = state{j};
               else
                   ostate = [ostate state(j)];
               end
                
            end
            
            [deltaH throttle action] = feval(state{i}{7},ostate,pstate,[]);
            if abs(deltaH)>deltaH_max
                deltaH = deltaH_max*sign(deltaH);
            end
            
            %Change heading
            state{i}{8} = mod(state{i}{8}+deltaH + pi, 2*pi) - pi;
                       
            %Add rifle shot
            if strcmp(action,'rifle')
                if rifle_cost<=state{i}{4}
                rifle = { 'rifle' ; state{i}{1} ; state{i}{2} ; state{i}{8}};
                objects = [objects {rifle}];
                state{i}{4} = state{i}{4}-rifle_cost;
                end
            end

             %Move Player
            if throttle*move_cost<=state{i}{4}
                state{i}{1} = state{i}{1}+throttle*cos(state{i}{8})*ts;
                state{i}{2} = state{i}{2}+throttle*sin(state{i}{8})*ts;
                state{i}{4} = state{i}{4}-move_cost*throttle;
            end
            
            %Check boundary
            [state{i}{1},state{i}{2}] = checkbounds(state{i}{1},state{i}{2},world);
            
            plot(state{i}{1},state{i}{2},'o','color',state{i}{9});
            line([state{i}{1} state{i}{1} + cos(state{i}{8}) * heading_length], ...
                 [state{i}{2} state{i}{2} + sin(state{i}{8}) * heading_length]);

            hold on

        else %if health<=0
            dpqueue = [dpqueue i];
        end %if health
    end %for players

    dplist = [dplist state(dpqueue)];
    state(dpqueue)=[];
    nplayers = length(state);

    delqueue = [];
    for i = 1:size(objects,2)
        if objects{i}{1}=='rifle'
            objects{i}{2} = objects{i}{2}+cos(objects{i}{4})*rifle_speed*ts;
            objects{i}{3} = objects{i}{3}+sin(objects{i}{4})*rifle_speed*ts;

            for j = 1:nplayers
                d = norm([ state{j}{1}-objects{i}{2}  state{j}{2}-objects{i}{3} ]);
                if d<=rifle_radius
                    state{j}{3} = state{j}{3}-rifle_damage;
                    plot(state{j}{1},state{j}{2},'r*')
                    delqueue = [delqueue i];
                end
            end

            [dummy,dummy,valid] = checkbounds(objects{i}{2},objects{i}{3},world);
            if ~valid
                delqueue = [delqueue i];
            else
                plot(objects{i}{2},objects{i}{3},'.')
            end
        end
    end

    objects(delqueue) = [];

    axis(world)
    axis square

    watch(t) = getframe;

    if length(state)==1
        term = 1;
    end

end

save gamemovie watch
movie(watch)

end %while



function [xnew,ynew,valid] = checkbounds(x,y,world)
xnew = x;
ynew = y;
valid = 1;
if x<world(1)
    xnew = world(1);
    valid = 0;
end
if x>world(2)
    xnew = world(2);
    valid = 0;
end

if y<world(3)
    ynew = world(3);
    valid = 0;
end
if y>world(4)
    ynew = world(4);
    valid = 0;
end

end