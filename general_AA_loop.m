%% set root directory (where files are located on PC)
root = upper('d:');

which_region = input('Which dataset do you want to analyze?\n 1) Code Test \n 2) BLA-NAcSh \n 3) vmPFC-NAcSh \n 4) D1 \n 5) D2 \n 6) BLA-NAcSh GFP \n 7) vmPFC-NAcSh GFP \n 8) GFP (to NAcSh) ALL \n 9) D1-iOP \n 10) D2-iOP \n 15) D1-eOP \n 16) D2-eOP \n 12) vHPC-NAcSh \n 13) BLA-PL \n','s');

which_sessions = input('Which sessions do you want to analyze from these mice? \n 1) Early RM \n 2) Late RM \n 3) RDT \n 4) Shock Test \n','s');


[animalNames, blockpaths, behavFiles, boris_files,  SLEAP_files, SLEAP_time_range_adjustments, session, implant_side, large_rew_side, whichStreams, whichTTL] = read_mouse_data_v2(root, which_region, which_sessions);





 

%%

for ii = 1:size(behavFiles, 2)
    boris_file = boris_files{ii};
    ABET_file = behavFiles{ii};
    file_string = strsplit(ABET_file, ' ');
    ABET_file_string = behavFiles(ii);
    BORIS_file_string = boris_files(ii);
    SLEAP_time_range_adjustment = SLEAP_time_range_adjustments{ii};
    [BehavData,ABETfile,Descriptives, block_end, largeRewSide, smallRewSide, forced_trial_start, free_trial_start]=ABET2TableFn_Chamber_A_v6(ABET_file,[]);
    [BehavData, boris_Extract_tbl] = boris_to_table(boris_file, BehavData, block_end, largeRewSide, smallRewSide, SLEAP_time_range_adjustment, forced_trial_start, free_trial_start);
    Descriptives.large_aborts = sum(BehavData.type_binary == 1);
    Descriptives.small_aborts = sum(BehavData.type_binary == 2);
    Descriptives.large_aborts_b1 = sum(BehavData.type_binary == 1 & BehavData.Block == 1);
    Descriptives.large_aborts_b2 = sum(BehavData.type_binary == 1 & BehavData.Block == 2);
    Descriptives.large_aborts_b3 = sum(BehavData.type_binary == 1 & BehavData.Block == 3);

    Descriptives.small_aborts_b1 = sum(BehavData.type_binary == 2 & BehavData.Block == 1);
    Descriptives.small_aborts_b2 = sum(BehavData.type_binary == 2 & BehavData.Block == 2);
    Descriptives.small_aborts_b3 = sum(BehavData.type_binary == 2 & BehavData.Block == 3);
    Descriptives.large_aborts = sum(BehavData.type_binary == 1);
    Descriptives.small_aborts = sum(BehavData.type_binary == 2);
    Descriptives.large_aborts_b1 = sum(BehavData.type_binary == 1 & BehavData.Block == 1);
    Descriptives.large_aborts_b2 = sum(BehavData.type_binary == 1 & BehavData.Block == 2);
    Descriptives.large_aborts_b3 = sum(BehavData.type_binary == 1 & BehavData.Block == 3);

    Descriptives.small_aborts_b1 = sum(BehavData.type_binary == 2 & BehavData.Block == 1);
    Descriptives.small_aborts_b2 = sum(BehavData.type_binary == 2 & BehavData.Block == 2);
    Descriptives.small_aborts_b3 = sum(BehavData.type_binary == 2 & BehavData.Block == 3);



    indices = BehavData.ForceFree == 0 & (BehavData.bigSmall == 1.2 | BehavData.bigSmall == 0.3);
    BehavData_filtered = BehavData(indices, :);

    sequence = zeros(size(BehavData_filtered, 1), 1);
    % Initialize arrays to store the first time values
    forced_trial_start = zeros(3, 1); % For strings of 1s
    free_trial_start = zeros(3, 1); % For strings of 0s

    % Loop through the data
    for i = 1:size(BehavData_filtered, 1)
        if i == 1
            sequence(1) = 0;
            % Check if the current value in column 2 is different from the previous one
        elseif i > 1 && BehavData_filtered.bigSmall(i) ~= BehavData_filtered.bigSmall(i-1)

            % Store the first time for string of 1s
            sequence(i) = 0;
        else
            if BehavData_filtered.bigSmall(i) == 1.2
                % Store the first time for string of 0s
                sequence(i) = 1;
            elseif BehavData_filtered.bigSmall(i) == 0.3
                sequence(i) = 2;
            end
        end
    end

    % remove first trials, because they follow forced choice trials & thus
    % can't be a sequence
    rows_to_remove = [1 23 45];
    num_rows = height(BehavData_filtered);
    rows_to_remove = rows_to_remove(rows_to_remove <= num_rows);

    BehavData_filtered(rows_to_remove, :) = [];
    sequence(rows_to_remove, :) = [];
    sequences_poss = 21; % because there are 22 free choice trials, and there can't be a sequence on the 1st one of each block (because there are forced choice trials prior)
    BehavData_filtered.sequence = sequence;
    Descriptives.large_sequence_B1 = (sum(BehavData_filtered.Block == 1 & BehavData_filtered.sequence == 1)/sequences_poss)*100;
    Descriptives.large_sequence_B2 = (sum(BehavData_filtered.Block == 2 & BehavData_filtered.sequence == 1)/sequences_poss)*100;
    Descriptives.large_sequence_B3 = (sum(BehavData_filtered.Block == 3 & BehavData_filtered.sequence == 1)/sequences_poss)*100;

    Descriptives.small_sequence_B1 = (sum(BehavData_filtered.Block == 1 & BehavData_filtered.sequence == 2)/sequences_poss)*100;
    Descriptives.small_sequence_B2 = (sum(BehavData_filtered.Block == 2 & BehavData_filtered.sequence == 2)/sequences_poss)*100;
    Descriptives.small_sequence_B3 = (sum(BehavData_filtered.Block == 3 & BehavData_filtered.sequence == 2)/sequences_poss)*100;

    descriptives_table(ii, :) = [cell2table(ABET_file_string) cell2table(BORIS_file_string) Descriptives];
end

%%
writetable(descriptives_table,'descriptives_table.csv')