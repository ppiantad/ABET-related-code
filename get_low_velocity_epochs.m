


% Assuming your table is named "final_SLEAP.BLA_Insc_25.Pre_RDT_RM.SLEAP_data"
% and columns are named 'X', 'Y', 'vel_cm_s', 'idx_time', and 'final_SLEAP.BLA_Insc_25.Pre_RDT_RM.BehavData.collectionTime'.

% Step 1: Create a logical index for velocity < 1
velocity_threshold = 1;
velocity_below_threshold = final_SLEAP.BLA_Insc_25.RDT_D1.SLEAP_data.vel_cm_s < velocity_threshold;

% Step 2: Identify start indices of low-velocity bouts
start_indices = find([0; diff(velocity_below_threshold)] == 1);

% Step 3: Filter out bouts where the velocity stays < 1 for at least one second,
% the separation between bouts is > 2 seconds, and not within ±1 second of collectionTime
min_duration_seconds = 1;
min_separation_seconds = 2;
valid_start_indices = [];
for i = 1:length(start_indices)
    current_start_index = start_indices(i);
    current_end_index = min(length(velocity_below_threshold), current_start_index + 10 * min_duration_seconds);

    if all(velocity_below_threshold(current_start_index:current_end_index))
        % Check if the separation between bouts is > 2 seconds
        if i == 1 || (final_SLEAP.BLA_Insc_25.RDT_D1.SLEAP_data.idx_time(start_indices(i)) - final_SLEAP.BLA_Insc_25.RDT_D1.SLEAP_data.idx_time(start_indices(i-1)) > min_separation_seconds)
            % Check if not within ±1 second of collectionTime
            current_start_time = final_SLEAP.BLA_Insc_25.RDT_D1.SLEAP_data.idx_time(current_start_index);
            collection_times = final_SLEAP.BLA_Insc_25.RDT_D1.BehavData.collectionTime;
            if ~any(abs(current_start_time - collection_times) <= 1)
                valid_start_indices = [valid_start_indices, current_start_index];
            end
        end
    end
end

% Step 4: Extract corresponding values from 'idx_time'
periods_with_low_velocity = final_SLEAP.BLA_Insc_25.RDT_D1.SLEAP_data.idx_time(valid_start_indices);

% Display the result
disp('Periods with velocity < 1 for more than 1 second, separated by at least 2 seconds, not within ±1 second of collectionTime:')
disp(periods_with_low_velocity)