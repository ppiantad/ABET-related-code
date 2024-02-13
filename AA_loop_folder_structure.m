metaDirectory = 'I:\MATLAB\Sean CNMFe\pan-neuronal BLA';
metaDirectory_subfolders = dir(metaDirectory );
metafolder_list = {};
%SLEAP_adjustment comes from photometry where triggering was sometimes
%faulty. Likely unnecessary for most Inscopix recordings, so should be able
%to set this as an empty array. 
SLEAP_time_range_adjustment = [];
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
        if subfolders(i).isdir && ~strcmp(subfolders(i).name, '.') && ~strcmp(subfolders(i).name, '..') && ~contains(subfolders(i).name, 'PR')
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
        csvs = csvFiles.name;

        if size(csvFiles, 1) < 4
            disp('Not enough .csv files, skipping folder');
        elseif size(csvFiles, 1) >= 4
          
            filesFound = true; % Set the flag to true since .mat files were found

        end
        % Check the filesFound flag and print the final message
        if filesFound
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


            [BehavData,ABETfile,Descriptives, block_end, largeRewSide, smallRewSide, force_free_timestamps]=ABET2TableFn_Chamber_A_v6(ABET_file,[]);
            [BehavData, boris_Extract_tbl] = boris_to_table(boris_file, BehavData, block_end, largeRewSide, smallRewSide, SLEAP_time_range_adjustment);

            
        end
    end
end