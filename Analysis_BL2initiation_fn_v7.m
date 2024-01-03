function [data, ZallMean,zerror,ts1,numTrials,STREAM_STORE1,STREAM_STORE2,TTLNumber, Descriptives, BehavData, zall, zall_motion, Y_dF_all, uv_temp, SLEAP_data_vel_filtered_session, Y_dF_all_session] =Analysis_BL2initiation_fn_v7(animalName,blockpath,whichStreams,whichTTL,behavFiles, EPOC, boris_files, SLEAP_files, SLEAP_time_range_adjustment, which_sessions);
 


%%

data = TDTbin2mat(blockpath);
%%

%work behavioral data into photo data, generate descriptive statistics
TTLNumber=fieldnames(data.epocs);
if whichTTL==2
   epoc1=2; 
elseif whichTTL==1
   epoc1=1;
elseif whichTTL==3
   epoc1=3;
elseif whichTTL==4
    epoc1=4;
elseif whichTTL==5
    epoc1=5;
end


if which_sessions == '4'
   [BehavData,ABETfile]=ABET2TableFn_ShockTest(behavFiles);
   timeStart=data.epocs.(TTLNumber{epoc1}).onset(1);
   timeShift=timeStart*ones(numel(BehavData.choiceTime(:)),1);
   BehavData.choiceTime(:)=BehavData.choiceTime(:)+timeShift;
   Descriptives = [];

elseif which_sessions ~= '4'
    [BehavData,ABETfile, Descriptives, block_end, largeRewSide, smallRewSide]=ABET2TableFn_Chamber_A_v6(behavFiles,[]); %ABET2TableFn_Chamber_Av3, updated to v6 as of 11/02/2021
    timeStart=data.epocs.(TTLNumber{epoc1}).onset(1);
    timeShift=timeStart*ones(numel(BehavData.choiceTime(:)),1);
    BehavData.choiceTime(:)=BehavData.choiceTime(:)+timeShift;
    BehavData.collectionTime(:)=BehavData.collectionTime(:)+timeShift;
    BehavData.stTime(:)=BehavData.stTime(:)+timeShift;
    block_end = block_end +timeShift;


end


%because function outputs zall_motion etc, need to create an empty vector
%if no SLEAP data are available for a given file
if isempty(SLEAP_files)
    SLEAP_data = []
    zall_motion = [];
    SLEAP_data_vel_filtered_session = [];
elseif ~isempty(SLEAP_files)
    SLEAP_data = readtable(SLEAP_files);
end

%align timestamps of behavioral data to timestamps of photometry
%find time of first TTL.  This value will be passed to Behavioral Data so
%that the timestamps of the ABET data will match the timestamps of Synapse


%%

if which_sessions == '4'

elseif which_sessions ~= '4'
    [BehavData, boris_Extract_tbl] = boris_to_table(boris_files, BehavData, block_end, largeRewSide, smallRewSide, SLEAP_time_range_adjustment);

end


%%
%pick trial types
% If analyzing entire dataset for a given exp, set to 'ALL', 1

if which_sessions == '4'
    BehavData=TrialFilter(BehavData,'SHK',1);
elseif which_sessions ~= '4'
    BehavData=TrialFilter(BehavData,'ALL',1);
end
%%



if strcmpi(EPOC, 'start')
    time2EPOC = BehavData.stTime(:) - BehavData.choiceTime(:);
elseif strcmpi(EPOC, 'Collect')
    BL_time = BehavData.collectionTime(:)-BehavData.choiceTime(:);
    time2EPOC = BehavData.choiceTime(:)-BehavData.collectionTime(:); %time2Collect = BehavData.collectionTime(:)-BehavData.choiceTime(:);
% For the epoch that provides timestamps just prior to reward collection
% (Collect), since there is no timestamp for reward collection on omitted
% trials, the code above
% (BehavData.collectionTime(:)=BehavData.collectionTime(:)+timeShift;) adds
% the ABET start time (timeShift) to each row of the column, making
% Collection time set to timeShift effectively. I couldn't get
% collectiontime(ii) == timeStart(ii) to work properly, so check that the
% diff is < 0.01 (which should never happen with a real timestamp) seemed
% to be the best way to go. 
    for ii = 1:size(BehavData, 1)
        if BehavData.collectionTime(ii) - timeStart <= 0.01
            toRemove(ii) = true;
        elseif BehavData.collectionTime(ii) - timeStart >= 0.01
            toRemove(ii) = false;
        end
%         
    end
    % Delete rows where collectionTime is close to timeStart (these are all
    % omissions, so they don't have a collection time
    BehavData(toRemove, :) = [];
    %Renumber the Trial column, because later outside of this function we
    %will use this column to index into the calcium data. 
    BehavData.Trial = (1:1:size(BehavData,1))';
    clear toRemove;
elseif strcmpi(EPOC, 'Choice')
    BL_time = BehavData.stTime(:)-BehavData.choiceTime(:);
%     time2Collect = BehavData.collectionTime(:)-BehavData.choiceTime(:);
    time2EPOC = BehavData.stTime(:)-BehavData.choiceTime(:);
end



%%
%create epoc for trials aligned to choice

if which_sessions == '4'
    %create epoc for trials aligned to Trial
    data.epocs.Trial.name = 'Trial';
    data.epocs.Trial.onset = BehavData.choiceTime; %
    data.epocs.Trial.offset = BehavData.choiceTime+0.1*ones(numel(BehavData.choiceTime),1);
    data.epocs.Trial.data = [1:numel(BehavData.choiceTime)]';

elseif which_sessions ~= '4'
    data.epocs.Choice.name = 'Choice';
    data.epocs.Choice.onset = BehavData.choiceTime; %
    data.epocs.Choice.offset = BehavData.choiceTime+0.1*ones(numel(BehavData.choiceTime),1);
    data.epocs.Choice.data = [1:numel(BehavData.choiceTime)]';


    %create epoc for trials aligned to collection time
    data.epocs.Collect.name = 'Collect';
    data.epocs.Collect.onset = BehavData.collectionTime; %
    data.epocs.Collect.offset = BehavData.collectionTime+0.1*ones(numel(BehavData.collectionTime),1);
    data.epocs.Collect.data = [1:numel(BehavData.collectionTime)]';


    %create epoc for trials aligned to Trial Start time
    data.epocs.start.name = 'start';
    data.epocs.start.onset = BehavData.stTime; %
    data.epocs.start.offset = BehavData.stTime+0.1*ones(numel(BehavData.stTime),1);
    data.epocs.start.data = [1:numel(BehavData.stTime)]';

end
%%

%find channel names
streamNames=fieldnames(data.streams);
if whichStreams==12
    stream1=2; stream2=1;
elseif whichStreams==34
    stream1=3; stream2=4;
end

%%
%use TDT filter to get just the trials you want
% EPOC = EPOC; %set which epoc to look at THIS WAS WRONG BEFORE 'Choice'
STREAM_STORE1 = streamNames{stream1}; %put here what your 405 channel is
STREAM_STORE2 = streamNames{stream2}; %put here what your 465 channel is

if which_sessions == '4'
    TRANGE = [-5 10]; % window size [start time relative to epoc onset, window duration] -10 20 default -4 12
    BASELINE_PER = [-5 -1]; % baseline period within our window -6 -1 default
    ARTIFACT = Inf; % optionally set an artifact rejection level
    data = TDTfilter(data,EPOC,'TIME',TRANGE); %perform TDTfilter

elseif which_sessions ~= '4'
    if strcmpi(EPOC, 'start')
        TRANGE = [-8 38]; % window size [start time relative to epoc onset, window duration](if baselining to START, which is initiation) has to include enough time to account for 30s pre-choice time + baseline period)  -10 20 default -4 12 -31 41 -41 51 -51 61 -33 43 -8 38
    elseif strcmpi(EPOC, 'Collect')
        TRANGE = [-4 12];
    elseif strcmpi(EPOC, 'Choice')
        TRANGE = [-33 43];
    end
    BASELINE_PER = 'TRANGE window'; % baseline period within our window -6 -1 default; THE FIRST VALUE CAN'T BE < THE FIRST TRANGE VALUE -10 -5 -2 -0 -3 -1 -3 0 -4 0: To analyze omissions, use -3 0 with EPOC on "start", otherwise make sure -10 -5 and EPOC "Choice" -10 -5 -8 -5
    ARTIFACT = Inf; % optionally set an artifact rejection level
    data = TDTfilter(data,EPOC,'TIME',TRANGE); %perform TDTfilter
end

%%
% time2Collect = BehavData.collectionTime(:)-BehavData.choiceTime(:);
% 
% 
% 
% if strcmpi(EPOC, 'start')
%     time2EPOC = BehavData.stTime(:) - BehavData.choiceTime(:);
% elseif strcmpi(EPOC, 'Collect')
%     BL_time = BehavData.collectionTime(:)-BehavData.choiceTime(:);
%     time2EPOC = BehavData.choiceTime(:)-BehavData.collectionTime(:); %time2Collect = BehavData.collectionTime(:)-BehavData.choiceTime(:);
% 
%     for ii = 1:size(BehavData, 1)
% 
%         if BehavData.collectionTime(ii) - timeStart <= 0.01
%             toRemove(ii) = true;
% %             toRemove(j, :) = BehavData(ii, :);
% 
%             % renumber the Trials so that that they match the Zscore? or
%             % actually it likely doesnt matter since the Zscored data are
%             % indexed 1 through end, and so is BehavData
%         elseif BehavData.collectionTime(ii) - timeStart >= 0.01
%             toRemove(ii) = false;
%         end
% %         
%     end
%     BehavData(toRemove, :) = [];
%     clear toRemove;
% elseif strcmpi(EPOC, 'Choice')
%     BL_time = BehavData.stTime(:)-BehavData.choiceTime(:);
% %     time2Collect = BehavData.collectionTime(:)-BehavData.choiceTime(:);
%     time2EPOC = BehavData.stTime(:)-BehavData.choiceTime(:);
% end


%%

%Check if any trials exist

if isempty(BehavData)
    ZallMean=999;
    zerror=999;
    ts1=999;
    numTrials=999; %set numTrials to 999 because this is an impossible # of trials, can then be filtered out for behavioral analysis in other code
    zall=999;
% if isempty(data.epocs.(EPOC).data)
%     ZallMean=999;
%     zerror=999;
%     ts1=999;
%     numTrials=0;
   
else


    % Optionally remove artifacts. If any waveform is above ARTIFACT level, or
    % below -ARTIFACT level, remove it from the data set.
    art1 = ~cellfun('isempty', cellfun(@(x) x(x>ARTIFACT), data.streams.(STREAM_STORE1).filtered, 'UniformOutput',false));
    art2 = ~cellfun('isempty', cellfun(@(x) x(x<-ARTIFACT), data.streams.(STREAM_STORE1).filtered, 'UniformOutput',false));
    good = ~art1 & ~art2;
    data.streams.(STREAM_STORE1).filtered = data.streams.(STREAM_STORE1).filtered(good);

    art1 = ~cellfun('isempty', cellfun(@(x) x(x>ARTIFACT), data.streams.(STREAM_STORE2).filtered, 'UniformOutput',false));
    art2 = ~cellfun('isempty', cellfun(@(x) x(x<-ARTIFACT), data.streams.(STREAM_STORE2).filtered, 'UniformOutput',false));
    good2 = ~art1 & ~art2;
    data.streams.(STREAM_STORE2).filtered = data.streams.(STREAM_STORE2).filtered(good2);

    numArtifacts = sum(~good) + sum(~good2);


    % Applying a time filter to a uniformly sampled signal means that the
    % length of each segment could vary by one sample.  Let's find the minimum
    % length so we can trim the excess off before calculating the mean.
    minLength1 = min(cellfun('prodofsize', data.streams.(STREAM_STORE1).filtered));
    minLength2 = min(cellfun('prodofsize', data.streams.(STREAM_STORE2).filtered));
    data.streams.(STREAM_STORE1).filtered = cellfun(@(x) x(1:minLength1), data.streams.(STREAM_STORE1).filtered, 'UniformOutput',false);
    data.streams.(STREAM_STORE2).filtered = cellfun(@(x) x(1:minLength2), data.streams.(STREAM_STORE2).filtered, 'UniformOutput',false);

    allSignals = cell2mat(data.streams.(STREAM_STORE1).filtered');
    


    % downsample 10x and average 405 signal
    N = 33.8822618125484;  %downsample_factor; %10
    
    
    
    F405 = zeros(size(allSignals(:,1:N:end-N+1)));
    for ii = 1:size(allSignals,1)
        F405(ii,:) = arrayfun(@(i) mean(allSignals(ii,i:i+N-1)),1:N:length(allSignals)-N+1);
        w = warning('query','last');
        id = w.identifier;
        warning('off',id)
    end
    minLength1 = size(F405,2);

    % Create mean signal, standard error of signal, and DC offset of 405 signal
    meanSignal1 = mean(F405);
    stdSignal1 = std(double(F405))/sqrt(size(F405,1));
    dcSignal1 = mean(meanSignal1);

    % downsample 10x and average 465 signal
    allSignals = cell2mat(data.streams.(STREAM_STORE2).filtered');
    F465 = zeros(size(allSignals(:,1:N:end-N+1)));
    for ii = 1:size(allSignals,1)
        F465(ii,:) = arrayfun(@(i) mean(allSignals(ii,i:i+N-1)),1:N:length(allSignals)-N+1);
    end
    minLength2 = size(F465,2);

    % Create mean signal, standard error of signal, and DC offset of 465 signal
    meanSignal2 = mean(F465);
    stdSignal2 = std(double(F465))/sqrt(size(F465,1));
    dcSignal2 = mean(meanSignal2);

   % Plot Epoch Averaged Response

    % Create the time vector for each stream store
    ts1 = TRANGE(1) + (1:minLength1) / data.streams.(STREAM_STORE1).fs*N;
    ts2 = TRANGE(1) + (1:minLength2) / data.streams.(STREAM_STORE2).fs*N;

    % Subtract DC offset to get signals on top of one another
    meanSignal1 = meanSignal1 - dcSignal1;
    meanSignal2 = meanSignal2 - dcSignal2;
    

    %get entire session trace & downsample
    F465_session_downsampled = data.streams.(STREAM_STORE2).data;
    F465_original_indices = 1:numel(F465_session_downsampled);
    F465_downsampled_indices = 1:N:numel(F465_session_downsampled);
    F465_downsampled_data = interp1(F465_original_indices, F465_session_downsampled, F465_downsampled_indices);

    %get entire session trace & downsample
    F405_session_downsampled = data.streams.(STREAM_STORE1).data;
    F405_original_indices = 1:numel(F405_session_downsampled);
    F405_downsampled_indices = 1:N:numel(F405_session_downsampled);
    F405_downsampled_data = interp1(F405_original_indices, F405_session_downsampled, F405_downsampled_indices);

    num_rows_in_table = size(SLEAP_data, 1);

    downsampled_size = size(F405_downsampled_data);
    % Calculate the number of rows to keep (minimum of the two counts)
    num_rows_to_keep = min(downsampled_size(2), num_rows_in_table);

    if downsampled_size(2) > num_rows_in_table
        F405_downsampled_data = F405_downsampled_data(1:num_rows_in_table);
        F405_downsampled_indices = F405_downsampled_indices(1:num_rows_in_table);
        F465_downsampled_data = F405_downsampled_data(1:num_rows_in_table);
        F465_downsampled_indices = F405_downsampled_indices(1:num_rows_in_table);

    elseif downsampled_size(2) < num_rows_in_table
        SLEAP_data = SLEAP_data(1:num_rows_to_keep, :);
    end
    

    % normal correction for motion
    bls_session = polyfit(F405_downsampled_data(1:end), F465_downsampled_data(1:end), 1); %polyfit(F465(1:end), F405(1:end), 1);
    Y_fit_session = bls_session(1) .* F405_downsampled_data + bls_session(2);
    Y_dF_all_session = F465_downsampled_data - Y_fit_session;
    

    % dit-bressel IRLS attempt - see "RegressionSim" package & paper: https://github.com/philjrdb/RegressionSim
    % [Y_dF_all_session, ~] = IRLS_dFF(F405_downsampled_data(1:end), F465_downsampled_data(1:end), 1.4);


    % Trim the table down to the desired size
    if ~isempty(SLEAP_files)
        
%         [data, downsample_factor, zall_motion, allSignals_motion] = SLEAP_Filter(data, allSignals,SLEAP_data, TRANGE, BASELINE_PER, SLEAP_time_range_adjustment);
        [data, zall_motion, allSignals_motion, SLEAP_data_vel_filtered_session] = SLEAP_Filter_v2(data, allSignals,SLEAP_data, TRANGE, BASELINE_PER, SLEAP_time_range_adjustment, downsampled_size);
        clear SLEAP_data

    end


%ADDED TO BL TO NSP 

% [numTrials,~]=size(BehavData.collectionTime(:));
% Tris=[1:numTrials]';

% time2Collect=BehavData.collectionTime(:)-BehavData.choiceTime(:);
% time2choose=BehavData.stTime(:)-BehavData.choiceTime(:);

    % Heat Map based on z score of 405 fit subtracted 465

    % Fitting 405 channel onto 465 channel to detrend signal bleaching
    % Scale and fit data
    % Algorithm sourced from Tom Davidson's Github:
    % https://github.com/tjd2002/tjd-shared-code/blob/master/matlab/photometry/FP_normalize.m
    
    bls = polyfit(F405(1:end),F465(1:end), 1);
    Y_fit_all = bls(1) .* F405 + bls(2);
    Y_dF_all = F465 - Y_fit_all;
    
    % dit-bressel IRLS attempt - see "RegressionSim" package & paper: https://github.com/philjrdb/RegressionSim

    % for qq = 1:size(F405, 1)
    %     [Y_dF_all(qq,:), ft_iso_signal_from_IRLS(qq,:)] = IRLS_dFF(F465(qq,:), F405(1,:), 1.4);
    % 
    % 
    %     % bls = polyfit(F405(1:end), F465(1:end), 1); %polyfit(F465(1:end), F405(1:end), 1);
    %     % Y_fit_all = bls(1) .* F405 + bls(2);
    %     % Y_dF_all = F465 - Y_fit_all;
    % end



    zall = zeros(size(Y_dF_all));
    tmp = 0;
    

if which_sessions == '4'
    
    for i = 1:size(Y_dF_all,1)
        ind = ts2(1,:) < BASELINE_PER(2) & ts2(1,:) > BASELINE_PER(1);
        zb = mean(Y_dF_all(i,ind)); % baseline period mean (-10sec to -6sec)
        zsd = std(Y_dF_all(i,ind)); % baseline period stdev
        for j = 1:size(Y_dF_all,2) % Z score per bin
            tmp = tmp + 1;
            zall(i,tmp)=(Y_dF_all(i,j) - zb)/zsd;
        end
        tmp=0;
    end


elseif which_sessions ~='4'
% to analyze omissions, ensure that "BL_shifted" and the BL_shifted ind are
% both uncommented! 
    for i = 1:size(Y_dF_all,1)
%             BL_shifted=[BASELINE_PER(1)+time2EPOC(i) BASELINE_PER(2)+time2EPOC(i)]; %BL_shifted(pp,:)=[BASELINE_PER(1)+(-1*time2Collect(i)) BASELINE_PER(2)+time2Collect(i)];
%         ind = ts2(1,:) < BASELINE_PER(2) & ts2(1,:) > BASELINE_PER(1); %use if you want to test without shifting baseline according to particular EPOC
%             ind = ts2(1,:) < BL_shifted(2) & ts2(1,:) > BL_shifted(1);

        %use if you want to take the Z-score using the entire window mean
        zb = mean(Y_dF_all(i,:)); % baseline period mean
        zsd = std(Y_dF_all(i,:)); % baseline period stdev

        %use if you want to calculate the Z-score using your specified baseline
%             zb = mean(Y_dF_all(i,ind)); % baseline period mean
%             zbmedian = median(Y_dF_all(i,length(ts1)));
%             zsd = std(Y_dF_all(i,ind)); % baseline period stdev





        %     zb = mean(Y_dF_all(i,:)); % baseline period mean
        % %     zbmedian = median(Y_dF_all(i,length(ts1)));
        %     zsd = std(Y_dF_all(i,:)); % baseline period stdev
        for j = 1:size(Y_dF_all,2) % Z score per bin
            tmp = tmp + 1;
            zall(i,tmp)=(Y_dF_all(i,j) - zb)/zsd;
        %         dfALL(i,tmp)=(Y_dF_all(i,j) - zbmedian)/zbmedian;
        %         BL_mean(i) = mean(Y_dF_all(i,:));

        end
    tmp=0;
    end
end
    
    % %dit-bressel Zall https://github.com/philjrdb/RegressionSim
    % zall = nullZ(Y_dF_all);


% Standard error of the z-score
    zerror = std(zall)/size(zall,1);
    
    
    ZallMean=mean(zall,1);
    [numTrials, ~] = size(F465);
    

    
    uv_temp.TRANGE = TRANGE;
    uv_temp.Baseline_4_zscore = BASELINE_PER;
    uv_temp.ARTIFACT = ARTIFACT;
    uv_temp.EPOC = EPOC;
    uv_temp.STREAMS = {STREAM_STORE1; STREAM_STORE2};



end   
end
