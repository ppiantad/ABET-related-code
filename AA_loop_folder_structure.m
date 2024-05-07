% use this for either inscopix mice or any other group - data must be
% organized in nested folder structure as follows:
%meta folder (experiment name)
%subfolder 1: mouse ID(s)
%subfolder 2: session(s)


metaDirectory = 'D:\MATLAB\Sean CNMFe\BLA-NAcSh';
metaDirectory_subfolders = dir(metaDirectory );
metafolder_list = {};
%SLEAP_adjustment comes from photometry where triggering was sometimes
%faulty. Likely unnecessary for most Inscopix recordings, so should be able
%to set this as an empty array. 
SLEAP_time_range_adjustment = [];
loop_num = 0;
aborts_table = table; 
%%
% Loop through the list of subfolders
for i = 1:length(metaDirectory_subfolders)
    % Check if the item in subfolders is a directory (not "." or "..") or
    % one of the sets of files that I haven't analyzed yet (PR currently)
    if metaDirectory_subfolders(i).isdir && ~strcmp(metaDirectory_subfolders(i).name, '.') && ~strcmp(metaDirectory_subfolders(i).name, '..') && ~contains(metaDirectory_subfolders(i).name, 'PR') && ~contains(metaDirectory_subfolders(i).name, 'not in final dataset')
        % if subfolders(i).isdir && ~strcmp(subfolders(i).name, '.') && ~strcmp(subfolders(i).name, '..') && ~contains(lower(subfolders(i).name), 'shock')
        % if subfolders(i).isdir && ~strcmp(subfolders(i).name, '.') && ~strcmp(subfolders(i).name, '..')
        % Get the full path of the subfolder
        metasubfolderPath = fullfile(metaDirectory, metaDirectory_subfolders(i).name);

        % Create a cell array for the subfolder path and append it
        % vertically to folder_list
        metafolder_list = vertcat(metafolder_list, {metasubfolderPath});



        % Add your analysis code here

    end
end

%%
for zz = 1:size(metafolder_list, 1)
    % Use the dir function to get a list of subfolders
    startDirectory = metafolder_list{zz};
    subfolders = dir(startDirectory);


    % Initialize folder_list as an empty cell array
    folder_list = {};


    % Loop through the list of subfolders
    for i = 1:length(subfolders)
        % Check if the item in subfolders is a directory (not "." or "..") or
        % one of the sets of files that I haven't analyzed yet (PR currently)
        if subfolders(i).isdir && ~strcmp(subfolders(i).name, '.') && ~strcmp(subfolders(i).name, '..') && ~contains(subfolders(i).name, 'PR') && ~contains(subfolders(i).name, 'SHOCK')
            % if subfolders(i).isdir && ~strcmp(subfolders(i).name, '.') && ~strcmp(subfolders(i).name, '..') && ~contains(lower(subfolders(i).name), 'shock')
            % if subfolders(i).isdir && ~strcmp(subfolders(i).name, '.') && ~strcmp(subfolders(i).name, '..')
            % Get the full path of the subfolder
            subfolderPath = fullfile(startDirectory, subfolders(i).name);

            % Create a cell array for the subfolder path and append it
            % vertically to folder_list
            folder_list = vertcat(folder_list, {subfolderPath});



            % Add your analysis code here

        end
    end

    for ii = 1:size(folder_list, 1)
        list = dir(folder_list{ii});%grab a directory of the foldercontents
        disp(['Analyzing subfolder: ' folder_list{ii,1}]);

        % Initialize a flag to check if files were found in this folder
        filesFound = false;




        folderMask = ~[list.isdir]; %find all of the folders in the directory and remove them from the list
        files = list(folderMask);  %now we have only files to work with
        clear folderMask list


        idx = ~cellfun('isempty',strfind({files.name},'.csv')); %find the instances of .xlsx in the file list.
        %This command converts the name field into a cell array and searches
        %the cell array with strfind
        csvFiles = files(idx); %build a mat file index
        clear idx
        
        
        if size(csvFiles, 1) < 2
            disp('Not enough .csv files, skipping folder');
        elseif size(csvFiles, 1) > 2 || contains(subfolderPath, 'hM4Di')
            for i = 1:size(csvFiles, 1)
                % Check if "BORIS" is present in the current name
                borisFound(i) = contains(csvFiles(i).name, 'BORIS');

                % Check if "ABET" is present in the current name
                abetFound(i) = contains(csvFiles(i).name, 'ABET');
            end

            % Check if any of the substrings were found in any of the names
            borisPresent = any(borisFound);
            abetPresent = any(abetFound);
            if borisFound == 0 
                boris_file = [];
            end
            if borisPresent | abetPresent
                filesFound = true; % Set the flag to true since .mat files were found
            else
                disp('Not enough .csv files, skipping folder');
            end
        end
        % Check the filesFound flag and print the final message
        clear borisFound abetFound
        if filesFound
            loop_num = loop_num+1; 
            disp('Folder will be analyzed');

            

            folder_strings = strsplit(folder_list{ii}, '\');
            %     session_strings = strsplit(folder_strings{end}, {'-', ' '});
            %     mat_strings = strsplit(char(matFiles.name),'_');
            %     date_strings = strsplit(mat_strings{4}, '-');
            csv_names = {csvFiles.name};
            current_animal = folder_strings{5}; % Would have to change this depending on your folder structure, but there should be an animal name folder given our current workflow.
            current_session = folder_strings{6};
            % Loop over each substring in the substrings array
            for mm = 1:length(csv_names)
                % Check if the current name contains three distinct substrings
                if contains(lower(csv_names{mm}), 'boris')
                    disp(['BORIS ApproachAbort File = ', csv_names{mm}])
                    boris_file = strcat(folder_list{ii}, '\', csv_names{mm});
                end
                if contains(csv_names{mm}, 'ABET')
                    disp(['ABET File = ', csv_names{mm}])
                    ABET_file = strcat(folder_list{ii}, '\', csv_names{mm});
                end
            end


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

            animal_string = {current_animal};
            session_string = {current_session}; 
            
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
            
            aborts_table(loop_num, :) = [cell2table(animal_string) cell2table(session_string) Descriptives];

            
        end
    end
end

%%
writetable(aborts_table,'descriptives_table.csv')