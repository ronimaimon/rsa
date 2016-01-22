%% My LDt
clc; clear all; close all;

%%%%%%%%%%%%%%%%%%%%
%% Initialisation %%
%%%%%%%%%%%%%%%%%%%%
toolboxRoot = '/home/user/dev/rsatoolbox/'; addpath(genpath(toolboxRoot)); % Catch sight of the toolbox code
addpath('/home/user/dev/nii_toolbox');
userOptions = defineUserOptions();

%%%%%%%%%%%%%%%%%%%%%%
%% Data preparation %%
%%%%%%%%%%%%%%%%%%%%%%
nSubjects = numel(userOptions.subjectNames);
nConditions = size(userOptions.alternativeConditionLabels,2);
nSessions = 8; % TODO: move to userOptions
for subject = 1:nSubjects % For each subject   
    % Figure out the subject's name
    thisSubject = userOptions.subjectNames{subject};
    
    fprintf(['Reading beta volumes for subject number ' num2str(subject) ' of ' num2str(nSubjects) ': ' thisSubject]);
    subjectPath = [userOptions.rootPath filesep thisSubject filesep 'functional'];
    
    for session = 1:nSessions % For each session...
        path = [subjectPath filesep 'run' num2str(session) filesep ...
            'run' num2str(session) '.feat' filesep 'filtered_func_data.nii.gz'];
        nii = load_untouch_nii(path);
        brainMatrix = nii.img;
        
        subjectMatrix(:,:,:,:, session) = brainMatrix; % (voxel, condition, session)
        path = [subjectPath filesep 'run' num2str(session) filesep ...
            'run' num2str(session) '.feat' filesep 'filtered_func_data.nii.gz'];
        
        xpath = [subjectPath filesep 'run' num2str(session) filesep ...
            'run' num2str(session) '.feat' filesep 'design.mat'];
        xpath
        x = dlmread(xpath,' ',5,0);
        xMatrix(:,:,session) = x(:,1:2:end);
        
        clear brainMatrix brainVector path nii;
        
        fprintf('.');
%         for condition = 1:nConditions % and each condition...
%             
%             
%         end%for
        
    end%for
    % For each subject, record the vectorised brain scan in a subject-name-indexed structure
%     mask = load_untouch_nii(fullfile(nii_dir, 'anatomy', ...
%     'masks_pve_0.nii.gz'));
%     mask = mask.img > 0;
%     mask = find(ws.mask);
%     num_of_relevant_voxels = length(ws.mask)
    
    data.(thisSubject).Ys = subjectMatrix; clear subjectMatrix;
    data.(thisSubject).Xs = xMatrix;
    fprintf('\b:\n');
end

% ModelRdm.all = [ 0 1 1 1; ...
%              1 0 1 1; ...
%              1 1 0 1; ...
%              1 1 1 0];
ModelRdm =      [ 0   0.5 0.5 1; ...
                  0.5 0   0   0.5; ...
                  0.5 0   0   0.5; ...
                  1   0.5 0.5 0];
%% SEARCHLIGHT
RDM_Brain = nan(128,128,32,6);
for subject = 1:nSubjects
        thisSubject = userOptions.subjectNames{subject};
        for i = 29:96
            i
            for j = 12:110
                for k = 3:30
                    for s = 1:4
                        Ys = (data.(thisSubject).Ys(i-1:i+1,j-1:j+1,k-1:k+1,:,s));
                        Ys = reshape(Ys, [] ,157);
                        Xs = data.(thisSubject).Xs(:,:,s);
                        if s == 1
                            Ya = Ys;
                            Xa = Xs;
                        else
                            Ya = [Ya Ys];
                            Xa = [Xa; Xs];
                        end
                    end
                    for s = 5:8
                        Ys = (data.(thisSubject).Ys(i-1:i+1,j-1:j+1,k-1:k+1,:,s));
                        Ys = reshape(Ys, [] ,157);
                        Xs = data.(thisSubject).Xs(:,:,s);
                        if s == 5
                            Yb = Ys;
                            Xb = Xs;
                        else
                            Yb = [Yb Ys];
                            Xb = [Xb; Xs];
                        end
                    end
                    [RDM_fdtFolded_ltv, cv2RDM_fdt_sq] = fisherDiscrTRDM(Xa, Ya', Xb, Yb',1:4);
                    RDM_Brain(i,j,k,:) = RDM_fdtFolded_ltv';             
                end
            end
        end
    
end

%%
 path = [subjectPath filesep 'run' num2str(1) filesep ...
            'run' num2str(1) '.feat' filesep 'thresh_zstat1.nii.gz'];
template_nii = load_untouch_nii(path);
for i = 1:6
    nii = template_nii;
    nii.img = RDM_Brain(:,:,:,i);
    filename = [userOptions.rootPath filesep thisSubject filesep 't_map' num2str(i)]
    save_untouch_nii(nii, filename);
    
end


%%
%% OLD
fullBrainVols = fMRIDataPreparation_FSL(userOptions);
binaryMasks_nS = fMRIMaskPreparation_FSL(userOptions);
responsePatterns = fMRIDataMasking(fullBrainVols, binaryMasks_nS, userOptions);