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
    // RunMacro("Prepare_Transit_Files", Args)
    // RunMacro("HwySkim_Peak", Args)
    // RunMacro("FillParkCost", Args)
    // RunMacro("AutoSkims_Free", Args)
    // RunMacro("AutoSkims_Peak", Args)
    // RunMacro("Reg_NonMotorized", Args)
    // RunMacro("Reg_PPrmW", Args)
    RunMacro("Reg_PPrmD", Args)
    return(1)
endmacro