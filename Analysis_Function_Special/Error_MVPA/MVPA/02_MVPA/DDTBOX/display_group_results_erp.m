function display_group_results_erp(ANALYSIS)
%__________________________________________________________________________
% DDTBOX script written by Stefan Bode 01/03/2013
%
% The toolbox was written with contributions from:
% Daniel Bennett, Jutta Stahl, Daniel Feuerriegel, Phillip Alday
%
% The author further acknowledges helpful conceptual input/work from: 
% Simon Lilburn, Philip L. Smith, Elaine Corbett, Carsten Murawski, 
% Carsten Bogler, John-Dylan Haynes
%__________________________________________________________________________
%
% This script is will plot results from the group analysis 

%__________________________________________________________________________
%
% Variable naming convention: STRUCTURE_NAME.example_variable

%% GENERAL PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

% post-processing script = 2 - needed for interaction with other scripts to regulate
% functions such as saving data, calling specific sub-sets of parameters
global CALL_MODE
CALL_MODE = 3;

global DCGTODO;
global SLIST;

%% PLOTTING PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%__________________________________________________________________________

% figure position__________________________________________________________
PLOT.FigPos = [100 100 800 400];

% define x/y-axis__________________________________________________________
PLOT.Y_min = 40; % Y axis lower bound (in % accuracy)
PLOT.Y_max = 85; % Y axis upper bound (in % accuracy)
PLOT.Ysteps = 5; % Interval between Y axis labels/tick marks

PLOT.X_min = 1; % X axis lower bound (first time point)
PLOT.X_max = ANALYSIS.xaxis_scale(2,end);
PLOT.Xsteps = ANALYSIS.step_width_ms;

PLOT.Ytick = [PLOT.Y_min:PLOT.Ysteps:PLOT.Y_max];
PLOT.Xtick = [ANALYSIS.xaxis_scale(1,1) : ANALYSIS.xaxis_scale(1,end)];

PLOT.XtickLabel = ANALYSIS.xaxis_scale(2,:) - ANALYSIS.pointzero; 

% added by André on March 28, 2019: Automatically label x-axis in steps of
% 5
PLOT.Xtick_keep = find(rem(PLOT.Xtick-1, 5) == 0);  
PLOT.Xtick = PLOT.Xtick(PLOT.Xtick_keep);
PLOT.XtickLabel = PLOT.XtickLabel(PLOT.Xtick_keep);

% define properties of significance markers________________________________
PLOT.Sign.LineColor = [0.93 0.93 0.93]; % 'original' code; colour = gray
%PLOT.Sign.LineColor = [73/255 182/255 53/255];
PLOT.Sign.LinePos = [PLOT.Y_min+0.5 PLOT.Y_max-0.5];
PLOT.Sign.LineWidth = 10;

% define properties of main plot___________________________________________
PLOT.Res.Line = '-ks';
PLOT.Res.LineWidth = 2;
PLOT.Res.MarkerEdgeColor = 'k';
PLOT.Res.MarkerFaceColor = 'w';
PLOT.Res.MarkerSize = 5;

PLOT.Res.Error = 'k';
PLOT.Res.ErrorLine = 'none';
PLOT.Res.ErrorLineWidth = 0.5;

% define properties of permutation / chance plot___________________________
PLOT.PermRes.Line = '-ks';
PLOT.PermRes.LineWidth = 2;
PLOT.PermRes.MarkerEdgeColor = [0.49 0.49 0.49];
PLOT.PermRes.MarkerFaceColor = 'w';
PLOT.PermRes.MarkerSize = 5;

PLOT.PermRes.Error = [0.49 0.49 0.49];
PLOT.PermRes.ErrorLine = 'none';
PLOT.PermRes.ErrorLineWidth = 0.5;

% define label / title properties__________________________________________
PLOT.xlabel.FontSize = 12;
PLOT.ylabel.FontSize = 12;

PLOT.xlabel.FontWeight = 'b';
PLOT.ylabel.FontWeight = 'b';

PLOT.xlabel.Text = 'Time-steps [ms]';
PLOT.ylabel.Text = 'Classification Accuracy [%]';

PLOT.PointZero.Color = 'k';
PLOT.PointZero.LineWidth = 3;
PLOT.PointZero.Point = find(ANALYSIS.data(3,:) == 1);

if ANALYSIS.stmode == 1
    PLOT.TileString = 'Spatial Class ';
elseif ANALYSIS.stmode == 2
    PLOT.TileString = 'Temporal Class ';
elseif ANALYSIS.stmode == 3
    PLOT.TileString = 'Spatiotemporal Class ';
end

PLOT.TitleFontSize = 14;
PLOT.TitleFontWeight = 'b';
%__________________________________________________________________________

%% PLOT THE RESULTS
%__________________________________________________________________________
% 
% plots the results depending on s/t-mode (information time-courses for
% spatial/spatio-temporal decoding; heat maps for temporal decoding)

if ANALYSIS.stmode == 1 || ANALYSIS.stmode == 3
    
    % determine the time-point for locking the data ("point zero")
%     [dummy pointzero] = min(abs(ANALYSIS.xaxis_scale(1,:)));
%     ANALYSIS.pointzero=pointzero; clear pointzero;
    
    % plot the information time-course for each analysis
    %______________________________________________________________________
    for ana = 1:size(ANALYSIS.RES.mean_subj_acc,1)
        
        fighandle = figure('Position',PLOT.FigPos);
        
        % get results to plot
        %__________________________________________________________________
        temp_data(1,:) = ANALYSIS.RES.mean_subj_acc(ana,:);
        temp_se(1,:) = ANALYSIS.RES.se_subj_acc(ana,:);
        
        % get permutation results to plot
        %__________________________________________________________________
        if ANALYSIS.permstats == 1
            temp_perm_data(1,1:size(ANALYSIS.RES.mean_subj_acc(ana,:),2)) = ANALYSIS.chancelevel;
            temp_perm_se(1,1:size(ANALYSIS.RES.mean_subj_acc(ana,:),2)) = zeros;
        elseif ANALYSIS.permstats == 2
            temp_perm_data(1,:) = ANALYSIS.RES.mean_subj_perm_acc(ana,:);
            temp_perm_se(1,:) = ANALYSIS.RES.se_subj_perm_acc(ana,:);
        end
        
        % mark significant points
        %__________________________________________________________________
        
        if ANALYSIS.disp.sign == 1
            for step = 1:size(temp_data,2)
                
                % plot if found significant...
                if ANALYSIS.RES.h_ttest(ana,step) == 1
                    
%                     % ... and if after baseline (careful - this might be a meaningful result!)
%                     if step >= PLOT.PointZero.Point

                        line([step step],PLOT.Sign.LinePos,'Color',PLOT.Sign.LineColor,'LineWidth',PLOT.Sign.LineWidth);
                        hold on;

%                     end 
                    
                end % if h_ttest
            end % step
        end % disp
        
        % plot main results
        %__________________________________________________________________
        plot(temp_data,PLOT.Res.Line,'LineWidth',PLOT.Res.LineWidth,'MarkerEdgeColor',PLOT.Res.MarkerEdgeColor,...
            'MarkerFaceColor',PLOT.Res.MarkerFaceColor,'MarkerSize',PLOT.Res.MarkerSize);
        hold on;      
        
        errorbar(temp_data,temp_se,PLOT.Res.Error,'linestyle',PLOT.Res.ErrorLine,...
            'linewidth',PLOT.Res.ErrorLineWidth);
        hold on;
        
        %% plot permutation / chance results
        %__________________________________________________________________
        if ANALYSIS.permdisp == 1
            
            plot(temp_perm_data,PLOT.PermRes.Line,'LineWidth',PLOT.PermRes.LineWidth,'MarkerEdgeColor',PLOT.PermRes.MarkerEdgeColor,...
                'MarkerFaceColor',PLOT.PermRes.MarkerFaceColor,'MarkerSize',PLOT.PermRes.MarkerSize);
            hold on;
            
            % Modified by André on March 28, 2019
            e = errorbar(temp_perm_data,temp_perm_se,'k','linestyle',PLOT.PermRes.ErrorLine,...
                'linewidth',PLOT.PermRes.ErrorLineWidth);
            e.Color = PLOT.PermRes.Error;
            hold on;
            
        end
        
        %% define labels, point zero, title
        %__________________________________________________________________
        
        axis([1 ANALYSIS.laststep PLOT.Y_min PLOT.Y_max]);
        
        xlabel(PLOT.xlabel.Text,'FontSize',PLOT.xlabel.FontSize,'FontWeight',PLOT.xlabel.FontWeight);
        ylabel(PLOT.ylabel.Text,'FontSize',PLOT.ylabel.FontSize,'FontWeight',PLOT.ylabel.FontWeight);
        
        %% define title
        if ANALYSIS.analysis_mode == 1 || ANALYSIS.analysis_mode == 2
           
            if size(ANALYSIS.DCG,1)==1
                
                title([PLOT.TileString ANALYSIS.DCG ' N='  num2str(ANALYSIS.nsbj)],...
                    'FontSize',PLOT.TitleFontSize,'FontWeight',PLOT.TitleFontWeight);
           
            elseif size(ANALYSIS.DCG,1)==2
                
                title([PLOT.TileString ANALYSIS.DCG{1} 'to' ANALYSIS.DCG{2} ' N='  num2str(ANALYSIS.nsbj)],...
                    'FontSize',PLOT.TitleFontSize,'FontWeight',PLOT.TitleFontWeight);
           
            end
            
        elseif ANALYSIS.analysis_mode == 3 || ANALYSIS.analysis_mode == 4
           
            title(['Regression N=' num2str(ANALYSIS.nsbj)],...
                'FontSize',PLOT.TitleFontSize,'FontWeight',PLOT.TitleFontWeight);
        end
        
        %% mark point zero (data was time-locked to this event)
        line([PLOT.PointZero.Point PLOT.PointZero.Point], [PLOT.Y_max PLOT.Y_min],'Color',PLOT.PointZero.Color,...
            'LineWidth',PLOT.PointZero.LineWidth);
        
        %% define ticks and axis labels
        %__________________________________________________________________
        
        set(gca,'Ytick',PLOT.Ytick,'Xtick',PLOT.Xtick);
        set(gca,'XTickLabel',PLOT.XtickLabel);

        % clear temp-data
        clear temp_data;   
        clear temp_se; 
    
    end % channel
    
end % analysis mode