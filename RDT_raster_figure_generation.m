%Plot multiple graphs using rasterFromBehav
close all; clear all; clc

%for right now: if Incorrect A is Sprior, use "rasterFromBehavREV2"
%if Incorrect A is Snever, use "rasterFromBehav"

figure
% subplot(3,2,1)
title('RDT Photometry')
[LargeRew,SmallRew,Shock,Omission,yyLarge, concat_all] = raster_RDT('RRD398 10062023 ABET.csv'); %early Disc
