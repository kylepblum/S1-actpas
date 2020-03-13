%% set file names, load file

    inputData.dataFileName = 'C:\Users\joh8881\Desktop\ActPassData\Han_20170203_COactpas_5ms.mat';
%     inputData.mapFileName = 'mapFileR:\limblab\lab_folder\Animal-Miscellany\Han_13B1\map files\Left S1\SN 6251-001459.cmp';

    % inputData.mapFileName = 'mapFileR:\limblab-archive\Retired Animal Logs\Monkeys\Chips_12H1\map_files\left S1\SN 6251-001455.cmp';
    inputData.mapFileName = 'mapFileZ:\Basic_Sciences\Phys\L_MillerLab\limblab\lab_folder\Animal-Miscellany\Han_13B1\map files\Left S1\SN 6251-001459.cmp';

    load(inputData.dataFileName);
    
    inputData.task='taskCObump'; 
    inputData.array1='arrayLeftS1'; 
    inputData.monkey='monkeyHan';
    inputData.labnum = 6;
    
%% split into trials

    splitParams.split_idx_name = 'idx_startTime';
    splitParams.linked_fields = {'trialID','bumpDir','tgtDir','result'};
    tds = splitTD(trial_data,splitParams);

%% separate passive and active trials
    td_bump = tds(~isnan([tds.idx_bumpTime]));
    td_act = tds(isnan([tds.idx_bumpTime]));
    td_act = td_act(find([td_act.result]=='R'));
    
%% get movement onset for active and passive 

    %active
     td_act = getNorm(td_act,struct('signals','vel','field_extra','_norm'));
     paramsAct.start_idx = 'idx_goCueTime';
     paramsAct.end_idx = 'idx_endTime';
     td_act = getMoveOnsetAndPeak(td_act, paramsAct);
     td_act = td_act(~isnan([td_act.idx_movement_on]));
     td_act = td_act(~isnan([td_act.tgtDir]));
     
    %passive
     td_bump = getNorm(td_bump,struct('signals','vel','field_extra','_norm'));
     paramsBump.start_idx = 'idx_bumpTime';
     paramsBump.end_idx = 'idx_goCueTime';
     td_bump = getMoveOnsetAndPeak(td_bump, paramsBump);
     td_bump = td_bump(~isnan([td_bump.idx_movement_on]));
     td_bump = td_bump(~isnan([td_bump.bumpDir]));

%% trim active and passive

    tdAct = trimTD(td_act, {'idx_movement_on',-100}, {'idx_movement_on',100});
    tdBump = trimTD(td_bump, {'idx_movement_on',-100}, {'idx_movement_on',100});
    
% %% separate by direction
% 
%     %find directions in tds
%     tempActDirs = unique([tdAct(1:end).tgtDir]);
%     for i=1:numel(tempActDirs)
%         emgDataAct(i).tgtDirs = tempActDirs(i);
%     end
%     
%     tempPassDirs = unique([tdBump(1:end).bumpDir]);
%     for i=1:numel(tempPassDirs)
%         emgDataPass(i).bumpDirs = tempPassDirs(i);
%     end
% 
%     %struct emgData contains td's separated by direction
%     for i=1:numel(emgDataAct)
%         emgDataAct(i).tdActDir = tdAct([tdAct.tgtDir]==emgDataAct(i).tgtDirs);
%     end
%     
%     for i=1:numel(emgDataPass)
%         emgDataPass(i).tdBumpDir = tdBump([tdBump.bumpDir]==emgDataPass(i).bumpDirs);
%     end
    
%% find average emg signals

avgDataAct = trialAverage(tdAct,{'tgtDir'});
avgDataPass = trialAverage(tdBump,{'bumpDir'});

%% plot avg emg signals

%plot em active
    timeArray = [-20:1:20];
    muscleArray = [5,6,7,12,22];
    muscleNames = string({'deltAnt','deltMid','deltPost','triMid','biLat'});
    directions = string({'0','90','180','270'});
    
    for i=1:numel(muscleArray)
        for j=1:4
            figureName = strcat(muscleNames(i),directions(j));
            figure()
            title(figureName)
            hold on
            plot(timeArray, avgDataAct(j).emg(81:121,muscleArray(i)))
            plot(timeArray, avgDataPass(j).emg(81:121,muscleArray(i)))
            legend('Active Average EMG','Passive Average EMG')
        end
    end
    
   
    

    
    
    