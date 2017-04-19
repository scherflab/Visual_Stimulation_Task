function runLocalizer(varargin)
% proc_display
% 12/5/12
% Original Author:
% Ken Hwang
% PSU, Scherf Lab, SLEIC, Dept. of Psych
%
% 
% 4/19/17
% Updated & Managed By:
% Daniel Elbich
% PSU, Scherf Lab, SLEIC, Dept. of Psych
% 
% 
% Please cite this publication upon any use of this task or stimuli:
% Elbich, D. B., & Scherf, S. (2017). 
% Beyond the FFA: Brain-behavior correspondences in 
% face recognition abilities. NeuroImage, 147, 409-422.
% http://doi.org/10.1016/j.neuroimage.2016.12.04
%
%
% Contact scherflab@gmail.com with questions regarding the task
% 
% Program Notes:
%
% Originally written in: MATLAB 2012b
% Currently works with: MATLAB 2015a
%
% Requires:
% Psychtoolbox >= 3.0.8
% GStreamer version >= 1.4.0
%
% 
% Visual display and response recording script
% Task-specific procedural display sequence
%
% Usage:
% proc_display for presentation
% proc_display('backup') to follow-up calculations and output of data


%% Cell 1: Start-up and Stimulus loading

backupflag = 0;

% Directory of this script
file_str = mfilename('fullpath');
[file_dir,~,~] = fileparts(file_str);
    
if nargin > 1
    
    error('Too many arguments')

elseif nargin == 1 
    
    switch varargin{1} % Check arg
        
        case 'backup'
            
            backuppath = uigetdir; % Select dir
            load([backuppath filesep 'vars.mat']); % Load contents
            RT_backup = csvread([backuppath filesep 'RT.csv']); % Load RT file
            backupflag = 1;
            
        otherwise
            
            disp('Unknown method.')
            
    end % End switch: switch varargin{1}
    
elseif nargin == 0
    
    PsychJavaTrouble;

    load([file_dir filesep 'params']); % Load params.mat

    % UI to select task
    [s,v] = listdlg('PromptString', 'Select a task:',...
    'SelectionMode', 'single',...
    'ListString',{params.TaskName});

    if v

        % UI to select version of task
        [s2,v2] = listdlg('PromptString', 'Select task type:',...
            'SelectionMode', 'single',...
            'ListString',params(s).Alt);

        if v2

            % OS check
            if ismac

                [~,tasklist] = system(['ls ''' file_dir '/Images/' params(s).path '/lists/' params(s).altpath{s2} '/'' | awk ''{print mat $1}''']); % List mat files

            elseif ispc

                [~,tasklist] = system(['dir /b /a-d-h "' file_dir '\Images\' params(s).path '\lists\' params(s).altpath{s2} '\*.mat"']); % List mat files

            end % End if: ismac

        else % v2 == 0

            error('User Cancelled')

        end % End if: v2


    else % v == 0

        error('User Cancelled')

    end % End if: v

    tasklist = regexp(tasklist(1:end-1), '\n', 'split');

    % List Loading
    load([file_dir filesep 'Images' filesep 'general' filesep 'lists' filesep 'patterns']); % patternLoc.mat (12x2 cell)
    load([file_dir filesep 'Images' filesep 'general' filesep 'lists' filesep 'Fixation_Cross']); % fixation (1x2 cell)

    list_struct(params(s).CondNum) = cell(1); % Preallocating list_struct with number of conditions
    list_names = cell([1 params(s).CondNum]); % Preallocating list_names with number of conditions

    for taskind = 1:length(tasklist)

        list_struct{taskind} = load([file_dir filesep 'Images' filesep params(s).path filesep 'lists' filesep params(s).altpath{s2} filesep tasklist{taskind}]); % Loading each list

        fieldlist = fieldnames(list_struct{taskind}); % Fields in list_struct
        list_names{taskind} = fieldlist{1}(1:end-1); % String of list name without index (final val)

    end % End for: taskind = 1:length(tasklist)

    % Task lengths
    x = params(s).CondNum; % Number of conditions
    %ws_list = who; % Workspace list
    %y = length(find(cellfun(@(x2)(~isempty(x2)),cellfun(@(x1)(regexp(x1, [list_names{1}])), ws_list, 'UniformOutput', false)))); % Number of lists pertaining to list_names{1} in workspace
    y = params(s).ListNum; % Number of lists
    %z = size(eval([list_names{1} '1']),1); % Number of images in first list of first condition (assuming equal for all)
    z = params(s).ImgNum; % Number of images

    BlockNum = x*y; % Total number of blocks

    % Preallocating img_cell: (Condition (x) x List number (y) x Trial number (z) x Description tags (3))
    % img_cell is the image-matrix cell for all pictures
    img_cell = cell(x,y,z,4); 

    % For loop to imread all necessary .jpg
    for i = 1:x % x conditions 
        for j = 1:y % y lists        
            for k = 1:z % z images
                % Inserting uint8 file into corresponding img_cell
                % Constructing field name from list_names to call from
                % structure

                temp = [file_dir filesep 'Images' filesep params(s).path filesep 'pictures' filesep list_struct{i}.([list_names{i} int2str(j)]){k,1}];

                [~,~,ext] = fileparts(temp);

                if sum(strcmpi(ext, {'.jpg', '.jpeg', '.bmp'})) % If image extension

                    try
                        img_cell{i,j,k,1} = imread(temp); % Image matrix
                    catch ME
                        disp(ME);
                        disp(['Could not read ' temp]);
                    end
                        
                    img_cell{i,j,k,2} = list_struct{i}.([list_names{i} int2str(j)]){k,1}; % Inputting image name to img_cell

                elseif strcmp(ext, {'.m4v'}) % If movie extension

                    img_cell{i,j,k,2} = temp; % Inputting movie directory to img_cell

                    movobj = VideoReader(temp);

                    img_cell{i,j,k,1} = get(movobj, 'Duration'); % Inputting Duration into second column

                    clear movobj % Removing movie object

                else % Display error

                    error('Invalid file extension for %s.  Check file extension and add to code, or use an acceptable file extension', temp)

                end % End img_cell load

                img_cell{i,j,k,3} = list_struct{i}.([list_names{i} int2str(j)]){k,2}; % Inputting sub-description to img_cell
                img_cell{i,j,k,4} = [list_struct{i}.([list_names{i} int2str(j)]){k,3} ' ' int2str(j)]; % Inputting list name and number to img_cell
            end % End image number
        end % end list number
    end % End condition number

    % Setting flag for movie presentation
    if strcmp(params(s).TaskName, 'Dynamic')
        params(s).dynFlag = 1; % Adding dynamic flag to params
        params(s).MovDuration = round(mean(mean(cell2mat(img_cell(:,:,1,1))))); % Adding rounded movie duration to params, assuming all durations are equal
    end % End if: strcmp(params.TaskName, 'Dynamic')

    % Instruction load for Dynamic
    if ~isfield(params(s),'dynFlag') 
        instruct = imread([file_dir filesep 'Images' filesep 'general' filesep 'Instructions.jpg']); % Loading instructions
    end
    
    % Instruction load for SexDiff
    if strcmp(params(s).TaskName,'SexDiff')
        instruct = imread([file_dir filesep 'Images' filesep 'general' filesep 'SD_Instructions.jpg']); % Loading instructions
    end
    
    % If no instructions have been made
    if ~exist('instruct','var') 
        instruct = imread([file_dir filesep 'Images' filesep 'general' filesep 'Instructions_dyn.jpg']); % Loading instructions
    end

    % Messages displayed in 'Introductory Text' - *** Unused ***
    % message1 = 'Welcome to the experiment';
    % message2 = 'You will now be presented with a number of pictures.';
    % message3 = 'Press any key to start.';
    % message4 = 'Thank you for participating'; % Not currently used

    % Loading fixation cross (Assuming fixation cross is in
    % ./Images/general/pictures)
    [fix_img, ~, alpha] = imread([file_dir filesep 'Images' filesep 'general' filesep 'pictures' filesep fixation{1,1}]);
    fix_img(:,:,4) = alpha(:,:);
    fix_pic{1,1} = fix_img;
    fix_pic{1,2} = fixation{1,1}; % Inputting image name
    fix_pic{1,3} = 'N/A'; % No sub-description for the fixation cross
    fix_pic{1,4} = fixation{1,2}; % 'Fixation cross' as condition

    % Pattern setup for 'Block of Patterns'
    pattern_order = Shuffle(1:length(patternLoc)); % Shuffle a pattern order
    pat_cell = cell(12,3); % Preallocate pat_cell

    % For loop for pattern loading (assuming pattern files are in
    % ./Images/general/pictures/)
    for i2 = 1:length(pattern_order) % Indices for length of pattern_order
        pat_cell{i2,1} = imread([file_dir filesep 'Images' filesep 'general' filesep 'pictures' filesep patternLoc{pattern_order(i2),1}]); % Read uint8 pattern image files into pat_cell
        pat_cell{i2,2} = patternLoc{pattern_order(i2),1}; % Inputting image name
        pat_cell{i2,3} = 'N/A'; % Pattern lists do not have a sub-description
        pat_cell{i2,4} = patternLoc{pattern_order(i2),2}; % Reading pattern description into pat_cell
    end % End for loop

    % Calling t_calc function to specify presentation time points and response flags for task (Output: t_list)
    t_list = t_calc(params(s));

    % Timing for evaluation purposes (Assumes t_list is synced with exp_cell)
    pres_time = zeros([length(t_list) 1]);

    % Presentation cell (613 presentations long x 4 description tags)
    % Column 1 refers to image matrix/movie name
    % Column 2 refers to image name/movie duration
    % Column 3 refers to sub-description
    % Column 4 refers to condition list
    block_col = 5; % Column 5 refers to Block number
    % Column 6 refers to matching flag (1 or 0)
    exp_cell = cell([length(t_list) 6]);

    % Adding patterns to exp_cell
    for i = 1:length(pattern_order)
        exp_cell(i,1:4) = pat_cell(i,:);
        exp_cell{i,5} = 0; % Entering 0 for block number
    end % End for loop

    % Conditional display randomized order setup
    block_order_1d = Shuffle(1:BlockNum); % Randomizing order out of BlockNum (1d)
    [cond_I, cond_J] = ind2sub([x y], 1:BlockNum); % cond_I and cond_J refer to row and column indices, respectively, for each of the conditional lists as a x-by-y matrix
    block_order_2d = [cond_I(block_order_1d); cond_J(block_order_1d)]; % converting the randomized sequence (block_order_1d) in terms of a x-by-y matrix;  These indices will apply directly to img_cell.      

    % Initial fixation
    next_cell = find(cellfun('isempty',exp_cell),1,'first'); % Next empty cell indice
    exp_cell(next_cell, 1:4) = fix_pic(:);
    exp_cell{next_cell, 5} = 0; % Entering 0 as block number

    % Adding block images to exp_cell
    for block_ind = 1:length(block_order_1d) % For loop for the length of blocks

        for trial_ind = 1:z 

            next_cell = find(cellfun('isempty',exp_cell),1,'first'); % Next empty cell indice

            exp_cell(next_cell, 1:4) = img_cell(block_order_2d(1,block_ind), block_order_2d(2,block_ind), trial_ind, :); % Transferring img_cell contents to exp_cell
            exp_cell{next_cell, 5} = block_ind; % Entering block number
            exp_cell((next_cell + 1), 1:4) = fix_pic(:); % Adding fixation point to following cell
            exp_cell{(next_cell + 1), 5} = block_ind; % Entering block number

        end % End for loop for trials

        if ~isfield(params(s),'dynFlag') % Unnecessary for dynamic task
            % Adding fixation at end of trial
            block_end_ind = find(cellfun('isempty',exp_cell),1,'first'); % Next empty cell indice   
            exp_cell(block_end_ind, 1:4) = fix_pic(:); % Adding fixation point to end of trial cell
            exp_cell{block_end_ind, 5} = block_ind; % Entering block number
        end

    end % End length of block order

    % % Adding final fixation to exp_cell
    % exp_cell(end, 1:4) = fix_pic(:);
    % exp_cell{end, 5} = 0; % Entering 0 as block number

    if strcmp(params(s).TaskName,'SexDiff') % Different task structure for SexDiff
        targ_str = 'Bleibtreu|Gruszka';
        exp_cell(:,6) = num2cell(cellfun(@(y2)(~isempty(y2)),cellfun(@(y)(regexp(y,targ_str)),exp_cell(:,2),'UniformOutput',false))); % Correct flags for 'Elias' and 'Valverde'
    else
        % Evaluating matching stimuli (2 of the same stimuli in a row)
        % Ignoring first two rows
        exp_cell{1,6} = 0;
        exp_cell{2,6} = 0;
        
        for i = 3:length(exp_cell) % For length of exp_cell, starting at index 3
            if ~(strcmp(exp_cell{i,2},fix_pic{1,2})) % If not fix_pic{1,2} string
                if strcmp(exp_cell{i,2},exp_cell{i-2,2}) % If string matches the string that came 2 before (takes into account fixation in between)
                    exp_cell{i,6} = 1; % Mark a 1 in the 6th column
                else
                    exp_cell{i,6} = 0; % Else mark a 0
                end % End string compare
            else
                exp_cell{i,6} = 0; % If fix_pic{1,2} mark a 0
            end % End string compare
        end % End for loop
    end
    
    % Calling data structure for monitor settings
    monitor = monitor_set;

    % Response flag
    resp_flag = 0;

    % Defining device numbers for experimenter and participant keyboards
    % *** Need to specify for pulse triggers ***
    %devices = PsychHID('devices');

    % Enable unified mode of KbName, so KbName accepts identical key names on
    % all operating systems:
    KbName('UnifyKeyNames');

    % States variables for respective keys
    c_key = KbName('c');
    tkey = KbName('t');
    esc_key = KbName('Escape');
    esc_flag = 0;

    % Input set-up
    devices = PsychHID('Devices');
    usageName = cellfun(@(y2)(~isempty(y2)),cellfun(@(y)(regexp(y,'Keyboard')),{devices.usageName},'UniformOutput',false));
    try
        trig_manufacturer = cellfun(@(y2)(~isempty(y2)),cellfun(@(y)(regexp(y,'Current Designs, Inc.')),{devices.manufacturer},'UniformOutput',false));
        trigdevice = find(usageName & trig_manufacturer);
    catch ME
        disp('Triggering device undetected.');
        warning(ME.message);
    end
    try
        grip_manufacturer = cellfun(@(y2)(~isempty(y2)),cellfun(@(y)(regexp(y,'Code Mercenaries')),{devices.manufacturer},'UniformOutput',false));
        gripdevice = find(usageName & grip_manufacturer);
    catch ME
        disp('Response grips undetected.');
        warning(ME.message);
    end
    try
        laptop_manufacturer = cellfun(@(y2)(~isempty(y2)),cellfun(@(y)(regexp(y,'Apple Inc.')),{devices.manufacturer},'UniformOutput',false));
        laptopdevice = find(usageName & laptop_manufacturer);
    catch ME
        disp('Laptop keyboard undetected.');
        warning(ME.message);
    end
    
    %% Cell 1 end

    %% Cell 2: Subject Entry

    % UI entry 
    prompt1 = {'Subject ID (YYMMDDffll):', 'Date (YYMMDD):'};
    dlg_title1 = 'Fill out Subject Information';    
    num_lines1 = 1;
    def1 = {'', datestr(now, 'yymmdd')}; % # of Defs = # prompt fields
    options.Resize = 'on';
    subjout = inputdlg(prompt1, dlg_title1, num_lines1, def1, options);

    % Subject data
    subj_id = subjout{1}; 
    subj_date = subjout{2};
    data_str = [subj_id '_' params(s).TaskName '_' params(s).Alt{s2} '_' subj_date];

    %% Cell 2 end

    %% Cell 3: PRT Output

    fid = fopen([file_dir filesep 'data' filesep data_str '.prt'],'w');
    prtmaker(fid,params(s),s2,t_list,exp_cell); % Data structure for times

    %% Cell 3 end

    %% Cell 4: Data Output Prep
    % Variables required: block_col, fix_pic, exp_cell, subj_id, subj_date

    block_vect = cell2mat(exp_cell(:,block_col)); % Convert block number to matrix
    ind = find(block_vect); % Finding only indices with block numbers
    pres_ind = []; % Initializing pres_ind (indices not including fixations)
    dat = struct('Condition',[],'Number',[]); % Initializing dat
    stat = struct('meanRT',[],'acc',[]); % Initializing stat

    % For loop to remove fixation presentations
    for i = 1:length(ind) % For the length of ind

        if ~(strcmp(exp_cell{ind(i),2},fix_pic{1,2})) % If not fix_pic{1,2} string
            pres_ind(end+1) = ind(i); % Record index into pres_ind
        end % End if strcmp

    end % End for loop

    % Initiating data_cell (1. Subject ID, 2. Date, 3. Stim Name, 4. Condition List 5. Block
    % Number, 6. Matching Flags, 7. RT, 8. Block mean RT, 9. Block Acc.,
    % 10. Presentation time, 11. Start of Summary)
    RT_col = 7;
    prestime_col = 10;
    data_cell = cell([length(pres_ind) 11]);

    % Fill data_cell columns
    [data_cell{:,1}] = deal(subj_id);
    [data_cell{:,2}] = deal(subj_date);

    % Pull stim name from different columns depending on dynamic stim or
    % not
    if isfield(params(s),'dynFlag')
        data_cell(:,3) = exp_cell(pres_ind, 1);
    else
        data_cell(:,3) = exp_cell(pres_ind, 2);
    end

    data_cell(:,4:6) = exp_cell(pres_ind, 4:6); 

    % Preallocating reaction time vector
    RT_exp = zeros([length(exp_cell) 1]);

    mkdir([file_dir filesep 'data' filesep 'backup_' data_str]) % Backup directory
    
    %cell2csv([file_dir filesep 'data' filesep 'backup_' data_str filesep data_str '.csv'],data_cell,',');
    save([file_dir filesep 'data' filesep 'backup_' data_str filesep 'vars.mat'],'RT_exp','pres_time','pres_ind','data_cell','block_order_1d','RT_col','dat','stat','prestime_col','data_str')
    %csvwrite([file_dir filesep 'data' filesep 'backup_' data_str filesep 'RT.csv'],'w'); % Write csv
    fRT = fopen([file_dir filesep 'data' filesep 'backup_' data_str filesep 'RT.csv'],'w');

    %% Cell 4 end

    %% Cell 5: Procedural display

    trig_flag = questdlg('Use trigger from scanner?'); % Ask for auto-trigger

    switch trig_flag
        case 'Yes'
            trig_flag = 1;

%             if ispc
%                 % Starting MCC_dio
%                 if( trig_flag )
%                     MCC_dio = digitalio( 'mcc' ,'0' );
%                     addline( MCC_dio, 0, 0, 'in' );
%                     start( MCC_dio );
%                 end % END - if( trig_flag )
%             elseif ismac
%                 DAQdeviceIndex = DaqFind;
%             end

        case 'No'
            trig_flag = 0;
        case 'Cancel'
            return;
    end % End switch

    try % Starting try loop

        % ---------- Window Setup ---------

        % Hides the mouse cursor and ListenChar
        HideCursor;
        ListenChar(2);

        % ***** This shortens SyncTest Screen.  Double check this. *****
        %Screen('Preference', 'SkipSyncTests', 1); %Uncomment to fix display issues

        % Opens a graphics window on the main monitor (screen 0).  If you have
        % multiple monitors connected to your computer, then you can specify
        % a different monitor by supplying a different number in the second
        % argument to OpenWindow, e.g. Screen('OpenWindow', 2).

        monitor.display_window = Screen('OpenWindow', monitor.whichScreen, monitor.gray, [] , 32, 2); % *** Trusting old params ***

        Screen('BlendFunction', monitor.display_window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        Screen('TextSize',monitor.display_window,18);
        Screen('TextFont',monitor.display_window,'Helvetica');
        Screen('TextStyle',monitor.display_window,0);

        %tic;
        if( trig_flag ) % If using auto-trigger
            Screen('FillRect', monitor.display_window, monitor.gray);
            instruct_ptr = Screen('MakeTexture', monitor.display_window, instruct); % Read from exp_cell
            Screen('DrawTexture', monitor.display_window, instruct_ptr);
    %         DrawFormattedText(monitor.display_window,'Waiting for trigger','center', 'center', monitor.black);
            Screen( 'Flip', monitor.display_window  );

            RestrictKeysForKbCheck(tkey);
            %KbStrokeWait(trigdevice);
            %RestrictKeysForKbCheck([]);
            
            KbStrokeWait;
            
            
%             if ispc
%                 while(  ~getvalue( MCC_dio )  ) % Wait for trigger
%                 end % END - while(  ~getvalue( MCC_dio )  )
%             elseif ismac
%                 while DaqDIn(DAQdeviceIndex,1) == 254 % Wait for trigger
%                 end
%             end

        else % Manual

            Screen('FillRect', monitor.display_window, monitor.gray);
            DrawFormattedText(monitor.display_window,'Waiting for scanner operator to press spacebar','center', 'center', monitor.black);
            Screen( 'Flip', monitor.display_window  );

            KbStrokeWait(laptopdevice);

    %         DrawFormattedText(monitor.display_window,'Pressed! 4.75s manual delay','center', 'center', monitor.black);
    %         Screen( 'Flip', monitor.display_window  );

            Screen('FillRect', monitor.display_window, monitor.gray);
            instruct_ptr = Screen('MakeTexture', monitor.display_window, instruct); % Read from exp_cell
            Screen('DrawTexture', monitor.display_window, instruct_ptr);  
            Screen( 'Flip', monitor.display_window  );

            if strcmp(params(s).TaskName,'MVPA')
                trwait = 6.75; % Additional 2 sec TR pulse for GRAPPA
            else
                trwait = 4.75; % 2 2sec TR pulse wait + .75 computer delay
            end
            
            WaitSecs(trwait); 

        end % END - if( trig_flag )
        %toc;

        start_t = GetSecs;

        %--------------Initial fixation screen (21 seconds)--------------%  

        fix_ptr = Screen('MakeTexture', monitor.display_window, fix_pic{1});
        Screen('DrawTexture', monitor.display_window, fix_ptr);
        Screen('Flip', monitor.display_window);
        %pres_time(1,1:2) = GetSecs - start_t; % Eval purposes

        %---------------- Presentation Sequence ---------------------------%

        % For loop to run through presentation cell
        for i = 1:length(exp_cell)

            if t_list(i,3) == 1 % If movie flag is 1

                wakeup = WaitSecs('UntilTime',start_t + t_list(i,1)); % Wait until movie start time
                PlayMovie(exp_cell{i,2}, monitor); % Display Movie, output vbl flip for initial frame

                % Time stamp for movie start
                pres_time(i,1) = wakeup - start_t;

            elseif t_list(i,3) == 0 % If movie flag is 0

                img_ptr = Screen('MakeTexture', monitor.display_window, exp_cell{i,1}); % Read from exp_cell
                Screen('DrawTexture', monitor.display_window, img_ptr);
                [~, ~, t1, ~] = Screen('Flip', monitor.display_window, start_t + t_list(i,1)); % Display at corresponding time point

                if t_list(i,2) == 1 % If recording flag is 1

                    while GetSecs < (start_t + (t_list(i+1) - .05)) % While the current time is less than the start time plus the next presentation time (giving .05s leeway)

                        if resp_flag == 0 % If response flag is 0

                            [~, secs, keyCode] = KbCheck([gripdevice laptopdevice]); % Start keyboard recording
                            if keyCode(c_key) % If the 'c' key is pressed
                                %fprintf('%d, %d, %d, %d\n', i, t_list(i),t_list(i+1), secs - t1) % Screen print
                                RT_exp(i) = (secs - t1); % Record reaction time into RT_exp
                                fprintf(fRT, '%d,%1.5f\n', i, RT_exp(i)); % Write to backup
                                resp_flag = 1; % Change response flag to 1
                            elseif keyCode(esc_key) % If the 'esc' key is pressed
                                esc_flag = 1;                           
                            end % End if statement
                        end % End resp_flag if statement

                     end % End current time check statement

                    % Resetting response flag to 0
                    resp_flag = 0;

                end % End recording flag if statement

                Screen('Close', img_ptr) % Closing image pointer

                % Timing vector
                pres_time(i,1) = t1 - start_t;

            end % End if: t_list(i,3) == 1

            %pres_time(i,2) = sum(pres_time(:,1)); % *** Double Check ***

            % Break if escape is hit
            if esc_flag == 1;
                break;
            end % End if: esc_flag = 1

        end % End for: i = 1:length(exp_cell)

        % Final fixation wait if no escape
        if esc_flag ~= 1;
            WaitSecs(params(s).TaskFinFix); 
        end

        % ---------- Window Cleanup ---------- 

        % Closes all windows.
        Screen('CloseAll');

        % Restores the mouse cursor and MatLab command input.
        ShowCursor;
        ListenChar(0);

        % Restore preferences
        Screen('Preference', 'VisualDebugLevel', monitor.oldVisualDebugLevel);
        Screen('Preference', 'SuppressAllWarnings', monitor.oldSupressAllWarnings);
        Screen('Preference', 'SkipSyncTests', monitor.oldEnableFlag);
% 
%         if( trig_flag )
%             if ispc
%                 stop( MCC_dio );
%                 delete( MCC_dio )
%                 clear MCC_dio 
%             end
%         end % END - if( trig_flag )

    catch exception

        % ---------- Error Handling ---------- 
        % If there is an error in our code, we will end up here.

        % The try-catch block ensures that Screen will restore the display and return us
        % to the MATLAB prompt even if there is an error in our code.  Without this try-catch
        % block, Screen could still have control of the display when MATLAB throws an error, in
        % which case the user will not see the MATLAB prompt.
        Screen('CloseAll');

        % Restores the mouse cursor and MatLab command input.
        ShowCursor;
        ListenChar(0);

        % Restore preferences
        Screen('Preference', 'VisualDebugLevel', monitor.oldVisualDebugLevel);
        Screen('Preference', 'SuppressAllWarnings', monitor.oldSupressAllWarnings);
        Screen('Preference', 'SkipSyncTests', monitor.oldEnableFlag);

%         if( trig_flag )
%             if ispc
%                 stop( MCC_dio );
%                 delete( MCC_dio )
%                 clear MCC_dio 
%             end
%         end % END - if( trig_flag )

        rethrow(exception)% Catch for try loop

        % We throw the error again so the user sees the error description.
        %psychrethrow(psychlasterror);

    end % End try loop
    %% Cell 5 end

end
    
%% Cell 6 Data Formatting and Calculations 

if backupflag % If backing up
    
    for backup_ind = 1:(size(RT_backup,1))
        RT_exp(RT_backup(backup_ind,1)) = RT_backup(backup_ind,2); 
    end

end

RT_data = RT_exp(pres_ind); % Formatted RT_exp for data_cell
prestime_data = pres_time(pres_ind,1); % Formatted presentation times for data_cell
MF_data = cell2mat(data_cell(:,6)); % Matching flags as matrix

for i = 1:length(block_order_1d) % For the length of blocks

    block_mat = cell2mat(data_cell(:,5)) == i; % Corresponding block index matrix
    block_i = find(block_mat); % Block indices
    blockRT = RT_data(block_mat); % Block RT vector
    meanRT = mean(blockRT(all(blockRT,2))); % Block Mean RT (non-zero only)
    % Accuracy calculated as sum of recorded responses that correspond
    % with matching flags divided by total length of the block
    acc = sum(MF_data(block_mat) == (RT_data(block_mat) > 0)) / length(find(block_mat));         
    
    % For indices within this block
    for j = block_i(1):block_i(end)
        
        data_cell{j,RT_col} = RT_data(j); % Input RT data into data_cell
        data_cell{j,prestime_col} = prestime_data(j); % Input presentation times into data_cell
        
        % If last index
        if j == block_i(end)
            
            % Placing meanRT and acc in two addition columns (7. Mean RT, 8. Accuracy) at end of block
            data_cell{j, 8} = meanRT;
            data_cell{j, 9} = acc;
            
            % Adding condition and list number to dat data structure
            dat(i) = regexp(data_cell{j, 4}, '(?<Condition>\D*)(?<Number>\d*)', 'names');
            
        end % End if
        
    end % End for loop for RT and acc entry
    
    % Adding meanRT and accuracy to stat data structure
    stat(i).meanRT = meanRT;
    stat(i).acc = acc;

end % End for loop

% Shifting everything a row down
[data_cell{end+1,:}] = deal(0);
data_cell(2:end,:) = data_cell(1:end-1,:);

% Adding labels
data_cell{1,1} = 'SubjectID';
data_cell{1,2} = 'Date'; 
data_cell{1,3} = 'StimName';
data_cell{1,4} = 'Condition';
data_cell{1,5} = 'BlockNumber';
data_cell{1,6} = 'MatchingFlag';
data_cell{1,7} = 'RT';
data_cell{1,8} = 'BlockRT';
data_cell{1,9} = 'BlockAcc';
data_cell{1,10} = 'PresTime';
data_cell{1, 11} = 'Summary';
data_cell{2, 11} = 'MeanRT';
data_cell{3, 11} = 'Accuracy';

% Condition statistics
cond_list = {dat.Condition}; % All conditions in order
cond_type = unique(cond_list); % Unique conditions

% For each unique condition
for i = 1:length(cond_type)
    cond_log = cellfun(@(x)(strcmp(x,cond_type{i})),cond_list); % Logicals under specified condition
    cond_mean = nanmean([stat(cond_log).meanRT]); % Condition mean (without NaN)
    cond_acc = mean([stat(cond_log).acc]); % Condition accuracy
    
    % Data_cell input (appends)
    data_cell{1,end+1} = cond_type{i};
    data_cell{2,end} = cond_mean;
    data_cell{3,end} = cond_acc;
    
end % End for loop

% File write
cell2csv([file_dir filesep 'data' filesep data_str '.csv'],data_cell,',');

%% Cell 6 end

end % End primary function