Macro "Update_DropOff_Skims_Mtx" (time_period,transit_mode, access_mode, Args)

    shared route_file, routename, net_file, link_lyr, node_lyr

    // LogFile = Args.[Log File]
    // SetLogFileName(LogFile)

    METDir = Args.[MET Directory]
    Dir = Args.[Run Directory]

    msg = null
    UpdateDropSkimOK = 1
    datentime = GetDateandTime()
    AppendToLogFile(2, "Enter Update_Dropoff_Skim_Mtx: " + datentime)



// --- Copy Matrices from the Template Directory

OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
on error default

updmtx = Dir+"\\Skims\\"+time_period+transit_mode+"_DODist.MTX"

CopyMatrixStructure({mc1}, {{"File Name", updmtx},
    {"Label", "UpdateDropOffAccess"},
    {"File Based", "Yes"},
    {"Tables", {"Cost", "Drive Length", "Park Node", "Actual Drive Time", "KNR 2 Dest Length", "In-Veh Time"}},
    {"Operation", "Union"},{"Compression",0}})

output_matrix = updmtx

    if (time_period="peak") then do
        modesplit_matrix = Dir + "\\skims\\PK_DROPTRAN_SKIMS.mtx"
        if (transit_mode="premium") then do
            input_matrix = Dir + "\\skims\\TR_SKIM_PPRMDROP.mtx"
            park_matrix=Dir + "\\skims\\TR_PARK_pprmdrop.mtx"
        end

        if (transit_mode="bus") then do
            input_matrix = Dir + "\\skims\\TR_SKIM_PBUSDROP.mtx"
            park_matrix=Dir + "\\skims\\TR_PARK_pbusdrop.mtx"
        end

        if (transit_mode="premium2") then do
            input_matrix = Dir + "\\skims\\TR_SKIM_PPRM2DROP.mtx"
            park_matrix=Dir + "\\skims\\TR_PARK_pprm2drop.mtx"
        end
        if (transit_mode="premium3") then do
            input_matrix = Dir + "\\skims\\TR_SKIM_PPRM3DROP.mtx"
            park_matrix=Dir + "\\skims\\TR_PARK_pprm3drop.mtx"
            modesplit_matrix = Dir + "\\skims\\PK_DROPTRAN_SKIMS3.mtx"
        end
    end //time_period = peak
    
    if (time_period="offpeak") then do
        modesplit_matrix = Dir + "\\skims\\OFFPK_DROPTRAN_SKIMS.mtx"
        if (transit_mode="premium") then do
            input_matrix = Dir + "\\skims\\TR_SKIM_OPPRMDROP.mtx"
            park_matrix=Dir + "\\skims\\TR_PARK_opprmdrop.mtx"
        end

        if (transit_mode="bus") then do
            input_matrix = Dir + "\\skims\\TR_SKIM_OPBUSDROP.mtx"
            park_matrix=Dir + "\\skims\\TR_PARK_opbusdrop.mtx"
        end
        
        if (transit_mode="premium2") then do
            input_matrix = Dir + "\\skims\\TR_SKIM_OPPRM2DROP.mtx"
            park_matrix=Dir + "\\skims\\TR_PARK_opprm2drop.mtx"
        end
        if (transit_mode="premium3") then do
            input_matrix = Dir + "\\skims\\TR_SKIM_OPPRM3DROP.mtx"
            park_matrix=Dir + "\\skims\\TR_PARK_opprm3drop.mtx"
            modesplit_matrix = Dir + "\\skims\\OFFPK_DROPTRAN_SKIMS3.mtx"
        end
    end

Opts = null

     Opts.Input.[Target Currency] = { output_matrix, "Cost", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Fare", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

Opts = null

     Opts.Input.[Target Currency] = {output_matrix, "Park Node", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{park_matrix, "Parking Nodes", "RCIndex", "RCIndex"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 2, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge



/////////////////////////////////////////////////////////////////////////////////////////////////////
// Write the control file and batch file

//  exist = GetFileInfo(METDir + "\\pgm\\ModeChoice\\UPD_DA_Dist_Time_Costv1.exe")
//  if (exist = null) then goto nofortran

//  ctlname = Dir + "\\skims\\Test.ctl"
  //    exist = GetFileInfo(ctlname)
//      if (exist <> null) then DeleteFile(ctlname)
 
// replace backslash "\" in ctl file filenames with forward slash "/" - Manish had a 
//  different method - but it won't work with longer file names , not sure why it needs it either, but it seems to. JWM - 11/2015

    // dirparse = parsestring(Dir, "\\")
    // DirSlash = dirparse[1]
    // for i = 2 to dirparse.length do
    //     DirSlash = DirSlash + "//" + dirparse[i]
    // end
    DirSlash = Dir
 
//      ctl = OpenFile(ctlname, "w")
     odmtx = DirSlash + "//Skims//"+time_period+transit_mode+"_DODist.MTX"

//  WriteLine(ctl, DirSlash + "//Skims//"+time_period+transit_mode+"_DODist.MTX")
    if (time_period="peak") then do
          opmtx = DirSlash + "//Skims//skim_pnr_peak_prm.mtx"
          pdmtx = DirSlash + "//Skims//skim_knr2dest_peak.mtx"

//      WriteLine(ctl, DirSlash + "//Skims//skim_knr_peak.mtx")
//      WriteLine(ctl, DirSlash + "//Skims//skim_knr2dest_peak.mtx")
    end
    else if (time_period="offpeak") then do
          opmtx = DirSlash + "//Skims//skim_knr_offpeak.mtx"
          pdmtx = DirSlash + "//Skims//skim_knr2dest_offpeak.mtx"

//      WriteLine(ctl, DirSlash + "//Skims//skim_knr_offpeak.mtx")
//      WriteLine(ctl, DirSlash + "//Skims//skim_knr2dest_offpeak.mtx")
    end

//                   
//  CloseFile(ctl)

//  batchname=Dir + "\\skims\\update_cost_dist.bat"
//      exist = GetFileInfo(batchname)
//      if (exist <> null) then DeleteFile(batchname)
//      bat = OpenFile(batchname, "w")

//  WriteLine(bat, METDir + "\\pgm\\ModeChoice\\UPD_DA_Dist_Time_Costv1.exe " + ctlname)
//  CloseFile(bat)

//  FortInfo = GetFileInfo(METDir + "\\Pgm\\ModeChoice\\UPD_DA_Dist_Time_Costv1.exe")
//  TimeStamp = FortInfo[7] + " " + FortInfo[8]
//  AppendToLogFile(2, "Update_Dropoff_Skims call to fortran: pgm=\\ModeChoice\\UPD_DA_Dist_Time_Costv1.exe, timestamp: " + TimeStamp)

    // Run Fortran program UPD_DA_Dist_Time_Costv2

//     status = RunProgram(batchname,{{"Maximize", "True"}})
//  if (status <> 0) then goto badfortran
     RunMacro("RunDADist2", odmtx, opmtx, pdmtx)

    input_matrix = updmtx
    if (transit_mode="premium") then do

// Nullify paths with PNR to Destination distance less then 1.0 miles
     Opts = null

     Opts.Input.[Target Currency] = { updmtx, "In-Veh Time", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{modesplit_matrix, "IVTT - Prem DropOff", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 3, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
     
     Opts=null

     Opts = {{"Input",    {{"Matrix Currency",   {updmtx,
                                                  "In-Veh Time",
                                                  "Rows",
                                                  "Columns"}}}},
             {"Global",   {{"Method",            11},
                           {"Cell Range",        2},
               {"Matrix K",          {1,
                          1}},
                           {"Expression Text",   "if [KNR 2 Dest Length] > 1.0 then [In-Veh Time] else null"},
                           {"Force Missing",     "Yes"}}}}

     ret_value = RunMacro("TCB Run Operation", 4, "Fill Matrices", Opts)
    if !ret_value then goto badfill
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "IVTT - Prem DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "In-Veh Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 5, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
////////
     
/*     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Cost - Prem Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Cost", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 
*/
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Distance - Prem DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Drive Length", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 6, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
/*
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Highway OP Time - Prem Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Actual Drive Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 
*/
    end

    if (transit_mode="premium2") then do

// Nullify paths with PNR to Destination distance less then 1.0 miles
     Opts = null

     Opts.Input.[Target Currency] = { updmtx, "In-Veh Time", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{modesplit_matrix, "IVTT - Prem2 DropOff", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 7, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
     
     Opts=null

     Opts = {{"Input",    {{"Matrix Currency",   {updmtx,
                                                  "In-Veh Time",
                                                  "Rows",
                                                  "Columns"}}}},
             {"Global",   {{"Method",            11},
                           {"Cell Range",        2},
               {"Matrix K",          {1,
                          1}},
                           {"Expression Text",   "if [KNR 2 Dest Length] > 1.0 then [In-Veh Time] else null"},
                           {"Force Missing",     "Yes"}}}}

     ret_value = RunMacro("TCB Run Operation", 8, "Fill Matrices", Opts)
    if !ret_value then goto badfill
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "IVTT - Prem2 DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "In-Veh Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 9, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
////////
     
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Distance - Prem2 DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Drive Length", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 10, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

    end

    if (transit_mode="premium3") then do

// Nullify paths with PNR to Destination distance less then 1.0 miles
     Opts = null

     Opts.Input.[Target Currency] = { updmtx, "In-Veh Time", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{modesplit_matrix, "IVTT - Prem2 DropOff", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 11, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
    
     Opts=null

     Opts = {{"Input",    {{"Matrix Currency",   {updmtx,
                                                  "In-Veh Time",
                                                  "Rows",
                                                  "Columns"}}}},
             {"Global",   {{"Method",            11},
                           {"Cell Range",        2},
               {"Matrix K",          {1,
                          1}},
                           {"Expression Text",   "if [KNR 2 Dest Length] > 1.0 then [In-Veh Time] else null"},
                           {"Force Missing",     "Yes"}}}}

     ret_value = RunMacro("TCB Run Operation", 12, "Fill Matrices", Opts)
    if !ret_value then goto badfill
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "IVTT - Prem2 DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "In-Veh Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 13, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
////////
     
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Distance - Prem2 DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Drive Length", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 14, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge

    end

    if (transit_mode="bus") then do

// Nullify paths with PNR to Destination distance less then 1.0 miles
     Opts = null

     Opts.Input.[Target Currency] = { updmtx, "In-Veh Time", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{modesplit_matrix, "IVTT - Bus DropOff", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 15, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
     
     Opts=null

     Opts = {{"Input",    {{"Matrix Currency",   {updmtx,
                                                  "In-Veh Time",
                                                  "Rows",
                                                  "Columns"}}}},
             {"Global",   {{"Method",            11},
                           {"Cell Range",        2},
               {"Matrix K",          {1,
                          1}},
                           {"Expression Text",   "if [KNR 2 Dest Length] > 1.0 then [In-Veh Time] else null"},
                           {"Force Missing",     "Yes"}}}}

     ret_value = RunMacro("TCB Run Operation", 16, "Fill Matrices", Opts)
    if !ret_value then goto badfill
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "IVTT - Bus DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "In-Veh Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 17, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
////////
/*     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Cost - Bus Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Cost", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 
*/
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Drive Access Distance - Bus DropOff", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Drive Length", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 18, "Merge Matrices", Opts) 
    if !ret_value then goto badmerge
/*
     Opts = null

     Opts.Input.[Target Currency] = { modesplit_matrix, "Highway OP Time - Bus Drive", "Rows", "Columns"}
     Opts.Input.[Source Currencies] = {{input_matrix, "Actual Drive Time", "Rows", "Columns"}}
     Opts.Global.[Missing Option].[Force Missing] = "Yes"

     ret_value = RunMacro("TCB Run Operation", 1, "Merge Matrices", Opts) 
*/
    end

//  
///////////////////////////////////////////
done:
goto quit

    badmerge:
     Throw("Update_Dropoff_Skim_Mtx - Error merging matrices")
    // Throw("Update_Dropoff_Skim_Mtx - Error merging matrices")
    // AppendToLogFile(2, "Update_Dropoff_Skim_Mtx - Error merging matrices")
    // goto badquit

    badfill:
     Throw("Update_Dropoff_Skim_Mtx - Error filling matrices")
    // Throw("Update_Dropoff_Skim_Mtx - Error filling matrices")
    // AppendToLogFile(2, "Update_Dropoff_Skim_Mtx - Error filling matrices")
    // goto badquit

    nofortran:
     Throw("Update_Dropoff_Skim_Mtx - Program Update_Dropoff_Skims_Mtx missing")
    // Throw("Update_Dropoff_Skim_Mtx - Program Update_Dropoff_Skims_Mtx missing")
    // AppendToLogFile(2, "Update_Dropoff_Skim_Mtx - Program Update_Dropoff_Skims_Mtx missing")
    // goto badquit

    badfortran:
     Throw("Update_Dropoff_Skims_Mtx - error return from \\ModeChoice\\UPD_DA_Dist_Time_Costv1 !")
    // Throw("Update_Dropoff_Skims_Mtx - error return from \\ModeChoice\\UPD_DA_Dist_Time_Costv1 !")
    // AppendToLogFile(2, "Update_Dropoff_Skims_Mtx - error return from \\ModeChoice\\UPD_DA_Dist_Time_Costv1 !")
    // goto badquit

    badquit:
    RunMacro("TCB Closing", 0, "TRUE" ) 
    UpdateDropSkimOK = 0
    goto quit
    
quit:

    datentime = GetDateandTime()
    AppendToLogFile(2, "Exit Update_Dropoff_Skim_Mtx: " + datentime)
    AppendToLogFile(1, " ")

    return({UpdateDropSkimOK, msg})

endMacro

macro "RunDADist1" (odmtx, opmtx, pdmtx)
//    folder = "C:\\temp\\dadist1\\"
//    odmtx = folder + "peakbus_DODist.MTX"
//    opmtx = folder + "skim_knr_peak.mtx"
//    pdmtx = folder + "skim_knr2dest_peak.mtx"
    od = CreateObject("Matrix", odmtx)
    op = CreateObject("Matrix", opmtx)
    pd = CreateObject("Matrix", pdmtx)
    tmp1 = GetTempFileName("*.bin")
    od.ExportToTable({OutputMode: "Tables", FileName: tmp1, Cores: {"Park Node"}})
    odt = CreateObject("Table", tmp1)
    tmp2 = GetTempFileName("*.bin")
    op.ExportToTable({OutputMode: "Tables", FileName: tmp2})
    opt = CreateObject("Table", tmp2)
    opt.RenameField({FieldName: "Length (Skim)", NewName: "OPLength"})
    opt.RenameField({FieldName: "TTPkAssn* (Skim)", NewName: "OPTime"})
    tmp3 = GetTempFileName("*.bin")
    pd.ExportToTable({OutputMode: "Tables", FileName: tmp3})
    pdt = CreateObject("Table", tmp3)
    pdt.RenameField({FieldName: "Length (Skim)", NewName: "PDLength"})
    jv1 = odt.Join({Table: opt, LeftFields: {"Rows", "Park Node"}, RightFields: {"Origin", "Destination"}})
    jv2 = jv1.Join({Table: pdt, LeftFields: {"Park Node", "Columns"}, RightFields: {"Origin", "Destination"}})
    jv = jv2.GetView()
    mhandle = od.GetMatrixHandle()
    UpdateCores = {null, "OPLength", null, "OPTime", "PDLength", null}
    UpdateMatrixFromView(mhandle, jv + "|", "Rows", "Columns", , UpdateCores, "Replace",) // fill in class number in matrix
    od.Cost := if od.Cost > 0 and od.[Drive Length] > 0 then 100 * od.Cost + 10 * od.[Drive Length] else null

endmacro