function [monitor] = monitor_set
% 12/3/11
% Ken Hwang
% PSU, Scherf Lab, SLEIC, Dept. of Psych.

% Determines monitor settings
% Output: monitor data structure
%
% ---------- Window Setup ----------
% Opens a window.

% Screen is able to do a lot of configuration and performance checks on
% open, and will print out a fair amount of detailed information when
% it does.  These commands supress that checking behavior and just let
% the demo go straight into action.  See ScreenTest for an example of
% how to do detailed checking.
oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);
oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);
oldEnableFlag = Screen('Preference', 'SkipSyncTests', 0);	

% Find out how many screens and use largest screen number.
whichScreen = max(Screen('Screens'));
    
% Opens a graphics window on the main monitor (screen 0).  If you have
% multiple monitors connected to your computer, then you can specify
% a different monitor by supplying a different number in the second
% argument to OpenWindow, e.g. Screen('OpenWindow', 2).

%Dan Update - 4/19/17
%Screen('Preference', 'SkipSyncTests', 1); %Uncomment to fix display issues
[window,rect] = Screen('OpenWindow', whichScreen);

% Screen center calculations
center_W = rect(3)/2;
center_H = rect(4)/2;
        
% ---------- Color Setup ----------
% Gets color values.

% Retrieves color codes for black and white and gray.
black = BlackIndex(window);  % Retrieves the CLUT color code for black.
white = WhiteIndex(window);  % Retrieves the CLUT color code for white.

gray = (black + white) / 2;  % Computes the CLUT color code for gray.
if round(gray)==white
	gray=black;
end
	 
% Taking the absolute value of the difference between white and gray will
% help keep the grating consistent regardless of whether the CLUT color
% code for white is less or greater than the CLUT color code for black.
absoluteDifferenceBetweenWhiteAndGray = abs(white - gray);

% Data structure for monitor info
monitor.oldVisualDebugLevel = oldVisualDebugLevel;
monitor.oldSupressAllWarnings = oldSupressAllWarnings;
monitor.oldEnableFlag = oldEnableFlag;
monitor.whichScreen = whichScreen;
monitor.window = window;
monitor.rect = rect;
monitor.center_W = center_W;
monitor.center_H = center_H;
monitor.black = black;
monitor.white = white;
monitor.gray = gray;
monitor.absoluteDifferenceBetweenWhiteAndGray = absoluteDifferenceBetweenWhiteAndGray;

% ---------- Window Cleanup ---------- 

% Closes all windows.
Screen('CloseAll');

% Restore preferences
Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);
Screen('Preference', 'SuppressAllWarnings', oldSupressAllWarnings);
Screen('Preference', 'SkipSyncTests', oldEnableFlag);	
end