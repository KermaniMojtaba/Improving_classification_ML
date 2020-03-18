% improving the performance of ML classifiers for electroencephalographic
% data.

% Matlab toolbox for classification and regression of multi-dimensional data

%% average trias
% pparam = mv_get_preprocess_param('average_samples');
pparam.is_train_set = 1;
pparam.group_size   = 10;
[~, data_bi_clean.data_MVPA_av, data_bi_clean.trialinfo_av] =...
    mv_preprocess_average_samples(pparam, data_bi_clean.data_MVPA, data_bi_clean.trialinfo);

% average trials in FieldTrip format
for i = 1:size(data_bi_clean.data_MVPA_av,1); data_bi_clean.trial_av{i} = data_bi_clean.data_MVPA_av(i,:,:);end

%% average time points

data_bi_clean.trial_av_t = zeros(25,174,300);

tmp = [];
for j = 1:28
    for i = 1:58
        tmp = [tmp;reshape(squeeze(data_bi_clean.data_MVPA_av(j,i,:)),3,300)];
    end
    data_bi_clean.trial_av_t(j,:,:) = tmp;
    tmp = [];
end
data_bi_clean.time_avg = data_bi_clean.time{1, 1}(1):0.01:data_bi_clean.time{1, 1}(end);


%% perform decoding 
cfg = [];
cfg.metric          = 'acc';
cfg.classifier      = 'svm';
cfg.preprocess      = 'pca';
[perf_bi, res_bi] = mv_classify_across_time...
    (cfg,  data_bi_clean.trial_av_t, data_bi_clean.trialinfo_av);

res_bi.name = 'biLingualTrials';
mv_plot_result(res_bi, data_bi_clean.time_avg);





