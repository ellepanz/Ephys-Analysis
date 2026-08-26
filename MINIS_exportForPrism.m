function MINIS_exportForPrism

load('\\bunson\bunson\Higley_Lab\Lauren bunsen\Data Summaries\mIPSCs with NMDA\NMDAmIPSCs_population.mat');
populationFolder = "\\bunson\bunson\Higley_Lab\Lauren bunsen\Data Summaries\mIPSCs with NMDA";

prismFile = fullfile(populationFolder,'NMDAmIPSCs_Prism.xlsx');

Holding = table(Population.CellID,Population.avgBaselineHolding,Population.avgWashoutHolding, ...
    'VariableNames',{'CellID','TTX_NBQX','Washout'});

Phasic = table(Population.CellID,Population.avgBaselinePhasic,Population.avgWashoutPhasic, ...
    'VariableNames',{'CellID','TTX_NBQX','Washout'});

writetable(Holding,prismFile,'Sheet','Holding Current');
writetable(Phasic,prismFile,'Sheet','Phasic Imean');

fprintf('Prism data exported to:\n%s\n',prismFile);

end