%%navigate to folder w/ raw data from ABET (no headers allowed), will loop through all .csvs in the folder. ensure there are no .csvs in folder except raw ABET data

xlfiles = dir('*.csv'); % You are in the folder of csv files/ change extension accordingly 
Nfiles = length(xlfiles) ;  % number of files
% loop for each file 
for i = 1:Nfiles
    fname = xlfiles(i).name ;   % file name
    [~,raw_ABET] = xlsread(fname);
    [~,~,Descriptives,~]=ABET2TableFn_Chamber_A_v6(fname,[]); 
    behavFiles = {xlfiles.name}';
    Descriptives2(i,:) = Descriptives;
    behavFiles2 = cell2table(behavFiles);
    
%     behavFiles{(i),2} = Descriptives.WinStayPercent(1);
%     behavFiles{(i),3} = Descriptives.LoseShiftPercent(1);
    %%do what you want %%%
end

WSLS_tbl = [behavFiles2 Descriptives2];

%% Uncomment to write .csv containing filenames + descriptive stats (make sure no other file is named the same in the "Current Folder")
writetable(WSLS_tbl,'WSLS_table.csv')


% [BehavData,ABETfile,Descriptives, block_end]=ABET2TableFn_Chamber_Av4('RRD179 04092021.csv',[]);