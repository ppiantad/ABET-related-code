function [data, ABETdata, Descriptives, block_end, largeRewSide, smallRewSide, forced_trial_start, free_trial_start] = ABET2TableFn_Chamber_A_v6(filename, dummy)


%ABET2Table creates a table with columns (outlined under "column headers"
%comment) from ABET behavioral data "filename"

%ABET file should be either Raw data, or reduced data so long as all
%relevant events are included
%input variable should be the file name, written in single quotation marks.
% 3/29/2020: Updated the omission filtering such that it can now also be
% filtered by Block or by Type (Force/Free)

% Added "TrialPossible" which looks for TTL#1 (or whatever it is named,
% redo this if there are multiple TTL#s), which indicates the increment of
% every new trial (and when ABET sends a TTL to the Inscopix system)

%initiate table

%column headers
% (1)Trial: trial number
% (2)Block: 1,2,3,4, or 5
% (3)Force/Free: 0 if free, 1 if force
% (4)big/small:
% (5)stTime: trial start time
% (6)choicetime: timestamp of choice 
% (7)collection time: timestamp of reward collection
% (8)shock: 0 if no shock, 1 if shock
% (9)omission: 0 if false, 1 if free trial omission, 2 if forced trial
% (10) omissionALL: 1 for omissions, can now also filter by Block and
% Force/Free
% (11)WL: 1 if win; 3 if loss
% (12)WSLScode: 2 if win+1; 4 if loss+1;
% (13)win_stay: 1 for large/risky choice trials following a large/risky
% choice with no punishment ("win)
% (14)lose_shift: 1 for safe choice trials following a large/risky choice
% with punishment ("loss")
% (15)lose_omit: 1 for omissions following a large/risky choice with
% punishment ("loss")
% (16)smallRew: total FREE CHOICE smallRew trials
% (17)bigRew: total FREE CHOICE bigRew trials
% (18)Blank_Touch: 1 for large screen touches, 2 for small screen touches.
% filter on forced choice to get within-trial touches, anything else is by
% default occuring during the ITI (when screens are blank!)

[~,~,ABETdata]=xlsread(filename);

Headers={'Trial','Block','ForceFree','bigSmall','RewSelection','TrialPossible','stTime','choiceTime'...
    'collectionTime','shock','omission','omissionALL','WL','WSLScode','win_stay','lose_shift','lose_omit','lose_stay','smallRew','bigRew', 'Blank_Touch'};
data=table(zeros(80,1),zeros(80,1),zeros(80,1),zeros(80,1),zeros(80,1),zeros(80,1),zeros(80,1),zeros(80,1),zeros(80,1),zeros(80,1),zeros(80,1),zeros(80,1),zeros(80,1),zeros(80,1),zeros(80,1),zeros(80,1),zeros(80,1),zeros(80,1), zeros(80,1), zeros(80,1), zeros(80,1));
data.Properties.VariableNames([1:21])=Headers;

%%
%add ABET data to table

%loop through all rows
[rows,~]=size(ABETdata);
trial=1;
blocks = 2;
block_end = [];
tbl_size = [];
currentLeftBlankCounter = 0;
currentRightBlankCounter = 0;
currentTrial = 0;
force_free_counter = 0;

forced_trials = [1:8, 31:38, 61:68];

%find the first nonzero timestamp (all timestamps at 0 are program checks,
%and we don't care about these when we're searching for behavioral events
stop=999; rr=2;
while stop>0
    startRow=rr;
    %report which side the mouse was assigned for large reward, which is
    %useful for assigning large/small aborts to BORIS data which is coded
    %as left/right alone. This data is used as an input to boris_to_table
    if regexp(ABETdata{rr,4},'Big_Grid_Position') & ABETdata{rr,9} == 2
        largeRewSide = 'right';
        smallRewSide = 'left';
    elseif regexp(ABETdata{rr,4},'Big_Grid_Position') & ABETdata{rr,9} == 1
        largeRewSide = 'left';
        smallRewSide = 'right';
    elseif ABETdata{rr,1}>0
        stop=-999;
    end
    rr=rr+1;
    
    
end

currBlock=1;

for ii=startRow:rows
    
    
    
    data.Trial(trial)=trial;
    
    %keep track of block
    if regexp(ABETdata{ii,4},'Session*')
        if ABETdata{ii,9}==1
            whichBlock=regexp(ABETdata{ii,4},'n','split'); %pull block from "SX-Free...=big" or similar name
            currBlock=str2num(whichBlock{2});

        end
        
    end
    
    data.Block(trial)=currBlock;
    
    %this was added to add Blocks to BORIS data. Plan to add a check for
    %the BORIS timestamp for an Approach/Abort, to see if the value is <
    %block_end(1,1), which corresponds to Block 1, > block_end(1,1) and <
    %block_end(1,2), which corredsponds to Block 2, and > block_end(1,2),
    %which corresponds to Block 3
    if blocks == 2 &&  data.Block(trial) == 2
        block_end(1,1) = ABETdata{ii,1};
        blocks = blocks + 1;
    elseif blocks == 3 &&  data.Block(trial) == 3
        block_end(1,2) = ABETdata{ii,1};
        blocks = blocks + 1;
    end
    

    %forced_free_indices
    if contains(ABETdata{ii,4}, 'Begin', 'IgnoreCase', true)
        force_free_counter = force_free_counter + 1;
        force_free_timestamps(force_free_counter, 1) = ABETdata{ii,1};
        %force or free?
        if contains(ABETdata{ii,4}, 'Free', 'IgnoreCase', true)
            force_free_timestamps(force_free_counter, 2)=0;
        elseif contains(ABETdata{ii,4}, 'Forced', 'IgnoreCase', true)
            force_free_timestamps(force_free_counter, 2)=1;
        end
        
    end

    %COLLECTION TIME
    %because I increment the trial based on feeder, add each
    %reward retrieved to the previous trial
    if regexp(ABETdata{ii,4},'Reward Retrieved*')
        data.collectionTime(trial-1)=ABETdata{ii,1};
    end
    
    %TrialStart
    if regexp(ABETdata{ii,4},'\w*Trials Begin','ignorecase')
        data.stTime(trial)=ABETdata{ii,1};
    end
    
    if regexp(ABETdata{ii,4},'TTL\w*')
        data.TrialPossible(trial)=ABETdata{ii,1};
    end
                
    %CHOICE TIME
    %if it's a choice
    if ABETdata{ii,2}==1 && ~ischar(ABETdata{ii,6})
        if ((ABETdata{ii,6}==9) || (ABETdata{ii,6}==12))
            if regexp(ABETdata{ii,4},'S*')
                touch=regexp(ABETdata{ii,4},'-','split');
              
                
                
                %force or free?
                if strcmp(touch{2},'Free')
                    data.ForceFree(trial)=0;
                elseif strcmp(touch{2},'Forced')
                    data.ForceFree(trial)=1;
                end
                
                %choice time
                data.choiceTime(trial)=ABETdata{ii,1};
                

            end
            
        end
        
         
    end
    
    %REWARD DELIVERY
    %if it's feeder, store delivery duration in bigSmall column, then
    %increment trial by 1
    %5/5/2021
    %added some details because for some mice the SMALL REW was 0.3 or
    %0.5s, depending on how fast the particular feeder spun. To make it
    %easier to work with, I'm converting all 0.5s to 0.3 (so that
    %TrialFilter etc. continues to work without being re-written)
    %10/18/2022: Changed to regexp to recognize Feeder #, because the B
    %chambers use "Feeder 1" whereas A and C use "Feeder 2". If this is
    %inconsistent, or if both feeders are used, this could cause problems
    if regexp(ABETdata{ii,4},'Feeder #*')
        data.bigSmall(trial)=ABETdata{ii,9};
        if data.bigSmall(trial) == 0.5 || data.bigSmall(trial) == 0.4
            data.bigSmall(trial) = 0.3;
            %         elseif data.bigSmall(trial) == 0.3 || 0.5
            %             data.RewSelection(trial) = 2;
        end
    end
    
%     if strcmp(ABETdata{ii,4},'Feeder #1')
%         data.bigSmall(trial)=ABETdata{ii,9};
%         if data.bigSmall(trial) == 0.5
%             data.bigSmall(trial) = 0.3;
% %         elseif data.bigSmall(trial) == 0.3 || 0.5
% %             data.RewSelection(trial) = 2;
%         end
%     end
    
    
    %if there's a shock
    %if there's a shock, the shock is recorded as happening after the most
    %recent reward delivery.  So,the trial counter will have already
    %incremeneted by 1.  In order to properly record the shock trial, set
    %shock to 1 on the nth trial, where n=trial-1.
    if strcmp(ABETdata{ii,4},'Shocker #1')
        data.shock(trial-1)=1;
        
    end
    
    
    
    if data.bigSmall(trial)~=0
        trial=trial+1;
        data.Trial(trial)=trial;
    end
    
    
    
    %if it's an omission --right now, omission trials aren't labeled within
    %their blocks.
%     if strcmp(ABETdata{ii,4},'freetrial_omission')
%         data.omission(trial)=1;
%         data.choiceTime(trial)=ABETdata{ii,1};
%         trial=trial+1;
%     elseif strcmp(ABETdata{ii,4},'forcedtrial_omission')
%         data.omission(trial)=2;
%         data.choiceTime(trial)=ABETdata{ii,1};
%         trial=trial+1;
%     end
    
    %if its an omission regardless of forced or free (has to be lowercase
    %because other indicators of omission are in uppercase)
%      if regexp(ABETdata{ii,4},'\w*omission')
%         data.omissionALL(trial)=1;
%         data.choiceTime(trial)=ABETdata{ii,1};
%         omits=regexp(ABETdata{7502,4},'_','split');
%         trial=trial+1;
%      end

    
    if regexp(ABETdata{ii,4},'Omission of a*')
        data.omissionALL(trial)=1;
        data.bigSmall(trial)=999;
        data.choiceTime(trial)=ABETdata{ii,1};
        omit_str=regexp(ABETdata{ii,4},' ','split');
        
         %force or free?
                if strcmp(omit_str{4},'Free')
                    data.ForceFree(trial)=0;
                elseif strcmp(omit_str{4},'Forced')
                    data.ForceFree(trial)=1;
                end
%         if blocks == 2 && currBlock == 2
%             block_end(1,1) = data.choiceTime(trial);
%             blocks = blocks + 1;
%         elseif blocks == 3 && currBlock == 3
%             block_end(1,2) = data.choiceTime(trial);
%         end
   
            
        trial=trial+1;
    end
    % keep track of which "real" trial we are on - this is a maximum of 91 

    if regexp(ABETdata{ii,4},'_Trial_Counter')
        currentTrial = currentTrial + 1;
    end

    % keep track of which side is blank, so that we can then accurately say
    % which blank screen was touched below! 

    if regexp(ABETdata{ii,4},'Blank Left')
        currentBlank = 'left';
        currentLeftBlankCounter = currentLeftBlankCounter + 1;
    elseif regexp(ABETdata{ii,4},'Blank Right')
        currentBlank = 'right';
        currentRightBlankCounter = currentRightBlankCounter + 1;
    end
        
    %continue to edit me to collect blank side touches
    if regexp(ABETdata{ii,4},'LeftBlank_touch_during_ITI|RightBlank_touch_during_ITI')
        data.ForceFree(trial)=999;
        data.bigSmall(trial)=999;
        data.choiceTime(trial)=ABETdata{ii,1};
        blank_touch_str=lower(regexp(ABETdata{ii,4},'Blank','split'));
        if strcmp(blank_touch_str{1}, largeRewSide)
            data.Blank_Touch(trial)=1; % large
        elseif strcmp(blank_touch_str{1}, smallRewSide)
            data.Blank_Touch(trial)=2; % small
        end
        % if ismember(currentTrial, forced_trials)
        %     data.ForceFree(trial)=1;
        % elseif ~ismember(currentTrial, forced_trials)
        %     data.ForceFree(trial)=0;
        % end
        trial=trial+1;
    end

    %continue to edit me to collect blank side touches
    if regexp(ABETdata{ii,4},'Forced-blank=touch')
        data.ForceFree(trial)=1;
        data.bigSmall(trial)=999;
        data.choiceTime(trial)=ABETdata{ii,1};
        
        if strcmp(currentBlank, largeRewSide)
            data.Blank_Touch(trial)=1; % large screen
        elseif strcmp(currentBlank, smallRewSide)
            data.Blank_Touch(trial)=2; % small screen
        end
        % if ismember(currentTrial, forced_trials)
        %     data.ForceFree(trial)=1;
        % elseif ~ismember(currentTrial, forced_trials)
        %     data.ForceFree(trial)=0;
        % end
        trial=trial+1;
    end




end

%Last "Trial" in data table is not a complete trial - delete this trial
%from table
data(max(data.Trial),:) = [];

%add win stay/lose shift info.  To do this, add a column for
%win-stay/lose-shift code, called WSLS code.  For this code,
% if trial is a win, code=1;
% if trial is the trial after a win, code=2;
% if trial is a loss, code=3;
% if trial is a trial after a loss, code=4;
% added 10/21/2023    
% Sometimes garbage columns get added at the end with no Trial #. Delete these columns 
% Find the index of the first occurrence of 0 in the 'Trial' column
% Find the indices where 'Trial' is 0
zero_indices = find(data.Trial == 0);
% 
if ~isempty(zero_indices)
    % Remove the rows where 'Trial' is 0
    data(zero_indices, :) = [];
end

dummy_table_for_WSLS = data(data.ForceFree ~= 999,:);

% choice_lat = [];
for jj=1: numel(dummy_table_for_WSLS.Trial)

    if dummy_table_for_WSLS.omission(jj)==0
%         choice_lat(jj,:) = [choice_lat, data.collectionTime(jj) - data.choiceTime(jj)];
        if dummy_table_for_WSLS.bigSmall(jj)== 1.2 && dummy_table_for_WSLS.ForceFree(jj)==0 %if data.bigSmall(jj)==1.2 && data.ForceFree(jj)==0
            data.bigRew(dummy_table_for_WSLS.Trial(jj))=1;
            if dummy_table_for_WSLS.shock(jj)==0
                data.WL(dummy_table_for_WSLS.Trial(jj))=1; %win
            elseif dummy_table_for_WSLS.shock(jj)==1
                data.WL(dummy_table_for_WSLS.Trial(jj))=3; %loss
            end
        end
        if dummy_table_for_WSLS.bigSmall(jj)== 0.3 && dummy_table_for_WSLS.ForceFree(jj)==0 %if data.bigSmall(jj)==0.3 && data.ForceFree(jj)==0 % || data.bigSmall(jj)==0.5
                   data.smallRew(dummy_table_for_WSLS.Trial(jj))=1;       
        end
        if jj>1
            if data.WL(dummy_table_for_WSLS.Trial(jj-1))==1
                data.WSLScode(dummy_table_for_WSLS.Trial(jj))=2; %win+1 trial
                if dummy_table_for_WSLS.bigSmall(jj)== 1.2 && dummy_table_for_WSLS.ForceFree(jj)==0 %if data.bigSmall(jj)==1.2 && data.ForceFree(jj)==0
                    data.win_stay(dummy_table_for_WSLS.Trial(jj))=1; %win_stay is 1 if chose big after a win
                end
                
            elseif data.WL(dummy_table_for_WSLS.Trial(jj-1))==3
                data.WSLScode(dummy_table_for_WSLS.Trial(jj))=4; %loss+1 trial
               if dummy_table_for_WSLS.bigSmall(jj) == 0.3 && dummy_table_for_WSLS.ForceFree(jj)==0 %if data.bigSmall(jj)==0.3 && data.ForceFree(jj)==0
                   data.lose_shift(dummy_table_for_WSLS.Trial(jj))=1;
               elseif dummy_table_for_WSLS.bigSmall(jj) == 1.2 && dummy_table_for_WSLS.ForceFree(jj)==0 %if data.bigSmall(jj)==0.3 && data.ForceFree(jj)==0
                   data.lose_stay(dummy_table_for_WSLS.Trial(jj))=1;
               elseif dummy_table_for_WSLS.omissionALL(jj)==1
                   data.lose_omit(dummy_table_for_WSLS.Trial(jj))=1;
               end
            
            end
        end
        
        
    end



end


collect_lat_b1 = [];
collect_lat_b2 = [];
collect_lat_b3 = [];

collect_lat_b1_free = [];
collect_lat_b2_free = [];
collect_lat_b3_free = [];

collect_lat_b1_forced = [];
collect_lat_b2_forced = [];
collect_lat_b3_forced = [];
for ii = 1: numel(data.Trial)
    %ignore omissions (no collectionTime) and the occasion where mice
    %don't finish the final trial (which leads to a massive diff b/w
    %choiceTime and collectionTime
    if data.omissionALL(ii)==0 && data.collectionTime(ii) ~= 0 && data.Blank_Touch(ii) == 0
        if data.Block(ii)==1
            collect_lat_b1 = [collect_lat_b1, (data.collectionTime(ii) - data.choiceTime(ii))];
            if data.ForceFree(ii)==0
                collect_lat_b1_free = [collect_lat_b1_free, (data.collectionTime(ii) - data.choiceTime(ii))];
            elseif data.ForceFree(ii)==1
                collect_lat_b1_forced = [collect_lat_b1_forced, (data.collectionTime(ii) - data.choiceTime(ii))];
            end
        elseif data.Block(ii)==2
            collect_lat_b2 = [collect_lat_b2, (data.collectionTime(ii) - data.choiceTime(ii))];
            if data.ForceFree(ii)==0
                collect_lat_b2_free = [collect_lat_b2_free, (data.collectionTime(ii) - data.choiceTime(ii))];
            elseif data.ForceFree(ii)==1
                collect_lat_b2_forced = [collect_lat_b2_forced, (data.collectionTime(ii) - data.choiceTime(ii))];
            end
        elseif data.Block(ii)==3
            collect_lat_b3 = [collect_lat_b3, (data.collectionTime(ii) - data.choiceTime(ii))];
            if data.ForceFree(ii)==0
                collect_lat_b3_free = [collect_lat_b3_free, (data.collectionTime(ii) - data.choiceTime(ii))];
            elseif data.ForceFree(ii)==1
                collect_lat_b3_forced = [collect_lat_b3_forced, (data.collectionTime(ii) - data.choiceTime(ii))];
            end
        end
    end
end


collect_lat_b1_large = [];
collect_lat_b2_large = [];
collect_lat_b3_large = [];

collect_lat_b1_small = [];
collect_lat_b2_small = [];
collect_lat_b3_small = [];


for ii = 1: numel(data.Trial)
    if data.omissionALL(ii)==0 && data.collectionTime(ii) ~= 0 && data.Blank_Touch(ii) == 0
        if data.bigSmall(ii) == 1.2
            if data.Block(ii)==1
                collect_lat_b1_large = [collect_lat_b1_large, (data.collectionTime(ii) - data.choiceTime(ii))];
            elseif data.Block(ii)==2
                collect_lat_b2_large = [collect_lat_b2_large, (data.collectionTime(ii) - data.choiceTime(ii))];
            elseif data.Block(ii)==3
                collect_lat_b3_large = [collect_lat_b3_large, (data.collectionTime(ii) - data.choiceTime(ii))];
            end
        elseif data.bigSmall(ii) == 0.3
            if data.Block(ii)==1
                collect_lat_b1_small = [collect_lat_b1_small, (data.collectionTime(ii) - data.choiceTime(ii))];
            elseif data.Block(ii)==2
                collect_lat_b2_small = [collect_lat_b2_small, (data.collectionTime(ii) - data.choiceTime(ii))];
            elseif data.Block(ii)==3
                collect_lat_b3_small = [collect_lat_b3_small, (data.collectionTime(ii) - data.choiceTime(ii))];
            end
        end
    end
end

% Initialize arrays to store the first time values
forced_trial_start = zeros(3, 1); % For strings of 1s
free_trial_start = zeros(3, 1); % For strings of 0s

% Loop through the data 
for i = 1:size(force_free_timestamps, 1)
    if i == 1
        forced_trial_start(1) = force_free_timestamps(i, 1);
    % Check if the current value in column 2 is different from the previous one
    elseif i > 1 && force_free_timestamps(i, 2) ~= force_free_timestamps(i-1, 2)
        if force_free_timestamps(i, 2) == 1
            % Store the first time for string of 1s
            forced_trial_start(sum(forced_trial_start ~= 0) + 1) = force_free_timestamps(i, 1);
        else
            % Store the first time for string of 0s
            free_trial_start(sum(free_trial_start ~= 0) + 1) = force_free_timestamps(i, 1);
        end
    end
end


block2_3_ind = data.Block(:)~=1;
Descriptives = table;
Descriptives.TotalWins = sum(data.WL(:)==1);
Descriptives.TotalLosses = sum(data.WL(:)==3);
Descriptives.RiskPercent = (sum(data.bigRew(:)==1)/(sum(data.bigRew)+(sum(data.smallRew))))*100;
Descriptives.TotalWinStay = sum(data.win_stay(:)==1);
Descriptives.TotalLoseShift = sum(data.lose_shift(:)==1);
Descriptives.TotalLoseOmit = sum(data.lose_omit(:)==1);
Descriptives.TotalLoseStay = sum(data.lose_stay(:)==1);
Descriptives.Block2_3_Wins = sum(data.WL(block2_3_ind)==1);
Descriptives.Block2_3_WinStay = sum(data.win_stay(block2_3_ind)==1);
Descriptives.Block2_3_WinStayPercent = Descriptives.Block2_3_WinStay / Descriptives.Block2_3_Wins;
Descriptives.WinStayPercent = Descriptives.TotalWinStay / Descriptives.TotalWins;
Descriptives.LoseShiftPercent = Descriptives.TotalLoseShift / Descriptives.TotalLosses;
Descriptives.LoseOmitPercent = Descriptives.TotalLoseOmit / Descriptives.TotalLosses;
Descriptives.LoseStaytPercent = Descriptives.TotalLoseStay / Descriptives.TotalLosses;

Descriptives.Block1_WinStay = sum(data.win_stay(data.Block(:)==1));
Descriptives.Block1_LoseShift = sum(data.lose_shift(data.Block(:)==1));
Descriptives.Block1_LoseOmit = sum(data.lose_omit(data.Block(:)==1));
Descriptives.Block1_LoseStay = sum(data.lose_stay(data.Block(:)==1));

Descriptives.Block2_WinStay = sum(data.win_stay(data.Block(:)==2));
Descriptives.Block2_LoseShift = sum(data.lose_shift(data.Block(:)==2));
Descriptives.Block2_LoseOmit = sum(data.lose_omit(data.Block(:)==2));
Descriptives.Block2_LoseStay = sum(data.lose_stay(data.Block(:)==2));

Descriptives.Block3_WinStay = sum(data.win_stay(data.Block(:)==3));
Descriptives.Block3_LoseShift = sum(data.lose_shift(data.Block(:)==3));
Descriptives.Block3_LoseOmit = sum(data.lose_omit(data.Block(:)==3));
Descriptives.Block3_LoseStay = sum(data.lose_stay(data.Block(:)==3));

Descriptives.Block1_WinStay_percent = sum(data.win_stay(data.Block(:)==1)) / Descriptives.TotalWins;
Descriptives.Block1_LoseShift_percent = sum(data.lose_shift(data.Block(:)==1)) / Descriptives.TotalLosses;
Descriptives.Block1_LoseOmit_percent = sum(data.lose_omit(data.Block(:)==1)) / Descriptives.TotalLosses;
Descriptives.Block1_LoseStay_percent = sum(data.lose_stay(data.Block(:)==1)) / Descriptives.TotalLosses;

Descriptives.Block2_WinStay_percent = sum(data.win_stay(data.Block(:)==2)) / Descriptives.TotalWins;
Descriptives.Block2_LoseShift_percent = sum(data.lose_shift(data.Block(:)==2)) / Descriptives.TotalLosses;
Descriptives.Block2_LoseOmit_percent = sum(data.lose_omit(data.Block(:)==2)) / Descriptives.TotalLosses;
Descriptives.Block2_LoseStay_percent = sum(data.lose_stay(data.Block(:)==2)) / Descriptives.TotalLosses;

Descriptives.Block3_WinStay_percent = sum(data.win_stay(data.Block(:)==3)) / Descriptives.TotalWins;
Descriptives.Block3_LoseShift_percent = sum(data.lose_shift(data.Block(:)==3)) / Descriptives.TotalLosses;
Descriptives.Block3_LoseOmit_percent = sum(data.lose_omit(data.Block(:)==3)) / Descriptives.TotalLosses;
Descriptives.Block3_LoseStay_percent = sum(data.lose_stay(data.Block(:)==3)) / Descriptives.TotalLosses;

Descriptives.B1_Collect_Lat = mean(collect_lat_b1);
Descriptives.B2_Collect_Lat = mean(collect_lat_b2);
Descriptives.B3_Collect_Lat = mean(collect_lat_b3);
Descriptives.B1_Collect_Lat_free = mean(collect_lat_b1_free);
Descriptives.B2_Collect_Lat_free = mean(collect_lat_b2_free);
Descriptives.B3_Collect_Lat_free = mean(collect_lat_b3_free);
Descriptives.B1_Collect_Lat_forced = mean(collect_lat_b1_forced);
Descriptives.B2_Collect_Lat_forced = mean(collect_lat_b2_forced);
Descriptives.B3_Collect_Lat_forced = mean(collect_lat_b3_forced);
Descriptives.B1_Collect_Lat_Large = mean(collect_lat_b1_large);
Descriptives.B2_Collect_Lat_Large = mean(collect_lat_b2_large);
Descriptives.B3_Collect_Lat_Large = mean(collect_lat_b3_large);
Descriptives.B1_Collect_Lat_Small = mean(collect_lat_b1_small);
Descriptives.B2_Collect_Lat_Small = mean(collect_lat_b2_small);
Descriptives.B3_Collect_Lat_Small = mean(collect_lat_b3_small);

Descriptives.B1_Blank_Touch_Large = sum(data.Blank_Touch == 1 & data.Block == 1);
Descriptives.B2_Blank_Touch_Large = sum(data.Blank_Touch == 1 & data.Block == 2);
Descriptives.B3_Blank_Touch_Large = sum(data.Blank_Touch == 1 & data.Block == 3);
Descriptives.B1_Blank_Touch_Small = sum(data.Blank_Touch == 2 & data.Block == 1);
Descriptives.B2_Blank_Touch_Small = sum(data.Blank_Touch == 2 & data.Block == 2);
Descriptives.B3_Blank_Touch_Small = sum(data.Blank_Touch == 2 & data.Block == 3);

Descriptives.B1_Blank_Touch_Large_forced = sum(data.Blank_Touch == 1 & data.Block == 1 & data.ForceFree == 1);
Descriptives.B2_Blank_Touch_Large_forced = sum(data.Blank_Touch == 1 & data.Block == 2 & data.ForceFree == 1);
Descriptives.B3_Blank_Touch_Large_forced = sum(data.Blank_Touch == 1 & data.Block == 3 & data.ForceFree == 1);
Descriptives.B1_Blank_Touch_Small_forced = sum(data.Blank_Touch == 2 & data.Block == 1 & data.ForceFree == 1);
Descriptives.B2_Blank_Touch_Small_forced = sum(data.Blank_Touch == 2 & data.Block == 2 & data.ForceFree == 1);
Descriptives.B3_Blank_Touch_Small_forced = sum(data.Blank_Touch == 2 & data.Block == 3 & data.ForceFree == 1);

Descriptives.B1_Blank_Touch_Large_free = sum(data.Blank_Touch == 1 & data.Block == 1 & data.ForceFree == 999);
Descriptives.B2_Blank_Touch_Large_free = sum(data.Blank_Touch == 1 & data.Block == 2 & data.ForceFree == 999);
Descriptives.B3_Blank_Touch_Large_free = sum(data.Blank_Touch == 1 & data.Block == 3 & data.ForceFree == 999);
Descriptives.B1_Blank_Touch_Small_free = sum(data.Blank_Touch == 2 & data.Block == 1 & data.ForceFree == 999);
Descriptives.B2_Blank_Touch_Small_free = sum(data.Blank_Touch == 2 & data.Block == 2 & data.ForceFree == 999);
Descriptives.B3_Blank_Touch_Small_free = sum(data.Blank_Touch == 2 & data.Block == 3 & data.ForceFree == 999);


% uncomment first one if you want to write descriptive statistics to file
%xlswrite(filename2,[TotalWins,TotalLosses,TotalWinStay,TotalLoseShift,WinStayPercent,LoseShiftPercent])
%xlswrite(filename,TotalWins,'TotalWins','B2')


end


% collect_lat_b1 = [];
% collect_lat_b2 = [];
% collect_lat_b3 = [];
% for ii = 1: numel(BehavData.Trial)
%     if BehavData.omissionALL(ii)==0
%         if BehavData.Block(ii)==1
%             collect_lat_b1 = [collect_lat_b1, (BehavData.collectionTime(ii) - BehavData.choiceTime(ii))];
%         elseif BehavData.Block(ii)==2
%             collect_lat_b2 = [collect_lat_b2, (BehavData.collectionTime(ii) - BehavData.choiceTime(ii))];
%         elseif BehavData.Block(ii)==3
%             collect_lat_b3 = [collect_lat_b3, (BehavData.collectionTime(ii) - BehavData.choiceTime(ii))];
%     end
%     end
% end