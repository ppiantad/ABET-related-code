
function [LargeRew,SmallRew,Shock,Omission, yyLarge, concat_all] = raster_RDT(fileName)

%read excel file
[num,text,raw]=xlsread(fileName);


[len,wid]=size(raw);

%find row that with headers
row=1;
found=0;
while row<=length(raw) && found ==0
    if strcmp(raw{row,1},'Evnt_Time')
        HeaderRow=row;
        found=999;
    elseif row>35000
        found=1;
    else
        row=row+1;
    end
end

%find columns with item name, timestamp
for col=1:wid
    if strcmp(raw{HeaderRow,col},'Item_Name')
        ItemCol=col;
       
    elseif strcmp(raw{HeaderRow,col},'Evnt_Time')
        TimeCol=col;
    end
end
    

%make vectors to store timestamps from trial types
LargeRewInd=1;SmallRewInd=1;ShockInd=1;OmissionInd=1;
LargeRew=[];
SmallRew=[];
Shock=[];
Omission=[];

for i=HeaderRow:len
    if raw{i,TimeCol}~=0
        if strcmp(raw{i,ItemCol},'BigRew_forced_counter')|| strcmp(raw{i,ItemCol},'BigRew_free_counter')
            LargeRew(LargeRewInd)=raw{i,TimeCol};
            LargeRewInd=LargeRewInd+1;
        elseif strcmp(raw{i,ItemCol},'SmallRew_forced_counter') || strcmp(raw{i,ItemCol},'SmallRew_free_counter')
            SmallRew(SmallRewInd)=raw{i,TimeCol};
            SmallRewInd=SmallRewInd+1;
        elseif strcmp(raw{i,ItemCol},'Shocker #1') 
            Shock(ShockInd)=raw{i,TimeCol};
            ShockInd=ShockInd+1;
        elseif strcmp(raw{i,ItemCol},'forcedtrial_omission') || strcmp(raw{i,ItemCol},'freetrial_omission')
            Omission(OmissionInd)=raw{i,TimeCol};
            OmissionInd=OmissionInd+1;
        end
    end
    
    
end

yyLarge=[ones(size(LargeRew));zeros(size(LargeRew))];
yyLarge=yyLarge+ones(size(yyLarge))*7;

yySmall=[ones(size(SmallRew));zeros(size(SmallRew))];
yySmall=yySmall+ones(size(yySmall))*5;

yyShock=[ones(size(Shock));zeros(size(Shock))];
yyShock=yyShock+ones(size(yyShock))*3;

yyOmission=[ones(size(Omission));zeros(size(Omission))];
yyOmission=yyOmission+ones(size(yyOmission));




hold on
red=[1 0 0]; green= [0 .353 0]; blue = [0 0 .753]; yellow = [1,1,0];
plot([LargeRew;LargeRew],yyLarge,'color',blue);
plot([SmallRew;SmallRew],yySmall,'color',green);
plot([Shock;Shock],yyShock,'color',red);
plot([Omission;Omission],yyOmission,'color',yellow);
line([0 5400], [6.5 6.5],'color','k')
line([0 5400], [4.5 4.5],'color','k')
line([0 5400], [2.5 2.5],'color','k')



xlabel('Time, s')

names = {'Omission';'Shock';'Small Reward';'Large Reward'};
set(gca, 'xtick',[0:400:5400],'ytick', [1.5 3.5 5.5 7.5],'yticklabel',names)

xlim([0 5400])

ylim([0.5 8.5])

figure(2);
plot([LargeRew;LargeRew],yyLarge,'color',blue);


concat_LargeRew = [LargeRew;ones(size(LargeRew))];
concat_SmallRew = [LargeRew;ones(size(LargeRew))*2];
concat_Omission = [Omission;ones(size(Omission))*3];
concat_Shock = [Shock;ones(size(Shock))*4];

concat_all = [concat_LargeRew, concat_SmallRew, concat_Omission, concat_Shock]


end
