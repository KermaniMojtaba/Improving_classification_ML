% ft_defaults
clear
load('data_bi_ICA_filt_reRef.mat');
load('data_mono_ICA_filt_reRef.mat');



%% detrending
cfg = [];
cfg.detrend    = 'yes';
data_bi_ICA_filt_reRef = ft_preprocessing(cfg, data_bi_ICA_filt_reRef);
% data_mono_ICA_filt_reRef = ft_preprocessing(cfg, data_mono_ICA_filt_reRef);

%% remove bad trils
% jump
cfg = [];
cfg.continuous = 'yes';
cfg.artfctdef.zvalue.channel = 'all';
cfg.artfctdef.zvalue.cutoff = 50;
cfg.artfctdef.zvalue.trlpadding = 0;
cfg.artfctdef.zvalue.artpadding = 0;
cfg.artfctdef.zvalue.fltpadding = 0;
cfg.artfctdef.zvalue.cumulative = 'yes';
cfg.artfctdef.zvalue.medianfilter = 'yes';
cfg.artfctdef.zvalue.medianfiltord = 25;
cfg.artfctdef.zvalue.absdiff = 'yes';
cfg.artfctdef.zvalue.interactive = 'yes';
[~, artifact_jump] = ft_artifact_zvalue(cfg,data_bi_ICA_filt_reRef);

%%
cfg=[];
cfg.artfctdef.reject = 'complete';
cfg.artfctdef.jump.artifact = artifact_jump;
data_bi_ICA_filt_reRef_clean= ft_rejectartifact(cfg,data_bi_ICA_filt_reRef);
save data_bi_ICA_filt_reRef_clean data_bi_ICA_filt_reRef_clean

%% remove bad trils
% jump
% cfg = [];
% cfg.continuous = 'yes';
% cfg.artfctdef.zvalue.channel = 'all';
% cfg.artfctdef.zvalue.cutoff = 50;
% cfg.artfctdef.zvalue.trlpadding = 0;
% cfg.artfctdef.zvalue.artpadding = 0;
% cfg.artfctdef.zvalue.fltpadding = 0;
% cfg.artfctdef.zvalue.cumulative = 'yes';
% cfg.artfctdef.zvalue.medianfilter = 'yes';
% cfg.artfctdef.zvalue.medianfiltord = 25;
% cfg.artfctdef.zvalue.absdiff = 'yes';
% cfg.artfctdef.zvalue.interactive = 'yes';%'no';
% [~, artifact_jump] = ft_artifact_zvalue(cfg,data_mono_ICA_filt_reRef);

%%
% cfg=[];
% cfg.artfctdef.reject = 'complete';
% cfg.artfctdef.jump.artifact = artifact_jump;
% data_mono_ICA_filt_reRef_clean= ft_rejectartifact(cfg,data_mono_ICA_filt_reRef);
% save data_mono_ICA_filt_reRef_clean data_mono_ICA_filt_reRef_clean

%% reformat the data for MVPA light 
disp ('MVPA toolbox format')
data_bi_ICA_filt_reRef_clean.data_MVPA = zeros(length(data_bi_ICA_filt_reRef_clean.trial),length(data_bi_ICA_filt_reRef_clean.label),size(data_bi_ICA_filt_reRef_clean.trial{1, 1},2));

for i = 1:length(data_bi_ICA_filt_reRef_clean.trial)
    data_bi_ICA_filt_reRef_clean.data_MVPA(i,:,:) = data_bi_ICA_filt_reRef_clean.trial {i};
end
data_bi_ICA_filt_reRef_clean.trialinfo(data_bi_ICA_filt_reRef_clean.trialinfo==0)=2;


%% average trias
disp('Averaging trias');
% pparam = mv_get_preprocess_param('average_samples');
pparam.is_train_set = 1;
pparam.group_size   = 10;
[~, data_bi_ICA_filt_reRef_clean.data_MVPA_av, data_bi_ICA_filt_reRef_clean.trialinfo_av] =...
    mv_preprocess_average_samples(pparam, data_bi_ICA_filt_reRef_clean.data_MVPA, data_bi_ICA_filt_reRef_clean.trialinfo);

% average trials in FieldTrip format
for i = 1:size(data_bi_ICA_filt_reRef_clean.data_MVPA_av,1); data_bi_ICA_filt_reRef_clean.trial_av{i} = data_bi_ICA_filt_reRef_clean.data_MVPA_av(i,:,:);end

%% average time points
disp('Averaging time points');

data_bi_ICA_filt_reRef_clean.trial_av_t = zeros(length(data_bi_ICA_filt_reRef_clean.trialinfo_av),length(data_bi_ICA_filt_reRef_clean.label)*3,300);

tmp = [];
for j = 1:size(data_bi_ICA_filt_reRef_clean.trial_av_t,1)
    for i = 1:58
        tmp = [tmp;reshape(squeeze(data_bi_ICA_filt_reRef_clean.data_MVPA_av(j,i,:)),3,300)];
    end
    data_bi_ICA_filt_reRef_clean.trial_av_t(j,:,:) = tmp;
    tmp = [];
end
data_bi_ICA_filt_reRef_clean.time_avg = data_bi_ICA_filt_reRef_clean.time{1, 1}(1):0.01:data_bi_ICA_filt_reRef_clean.time{1, 1}(end);


%% perform decoding 
disp ('running MVPA')
cfg = [];
cfg.metric          = 'acc';
% cfg.classifier          = 'naive_bayes';
cfg.classifier      = 'svm';
cfg.preprocess      = {'pca','zscore'};
[perf_bi, res_bi] = mv_classify_across_time...
    (cfg,  data_bi_ICA_filt_reRef_clean.trial_av_t, data_bi_ICA_filt_reRef_clean.trialinfo_av);

res_bi.name = 'biLingualTrials';
mv_plot_result(res_bi, data_bi_ICA_filt_reRef_clean.time_avg);

decoding.time = res_bi;

%% channel decoding ( with FieldTrip)
cfg=[];
cfg.trials = data_bi_ICA_filt_reRef_clean.trialinfo_av==1;
trial1 = ft_selectdata(cfg, data_bi_ICA_filt_reRef_clean);

cfg=[];
cfg.trials = data_bi_ICA_filt_reRef_clean.trialinfo_av==2;
trial2 = ft_selectdata(cfg, data_bi_ICA_filt_reRef_clean);


%%
cfg = [] ;  
cfg.method      = 'mvpa';
cfg.metric      = 'acc';
cfg.classifier  = 'svm';
cfg.searchlight = 'yes';
cfg.design      = data_bi_ICA_filt_reRef_clean.trialinfo_av;
cfg.latency     = [0.6, 1];
cfg.avgovertime = 'yes';

stat = ft_timelockstatistics(cfg, trial1, trial2);
figure;
cfg              = [];
cfg.parameter    = 'accuracy';
cfg.layout    = 'quickcap64.mat';         
cfg.xlim         = [0, 0];

cfg.colorbar     = 'yes';
ft_topoplotER(cfg, stat);

decoding.loc = stat;

%%

