function [BehavData, boris_Extract_tbl] = boris_to_table(boris_file, BehavData, block_end, largeRewSide, smallRewSide, SLEAP_time_range_adjustment)
%% boris_to_table: integrate approach/abort behaviors scored in BORIS directly into the organized ABET data table

if isempty(boris_file)
    BehavData.type = NaN(size(BehavData,1), 1);
    boris_Extract_tbl = [];
elseif ~isempty(boris_file)
    [~,~,boris] = xlsread(boris_file);
    %the default output (export to csv) of BORIS changed in 2023. files w/
    %the old version had a row with missing values (all NaN) in row 2, so
    %to differentiate those files, I've added a check for row 2 cell 1 to
    %see if it contains NaNs. This should never be true of the "new" BORIS
    %outputs.
    if isnan(boris{2,1})
        boris_extract = boris(17:end,[1,6]);
    elseif ~isnan(boris{2,1})
        %check if the 2nd row contains 'start', which will be true of some
        %files, but is not necessary to keep in the final table. If it does
        %contain 'start', skip the 2nd row and extract from the 3rd row
        %onways
        containsStart = any(strcmpi(boris(2, :), 'start'));
        if containsStart
            % If row 2 contains 'start', extract from row 3 to the final row
            boris_extract = boris(3:end, [13, 10]);
            %If row 2 does not contain start, extract from the 2nd row to
            %the final row
        elseif ~containsStart
            boris_extract = boris(2:end,[13, 10]);
        end

    end
        
    if ~isempty(SLEAP_time_range_adjustment)
       	SLEAP_adjust_array=SLEAP_time_range_adjustment*ones(numel(boris_extract(:,1)),1);  
        boris_Extract_tbl = cell2table(boris_extract);
        boris_Extract_tbl.Properties.VariableNames = {'choiceTime','type'};
        boris_Extract_tbl.choiceTime = boris_Extract_tbl.choiceTime(:) + SLEAP_adjust_array;
    elseif isempty(SLEAP_time_range_adjustment)
        boris_Extract_tbl = cell2table(boris_extract);
        boris_Extract_tbl.Properties.VariableNames = {'choiceTime','type'};
    end
            
            
    
    
    boris_Extract_tbl.stTime = boris_Extract_tbl.choiceTime;
    boris_Extract_tbl.collectionTime = boris_Extract_tbl.choiceTime+30;
    
    % outerjoin(boris_Extract_tbl, BehavData);
    
    %block_end is from ABET2Table, and defines the time when a given block
    %ended. Use these times to compare if a BORIS approach/abort time was
    %greater than or less than a given block_end time, then assign Block to
    %the corresponding value (1, 2, or 3)
    [boris_rows,~]=size(boris_Extract_tbl);
    for hh = 1:boris_rows
        if boris_Extract_tbl.stTime(hh) < block_end(1,1)
            boris_Extract_tbl.Block(hh) = 1;
        elseif boris_Extract_tbl.choiceTime(hh) > block_end(1,1) &&  boris_Extract_tbl.choiceTime(hh) < block_end(1,2)
            boris_Extract_tbl.Block(hh) = 2;
        elseif boris_Extract_tbl.choiceTime(hh) > block_end(1,2)
            boris_Extract_tbl.Block(hh,1) = 3;
        end
        
    end
    
    %add column titles to table
    boris_Extract_tbl.Properties.VariableNames = {'choiceTime','type','stTime','collectionTime','Block'};
    
    %ABET2Table generates which side corresponded to Large and Small reward
    %for the mouse (largeRewSide and smallRewSide). Because BORIS coding is
    %"left abort" or "right abort", compare the value in the boris column
    %"type" to the side in the variable largeRewSide or smallRewSide, then
    %reclassify the "type" column as large abort / small abort, and create
    %a binary value in "type_binary". Can probably delete the 2nd line of
    %each if statement, because it is now unnecessary? 
    for hh = 1:size(boris_Extract_tbl,1)
        if contains(boris_Extract_tbl.type(hh), largeRewSide)
            boris_Extract_tbl.type{hh} = 'large abort';
            boris_Extract_tbl.type_binary(hh) = 1;
        elseif contains(boris_Extract_tbl.type(hh), smallRewSide)
            boris_Extract_tbl.type{hh} = 'small abort';
            boris_Extract_tbl.type_binary(hh) = 2;
        end
    end
    
    %the strings in boris_Extract_tbl.type make it impossible to use
    %cell2mat to reconstruct the table in access_behav_struct_v2, to
    %quickly go through data. To deal with this, I've binarized the abort
    %data (above, see "type_binary", and then delete the non-binarized
    %"type" column
    boris_Extract_tbl = removevars(boris_Extract_tbl, {'type'});
    
%     abet_and_boris = tblvertcat(boris_Extract_tbl, BehavData);
    %the order of BehavData and brosi_extract_tbl matters here, keep in
    %this order to maintain the BehavData table orientation, appending the
    %row "type" and "type_binary" to the end
    abet_and_boris = tblvertcat(BehavData, boris_Extract_tbl);
    tblB = sortrows(abet_and_boris,{'choiceTime'},{'ascend'});
    
    BehavData = tblB;
    
    %to index into "trials" later, each Trial (row) must have a unique #,
    %so that you can find the corresponding row in the photometry trace.
    %This code assigns "Trial" to the number corresponding to its row. 
    BehavData_size = size(BehavData);
    renum_trials = 1:BehavData_size(1);
    BehavData.Trial = renum_trials';
    
    
end
end