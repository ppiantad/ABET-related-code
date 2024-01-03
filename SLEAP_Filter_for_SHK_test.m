function [data, zall_motion, allSignals_motion, SLEAP_data_vel_filtered_session] = SLEAP_Filter_for_SHK_test(data, allSignals, SLEAP_data, TRANGE, BASELINE_PER, SLEAP_time_range_adjustment, downsampled_size)
%% filter SLEAP_data by EPOC Choice
time_ranges = data.time_ranges;





SLEAP_data.vel_filtered = sgolayfilt(SLEAP_data.vel_cm_s, 2, 33);
SLEAP_data.vel_filtered_2 = sgolayfilt(SLEAP_data.vel_cm_s, 3, 25);
SLEAP_data.x_pix_filtered = sgolayfilt(SLEAP_data.x_pix, 2, 33);
SLEAP_data.y_pix_filtered = sgolayfilt(SLEAP_data.y_pix, 2, 33);
SLEAP_data.pix_calc_2 = SLEAP_data.x_pix*(2.54/96);

SLEAP_data.pix_calc_3= SLEAP_data.pix_calc_2 * (2.54/96) * (30/1);

if ~isempty(SLEAP_time_range_adjustment)
    time_ranges = time_ranges-SLEAP_time_range_adjustment;
end

SLEAP_data_vel_filtered_session = SLEAP_data.vel_filtered_2';


KEEPDATA  = 1;
%%
% FILTER ALL EXISTING DATA ON THESE TIME RANGES
% filter streams
if ~isempty(SLEAP_data)
    n = fieldnames(data.streams);
    for i = 1:length(n)
        fs_cam = 30; %set sampling rate according to camera, this is hard coded for now
        filtered = [];
        max_ind = max(size(SLEAP_data));
        good_index = 1;
        for j = 1:size(time_ranges,2)
            onset = round(time_ranges(1,j)*fs_cam)+1;
            offset = round(time_ranges(2,j)*fs_cam);
            % throw it away if onset or offset extends beyond recording window
            if isinf(offset)
                if onset <= max_ind && onset > 0
                    filtered{good_index} = SLEAP_data(onset:end);
                    break %return
                end
            else
                if offset <= max_ind && offset > 0 && onset <= max_ind && onset > 0
                    filtered{good_index} =SLEAP_data.vel_filtered(SLEAP_data.idx_frame(onset:offset)); %SLEAP_data.vel_cm_s(SLEAP_data.idx_frame(onset:offset));
                    good_index = good_index + 1;
                end
            end
        end
        if KEEPDATA
            data.streams.Motion.filtered = filtered;
        else
            data.streams.Motion.data = filtered;
            data.streams.Motion.filtered = [];
        end
    end
end

%%
allSignals_motion = cell2mat(data.streams.Motion.filtered)';





minLength_motion = size(allSignals_motion,2);


ts_motion = TRANGE(1) + (1:minLength_motion) / fs_cam;

downsample_factor = (size(allSignals,2) /  minLength_motion); %allSignals comes from PhotometryAnalysis code


%%
zall_motion = zeros(size(allSignals_motion));

pp = 1;
tmp = 0;
% Comment out BL_shifted(pp,:) and the associated ind to not adjust
% baseline to the ITI period

for i = 1:size(allSignals_motion,1)
%     BL_shifted(pp,:)=[BASELINE_PER(1)+time2EPOC(i) BASELINE_PER(2)+time2EPOC(i)]; %BL_shifted(pp,:)=[BASELINE_PER(1)+(-1*time2Collect(i)) BASELINE_PER(2)+time2Collect(i)];
%     ind = ts2(1,:) < BL_shifted(pp,2) & ts2(1,:) > BL_shifted(pp,1);
    ind = ts_motion(1,:) < BASELINE_PER(2) & ts_motion(1,:) > BASELINE_PER(1);
    
    
%     zb = mean(Y_dF_all(i,:)); % baseline period mean
%     zsd = std(Y_dF_all(i,:)); % baseline period stdev
    
    %use if you want to calculate the Z-score using your specified baseline
%     zb_motion = mean(allSignals_motion(i,ind)); % baseline period mean
%     zsd_motion = std(allSignals_motion(i,ind)); % baseline period stdev

    %use if you want to take the Z-score using the entire window mean
    zb_motion = mean(allSignals_motion(i,:)); % entire window mean
    zsd_motion = std(allSignals_motion(i,:)); % entire window stdev
    
    
%     zbmedian_motion = median(allSignals_motion(i,length(ts_motion)));


    
    pp=pp+1;
    for j = 1:size(allSignals_motion,2) % Z score per bin
        tmp = tmp + 1;
        zall_motion(i,tmp)=(allSignals_motion(i,j) - zb_motion)/zsd_motion;
%         dfALL(i,tmp)=(allSignals_motion(i,j) - zbmedian_motion)/zbmedian_motion;
%         BL_mean_motion(i) = mean(allSignals_motion(i,:));
    end
    tmp=0;
end


%%
% s = seconds(99.0816213722229);
% s.Format = 'hh:mm:ss.SSS'

%%
% N = 2;
% 
% for ii = 1:size(allSignals,1)
%     zall_motion_downsample(ii,:) = arrayfun(@(i) mean(zall_motion(ii,i:i+N-1)),1:N:length(zall_motion)-N+1);
% end
% minLength1 = size(zall_motion_downsample,2);

% sgf_6 = sgolayfilt(SLEAP_data.vel_cm_s, 2, 33);
% [pks,locs] = findpeaks(sgf_6, 30, 'MinPeakHeight',5,'MinPeakDistance',5);
% 
% 
% samples = 60;
% 
% n = 1;
% 
% for ii = 1:size(locs,1)
%     %time series doesn't match exactly, round to 2 decimal places before
%     %comparing w/ ismembertol
%     [~,ind] = ismembertol(round(locs(ii),2), round(SLEAP_data.idx_time,2));
%     window = [(ind-60) (ind+60)];
%     peak_motion(ii,:) = SLEAP_data.vel_cm_s(window(1):window(2));
%     n = 1;
%     
%     for kk = 1:size(peak_motion,2)
%         if peak_motion(ii,60-n) <=1.5
%             start_ind(ii) = peak_motion(ii,60-n);
%         elseif peak_motion(ii,60-n) >= 1.5
%             n = n+1;
%             if n == 60
%                 peak_motion(ii,:) = [];
%             end
% 
%     
%         end
% %     [changeindex(ii),~] = findchangepts(peak_motion(ii,:));
%     changeindex{ii,:} = findchangepts(peak_motion(ii,:),'Statistic','linear','MinThreshold',50);
%     %findchangepts(peak_motion(84,:),'Statistic','linear','MinThreshold',50)
%     
%     end
% end   


%%
% for ii = 1:fs_cam*2:size(SLEAP_data,1)
%     2s_slopes = polyfit(SLEAP_data.idx_time(1:61), SLEAP_data.vel_cm_s(1:61));

% size_zall_array = floor(size(allSignals,2)/N);
% 
% interp_factor = size(ts_motion,2)/size_zall_array;
% 
% test_interp_2 = interp(allSignals_motion(1,:), interp_factor);
% 
% 
% test_interp = interp(allSignals_motion(1,:), 2);
% ts_interp = interp(ts_motion,2);
