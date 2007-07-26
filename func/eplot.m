% Matbots plot wrapper
%
% Call this to have plot calls recorded into the game recording scripts and
% handled properly by plot settings.
function eplot(varargin)
engine_settings;
global watch;
global script_fid;

num_argin = nargin;

if strcmp(varargin{1}, 'engine')
    varargin(1) = [];
    num_argin = num_argin - 1;
else
    if silent_bots
        return;
    end
end

if length(varargin) == 1
    if strcmp(varargin{1}, 'init')
        if record_game
            watch = [];
        end
        if script_game
            script_fid = fopen(script_file, 'wt');
            fprintf(script_fid, '%% Settings:\n');
            fprintf(script_fid, 'record_game = 0;\n');
            fprintf(script_fid, 'watch = [];\n\n');
        end
    elseif strcmp(varargin{1}, 'finish')
        if script_game
            fclose(script_fid);
        end
        if record_game
            save('gamemovie', 'watch');
            disp('Saved movie to "gamemovie.mat".')
        end
    elseif strcmp(varargin{1}, 'clearframe')
        if display_game || record_game
            clf;
            hold on;
        end
        if script_game
            fprintf(script_fid, 'clf;\nhold on;\n');
        end
    elseif strcmp(varargin{1}, 'setframe')
        if display_game || record_game
            axis('equal');
            axis(world);
            drawnow;
        end
        if record_game
            watch = [watch getframe];
        end
        if script_game
            fprintf(script_fid, 'axis(''equal'');\n');
            fprintf(script_fid, ['axis([' num2str(world) ']);\n']);
            fprintf(script_fid, 'drawnow;\n');
            fprintf(script_fid, 'if record_game\n');
            fprintf(script_fid, '  watch = [watch getframe];\n');
            fprintf(script_fid, 'end\n');
        end
    end
    return;
end

% Check for text plot
cmd = 'plot';
not_plot = 0;
if strcmp(varargin{1}, 'text')
    cmd = 'text';
    varargin(1) = [];
    not_plot = 1;
elseif strcmp(varargin{1}, 'fill')
    cmd = 'fill';
    varargin(1) = [];
    not_plot = 1;
end

% Avoid evaling a string
done_plot = 0;
if (display_game || record_game) && ~not_plot
    if num_argin == 3
        plot(varargin{1}, varargin{2}, varargin{3});
        done_plot = 1;
    elseif num_argin == 4
        plot(varargin{1}, varargin{2}, varargin{3}, varargin{4});
        done_plot = 1;
    elseif num_argin == 5
        plot(varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5});
        done_plot = 1;
    end
end

% Build plot string
if (~done_plot && (display_game || record_game)) || script_game
    plot_cmd = [cmd '('];
    for i = varargin
        i = i{1};
        if isnumeric(i)
            plot_cmd = [plot_cmd '[' num2str(i) '], '];
        else
            i = strrep(i, '''', '''''');
            plot_cmd = [plot_cmd '''' i ''', '];
        end
    end
    plot_cmd(end-1:end) = [];
    plot_cmd = [plot_cmd ');'];
end

if ~done_plot && (display_game || record_game)
    eval(plot_cmd);
end
if script_game
    fprintf(script_fid, '%s\n', plot_cmd);
end

end
