classdef app1 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        SelectSecondPharmacologyLabel  matlab.ui.control.Label
        SelectFirstPharmacologyLabel   matlab.ui.control.Label
        MuscarineCheckBox_2            matlab.ui.control.CheckBox
        CdCl2CheckBox                  matlab.ui.control.CheckBox
        ConoGVIACheckBox_2             matlab.ui.control.CheckBox
        AgaTKCheckBox_2                matlab.ui.control.CheckBox
        MuscarineCheckBox              matlab.ui.control.CheckBox
        ConoGVIACheckBox               matlab.ui.control.CheckBox
        AgaTKCheckBox                  matlab.ui.control.CheckBox
        PlotButton                     matlab.ui.control.Button
        SelectPlotstoGenerateLabel     matlab.ui.control.Label
        cb_Peaks                       matlab.ui.control.CheckBox
        cb_PPRs                        matlab.ui.control.CheckBox
        cb_avgWaves                    matlab.ui.control.CheckBox
    end



    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: PlotButton
        function PlotButtonPushed(app, event)

        if app.cb_avgWaves.Value
            disp('Plotting Average Waves...');
            % Put your Average Waves plotting code here
        end
        
        if app.cb_PPRs.Value
            disp('Plotting PPRs...');
            % Put your PPR plotting code here
        end
        
        if app.cb_Peaks.Value
            disp('Plotting Peaks...');
            % Put your Peaks plotting code here
        end
        close(app.UIFigure)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [800 500 216 464];
            app.UIFigure.Name = 'MATLAB App';

            % Create cb_avgWaves
            app.cb_avgWaves = uicheckbox(app.UIFigure);
            app.cb_avgWaves.Text = 'Average Waves';
            app.cb_avgWaves.Position = [23 107 106 22];

            % Create cb_PPRs
            app.cb_PPRs = uicheckbox(app.UIFigure);
            app.cb_PPRs.Text = 'PPRs';
            app.cb_PPRs.Position = [23 80 53 22];

            % Create cb_Peaks
            app.cb_Peaks = uicheckbox(app.UIFigure);
            app.cb_Peaks.Text = 'Peaks';
            app.cb_Peaks.Position = [23 53 55 22];

            % Create SelectPlotstoGenerateLabel
            app.SelectPlotstoGenerateLabel = uilabel(app.UIFigure);
            app.SelectPlotstoGenerateLabel.FontWeight = 'bold';
            app.SelectPlotstoGenerateLabel.Position = [23 134 147 22];
            app.SelectPlotstoGenerateLabel.Text = 'Select Plots to Generate:';

            % Create PlotButton
            app.PlotButton = uibutton(app.UIFigure, 'push');
            app.PlotButton.ButtonPushedFcn = createCallbackFcn(app, @PlotButtonPushed, true);
            app.PlotButton.Position = [65 20 88 23];
            app.PlotButton.Text = 'Plot!';

            % Create AgaTKCheckBox
            app.AgaTKCheckBox = uicheckbox(app.UIFigure);
            app.AgaTKCheckBox.Text = 'AgaTK';
            app.AgaTKCheckBox.Position = [23 391 59 22];

            % Create ConoGVIACheckBox
            app.ConoGVIACheckBox = uicheckbox(app.UIFigure);
            app.ConoGVIACheckBox.Text = 'ConoGVIA';
            app.ConoGVIACheckBox.Position = [23 364 79 22];

            % Create MuscarineCheckBox
            app.MuscarineCheckBox = uicheckbox(app.UIFigure);
            app.MuscarineCheckBox.Text = 'Muscarine';
            app.MuscarineCheckBox.Position = [23 337 77 22];

            % Create AgaTKCheckBox_2
            app.AgaTKCheckBox_2 = uicheckbox(app.UIFigure);
            app.AgaTKCheckBox_2.Text = 'AgaTK';
            app.AgaTKCheckBox_2.Position = [23 263 59 22];

            % Create ConoGVIACheckBox_2
            app.ConoGVIACheckBox_2 = uicheckbox(app.UIFigure);
            app.ConoGVIACheckBox_2.Text = 'ConoGVIA';
            app.ConoGVIACheckBox_2.Position = [23 236 79 22];

            % Create CdCl2CheckBox
            app.CdCl2CheckBox = uicheckbox(app.UIFigure);
            app.CdCl2CheckBox.Text = 'CdCl2';
            app.CdCl2CheckBox.Position = [23 236 79 22];

            % Create MuscarineCheckBox_2
            app.MuscarineCheckBox_2 = uicheckbox(app.UIFigure);
            app.MuscarineCheckBox_2.Text = 'Muscarine';
            app.MuscarineCheckBox_2.Position = [23 182 77 22];

            % Create SelectFirstPharmacologyLabel
            app.SelectFirstPharmacologyLabel = uilabel(app.UIFigure);
            app.SelectFirstPharmacologyLabel.FontWeight = 'bold';
            app.SelectFirstPharmacologyLabel.Position = [23 418 160 22];
            app.SelectFirstPharmacologyLabel.Text = 'Select First Pharmacology:';

            % Create SelectSecondPharmacologyLabel
            app.SelectSecondPharmacologyLabel = uilabel(app.UIFigure);
            app.SelectSecondPharmacologyLabel.FontWeight = 'bold';
            app.SelectSecondPharmacologyLabel.Position = [23 290 177 22];
            app.SelectSecondPharmacologyLabel.Text = 'Select Second Pharmacology:';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app1

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end