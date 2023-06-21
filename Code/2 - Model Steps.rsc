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

    first_iter = if Args.[Current Feedback Iter] = 1
        then "true"
        else "false"

    if first_iter then do
        RunMacro("HwySkim_Free", Args)
        RunMacro("Prepare_Transit_Files", Args)
    end
    RunMacro("HwySkim_Peak", Args)
    RunMacro("FillParkCost", Args)
    RunMacro("AutoSkims_Free", Args)
    RunMacro("AutoSkims_Peak", Args)
    if first_iter then RunMacro("Reg_NonMotorized", Args)
    RunMacro("Reg_PPrmW", Args)
    RunMacro("Reg_PPrmD", Args)
    RunMacro("Reg_PPrmDrop", Args)
    RunMacro("Reg_PBusW", Args)
    RunMacro("Reg_PBusD", Args)
    RunMacro("Reg_PBusDrop", Args)
    if first_iter then do
        RunMacro("Reg_OPPrmW", Args)
        RunMacro("Reg_OPPrmD", Args)
        RunMacro("Reg_OPPrmDrop", Args)
        RunMacro("Reg_OPBusW", Args)
        RunMacro("Reg_OPBusD", Args)
        RunMacro("Reg_OPBusDrop", Args)
    end
    return(1)
endmacro

Macro "Trip Generation" (Args)
    
    if Args.[Current Feedback Iter] > 1 then return(1)
    
    RunMacro("ExtStaforTripGen", Args)
    RunMacro("HHMET", Args)
    RunMacro("Tour_Accessibility", Args)
    RunMacro("Tour_XX", Args)
    RunMacro("Tour_Frequency", Args)
    return(1)
endmacro

Macro "Trip Distribution" (Args)

    first_iter = if Args.[Current Feedback Iter] = 1
        then "true"
        else "false"

    RunMacro("TD_TranPath_Peak", Args)
    RunMacro("TD_TranPath_Free", Args)
    if first_iter then do
        RunMacro("Tour_DestinationChoice", Args)
        RunMacro("Tour_IS", Args)
        RunMacro("Tour_IS_Location", Args)
    end else do
        RunMacro("Tour_DC_FB", Args)
        RunMacro("Tour_IS_FB", Args)
        RunMacro("Tour_IS_Location_FB", Args)
    end
    return(1)
endmacro

Macro "Trucks" (Args)
    RunMacro("Tour_TruckTGTD", Args)
    return(1)
endmacro

Macro "Mode Split" (Args)

    first_iter = if Args.[Current Feedback Iter] = 1
        then "true"
        else "false"

    if first_iter then do
        RunMacro("Tour_ToD1", Args)
        RunMacro("Tour_TripAccumulator", Args)
    end else do
        RunMacro("Tour_ToD1_FB", Args)
        RunMacro("Tour_TripAccumulator_FB", Args)
    end
    RunMacro("MS_RunPeak", Args)
    RunMacro("Tour_TOD2_AMPeak", Args)
    return(1)
endmacro

Macro "Peak Highway Assignment" (Args)
    RunMacro("HwyAssn_RunAMPeak", Args)    
    return(1)
endmacro

Macro "Convergence" (Args)
    curiter = Args.[Current Feedback Iter]
	maxiter = Args.[Feedback Iterations]
    if curiter < maxiter then do
        converged = 0
        RunMacro("Feedback_TravelTime", Args)    
        Args.[Current Feedback Iter] = Args.[Current Feedback Iter] + 1
    end else converged = 1
    return(converged + 1)
endmacro

Macro "Post Feedback" (Args)
    RunMacro("MS_RunOffPeak", Args)
    RunMacro("MSMatrixStats", Args)
    RunMacro("Tour_TOD2_PMPeak", Args)
    RunMacro("Tour_TOD2_Midday", Args)
    RunMacro("Tour_TOD2_Night", Args)
    RunMacro("HwyAssn_RunPMPeak", Args)
    RunMacro("HwyAssn_RunMidday", Args)
    RunMacro("HwyAssn_RunNight", Args)
    return(1)
endmacro

endmacro