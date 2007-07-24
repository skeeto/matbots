function [deltaH throttle action] = pulsor(state,player,objects,req)

engine_settings


heading = player{8};
num = player{6};
datafile = ['pulsor' num2str(num) '.mat'];
sniperdatafile = ['sniper' num2str(player{5}) num2str(player{6}) '.mat'];

nothers = size(state,2);

if strcmp(req,'selfplot')
    action = req;
    throttle = 0;
    deltaH = 0;
    return
elseif strcmp(req,'preclean')||strcmp(req,'clean')
    sniper(state,player,objects,req)
    if exist(datafile,'file')
        delete(datafile)
    end
    if strcmp(req,'preclean')
    time = 0;
    headshot = 0;
    mytarget = 0;
    save (datafile,'time','headshot','mytarget')
    end
    return
end

load (datafile)
load (sniperdatafile)

badguys = [];
for i = 1:nothers
    if ~strcmp(player{5},state{i}{5})
        badguys = [badguys state{i}{6}];
    end
end

if isempty(badguys)
    deltaH = 0;
    throttle = 0;
    action = 'booyeah';
    return
end

numlist = [];
for i = 1:nothers
    numlist = [numlist state{i}{6}];
end

if (mytarget~=0)&&(headshot==0)
    if sum(find(numlist==mytarget))==0
        headshot = 20;
    end
end

if headshot>0
    headshot = headshot-1;
    text(player{1},player{2}+.5,'Hellz Yeah!')
end

[deltaH throttle action] = sniper(state,player,objects,req); 

load (sniperdatafile)

if oldtarget
    mytarget = state{oldtarget}{6};
end

if abs(throttle)>1
    throttle = throttle/abs(throttle);
end

xpos = player{1}+throttle*ts*cos(player{8});
ypos = player{2}+throttle*ts*sin(player{8});;

time = time+ts;

w = 1000;
R = cos(time*w)/4;
psi = (0:360)*pi/180;

eplot(xpos+R*cos(psi),ypos+R*sin(psi),'Color',player{9})

oldtarget = target;
save (datafile,'time','headshot','mytarget')