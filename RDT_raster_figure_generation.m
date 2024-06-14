%Plot multiple graphs using rasterFromBehav
% close all; clear all; clc


[BehavData,ABETfile,Descriptives, block_end, largeRewSide, smallRewSide, forced_trial_start, free_trial_start]=ABET2TableFn_Chamber_A_v6('BLA-Insc-26 12162022 ABET.csv',[]);
SLEAP_data = readtable('BLA-Insc-26_RM D1_body_sleap_data.csv');
%EDIT FOR EACH MOUSE AS NECESSARY
SLEAP_time_range_adjustment =  []; %16.2733; %15.3983; %[]; %-16.5448; %[]; %[]16.2733; 


boris_file = []; %'BLA-Insc-27_RDT_D1.csv';




[BehavData, boris_Extract_tbl] = boris_to_table(boris_file, BehavData, block_end, largeRewSide, smallRewSide, SLEAP_time_range_adjustment, forced_trial_start, free_trial_start);


%make vectors to store timestamps from trial types
LargeRewInd=1;SmallRewInd=1;ShockInd=1;OmissionInd=1;systemInd=1;
LargeRew=[];
SmallRew=[];
Shock=[];
Omission=[];
system = [];
BlankTouches = [];
AA_large = [];
AA_small = [];


LargeRew = BehavData.choiceTime(BehavData.bigSmall == 1.2)';
SmallRew = BehavData.choiceTime(BehavData.bigSmall == 0.3)';
Shock = BehavData.choiceTime(BehavData.shock == 1)';
Omission = BehavData.choiceTime(BehavData.omissionALL == 1)';
BlankTouches = BehavData.choiceTime(BehavData.Blank_Touch == 1 | BehavData.Blank_Touch == 2)';

if any("type_binary" == string(BehavData.Properties.VariableNames))

    AA_large = BehavData.choiceTime(BehavData.type_binary == 1)';
    AA_small = BehavData.choiceTime(BehavData.type_binary == 2)';
else
    AA_large = zeros(1, size(BehavData.choiceTime, 1));
    AA_small = zeros(1, size(BehavData.choiceTime, 1));

end
yyLarge=[ones(size(LargeRew));zeros(size(LargeRew))];
yyLarge=yyLarge+ones(size(yyLarge))*13;

yySmall=[ones(size(SmallRew));zeros(size(SmallRew))];
yySmall=yySmall+ones(size(yySmall))*11;

yyShock=[ones(size(Shock));zeros(size(Shock))];
yyShock=yyShock+ones(size(yyShock))*9;

yyOmission=[ones(size(Omission));zeros(size(Omission))];
yyOmission=yyOmission+ones(size(yyOmission))*7;

yyBlankTouches = [ones(size(BlankTouches));zeros(size(BlankTouches))];
yyBlankTouches=yyBlankTouches+ones(size(BlankTouches))*5;



yyAA_large= [ones(size(AA_large));zeros(size(AA_large))];
yyAA_large=yyAA_large+ones(size(AA_large))*3;


yyAA_small= [ones(size(AA_small));zeros(size(AA_small))];
yyAA_small=yyAA_small+ones(size(AA_small));



block_labels = [60 block_end];

trial_timestamps = zeros(2,3);
forced_trial_timestamps = [];
free_trial_timestamps = []
forced_trial_counts = 0;
free_trial_counts = 0
forced_tmp = 1;
free_tmp = 1;
for zz = 1:size(BehavData, 1)
    if BehavData.ForceFree(zz) == 1 & (BehavData.bigSmall(zz) ~= 999 & ~isnan(BehavData.bigSmall(zz)))
        forced_trial_counts = forced_trial_counts + 1;
        if forced_trial_counts == 1
            forced_trial_timestamps(1, forced_tmp) = BehavData.stTime(zz);
        end
        
        
        if forced_trial_counts == 8
            forced_trial_timestamps(2, forced_tmp) = BehavData.collectionTime(zz);
            forced_trial_counts = 0;
            forced_tmp = forced_tmp+1;
        end
    elseif BehavData.ForceFree(zz) == 0 & (BehavData.bigSmall(zz) ~= 999 & ~isnan(BehavData.bigSmall(zz)))
        free_trial_counts = free_trial_counts + 1;
        if free_trial_counts == 1
            free_trial_timestamps(1, free_tmp) = BehavData.stTime(zz);
        end


        if free_trial_counts == 22
            free_trial_timestamps(2, free_tmp) = BehavData.collectionTime(zz);
            free_trial_counts = 0;
            free_tmp = free_tmp+1;
        end
    end
end




figure;
hold on
red=[1 0 0]; green= [0 .353 0]; blue = [0 0 .753]; yellow = [1,1,0]; gray = [.7 .7 .7]; orange = [0.9290 0.6940 0.1250];
plot([LargeRew;LargeRew],yyLarge,'color',blue);
plot([SmallRew;SmallRew],yySmall,'color',green);
plot([Shock;Shock],yyShock,'color',red);
plot([Omission;Omission],yyOmission,'color','k');
plot([BlankTouches;BlankTouches],yyBlankTouches,'color', orange);
plot([AA_large;AA_large],yyAA_large,'color','k');
plot([AA_small;AA_small],yyAA_small,'color', orange);
yline([12.5 10.5 8.5 6.5 4.5 2.5],'color','k')
xline(block_labels,'-',{{'Block 1', 'Start'},{'Block 2', 'Start'},{'Block 3', 'Start'}})
% Create patches for forced_trials_timestamps
% Create patches for forced_trials_timestamps
for i = 1:size(forced_trial_timestamps, 2)
    patch([forced_trial_timestamps(1, i), forced_trial_timestamps(1, i), forced_trial_timestamps(2, i), forced_trial_timestamps(2, i)], ...
        [0.5, 15.5, 15.5, 0.5], gray, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
end

for i = 1:size(free_trial_timestamps, 2)
    patch([free_trial_timestamps(1, i), free_trial_timestamps(1, i), free_trial_timestamps(2, i), free_trial_timestamps(2, i)], ...
        [0.5, 15.5, 15.5, 0.5], green, 'FaceAlpha', 0.1, 'EdgeColor', 'none');
end


xlabel('Time, s')

names = {'Small Aborts'; 'Large Aborts'; 'Blank Touches'; 'Omission';'Shock';'Small Reward';'Large Reward'};
set(gca, 'xtick',[0:400:5400],'ytick', [1.5 3.5 5.5 7.5 9.5 11.5 13.5],'yticklabel',names)

% xlim([0 BehavData.choiceTime(end)+100])
xlim([0 4000])

ylim([0.5 15.5])



% 
% concat_LargeRew = [LargeRew;ones(size(LargeRew))];
% concat_SmallRew = [LargeRew;ones(size(LargeRew))*2];
% concat_Omission = [Omission;ones(size(Omission))*3];
% concat_Shock = [Shock;ones(size(Shock))*4];
% 
% concat_all = [concat_LargeRew, concat_SmallRew, concat_Omission, concat_Shock]



%% OLD RASTER CODE USING FUNCTION IS BELOW - MIGHT BE GOOD TO REMAKE FUNCTION CAPABILITY ENCORPORATING NEW CODE ABOVE! 
figure
% subplot(3,2,1)
title('RDT Behavior')
[LargeRew,SmallRew,Shock,Omission, system, yyLarge, concat_all] = raster_RDT('BLA-INSC-27 01022023 ABET.csv'); %early Disc
