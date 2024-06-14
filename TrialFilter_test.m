function [data, trials, varargin] = TrialFilter_test(data,varargin)
  VALID_PARS = {'BLOCK','TYPE','SHK','REW','OMIT','OMITALL','ALL','WSLS','STTOCHO','WINSTAY','LOSESHIFT','LOSEOMIT', 'LOSESTAY', 'WIN', 'LOSS', 'AA', 'BLANK_TOUCH', 'LOSS_PLUS_ONE'};


  % parse varargin
  for ii = 1:2:length(varargin)
      if ~ismember(upper(varargin{ii}), VALID_PARS)
          error('%s is not a valid parameter', upper(varargin{ii}));
      end
  end


    % Combine duplicate parameter occurrences and their values
    combined_params = {};
    combined_values = {};
    for ii = 1:2:length(varargin)
        param = upper(varargin{ii});
        if ismember(param, combined_params)
            idx = find(strcmpi(combined_params, param));
            combined_values{idx} = [combined_values{idx}, varargin{ii+1}];
        else
            combined_params = [combined_params, param];
            combined_values = [combined_values, {varargin{ii+1}}];
        end
    end
    
    % Initialize logical index array for filtering
    idx = true(height(data), 1);
    
    % Apply filtering based on combined parameters and values
    for ii = 1:length(combined_params)
        param = combined_params{ii};
        values = combined_values(ii);
        
        condition = false(height(data), 1);
        for jj = 1:length(values)
            switch param
                case 'BLOCK'
                    condition = condition | (data.Block == values{jj});
                case 'TYPE'
                    condition = condition | (data.ForceFree == values{jj});
                case 'SHK'
                    condition = condition | (data.shock == values{jj});
                case 'REW'
                    condition = condition | (data.bigSmall == values{jj});
                case 'OMIT'
                    condition = condition | (data.omission == values{jj});
                case 'OMITALL'
                    condition = condition | (data.omissionALL == values{jj});
                case 'ALL'
                    % No filtering needed for 'ALL'
                    condition = true(height(data), 1);
                case 'WSLS'
                    condition = condition | (data.WSLScode == values{jj});
                case 'WINSTAY'
                    condition = condition | (data.win_stay == values{jj});
                case 'LOSESHIFT'
                    condition = condition | (data.lose_shift == values{jj});
                case 'LOSEOMIT'
                    condition = condition | (data.lose_omit == values{jj});
                case 'LOSESTAY'
                    condition = condition | (data.lose_stay == values{jj});
                case 'WIN'
                    condition = condition | (data.WL == values{jj});
                case 'LOSS'
                    condition = condition | (data.WL == values{jj});
                case 'AA'
                    condition = condition | (data.type_binary == values{jj});
                case 'BLANK_TOUCH'
                    condition = condition | (data.Blank_Touch == values{jj});
                case 'LOSS_PLUS_ONE'
                    condition = condition | (data.trial_after_shk == values{jj});
            end
        end
        combined_condition = any(condition, 2);
        % Combine the current condition with previous conditions using logical AND
        idx = idx & combined_condition;
    end
    
    % Apply filtering
    data = data(idx, :);
    trials = table2cell(data(:, 1));
end