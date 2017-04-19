function [t_list] = t_calc(params)

% 4/2/12
% Ken Hwang
% Scherf Lab, SLEIC, PSU
%
% Function for presentation timing production depending on project
% 
% Input: params (parameter file)
% Output: t_list (vector of time points)
%
% If movie presentation:
% Amount of presentations Initial fixation + # Patterns (# Movies + # Fixation) * # of
% Conditions + Final Fixation
%
% If image presentation:
% Amount of presentations Initial fixation + # Patterns + (# Images + # Fixation) * #
% Conditions * # Lists  + Final fixation

if isfield(params,'dynFlag') % If movie presentation
    presNum = ((params.ImgNum*2) * params.CondNum * params.ListNum) + params.PatternNum + 1; % Assuming each list only has 1 movie
elseif strcmpi(params.TaskName,'KateTask')==1
    presNum = ((params.ImgNum + (params.ImgNum + 1)) * params.CondNum * params.ListNum) + params.PatternNum + 1;
else
    presNum = ((params.ImgNum + (params.ImgNum + 1)) * params.CondNum * params.ListNum) + params.PatternNum + 1;
end % End if: isfield(params,'dynFlag')

% Preallocating: first column is for time points , second column is for
% recording flags, third is for movie presentation
t_list = zeros([presNum 3]);

% Time points for pattern presentations (And first fixation)
t_list(1:(params.PatternNum + 1),1) = params.InitFix:(params.InitFix+params.PatternNum);

if isfield(params,'dynFlag') % If movie presentation
    
    % Calculating time points for params.ListNum blocks
    for i = 1:(params.CondNum*params.ListNum)
    
        % Finding the last entry and adding one
        t_ind = find(t_list(:,1), 1, 'last') + 1;
        
        % If first iteration
        if i == 1
            t_list(t_ind,1) = (t_list(find(t_list(:,1), 1, 'last')) + params.FirstBlockFix); % Movie presentation
            t_list(t_ind,3) = 1; % Movie flag
            t_list((t_ind + params.ImgNum),1) = ((t_list(find(t_list(:,1), 1, 'last')) + params.MovDuration)); % Fixation Presentation
            t_list((t_ind + params.ImgNum),3) = 0; % No movie flag
        else
            t_list(t_ind,1) = (t_list(find(t_list(:,1), 1, 'last')) + params.BlockFinFix); % Movie presentation
            t_list(t_ind,3) = 1; % Movie flag
            t_list((t_ind + params.ImgNum),1) = ((t_list(find(t_list(:,1), 1, 'last')) + params.MovDuration)); % Fixation Presentation
            t_list((t_ind + params.ImgNum),3) = 0; % No movie flag
        end
        
    end % End for: i = 1:(params.ListNum) 
    
    
elseif strcmpi(params.TaskName,'KateTask')==1
    
    % Calculating time points for params.CondNum*params.ListNum blocks
    for i = 1:(params.CondNum*params.ListNum)

        % Finding the last entry and adding one
        t_ind = find(t_list(:,1), 1, 'last') + 1;
        
        for j=0:2:20
            
            if j==0
                t_list(t_ind+j,1)=t_list(t_ind+j-1,1)+8;
                t_list(t_ind+j+1,1)=t_list(t_ind+j,1)+1;
            else
                t_list(t_ind+j,1)=t_list(t_ind+j-1,1)+1;
                t_list(t_ind+j+1,1)=t_list(t_ind+j,1)+.3;
            end
            
            
        end
        
    end
    
    
else % If image presentation
    
    % Calculating time points for params.CondNum*params.ListNum blocks
    for i = 1:(params.CondNum*params.ListNum)

        % Finding the last entry and adding one
        t_ind = find(t_list(:,1), 1, 'last') + 1;

        % Conditional statement for the first block (Timing only needs to
        % wait one second, where as the others will wait params.BlockFinFix).
        if i == 1

            % img_t corresponds with the (params.ImgNum + params.FirstBlockFix) presentation times (last is fixation) on the start
            % of the second by:
            % Finding last entry in t_list, and adding 1 (Adding params.FirstBlockFix only
            % pertains to Block 1), then creating (params.ImgNum + params.FirstBlockFix) time points in sequence at 1 second intervals.
            img_t(:,1) = (t_list(find(t_list(:,1), 1, 'last')) + params.FirstBlockFix):((t_list(find(t_list(:,1), 1, 'last')) + params.FirstBlockFix) + params.ImgNum);
            img_flags = ones([1 (params.ImgNum + 1)]); % Creating 1 flags
            img_flags(params.ImgNum + 1) = 0; % Last flag is 0 (fixation)
            img_t(:,2) = img_flags; % Appending img_flags to second column of img_t

            % fix_t corresponds with the 16 fixation presentation times on
            % the .8 of the second
            % Finding last entry in t_list, and adding (params.FirstBlockFix + .8) (Adding params.FirstBlockFix + .8 only
            % pertains to Block 1), then creating 12 time points in sequence at 1 second intervals.
            fix_t(:,1) = (t_list(find(t_list(:,1), 1, 'last')) + params.FirstBlockFix + .8):((t_list(find(t_list(:,1), 1, 'last')) + params.FirstBlockFix + .8) + (params.ImgNum - 1));
            fix_t(:,2) = zeros([1 params.ImgNum]); % Appending zeros to second row of fix_t

            % Adding (params.ImgNum + params.ImgNum + 1) sorted time entries (and corresponding flags) into t_list according to next open
            % space.
            t_set = [img_t; fix_t]; % Subset of time points created by img_t and fix_t
            [~, I] = sort(t_set); % Getting sorting indices, I(:,1) is associated with sorted time points
            t_set = t_set(I(:,1),:); % Applying sorting index to both columns of t_set
            t_list(t_ind:(t_ind+(2*params.ImgNum)),1:2) = t_set; % Filling open spots in t_list with t_set

        else

            % img_t corresponds with the (params.ImgNum + 1) presentation times (last is fixation) on the start
            % of the second by:
            % Finding last entry in t_list, and adding params.BlockFinFix (params.BlockFinFix second wait between last block's presentation time),
            % then creating (params.ImgNum + 1) time points in sequence at 1 second intervals.
            img_t(:,1) = (t_list(find(t_list(:,1), 1, 'last')) + params.BlockFinFix):((t_list(find(t_list(:,1), 1, 'last')) + params.BlockFinFix) + params.ImgNum);
            img_flags = ones([1 (params.ImgNum + 1)]); % Creating 1 flags
            img_flags(params.ImgNum + 1) = 0; % Last flag is 0 (fixation)
            img_t(:,2) = img_flags; % Appending img_flags to second column of img_t

            % fix_t corresponds with the params.BlockFinFix fixation presentation times on
            % the .8 of the second
            % Finding last entry in t_list, and adding params.BlockFinFix + .8 (Adding params.BlockFinFix + .8 only
            % pertains to Blocks after 1), then creating params.ImgNum time points in
            % sequence at 1 second intervals.
            fix_t(:,1) = (t_list(find(t_list(:,1), 1, 'last')) + params.BlockFinFix + .8):((t_list(find(t_list(:,1), 1, 'last')) + params.BlockFinFix + .8) + (params.ImgNum - 1));
            fix_t(:,2) = zeros([1 params.ImgNum]); % Appending zeros to second row of fix_t

            % Adding (params.ImgNum + params.ImgNum + 1) sorted time entries (and corresponding flags) into t_list according to next open
            % space.
            t_set = [img_t; fix_t]; % Subset of time points created by img_t and fix_t
            [~, I] = sort(t_set); % Getting sorting indices, I(:,1) is associated with sorted time points
            t_set = t_set(I(:,1),:); % Applying sorting index to both columns of t_set
            t_list(t_ind:(t_ind+(2*params.ImgNum)),1:2) = t_set; % Filling open spots in t_list with t_set

        end % End if statement
    
    end % End for loop
    
end % End if: isfield(params,'dynFlag')

end % End primary function
