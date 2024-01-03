%%navigate to folder w/ raw data from ABET , will loop through all .csvs in the folder. ensure there are no .csvs in folder except raw ABET data

xlfiles = dir('*.csv'); % You are in the folder of csv files/ change extension accordingly 
Nfiles = length(xlfiles) ;  % number of files

trimmed_directory = 'H:\MATLAB\TDTbin2mat\RRD Raw Data\INSCOPIX RAW DATA\redo\trimmed\';
% loop for each file 
for i = 1:Nfiles
    fname = xlfiles(i).name ;   % file name
    [~,~,raw_ABET] = xlsread(fname);
    ind_ID = strcmp(raw_ABET(1:21), 'Animal ID');
    get_animal_id = string(raw_ABET(ind_ID, 2));
    ind_date = strcmp(raw_ABET(1:21), 'Date/Time');
    get_date = split(raw_ABET(ind_date, 2),["/"," "]);
    date = strjoin(get_date(1:3,1),'');
    new_fname = strcat(trimmed_directory, get_animal_id, '_', date,'.csv');
    raw_ABET_table = readtable(fname);
    writetable(raw_ABET_table,new_fname)
    
%     behavFiles{(i),2} = Descriptives.WinStayPercent(1);
%     behavFiles{(i),3} = Descriptives.LoseShiftPercent(1);
    %%do what you want %%%
end


%% Uncomment to write .csv containing filenames + descriptive stats (make sure no other file is named the same in the "Current Folder")
csvread(fname)

opts = detectImportOptions(fname);
readtable(fname, opts)