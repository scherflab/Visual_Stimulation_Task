function prtmaker(fid,params,s2,t_list,exp_cell)

% User prompt
prompt1 = {'TR:', 'Dropped TRs:'};
dlg_title1 = 'Analysis parameters?';    
num_lines1 = 1;
def1 = {'2', '4'}; % Default TR = 2, Skipped TRs = 2
options.Resize = 'on';
timeset = inputdlg(prompt1, dlg_title1, num_lines1, def1, options);
TR = str2double(timeset{1});
skipTR = str2double(timeset{2});

% Beginning stuff
fprintf(fid,'\n');
fprintf(fid,'FileVersion:        2\n');
fprintf(fid,'\n');
fprintf(fid,'ResolutionOfTime:   Volumes\n');
fprintf(fid,'\n');
fprintf(fid,'Experiment:         %s\n',[params.TaskName '_' params.Alt{s2}]);
fprintf(fid,'\n');
fprintf(fid,'BackgroundColor:    0 0 0\n');
fprintf(fid,'TextColor:          255 255 255\n');
fprintf(fid,'TimeCourseColor:    255 255 255\n');
fprintf(fid,'TimeCourseThick:    2\n');
fprintf(fid,'ReferenceFuncColor: 0 0 80\n');
fprintf(fid,'ReferenceFuncThick: 2\n');
fprintf(fid,'\n');
fprintf(fid,'NrOfConditions:  %d\n',params.CondNum+1); % Condition number + 1 (patterns)
fprintf(fid,'\n');

% Adjust TR list (Adding one, TR 1 starts at 0)
TR_list = (t_list(:,1)/TR) + 1 - (skipTR); 

% Unique categories in task
catlist = cellfun(@(cat2)(cat2(cat2~=' ')),unique(cellfun(@(cat)(regexp(cat,'\D*','match')),unique(exp_cell(:,4)))),'UniformOutput',false);

% Preallocate
cellfun(@(cat3)(eval(['category.' cat3 '=[];'])),catlist,'UniformOutput',false)

% Order categories
perm = 1:length(catlist);
% perm(strcmp(fieldnames(category),'FixationCross'))=length(catlist); % Fixation Cross is last
% perm(length(catlist)) = find(strcmp(fieldnames(category),'FixationCross'));
perm(strcmp(fieldnames(category),'Pattern'))=1; % Pattern is first
perm(1) = find(strcmp(fieldnames(category),'Pattern'));
category = orderfields(category,perm);

category.FixationCross = [category.FixationCross; 1 TR_list(1)-1]; % Adding beginning TRs

temp_old = [];
catTR = [];

% For each TR integer, starting from first non-skipped and ending before
% final fixation (first and last fixations will be added later)

if isfield(params,'dynFlag') % If movie presentation
    i = TR_list(1):TR_list(end); 
else
    i = TR_list(1):TR_list(end-1); 
end
    
for i = i
    
    if ~isempty(find(TR_list==i, 1))
        
        temp = exp_cell{TR_list==i,4}; % Category name
        %temp = exp_cell{i,4}; % Category name 
        
        % Check if block name changed
        if ~strcmp(temp_old, temp)
            
            % If not first iteration
            if i ~= TR_list(1) 
                
                if catTR(1)==catTR(end)
                    catTR = [catTR i-1];
                end
                
                category.(cat_temp(cat_temp~=' ')) = [category.(cat_temp(cat_temp~=' ')); catTR(1) catTR(end)]; % On change of category type, append to structure
            end
            
            % Reset category, create structure field name, and start index
            temp_old = temp;
            cat_temp = regexp(exp_cell{TR_list==i,4},'\D*','match'); % Removing number
            cat_temp = cat_temp{1}; % Change to string
            catTR = i;
        
        else
            
            catTR = [catTR i]; % Add to catTR
            
        end
        
    else % If no index
        
        catTR = [catTR i]; % Add to catTR
        
    end % End if: ~isempty(find(TR_list==i, 1))
    
end % End for: i = TR_list(1):TR_list(end-1) 

if ~isfield(params,'dynFlag') % If not movie presentation
    category.(cat_temp(cat_temp~=' ')) = [category.(cat_temp(cat_temp~=' ')); catTR(1) catTR(end)]; % Last category append to structure
end

category.FixationCross = [category.FixationCross; TR_list(end) TR_list(end)+(params.TaskFinFix/2)-1]; % Adding end TRs (Last TR is subtracted by one because it is TR start, rather than duration end)

% [category.Blank] = category.FixationCross; % Change to Blank
% category = rmfield(category,'FixationCross'); % Remove FixationCross

fnames = fieldnames(category); % Field names

% For each field in category structure
for ii = 1:length(fnames)
    
    fprintf(fid,'%s\n',params.fnames{ii,1}); % Category name
    index = strcmp(params.fnames{ii,2},fnames); % Index
    fprintf(fid,'%d\n',size(category.(fnames{index}),1)); % Number of presentations
    
    for iii = 1:size(category.(fnames{index}),1) % For number of presentations
        
        fprintf(fid,'   %d %d\n', category.(fnames{index})(iii,1), category.(fnames{index})(iii,2)); % Print each TR
    
    end % End for: iii = 1:length(size(category.(fnames{ii}),1))
    
    fprintf(fid,'Color: %d %d %d\n', params.fnames{ii,3}(1), params.fnames{ii,3}(2), params.fnames{ii,3}(3)); % Enter color
    fprintf(fid,'\n');
    
end % End for: ii = 1:length(fieldnames(category))