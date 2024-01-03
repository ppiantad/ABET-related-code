function [data, ABETdata] = ABET2TableFn_ShockTest(filename)


%ABET2Table creates a table with columns (outlined under "column headers"
%comment) from ABET behavioral data "filename"

%ABET file should be either Raw data, or reduced data so long as all
%relevant events are included
%input variable should be the file name, written in single quotation marks.




%initiate table

%column headers
% (1)Trial: trial number
% (2)Block: 1,2,3,4, or 5
% (3)Force/Free: 0 if free, 1 if force
% (4)big/small: 
% (5)choicetime: timestamp of choice 
% (6)collection time: timestamp of reward collection
% (7)shock: 0 if no shock, 1 if shock
% (8)omission: 0 if false, 1 if free trial omission, 2 if forced trial
% omission
% (9)WL: 1 if win; 3 if loss
% (10)WSLScode: 2 if win+1; 4 if loss+1;
[~,~,ABETdata]=xlsread(filename);

Headers={'Trial','shock','shockIntensity','TrialPossible'};
data=table(zeros(25,1),zeros(25,1),zeros(25,1),zeros(25,1));
data.Properties.VariableNames([1:4])=Headers;

%%
%add ABET data to table

%loop through all rows
[rows,~]=size(ABETdata);
trial=1;

%find the first nonzero timestamp (all timestamps at 0 are program checks,
%and we don't care about these when we're searching for behavioral events
stop=999; rr=2;
while stop>0
    startRow=rr;
    if ABETdata{rr,1}>0
        stop=-999;
    end
    rr=rr+1;
    
    
end

initialShock=0;
for ii=startRow:rows
    
    
    
    data.Trial(trial)=trial;
    if regexp(ABETdata{ii,4},'TTL\w*')
        data.TrialPossible(trial)=ABETdata{ii,1};
    end

   
    %if there's a shock
    %if there's a shock, the shock is recorded as happening after the most
    %recent reward delivery.  So,the trial counter will have already
    %incremeneted by 1.  In order to properly record the shock trial, set
    %shock to 1 on the nth trial, where n=trial-1.
    if strcmp(ABETdata{ii,4},'Shocker #1')
        data.shock(trial)=1;
        data.choiceTime(trial)=ABETdata{ii,1};
        data.shockIntensity(trial)=initialShock;
        initialShock=initialShock+0.02;
        trial=trial+1;
        
    end
    
  




end
end

