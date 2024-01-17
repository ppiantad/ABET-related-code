%% Combine this with patDataScript for the relevant mouse (for now), eventually will be better to integrate w/ the final meta-data structure. 

animalIDs = (fieldnames(final_SLEAP));

select_mouse = 'BLA_Insc_40';

select_mouse_index = find(strcmp(animalIDs, select_mouse));

session_to_analyze = 'RDT_D1';


%%


% Assuming your table is named "final_SLEAP.BLA_Insc_25.Pre_RDT_RM.SLEAP_data"
% and columns are named 'X', 'Y', 'vel_cm_s', 'idx_time', and 'final_SLEAP.BLA_Insc_25.Pre_RDT_RM.BehavData.collectionTime'.

% Step 1: Create a logical index for velocity < 1
velocity_threshold = 1;
velocity_below_threshold = final_SLEAP.(select_mouse).(session_to_analyze).SLEAP_data.vel_cm_s < velocity_threshold;

% Step 2: Identify start indices of low-velocity bouts
start_indices = find([0; diff(velocity_below_threshold)] == 1);

% Step 3: Filter out bouts where the velocity stays < 1 for at least one second,
% the separation between bouts is > 2 seconds, and not within ±1 second of collectionTime
min_duration_seconds = 1;
min_separation_seconds = 2;
min_mean_velocity_before_start = 2;
valid_start_indices = [];
for i = 1:length(start_indices)
    current_start_index = start_indices(i);
    current_end_index = min(length(velocity_below_threshold), current_start_index + 10 * min_duration_seconds);

    if all(velocity_below_threshold(current_start_index:current_end_index))
        % Check if the separation between bouts is > 2 seconds
        if i == 1 || (final_SLEAP.(select_mouse).(session_to_analyze).SLEAP_data.idx_time(start_indices(i)) - final_SLEAP.(select_mouse).(session_to_analyze).SLEAP_data.idx_time(start_indices(i-1)) > min_separation_seconds)
            % Check if not within ±1 second of collectionTime
            current_start_time = final_SLEAP.(select_mouse).(session_to_analyze).SLEAP_data.idx_time(current_start_index);
            collection_times = final_SLEAP.(select_mouse).(session_to_analyze).BehavData.collectionTime;
            if ~any(abs(current_start_time - collection_times) <= 1)
                % Check if mean velocity in the 1 second before start index is > 2 cm/s
                mean_velocity_before_start = mean(final_SLEAP.(select_mouse).(session_to_analyze).SLEAP_data.vel_cm_s(current_start_index - 10:current_start_index - 1));
                if mean_velocity_before_start > min_mean_velocity_before_start
                    valid_start_indices = [valid_start_indices, current_start_index];
                end
            end
        end
    end
end

% Step 4: Extract corresponding values from 'idx_time'
periods_with_low_velocity = final_SLEAP.(select_mouse).(session_to_analyze).SLEAP_data.idx_time(valid_start_indices);

% Display the result
disp('Periods with velocity < 1 for more than 1 second, separated by at least 2 seconds, not within ±1 second of collectionTime:')
disp(periods_with_low_velocity)

%%
uv.sigma = 1.5;                                                               %this parameter controls the number of standard deviations that the response must exceed to be classified as a responder. try 1 as a starting value and increase or decrease as necessary.
uv.evtWin = [-10 10];    
uv.dt = 0.1;  
uv.BLper = [-10 -5]; %what baseline period do you want for z-score [-10 -5] [-5 0]

ts1 = (-10:.1:10-0.1);

for i = 1 %could loop through multiple mice like this if you had it
    eTS = periods_with_low_velocity; %BehavData.(uv.behav); %get time stamps
    velocity = final_SLEAP.(select_mouse).(session_to_analyze).SLEAP_data.vel_cm_s; %get velocity
    %     ca = neuron.S; %get binarized calcium
    
    velocity_time = final_SLEAP.(select_mouse).(session_to_analyze).SLEAP_data.idx_time'; % time trace
    % velocity_time  = final_SLEAP.(select_mouse).(session_to_analyze).SLEAP_data.idx_time(1):uv.dt:length(velocity)*uv.dt; %generate time trace

    %calculate time windows for each event
    evtWinSpan = max(uv.evtWin) - min(uv.evtWin);
    numMeasurements = round(evtWinSpan/uv.dt); %need to round due to odd frame rate
    %
    tic

    % initialize trial matrices
    velocity_TraceTrials = NaN(size(eTS,1),numMeasurements); %
    % unitTrace = velocity(u,:); %get trace
    %             %%
    for t = 1:size(eTS,1)
        % set each trial's temporal boundaries
        timeWin = [eTS(t)+uv.evtWin(1,1):uv.dt:eTS(t)+uv.evtWin(1,2)];  %calculate time window around each event
        BL_win = [eTS(t)+uv.BLper(1,1):uv.dt:eTS(t)+uv.BLper(1,2)];
        if min(timeWin) > min(velocity_time ) & max(timeWin) < max(velocity_time )    %if the beginning and end of the time window around the event occurred during the recording period. if not, the time window is out of range %if min(timeWin) > min(caTime) & max(timeWin) < max(caTime)
            % get unit event counts in trials
            % get unit ca traces in trials
            idx = velocity_time > min(timeWin) & velocity_time <= max(timeWin);      %logical index of time window around each behavioral event time  %idx = caTime > min(timeWin) & caTime < max(timeWin);
            sum(idx)
            bl_idx = velocity_time > min(BL_win) & velocity_time <= max(BL_win);
            %caTraceTrials(t,1:sum(idx)) = unitTrace(idx);               %store the evoked calcium trace around each event   (see below, comment out if dont want normalized to whole trace)
            velocity_TraceTrials(t,1:sum(idx)) = velocity(idx);
            % zb(t,:) = mean(unitTrace(bl_idx)); %baseline mean
            % zsd(t,:) = std(unitTrace(bl_idx)); %baseline std
            velocity_zb(t,:) = mean(velocity_TraceTrials(t,:)); %baseline mean
            velocity_zsd(t,:) = std(velocity_TraceTrials(t,:)); %baseline std


            tmp = 0;
            for j = 1:size(velocity_TraceTrials,2)
                tmp = tmp+1;
                velocity_zall(t,tmp) = (velocity_TraceTrials(t,j) - velocity_zb(t))/velocity_zsd(t);
            end
            clear j;
        elseif ~(min(timeWin) > min(velocity_time ) & max(timeWin) < max(velocity_time ))
            continue


        end
        clear idx timeWin BL_win bl_idx

        unitXTrials.velocity_Traces = velocity_TraceTrials;
        unitXTrials.velocity_zb = velocity_zb;
        unitXTrials.velocity_zsd = velocity_zsd;
        % unitXTrials(u).zall = velocity_zall;

        % store unit averaged data
        % unitAVG.caTraces(u,:) = nanmean(velocity_TraceTrials);           %store trial averaged calcium traces
        % unitSEM.caTraces(u,:) = std(velocity_TraceTrials,'omitnan')/sqrt(size(velocity_TraceTrials,1));
        clear caEvtCtTrials caEvtRateTrials unitTrace idx
    end
end


zscore(velocity_TraceTrials,1,2);
figure; plot(ts1, velocity_zall);

figure
imagesc(ts1, 1, velocity_zall);hold on;   
figure;
plot(ts1, velocity_zall);