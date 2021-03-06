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
    
%%
%%plot velocity
    %create x and y array for plot
    velocityData.yVel = [];
    velocityData.xVel = [];
    velocityData.velCombo = [];
    velocityData.time = [];
    %look at trial 176
    i=trial_data.idx_startTime(176);
    while i<trial_data.idx_startTime(177)
        %add velocity to y array for plot
        velocityData.yVel = [velocityData.yVel, trial_data.vel(i,2)];
        velocityData.xVel = [velocityData.xVel, trial_data.vel(i,1)];
        velocityData.velCombo = [velocityData.velCombo, sqrt(trial_data.vel(i,1)^2 + trial_data.vel(i,2)^2)];
        %add time bin to x array for plot
        velocityData.time = [velocityData.time, i]
        %add one time bin for next loop (bin = 5ms)
        i = i+1;
    end
    
    hold on
    %plot(inputData.time, inputData.yVel, 'DisplayName', 'yVel')
    %plot(inputData.time, inputData.xVel, 'DisplayName', 'xVel')
    plot(velocityData.time, velocityData.velCombo, 'DisplayName', 'velCombo');
    %show bump onset on graph (time 107551)
    plot(trial_data.idx_bumpTime(69),0,'r*');
    hold off
    legend('velocity');
    
    %legend('velCombo', 'bumpOnset');
    %pick movement onset points on graph
    %[x,y] = getpts
    
    %trial 175 movement onset time = 107010
    %trial 176 bump movement onset time = bumpTime(69) = 107551
    %trial 176 movement onset time = 107690
    velocityData.moveOnset = [107551, 107690];
    
%%
%%plot EMG 100ms (20 bins) before and after movement onset
    disp('start')

    %set window size
    emgData.timeWindow = 0.1/trial_data.bin_size;

    %create time arrays
    emgData.time = [velocityData.moveOnset(1)-emgData.timeWindow:1:velocityData.moveOnset(1)+emgData.timeWindow;
                    velocityData.moveOnset(2)-emgData.timeWindow:1:velocityData.moveOnset(2)+emgData.timeWindow];
    
    %create EMG arrays
    emgData.deltAnt = zeros(3,2*emgData.timeWindow+1);
    emgData.deltMid = zeros(3,2*emgData.timeWindow+1);
    emgData.deltPost = zeros(3,2*emgData.timeWindow+1);
    emgData.triMid = zeros(3,2*emgData.timeWindow+1);
    emgData.biLat = zeros(3,2*emgData.timeWindow+1);
    
    %look at all 2 events (176 bump, 176 move)
    for event = 1:2
        %go through current event
        for i=1:size(emgData.time,2)
            %add emg to 5 muscle arrays
            emgData.deltAnt(event,i) = trial_data.emg(emgData.time(event,i),5);
            emgData.deltMid(event,i) = trial_data.emg(emgData.time(event,i),6);
            emgData.deltPost(event,i) = trial_data.emg(emgData.time(event,i),7);
            emgData.triMid(event,i) = trial_data.emg(emgData.time(event,i),12);
            emgData.biLat(event,i) = trial_data.emg(emgData.time(event,i),22);
        end
    end
        
    %plot em
    timeArray = [-20:1:20];
    
    figure('Name','deltAnt')
    hold on
    plot(timeArray, emgData.deltAnt(1:2,1:end))
    legend('Trial 176 Bump','Trial 176 Move')
    
    figure('Name','deltMid')
    hold on
    plot(timeArray, emgData.deltMid(1:2,1:end))
    legend('Trial 176 Bump','Trial 176 Move')
    
    figure('Name','deltPost')
    hold on
    plot(timeArray, emgData.deltPost(1:2,1:end))
    legend('Trial 176 Bump','Trial 176 Move')
    
    figure('Name','triMid')
    hold on
    plot(timeArray, emgData.triMid(1:2,1:end))
    legend('Trial 176 Bump','Trial 176 Move')
    
    figure('Name','biLat')
    hold on
    plot(timeArray, emgData.biLat(1:2,1:end))
    legend('Trial 176 Bump','Trial 176 Move')
    
   
    
        
        
        
        
        