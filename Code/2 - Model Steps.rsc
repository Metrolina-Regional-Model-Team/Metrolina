/*

*/

Macro "Initial Processing" (Args)
    RunMacro("Build_Networks", Args)
    RunMacro("Area_Type", Args)
    RunMacro("CapSpd", Args)
    RunMacro("RouteSystemSetUp", Args)
    return(1)
endmacro

Macro "Skimming" (Args)
    // RunMacro("HwySkim_Free", Args)
    // RunMacro("HwySkim_Peak", Args)
    // RunMacro("FillParkCost", Args)
    RunMacro("AutoSkims_Free", Args)
    return(1)
endmacro