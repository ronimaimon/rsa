function [varargout] = fMRIDataPreparation_FSL(userOptions)
%
% fMRIDataPreparation is a function designed to take fMRI data and load it into
% the correct format for the rest of the toolbox to use.
%
% [fullBrainVols =] fMRIDataPreparation(betaCorrespondence, userOptions)
%
%       betaCorrespondence --- The array of beta filenames.
%               betas(condition, session).identifier is a string which referrs
%               to the filename (not including path) of the SPM beta image.
%               Alternatively, this can be the string 'SPM', in which case the
%               SPM metadata will be used to infer this information, provided
%               that userOptions.conditionLabels is set, and the condition
%               labels are the same as those used in SPM.
%
%        userOptions --- The options struct.
%                userOptions.analysisName
%                        A string which is prepended to the saved files.
%                userOptions.rootPath
%                        A string describing the root path where files will be
%                        saved (inside created directories).
%                userOptions.subjectNames
%                        A cell array containing strings identifying the subject
%                        names. Defaults to the fieldnames in fullBrainVols.
%                userOptions.conditionLabels
%                        A cell array containing the names of the conditions in
%                        this experiment. This must be set if the 'SPM' option
%                        is used.
%
% The following files are saved by this function:
%        userOptions.rootPath/ImageData/
%                userOptions.analysisName_ImageData.mat
%                        Contains the raw beta images in a struct such that
%                        fullBrainVols.(subject) is a [nVoxels nConditions
%                        nSessions] matrix.
%        userOptions.rootPath/Details/
%                userOptions.analysisName_fMRIDataPreparation_Details.mat
%                        Contains the userOptions for this execution of the
%                        function and a timestamp.
%  
%  Cai Wingfield 11-2009 -- 1-2010, 6-2010
%__________________________________________________________________________
% Copyright (C) 2010 Medical Research Council

returnHere = pwd; % We'll return to the pwd when the function has finished

%% Set defaults and check options struct
if ~isfield(userOptions, 'analysisName'), error('fMRIDataPreparation:NoAnalysisName', 'analysisName must be set. See help'); end%if
if ~isfield(userOptions, 'rootPath'), error('fMRIDataPreparation:NoRootPath', 'rootPath must be set. See help'); end%if
if ~isfield(userOptions, 'subjectNames'), error('fMRIDataPreparation:NoSubjectNames', 'subjectNames must be set. See help'); end%if
if (~isfield(userOptions, 'conditionLabels') && ischar(betaCorrespondence) && strcpmi(betaCorrespondence, 'SPM')), error('fMRIDataPreparation:NoConditionLabels', 'conditionLables must be set if the data is being extracted from SPM.'); end%if

% The filenames contain the analysisName as specified in the user options file
ImageDataFilename = [userOptions.analysisName, '_ImageData.mat'];
DetailsFilename = [userOptions.analysisName, '_fMRIDataPreparation_Details.mat'];

promptOptions.functionCaller = 'fMRIDataPreparation';
promptOptions.defaultResponse = 'S';
promptOptions.checkFiles(1).address = fullfile(userOptions.rootPath, 'ImageData', ImageDataFilename);
promptOptions.checkFiles(2).address = fullfile(userOptions.rootPath, 'Details', DetailsFilename);

overwriteFlag = overwritePrompt(userOptions, promptOptions);

if overwriteFlag

	%% Get Data
	nSubjects = numel(userOptions.subjectNames);
	nConditions = size(userOptions.alternativeConditionLabels,2);
	nSessions = 8; % TODO: move to userOptions

	fprintf('Gathering scans.\n');

	for subject = 1:nSubjects % For each subject

		% Figure out the subject's name
		thisSubject = userOptions.subjectNames{subject};

		fprintf(['Reading beta volumes for subject number ' num2str(subject) ' of ' num2str(nSubjects) ': ' thisSubject]);
        subjectPath = [userOptions.rootPath filesep thisSubject filesep 'functional'];

		for session = 1:nSessions % For each session...
			for condition = 1:nConditions % and each condition...
                path = [subjectPath filesep 'run' num2str(session) filesep ...
                    'run' num2str(session) '.feat' filesep 'stats' filesep 'pe' num2str(condition) '.nii.gz'];
                nii = load_untouch_nii(path);
                brainMatrix = nii.img;
				brainVector = reshape(brainMatrix, 1, []);
				subjectMatrix(:, condition, session) = brainVector; % (voxel, condition, session)

				clear brainMatrix brainVector path nii;

				fprintf('.');

			end%for

		end%for

		% For each subject, record the vectorised brain scan in a subject-name-indexed structure
		fullBrainVols.(thisSubject) = subjectMatrix; clear subjectMatrix;

		fprintf('\b:\n');

	end%for

	%% Save relevant info

	timeStamp = datestr(now);

% 	fprintf(['Saving image data to ' fullfile(userOptions.rootPath, 'ImageData', ImageDataFilename) '\n']);
    disp(['Saving image data to ' fullfile(userOptions.rootPath, 'ImageData', ImageDataFilename)]);
	gotoDir(userOptions.rootPath, 'ImageData');
	save(ImageDataFilename, 'fullBrainVols', '-v7.3');

% 	fprintf(['Saving Details to ' fullfile(userOptions.rootPath, 'Details', DetailsFilename) '\n']);
    disp(['Saving Details to ' fullfile(userOptions.rootPath, 'Details', DetailsFilename)]);
	gotoDir(userOptions.rootPath, 'Details');
	save(DetailsFilename, 'timeStamp', 'userOptions');
	
else
	disp(['Loading previously saved volumes from ' fullfile(userOptions.rootPath, 'ImageData', ImageDataFilename) '...']);
	load(fullfile(userOptions.rootPath, 'ImageData', ImageDataFilename));
end%if

if nargout == 1
	varargout{1} = fullBrainVols;
elseif nargout > 0
	error('0 or 1 arguments out, please.');
end%if:nargout

cd(returnHere); % Go back (probably will never have left)
