%Plot multiple graphs using rasterFromBehav
% close all; clear all; clc

%for right now: if Incorrect A is Sprior, use "rasterFromBehavREV2"
%if Incorrect A is Snever, use "rasterFromBehav"

figure
% subplot(3,2,1)
title('RDT Behavior')
[LargeRew,SmallRew,Shock,Omission,yyLarge, concat_all] = raster_RDT('BLA-INSC-27 12302022 ABET.csv'); %early Disc
