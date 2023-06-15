
Macro "Model.Attributes" (Args,Result)
    Attributes = {
        {"BackgroundColor", null},
        {"BannerPicture", null},
        {"BannerHeight", 80},
        {"BannerWidth", 2000},
        {"ResizePicture", 1},
        {"HideBanner", 0},
        {"DebugMode", 1},
        {"Layout", null},
        {"ExpandStages", "Side by Side"},
        {"MinItemSpacing", 5},
        {"MaxProgressBars", 2},
        {"CodeUI", "Code\\ui.dbd"},
        {"Base Scenario Name", "Base"},
        {"ClearLogFiles", 1},
        {"CloseOpenFiles", 1},
        {"Output Folder Format", "Output Folder\\Scenario Name"},
        {"Output Folder Parameter", "Output Folder"},
        {"Output Folder Per Run", "No"},
        {"ReportAfterStep", 0},
        {"Shape", "Rectangle"},
        {"SourceMacro", "Model.Attributes"},
        {"Time Stamp Format", "yyyyMMdd_HHmm"}
    }
EndMacro


Macro "Model.Step" (Args,Result)
    Attributes = {
        {"FillColor",{127,191,255}},
        {"FillColor2",{127,217,255}},
        {"FrameColor",{255,255,255}},
        {"Height", 25},
        {"TextFont", "Arial Narrow|10|700|000000|0"},
        {"Width", 150}
    }
EndMacro


Macro "Model.Arrow" (Args,Result)
    Attributes = {
        {"ArrowBase", "No Arrow Head"},
        {"ArrowBaseSize", 1},
        {"ArrowHead", "No Arrow Head"},
        {"ArrowHeadSize", 1},
        {"Color", "#808080"},
        {"FillColor", "#808080"},
        {"PenStyle", "Solid"},
        {"PenWidth", 1}
    }
EndMacro


/**
  This macro will run when the user open a new model file in a TransCAD window.
  You can use it to change the value for some particular parameters.
**/
Macro "Model.OnModelReady" (Args,Result)
    Return({"Base Folder": "%Model Folder%"})
EndMacro


Macro "Model.OnModelLoad" (Args, Results)
Body:
    // Compile source code
    flowchart = RunMacro("GetFlowChart")
    { drive , path , name , ext } = SplitPath(flowchart.UI)
    rootFolder = drive + path
    ui_DB = rootFolder + "Code\\ui.dbd"
    srcFile = rootFolder + "Code\\menu_MRM2002_laptop.lst"
    RunMacro("CompileGISDKCode", {Source: srcFile, UIDB: ui_DB, Silent: 0, ErrorMessage: "Error compiling code"})

    if lower(GetMapUnits()) <> "miles" then
        MessageBox("Set the system to miles before running the model", {Caption: "Warning", Icon: "Warning", Buttons: "yes"})
EndMacro

