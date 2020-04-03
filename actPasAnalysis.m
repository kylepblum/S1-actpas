% %% set file names, load file
% 
%     %inputData.dataFileName = 'C:\Users\joh8881\Desktop\ActPassData\Han_20170203_COactpas_5ms.mat';
%     inputData.dataFileName = '/Volumes/fsmresfiles/Basic_Sciences/Phys/L_MillerLab/limblab/User_folders/Juliet/actPasAnalysis/Han_20171201_COactpas_5ms.mat';
% 
%     %inputData.mapFileName = 'mapFileZ:\Basic_Sciences\Phys\L_MillerLab\limblab\lab_folder\Animal-Miscellany\Han_13B1\map files\Left S1\SN 6251-001459.cmp';
%     %inputData.mapFileName = 'mapFileVolumes\fsmresfiles\Basic_Sciences\Phys\L_MillerLab\limblab\lab_folder\Animal-Miscellany\Han_13B1\map files\Left S1\SN 6251-001455.cmp';
% 
     load('Han_20171201_COactpas_5ms.mat');
%     
%     inputData.task='taskCObump'; 
%     inputData.array1='arrayLeftS1'; 
%     inputData.monkey='monkeyHan';
%     inputData.labnum = 6;

%% normalize data
    td = trial_data;
    %rebin TD to 50ms bins
    %td = binTD(trial_data, 10);
    %only look at sorted units
    td.S1_spikes(:,td.S1_unit_guide(:,2)==0) = [];
    td.S1_unit_guide(td.S1_unit_guide(:,2)==0,:) = [];
    %normalize data
    td.emg = normalize(td.emg, 'range');
    td.muscle_vel = normalize(td.muscle_vel, 'range');
    td.muscle_len = normalize(td.muscle_len, 'range');
    params.signals = {'emg','all';'muscle_len','all';'muscle_vel','all'};
    params.width = 0.01;
    td = smoothSignals(td,params);
    %larger smoothing window bec low firing neurons 
    td.S1_spikes = normalize(td.S1_spikes, 'range');
    params1.signals = {'S1_spikes','all'};
    params1.width = 0.01;
    params1.calc_rate = true;
    td = smoothSignals(td,params1);
    
    clear params params1

%% split into trials

    splitParams.split_idx_name = 'idx_startTime';
    splitParams.linked_fields = {'trialID','bumpDir','tgtDir','result'};
    tds = splitTD(td,splitParams);
    
    clear splitParams

%% separate passive and active trials, only look at reward trials
    td_bump = tds(~isnan([tds.idx_bumpTime]));
    td_act = tds(isnan([tds.idx_bumpTime]));
    td_act = td_act(find([td_act.result]=='R'));
    
    clear tds
    
%% get movement onset for active and passive 

    %active
    td_act = getNorm(td_act,struct('signals','vel','field_extra','_norm'));
    paramsAct.start_idx = 'idx_goCueTime';
    paramsAct.start_idx_offset = -5;
    paramsAct.end_idx = 'idx_trial_end';
    td_act = getMoveOnsetAndPeak(td_act, paramsAct);
    td_act = td_act(~isnan([td_act.idx_movement_on]));
    td_act = td_act(~isnan([td_act.tgtDir]));
     
    %passive
    td_bump = getNorm(td_bump,struct('signals','vel','field_extra','_norm'));
    paramsBump.start_idx = 'idx_bumpTime'
    paramsBump.end_idx = 'idx_goCueTime';
    td_bump = getMoveOnsetAndPeak(td_bump, paramsBump);
    td_bump = td_bump(~isnan([td_bump.idx_movement_on]));     
    td_bump = td_bump(~isnan([td_bump.bumpDir]));

    clear paramsAct paramsBump
     
%% trim active and passive

    td_act = trimTD(td_act, {'idx_movement_on',-0.5/td.bin_size}, {'idx_movement_on',0.5/td.bin_size});
    td_bump = trimTD(td_bump, {'idx_movement_on',-0.5/td.bin_size}, {'idx_movement_on',0.5/td.bin_size});
    
%% find average muscle signals

    paramsAct.conditions = 'tgtDir';
    paramsAct.add_std = true;
    avgDataAct = trialAverage(td_act,paramsAct);

    paramsPas.conditions = 'bumpDir';
    paramsPas.add_std = true;
    avgDataPass = trialAverage(td_bump,paramsPas);
    
    %calculate 95% confidence interval from std
    for i=1:numel(avgDataAct)
        %active
        ActEmgStd = cell2mat({avgDataAct(i).emg_std});
        avgDataAct(i).emg_confInt = 1.96 .* ActEmgStd ./ sqrt(numel(ActEmgStd(:,1)));
        
        ActMuscleVelStd = cell2mat({avgDataAct(i).muscle_vel_std});
        avgDataAct(i).muscle_vel_confInt = 1.96 .* ActMuscleVelStd ./ sqrt(numel(ActMuscleVelStd(:,1)));
        
        ActMuscleLenStd = cell2mat({avgDataAct(i).muscle_len_std});
        avgDataAct(i).muscle_len_confInt = 1.96 .* ActMuscleLenStd ./ sqrt(numel(ActMuscleLenStd(:,1)));
        
        ActSpikesStd = cell2mat({avgDataAct(i).S1_spikes_std});
        avgDataAct(i).S1_spikes_confInt = 1.96 .* ActSpikesStd ./ sqrt(numel(ActSpikesStd(:,1)));
        
        %passive
        PasEmgStd = cell2mat({avgDataPass(i).emg_std});
        avgDataPass(i).emg_confInt = 1.96 .* PasEmgStd ./ sqrt(numel(PasEmgStd(:,1)));
        
        PasMuscleVelStd = cell2mat({avgDataPass(i).muscle_vel_std});
        avgDataPass(i).muscle_vel_confInt = 1.96 .* PasMuscleVelStd ./ sqrt(numel(PasMuscleVelStd(:,1)));
        
        PasMuscleLenStd = cell2mat({avgDataPass(i).muscle_len_std});
        avgDataPass(i).muscle_len_confInt = 1.96 .* PasMuscleLenStd ./ sqrt(numel(PasMuscleLenStd(:,1)));
        
        PasSpikesStd = cell2mat({avgDataPass(i).S1_spikes_std});
        avgDataPass(i).S1_spikes_confInt = 1.96 .* PasSpikesStd ./ sqrt(numel(PasSpikesStd(:,1)));
    end

    clear paramsAct paramsPas td_act td_bump avgData
    clear i ActEmgStd ActMuscleVelStd ActMuscleLenStd ActSpikesStd
    clear PasEmgStd PasMuscleVelStd PasMuscleLenStd PasSpikesStd

%% plot avg emg signals

    %define time window
    timeArray = [-500:(td.bin_size*1000):500]; %ms
    tStart = 1; %bins
    tEnd = numel(avgDataAct(1).emg(:,1)); %bins
    %define muscles
    muscleArrayEMG = [5,6,7,12,22,3,17]; %from EMG list
    muscleArrayM = [8,9,10,38,3,19,14]; %from motion tracking list
    muscleNames = string({'deltAnt','deltMid','deltPost','triMid','biLat','FCU','ECU'});
    %define directions
    dir = {avgDataAct.tgtDir};
    directions = string(unique(cell2mat(dir)));
    
    %plot 'em
    figEMG = figure('Name','EMG');
    figMuscleVel = figure('Name','Muscle Velocity');
    figMuscleLen = figure('Name','Muscle Length');
    figUnits = figure('Name','Neural Units');
    k=0;
    
    for i=1:numel(muscleArrayEMG)
        for j=1:numel(directions)
            k=k+1;
            
            %emg plots
            set(0,'CurrentFigure',figEMG)
            subplot(numel(muscleArrayEMG),numel(directions),k);
            title(strcat(muscleNames(i),directions(j)))
            hold on
            errorbar(timeArray, avgDataAct(j).emg(tStart:tEnd,muscleArrayEMG(i)), avgDataAct(j).emg_confInt(tStart:tEnd,muscleArrayEMG(i)))
            errorbar(timeArray, avgDataPass(j).emg(tStart:tEnd,muscleArrayEMG(i)), avgDataPass(j).emg_confInt(tStart:tEnd,muscleArrayEMG(i)))
            axis([-500 500 0 0.25]);
            sgtitle('EMG');
            if k==1
                legend('Active','Passive','Position',[0 0.8 0.12 0.1])
            end
            
            %muscle velocity plots
            set(0,'CurrentFigure',figMuscleVel)
            subplot(numel(muscleArrayM),numel(directions),k);
            title(strcat(muscleNames(i),directions(j)))
            hold on
            errorbar(timeArray, avgDataAct(j).muscle_vel(tStart:tEnd,muscleArrayM(i)), avgDataAct(j).muscle_vel_confInt(tStart:tEnd,muscleArrayM(i)))
            errorbar(timeArray, avgDataPass(j).muscle_vel(tStart:tEnd,muscleArrayM(i)), avgDataPass(j).muscle_vel_confInt(tStart:tEnd,muscleArrayM(i)))
            axis([-500 500 0 0.8]);
            sgtitle('Muscle Velocity');
            if k==1
                legend('Active','Passive','Position',[0 0.8 0.12 0.1])
            end
            
            %muscle length plots
            set(0,'CurrentFigure',figMuscleLen)
            subplot(numel(muscleArrayM),numel(directions),k);
            title(strcat(muscleNames(i),directions(j)))
            hold on
            errorbar(timeArray, avgDataAct(j).muscle_len(tStart:tEnd,muscleArrayM(i)), avgDataAct(j).muscle_len_confInt(tStart:tEnd,muscleArrayM(i)))
            errorbar(timeArray, avgDataPass(j).muscle_len(tStart:tEnd,muscleArrayM(i)), avgDataPass(j).muscle_len_confInt(tStart:tEnd,muscleArrayM(i)))
            axis([-500 500 0 0.8]);
            sgtitle('Muscle Length');
            if k==1
                legend('Active','Passive','Position',[0 0.8 0.12 0.1])
            end
        end
    end
    
    k=0;
    for i=11:17
        for j=1:numel(directions)
            k=k+1;
            
            %neural unit plots
            set(0,'CurrentFigure',figUnits)
            subplot(7,numel(directions),k);
            title(strcat('Neuron',int2str(i),' Direction',directions(j)))
            hold on
            errorbar(timeArray, avgDataAct(j).S1_spikes(tStart:tEnd,i), avgDataAct(j).S1_spikes_confInt(tStart:tEnd,i))
            errorbar(timeArray, avgDataPass(j).S1_spikes(tStart:tEnd,i), avgDataPass(j).S1_spikes_confInt(tStart:tEnd,i))
            axis([-500 500 0 10]);
            sgtitle('Neural Units');
            if k==1
                legend('Active','Passive','Position',[0 0.8 0.12 0.1])
            end
        end
    end
    
    
    clear i j k tStart tEnd dir directions muscleArrayEMG muscleArrayM muscleNames timeArray
    

    
    
    