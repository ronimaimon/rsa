% Recipe_fMRI_searchlight
%
% Cai Wingfield 11-2009, 2-2010, 3-2010, 8-2010
%__________________________________________________________________________
% Copyright (C) 2010 Medical Research Council

%%%%%%%%%%%%%%%%%%%%
%% Initialisation %%
%%%%%%%%%%%%%%%%%%%%

toolboxRoot = '/home/user/dev/rsatoolbox/'; addpath(genpath(toolboxRoot)); % Catch sight of the toolbox code
addpath('/home/user/dev/nii_toolbox');
userOptions = defineUserOptions();

%%%%%%%%%%%%%%%%%%%%%%
%% Data preparation %%
%%%%%%%%%%%%%%%%%%%%%%

fullBrainVols = fMRIDataPreparation_FSL(userOptions);
binaryMasks_nS = fMRIMaskPreparation_FSL(userOptions);

%%%%%%%%%%%%%%%%%%%%%
%% RDM calculation %%
%%%%%%%%%%%%%%%%%%%%%

models = constructModelRDMs(modelRDMs(), userOptions);

%%%%%%%%%%%%%%%%%
%% Searchlight %%
%%%%%%%%%%%%%%%%%

fMRISearchlight(fullBrainVols, binaryMasks_nS, models, userOptions);
