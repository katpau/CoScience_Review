%plotGmaResults Plots GMA results (GmaResults)
%
%% Syntax
%   % Fit EEG data and invert it to find negative components.
%   fit = gmaFitEeg(EEG, eegChannel, 50, 100, invData = 1);
%
%% Description
%   The function plots the content of GmaResults for data of a single channel
%   with the fitted probability density function (PDF) of a Gamma Model
%   Analysis as well as some Gamma PDF parameters and error measures as well as
%   a status as successful or unsuccessful fit.
%
%   The EEG information, contained within GmaResults (e.g. the dataset name,
%   channel name, sampling rate, …) will be obtained from the eegInfo property.
%   This information can either be added manually, using <a href="matlab:help('GmaResults.addEegInfo')">GmaResults.addEegInfo</a>
%   or by using <a href="matlab:help('gmaFitEeg')">gmaFitEeg</a> from the outset.
%
%   The created plot will be tagged as 'gmaPlot' for easy identification within
%   the MATLAB figures.
%
%   Important:
%   This function is still very much BETA and mostly serves demonstration
%   purposes. It is not robust and not optimized, but should work to glance a
%   at a GMA fit.
%
%% Input
%   results     - [<a href="matlab:help('GmaResults')">GmaResults</a>] Results of the GMA to be plotted, preferably
%               including EEG meta information.
%
%   [Optional] Name-value parameters
%   invData     - [logical| true, will invert the data in the plot (to be used
%               if the data had been inverted before fitting it; false (default)
%               will plot the data without changing the ploarity.
%               A changed polarity will also be stated below the plot. If the
%               GmaResults.eegInfo already flagged the data as inverted,
%               invData will reverse the inversion state.
%   headl       - [char] Headline for the graph. If empty (default), uses the
%               setname from GmaResults.eegInfo
%   desc        - [char] Description, to be included in the subheader. If empty
%               (default), the desc field in 'eegInfo' will be used, instead.
%   yrev        [logical] true (default) reverses y-axis (negative is up) for
%               the data plot
%   xorigin     - [double] The origin of the x-axis, asthe data point at time 
%               zero, used for all time adjustments.
%               The default of 0, will either use the field 'xmin' of the 
%               property eegInfo in the results if present (it contains the 
%               relative time of the first data point in seconds) to set the 
%               origin or set it to 1, otherwise.
%   ticksMs     - [double {integer}] Desired tick spacing in milliseconds.
%               Default: 50
%   srate       - [double {integer}] The sampling rate of the data used for
%               conversions. The parameter will only be used, if eegInfo does
%               not contain the field 'srate', which overrides this setting.
%               Otherwise defaults to 1000.
%   xlim        [double] Limits of the x-axis of the plot as two-element vector.
%               Default: [NaN, NaN]
%   data        - [double] Vector of data to plot. If left empty (default), the
%               data contained in the GmaResults ('data') will be used.
%   plotTails   - [logical] true (default) enables plotting the tails, before
%               and after a segment in the data, fitted  by GMA. false will only
%               plot the PDF "above" the segment.
%
%% See also
%   GmaResults, gmaFit, gmaFitEeg

%% Attribution
%	Last author: Olaf C. Schmidtmann, last edit: 16.11.2023
%   Code adapted from the original version by André Mattes and Kilian Kummer.
%   Source: https://github.com/0xlevel/gma
%	MATLAB version: 2023a
%
%	Copyright (c) 2023, Olaf C. Schmidtmann, University of Cologne
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

function plotGmaResults(results, args)

    arguments
        results(1, 1) GmaResults
        args.invData logical = false
        args.headl = ''
        args.desc = ''
        args.yrev logical = true
        args.xorigin(1, 1) = 0;
        args.ticksMs(1, 1) = 50;
        args.srate(1, 1) = 1000;
        args.xlim(1, 2) double = [NaN, NaN]
        args.data(1, :) double = []
        args.plotTails(1, 1) logical = true
    end

    % Constants
    DEF_HEAD = 'GMA Results';
    PLOT_TAG = 'gmaPlot';

    if isempty(results.data) || length(results.data) == 1 && isnan(results.data)
        fprintf("No data to plot.\n");
        return;
    end

    if ~isempty(results.eegInfo)
        % Mandatory fields
        srate = results.eegInfo.srate;
        ratef = 1000 / srate;
        % Optional fields
        if isfield(results.eegInfo, 'chLabel')
            chLabel = results.eegInfo.chLabel;
        else
            chLabel = '';
        end
        if isfield(results.eegInfo, 'setname')
            setname = results.eegInfo.setname;
        else
            setname = '';
        end

        if isfield(results.eegInfo, 'dataid')
            setname = strjoin({results.eegInfo.dataid, setname, chLabel}, '_');
        end

        if ~strlength(args.desc) && isfield(results.eegInfo, 'desc')
            args.desc = results.eegInfo.desc;
        end

        if ~strlength(args.headl)
            if isfield(results.eegInfo, 'condition')
                args.headl = [DEF_HEAD, ': ', results.eegInfo.condition];
            elseif strlength(setname)
                args.headl = [DEF_HEAD, ': ', replace(setname, '_', '\_')];
            else
                args.headl = DEF_HEAD;
            end
        end

        if args.xorigin <= 0
            if isfield(results.eegInfo, 'xmin')
                % Get x origin offset (for locked epochs) in samples, already
                % compensated for other 1-based offsets (thus +1).
                args.xorigin = -results.eegInfo.xmin * srate + 1;
            else
                args.xorigin = 1;
            end
        end

    else
        % Set minimum required settings
        setname = DEF_HEAD;
        ratef = 1000 / args.srate;
        chLabel = '';
        if args.xorigin <= 0
            args.xorigin = 1;
        end
    end

    if ~isempty(args.data)
        chData = args.data;
    else
        chData = results.data;
    end
    nData = numel(chData);

    fitSuccessful = results.isFit;
    dataInverted = xor(args.invData, results.isInverted);
    if dataInverted
        invStatus = '\it (inverted)';
        dsign = -1;
    else
        invStatus = '';
        dsign = 1;
    end

    if strlength(args.desc) && strlength(chLabel)
        args.desc = [args.desc, ' | '];
    end
    subhead = sprintf('%s%s', args.desc, chLabel);


    %% Compose figure
    fig = figure(Color = "white");
    set(fig, 'Tag', PLOT_TAG);
    set(fig, 'Name', ['GMA_', setname]);
    set(fig, 'MenuBar', 'none');
    set(fig, 'ToolBar', 'none');
    % set(gca,'TickLabelInterpreter','latex');

    hold on;
    title(args.headl, subhead, 'fontsize', 11);

    %% Plot data
    yyaxis right;
    ax = gca;
    dataColor = [0.8500, 0.3250, 0.0980];
    ax.YColor = dataColor;
    ylabel('\muV', 'fontsize', 12, 'Color', dataColor);

    dx = 1:nData;
    plot(dx, chData * dsign, DisplayName="Data");

    if anynan(args.xlim)
        if nData && ~isempty(results.y)
            args.xlim = [0, round(max(nData, length(results.y)))];
        else
            args.xlim = [round(dx(1), 2), round(dx(end))];
        end
    end
    
    [l1, u1] = bounds([chData(:, args.xlim(1) + 1:args.xlim(2)), results.y]);
    maxLim = max(abs([l1, u1]));
    % Slightly increase the limits beyond the bounds to display curves properly.
    yBounds = [min(-0.1, -maxLim), max(0.1, maxLim)] * 1.1;

    % display the last tick
    args.xlim = args.xlim + [0, 1];

    xlim(args.xlim);
    ylim(yBounds);

    if dataInverted && args.yrev, ax.YDir = "reverse"; end

    %% Plot PDF axis / GMA fit
    yyaxis left;
    ax = gca;
    gmaColor = [0, 0.4470, 0.7410];
    ax.YColor = gmaColor;
    ylabel('Gamma PDF', 'fontsize', 12, 'Color', gmaColor);

    if ~isempty(results.y)
        % Re-base the x values to zero and add the segment offset
        px = results.x + results.localOffset;
        py = results.y;

        if results.isValidPdf
            % shift zero-based local values
            pois = [results.ip1, results.mode, results.ip2];
            pois = round(pois - results.seg(1) + 1);
            markers = pois(pois > 0 & pois <= length(px));
        else
            pois = [];
        end

        if fitSuccessful
            plot(px, py, LineWidth = 2, ...
                Marker = 'o', MarkerSize = 3, MarkerIndices = markers, ...
                DisplayName="Gamma PDF");
        else
            plot(px, py, ':', LineWidth = 2, ...
                Marker = 'o', MarkerSize = 3, MarkerIndices = markers, ...
                DisplayName="Gamma PDF (no fit)");
        end

        xlim(args.xlim);
        ylim(yBounds);

        % Plot tails
        if args.plotTails
            if results.isFullOpt
                tailLine = '-';
            else
                tailLine = ':';
            end

            if results.seg(2) < nData
                [tx, ty] = results.getTailRear();
                if ~isempty(pois)
                    tailPois = pois(pois > length(px));
                    tailPois = tailPois - length(px);
                else
                    tailPois = [];
                end
                % Shift the plot by the local offset
                plot(tx + results.localOffset, ty, LineStyle = tailLine, ...
                    LineWidth = 2, Color = '#666', ...
                    Marker = 'o', MarkerSize = 2, MarkerIndices = tailPois, ...
                    HandleVisibility="off");
            end

            if results.x(1) > 1
                [tx, ty] = results.getTailFront();
                % Shift the plot by the local offset
                plot(tx + results.localOffset, ty, LineStyle = tailLine, ...
                    LineWidth = 2, Color = '#666', HandleVisibility="off");
            end
        end
    end

    if dx(1) ~= args.xorigin
        % Draw time lock
        xline(args.xorigin, HandleVisibility="off");
    end
    yline(0, HandleVisibility="off");

    % Mark nonnegative interval found by the pre-search
    segmarks = results.seg;
    segmarksMs = round((segmarks' - args.xorigin) * ratef, 2);
    if all(segmarks > 0)
        segLabel = sprintf("[%g, %g) ms", segmarksMs);
        segxl = xline(max(1, segmarks(1)), ":", segLabel, LineWidth = 1, ...
            LabelOrientation = "horizontal", HandleVisibility="off");
        segxl.FontSize = 9;
        xline(segmarks(2), ":", LineWidth = 1, HandleVisibility="off");
    end

    % Mark search window for mode
    winmarks = results.win;
    winmarksMs = round((winmarks - args.xorigin) * ratef, 2);
    if winmarks(1) > 1
        wxl1 = xline(winmarks(1), "-.", sprintf("  %g ms", winmarksMs(1)), ...
            LineWidth = 0.5, color = [0.4660, 0.6740, 0.1880], ...
            LabelHorizontalAlignment = "right", ...
            LabelVerticalAlignment = "bottom", HandleVisibility="off");
        wxl1.FontSize = 9;
    end

    if winmarks(2) >= winmarks(1) && winmarks(2) < nData
        wxl2 = xline(winmarks(2), "-.", sprintf("  %g ms", winmarksMs(2)), ...
            LineWidth = 0.5, color = [0.4660, 0.6740, 0.1880], ...
            LabelHorizontalAlignment = "left", ...
            LabelVerticalAlignment = "bottom", HandleVisibility="off");
        wxl2.FontSize = 9;
    end

    tickDist = args.ticksMs / ratef;
    % Set ticks before and after the origin and include the outer values
    ticks = (tickDist:tickDist:dx(end) + 1) + 1;

    if args.xorigin == 1
        ticks = [dx(1), ticks];
    end
    
    xticks(ticks);

    xticklabels(round((ticks - args.xorigin) * ratef));
    xlabel('Time (ms)', 'fontsize', 12);

    % Legend
    ldg = legend(AutoUpdate = 'off');
    ldg.Location = "southeast";

    %% Data Text Panel
    ax.Position(4) = 0.6;
    ax.Position(2) = 0.32;

    if fitSuccessful
        successStr = '\color{darkGreen}successful\color{black}';
    else
        successStr = '\color{red}unsuccessful\color{black}';
    end

    % Text annotation: Tabs (`\t`) are not supported by the MATLAB tex
    % interpreter. Thus, either replace them using spaces or something like detab
    % (https://www.mathworks.com/matlabcentral/fileexchange/10536-detab-a-pedestrian-string-detabulator)
    % or create a latex tabular ('$$\begin{tabular}{lllll}', ...).

    stats = {; ...
        getResultTex(results, {'shape', 'rate', 'yscale', 'skew', 'excess'}), ...
        getResultTex(results, {'ip1', 'mode', 'ip2'}, 3, 'ms', ratef, -args.xorigin), ...
        getResultTex(results, {'rmse', 'nrmse', 'r'}, 4)};


    infoStr = {'\fontsize{14}Gamma Model Analysis\fontsize{3}', ...
        ['\fontsize{11}', successStr, invStatus], ...
        sprintf('%s ', stats{1}{:}), ...
        sprintf('%s ', stats{2}{:}), ...
        sprintf('%s ', stats{3}{:})};

    annotation('textbox', [0.13, 0.13, 0.1, 0.1], 'String', infoStr, ...
        'LineStyle', 'none', 'FitBoxToText', 'on');

    hold off;
end

function flds = getResultTex(results, flds, precision, unit, factor, offset)
    arguments
        results(1, 1) GmaResults
        flds(1, :) cell{mustBeText}
        precision(1, 1) {mustBeInteger} = 3
        unit(1, :) {mustBeText} = ''
        factor(1, 1) double = 1
        offset(1, 1) double = 0
    end

    fmt = sprintf('\\\\bf%%s\\\\rm: %%.%if %s', precision, unit);

    for i = 1:numel(flds)
        flds{i} = sprintf(fmt, flds{i}, (results.(flds{i}) + offset) * factor);
    end
end
