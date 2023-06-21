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
    RunMacro("HwySkim_Free", Args)
    RunMacro("Prepare_Transit_Files", Args)
    RunMacro("HwySkim_Peak", Args)
    RunMacro("FillParkCost", Args)
    RunMacro("AutoSkims_Free", Args)
    RunMacro("AutoSkims_Peak", Args)
    RunMacro("Reg_NonMotorized", Args)
    RunMacro("Reg_PPrmW", Args)
    RunMacro("Reg_PPrmD", Args)
    RunMacro("Reg_PPrmDrop", Args)
    RunMacro("Reg_PBusW", Args)
    RunMacro("Reg_PBusD", Args)
    RunMacro("Reg_PBusDrop", Args)
    RunMacro("Reg_OPPrmW", Args)
    RunMacro("Reg_OPPrmD", Args)
    RunMacro("Reg_OPPrmDrop", Args)
    RunMacro("Reg_OPBusW", Args)
    RunMacro("Reg_OPBusD", Args)
    RunMacro("Reg_OPBusDrop", Args)
    return(1)
endmacro

Macro "Trip Generation" (Args)
    RunMacro("ExtStaforTripGen", Args)
    RunMacro("HHMET", Args)
    RunMacro("Tour_Accessibility", Args)
    RunMacro("Tour_XX", Args)
    RunMacro("Tour_Frequency", Args)
    return(1)
endmacro

Macro "Trip Distribution" (Args)
    RunMacro("TD_TranPath_Peak", Args)
    RunMacro("TD_TranPath_Free", Args)
    RunMacro("Tour_DestinationChoice", Args)
    RunMacro("Tour_IS", Args)
    RunMacro("Tour_IS_Location", Args)
    return(1)
endmacro

Macro "Trucks" (Args)
    RunMacro("Tour_TruckTGTD", Args)
    return(1)
endmacro

Macro "Mode Split" (Args)
    RunMacro("Tour_ToD1", Args)
    RunMacro("Tour_TripAccumulator", Args)
    RunMacro("MS_RunPeak", Args)
    RunMacro("Tour_TOD2_AMPeak", Args)
    return(1)
endmacro

Macro "Peak Highway Assignment" (Args)
    RunMacro("HwyAssn_RunAMPeak", Args)    
    return(1)
endmacro