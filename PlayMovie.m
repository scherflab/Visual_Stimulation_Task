function [movie] = PlayMovie(moviename, monitor)
%
% PlayMovie\(moviename)
%
% This demo accepts a pattern for a valid moviename, e.g.,
% moviename='*.mpg', then it plays all movies in the current working
% directory whose names match the provided pattern, e.g., the '*.mpg'
% pattern would play all MPEG files in the current directory.
%
% This demo uses automatic asynchronous playback for synchronized playback
% of video and sound. Each movie plays until end, then rewinds and plays
% again from the start. Pressing the Cursor-Up/Down key pauses/unpauses the
% movie and increases/decreases playback rate.
% The left- right arrow keys jump in 1 seconds steps. SPACE jumps to the
% next movie in the list. ESC ends the demo.
%
% This demo needs MacOS-X 10.3.9 or 10.4.x with Quicktime-7 installed!

% History:
% 10/30/05  mk  Wrote it.
% 1/31/12 krh modified without keypresses
% 4/2/12 krh modified for dynamic localizer presentation

% Child protection
AssertOpenGL;

% Open movie file and retrieve basic info about movie:
[movieptr movie.movieduration movie.fps movie.imgw movie.imgh movie.count] = Screen('OpenMovie', monitor.display_window, moviename);

% Seek to start of movie (timeindex 0):
Screen('SetMovieTimeIndex', movieptr, 0, 1);

% Start playback of movie. This will start
% the realtime playback clock and playback of audio tracks, if any.
% Play 'movie', at a playbackrate = 1, with endless loop=1 and
% 1.0 == 100% audio volume.
Screen('PlayMovie', movieptr, 1, 0, 1.0);

i = 0;

mov_start = GetSecs; % Start time

% Clipping off last 15 frames because of encoding issues at end of
% movie and to avoid overlap with next presentation
while i < movie.count - 15
    
    i=i+1; % Add iteration
    
    % Return next frame in movie, in sync with current playback
    % time and sound.
    % tex either the texture handle or zero if no new frame is
    % ready yet. pts = Presentation timestamp in seconds.
    [tex] = Screen('GetMovieImage', monitor.display_window, movieptr, 1, [], [], 1);

    % Draw the new texture immediately to screen:
    Screen('DrawTexture', monitor.display_window, tex);


    vbl=Screen('Flip', monitor.display_window); % Process subsequent flips according to timeindex, but do not have MatLab wait for execution (timestamps are invalid)

    % Release texture:
    Screen('Close', tex);
 
end % End while(1)

mov_end = GetSecs-mov_start

%movie.pts = pts;

% % Done. Stop playback:
% Screen('PlayMovie', movieptr, 0);

% Close movie object:
Screen('CloseMovie', movieptr);

% % Closes all windows.
% Screen('CloseAll');
% 
% % Restores the mouse cursor and MatLab command input.
% ShowCursor;
% ListenChar(0);
% 
% % Restore preferences
% Screen('Preference', 'VisualDebugLevel', monitor.oldVisualDebugLevel);
% Screen('Preference', 'SuppressAllWarnings', monitor.oldSupressAllWarnings);
% Screen('Preference', 'SkipSyncTests', monitor.oldEnableFlag);

% Done.
return;
