/*

*/

// Create tour directory
Macro "Create Tour Dir" (Args)
    
    run_dir = Args.[Run Directory]
    mrm_dir = Args.[MRM Directory]
    year = Args.[Run Year]
    keepgoing = "Yes"
    
    modeltype = "Tour"
    CreateDirectory = 1
    // RunMacro("GetDir")

    // if GetDirectoryInfo(run_dir, ) <> 0
    //     then do
    //         button = MessageBox("OVERWRITE Tour Run Dir: " + DirUser + " ? - All files to recycle bin", 
    //             {{Caption, "\\Overwrite tour run dir"}, {"Buttons", "YesNo"},
    //                 {"Icon", "Warning"}})
    //         PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
    //         if button = "No" 
    //             then do
    //                 Message = Message + {"Run Dir: " + DirUser + " NOT overwritten"}
    //                 goto quitcreatedirtourbutton
    //             end
    //             else PutInRecycleBin(DirUser)
    //     end  //DirExist > 1

    // if keepgoing = "Yes" then RunMacro("GetMRM")
    // if keepgoing = "Yes" then RunMacro("GetYear")
    if keepgoing = "Yes" then RunMacro("CreateDir", Args)
    if keepgoing = "Yes" then RunMacro("GetTAZ", Args)
    if keepgoing = "Yes" then RunMacro("GetLU", Args)
    if keepgoing = "Yes" 
        then do
            // Args = RunMacro("InitializeArgs")

            // Report and Log files initialized
            // datentime = GetDateandTime()
            // ReportFile = DirUser + "\\Report\\TC_Report.xml"
            // SetReportFileName(ReportFile)
            AppendtoReportFile(1, "Create Directory: " + DirUser + ",  " + datentime)
            AppendtoReportFile(1, " ") 
            // LogFile = DirUser + "\\Report\\TC_Log.xml"
            // SetLogFileName(LogFile)
            AppendtoLogFile(1, "Create Tour Directory: " + DirUser + ",  " + datentime)
            AppendtoLogFile(1, " ") 
            AppendtoLogFile(1, "Create Tour Directory messages")
            for i = 1 to Messages.length do
                AppendtoLogFile(2, Messages[i])
            end
            AppendtoLogFile(2, " ")				
            
            // RunMacro("SetArguments")
        end
    // RunMacro("SetSignals")

    quitcreatedirtourbutton:
    ShowMessage("Tour Directory Created.")

endmacro

// **************************  Macros section of DBox *******************************
//
//	GetDir - Get file name of run directory 
//	GetArguments - Read arguments file or initialize 
//	SetArguments - Save arguments to file file 
//	CheckArguments - Last check called by run model buttons
//	GetMRM - Get file name of MRM directory
//		GetMRMDefault - Get MRM default from \TransCad dir
//	GetYear - Get year of run
//	CreateDir - Create run directory
//	GetTAZ - get TAZ file - copy to \\Metrolina if nec.
//	GetLU - get land use file
//	SetSignals

//	CheckDirFiles - check MRM, Year, TAZ, LU files - set signals 
//  CreateRunDirectory - Create run directory and fill.   If necessary - create \Metrolina also
//*************************************************************************************************



// *************************************Create Directory ************************************		

Macro "CreateDir" (Args)
// Creates run directory and subdirectories, fills files from MRM

    MRMUser = Args.[MRM Directory]
    METUser = Args.[MET Directory]
    DirUser = Args.[Run Directory]
    YearUser = Args.[Run Year]

    // //If Metrolina does not exist create it and subdirs (not year yet), otherwise check for msg files 
    // keepgoing = "Yes"
    // METSignalStatus = 3
    // DirSignalStatus = 3

    // METMissing = null

    // if METExist = 0 then CreateDirectory(METUser) 

    // for i = 1 to METSubDir.length do
    //     METInfo = GetDirectoryInfo(METUser + METSubDir[i], "Directory")	
    //     if METInfo = null then CreateDirectory(METUser + METSubDir[i])
    // end // for i	

    // ADDED condition to pull different sets of mode choice constants based on version (Trip vs Tour)
    // ALSO checks datestamp and pulls one matching MRM

    METFiles =
        {
            {"\\MS_Control_Template", 
            {"ALTNAME_HBW_PEAK.bat", "ALTNAME_HBW_OFFPEAK.bat", "ALTNAME_HBW_PEAK.ctl", "ALTNAME_HBW_OFFPEAK.ctl",
            "ALTNAME_HBO_PEAK.bat", "ALTNAME_HBO_OFFPEAK.bat", "ALTNAME_HBO_PEAK.ctl", "ALTNAME_HBO_OFFPEAK.ctl",
            "ALTNAME_NHB_PEAK.bat", "ALTNAME_NHB_OFFPEAK.bat", "ALTNAME_NHB_PEAK.ctl", "ALTNAME_NHB_OFFPEAK.ctl",
            "ALTNAME_HBU_PEAK.bat", "ALTNAME_HBU_OFFPEAK.bat", "ALTNAME_HBU_PEAK.ctl", "ALTNAME_HBU_OFFPEAK.ctl",
            "Mode_Choice_Script.txt", "Segment_Map.txt", "Segment_Map.txt.def",
            "TAZ_ATYPE_TRANSIT_FLAGS.dbf", "TAZ_ATYPE.asc.def"}},

            // {"\\MS_Control_Template\\Trip", 
            // {"HBW_PEAK_Bias.txt", "HBW_PEAK_Bias.txt.def", "HBW_PEAK_Constant.txt", "HBW_PEAK_Constant.txt.def",
            // "HBW_OFFPEAK_Bias.txt", "HBW_OFFPEAK_Bias.txt.def", "HBW_OFFPEAK_Constant.txt", "HBW_OFFPEAK_Constant.txt.def",
            // "HBO_PEAK_Bias.txt", "HBO_PEAK_Bias.txt.def", "HBO_PEAK_Constant.txt", "HBO_PEAK_Constant.txt.def",
            // "HBO_OFFPEAK_Bias.txt", "HBO_OFFPEAK_Bias.txt.def", "HBO_OFFPEAK_Constant.txt", "HBO_OFFPEAK_Constant.txt.def",
            // "NHB_PEAK_Bias.txt", "NHB_PEAK_Bias.txt.def", "NHB_PEAK_Constant.txt", "NHB_PEAK_Constant.txt.def",
            // "NHB_OFFPEAK_Bias.txt", "NHB_OFFPEAK_Bias.txt.def", "NHB_OFFPEAK_Constant.txt", "NHB_OFFPEAK_Constant.txt.def",
            // "HBU_PEAK_Bias.txt", "HBU_PEAK_Bias.txt.def", "HBU_PEAK_Constant.txt", "HBU_PEAK_Constant.txt.def",
            // "HBU_OFFPEAK_Bias.txt", "HBU_OFFPEAK_Bias.txt.def", "HBU_OFFPEAK_Constant.txt", "HBU_OFFPEAK_Constant.txt.def",
            // "modes.dbf", "modexfer.dbf"}},


            // {"\\MS_Control_Template\\Tour", 
            {"\\MS_Control_Template", 
            {"HBW_PEAK_Bias.txt", "HBW_PEAK_Bias.txt.def", "HBW_PEAK_Constant.txt", "HBW_PEAK_Constant.txt.def",
            "HBW_OFFPEAK_Bias.txt", "HBW_OFFPEAK_Bias.txt.def", "HBW_OFFPEAK_Constant.txt", "HBW_OFFPEAK_Constant.txt.def",
            "HBO_PEAK_Bias.txt", "HBO_PEAK_Bias.txt.def", "HBO_PEAK_Constant.txt", "HBO_PEAK_Constant.txt.def",
            "HBO_OFFPEAK_Bias.txt", "HBO_OFFPEAK_Bias.txt.def", "HBO_OFFPEAK_Constant.txt", "HBO_OFFPEAK_Constant.txt.def",
            "NHB_PEAK_Bias.txt", "NHB_PEAK_Bias.txt.def", "NHB_PEAK_Constant.txt", "NHB_PEAK_Constant.txt.def",
            "NHB_OFFPEAK_Bias.txt", "NHB_OFFPEAK_Bias.txt.def", "NHB_OFFPEAK_Constant.txt", "NHB_OFFPEAK_Constant.txt.def",
            "HBU_PEAK_Bias.txt", "HBU_PEAK_Bias.txt.def", "HBU_PEAK_Constant.txt", "HBU_PEAK_Constant.txt.def",
            "HBU_OFFPEAK_Bias.txt", "HBU_OFFPEAK_Bias.txt.def", "HBU_OFFPEAK_Constant.txt", "HBU_OFFPEAK_Constant.txt.def",
            "modes.dbf", "modexfer.dbf"}},


        {"\\TAZ", 
            {"TAZNeighbors_pct.asc", "TAZNeighbors_pct.dct", "Parking_Cost_Base06.dbf", "PUMAequiv.prn"}},

        {"\\Pgm",
            {"CaliperMTXF.dll","CaliperMTXF.lib","capspd.exe","SHW32.DLL",
            "tdmet_mtx.exe", "tgmet2015_171013.exe"}},

        {"\\Pgm\\ModeChoice",  
            {"Add_Shadow_Price.exe","CALIBMS.exe","Caliperb.dll","CaliperMTX.dll","CaliperMTXF.dll","CaliperMTXF.lib",
            "DFORMD.DLL","Drv2PNR2Attr.exe","ExportUBMatrix.exe","HA312W32.dll","KNR_Loc_CAT.exe","SHW32.DLL", "ModeChoice.exe",
            "UPD_DA_Dist_Time_Costv1.exe","UPD_DA_Dist_Time_Costv2.exe"}},

        {"\\Pgm\\CapspdFactors", 
            {"capspd_factors.prn", "capspd_nodeerrors.asc", "capspd_nodeerrors.dct", "guideway20.prn"}},

        // {"\\Pgm\\FrictionFactors\\Trip",  
        //     {"ffhbw1.prn", "ffhbw2.prn", "ffhbw3.prn", "ffhbw4.prn", 
        //     "ffhbo1.prn", "ffhbo2.prn", "ffhbo3.prn", "ffhbo4.prn",
        //     "ffhbs1.prn", "ffhbs2.prn", "ffhbs3.prn", "ffhbs4.prn", 
        //     "ffhbu.prn",  "ffsch.prn",  
        //     "ffjtw.prn",  "ffatw.prn",  "ffnwk.prn",
        //     "ffcom.prn",  "ffmtk.prn",  "ffhtk.prn",  
        //     "ffeiw.prn",  "ffein.prn",  "ffeic.prn", "ffeim.prn", "ffeih.prn",
        //     "ffiew.prn",  "ffien.prn",  "ffiec.prn", "ffiem.prn", "ffieh.prn"}},

        // {"\\Pgm\\FrictionFactors\\Tour",  
        {"\\Pgm\\FrictionFactors",  
            {"ffcom.bin", "ffcom.dcb", "ffmtk.bin", "ffmtk.dcb",  "ffhtk.bin", "ffhtk.dcb",  
            "ffeic.bin", "ffeic.dcb", "ffeim.bin", "ffeim.dcb", "ffeih.bin", "ffeih.dcb",
            "ffiec.bin", "ffiec.dcb", "ffiem.bin", "ffiem.dcb", "ffieh.bin", "ffieh.dcb"}},

        {"\\ExtSta", 
            {"thrubase_auto.asc", "thrubase_auto.dct", "thrubase_com.asc", "thrubase_com.dct",
            "thrubase_mtk.asc",  "thrubase_mtk.dct",  "thrubase_htk.asc", "thrubase_htk.dct",
            "bvthru.asc", "bvthru.dct", "extstavol18_base.asc", "extstavol18_base.dct"}},

        {"",
            {"ATFUN_ID.dbf", "COATFUN_ID.dbf", "County_ATFun.bin","County_ATFun.dcb","County_ATFunID.bin", 
            "County_ATFunID.dcb", "FUNAQ_ID.dbf", "ScreenlineID.bin", "ScreenlineID.dcb", "STCNTY_ID.dbf", 
            "trnpnlty.bin", "trnpnlty.dcb", "HOT_Table.hot"}}
        }

    for i = 1 to METFiles.length do	
        MRMSubDir = METFiles[i][1]

        // TripPos = Position(MRMSubDir,"\\Trip")
        // TourPos = Position(MRMSubDir,"\\Tour")

        METSubDir = MRMSubDir
        // // Trip/Tour not specified
        // if TripPos =  0 and TourPos = 0 then METSubDir = MRMSubDir
        
        // else do
        //     // Trip model
        //     if modeltype = "Trip" then do
        //         if TourPos <> 0 then goto skipsubdir
        //         else do
        //             METSubDir = Left(MRMSubDir,	TripPos -1)
        //             Message = Message + {"CreateDir Info:  Using Trips model subdir " + MRMSubDir}
        //         end
        //     end
            
        //     // Tour model
        //     if modeltype = "Tour" then do
        //         if TripPos <> 0 then goto skipsubdir
        //         else do
        //             METSubDir = Left(MRMSubDir,	TourPos -1)
        //             Message = Message + {"CreateDir Info:  Using Tour model subdir " + MRMSubDir}
        //         end
        //     end
        // end 

        // Check files - if MET created, all the files should be listed here 
        for j = 1 to METFiles[i][2].length do
            MRMdatestamp = null
            METdatestamp = null
            MRMInfo = GetFileInfo(MRMUser + MRMSubDir + "\\" + METFiles[i][2][j])
            if MRMInfo = null then Throw("CreateDir Warning! MRM! " + MRMUser + MRMSubSir + "\\" +  METFiles[i][2][j] + " not found")
                // then Message = Message + {"CreateDir Warning! MRM! " + MRMUser + MRMSubSir + "\\" +  METFiles[i][2][j] + " not found"}
            MRMdatestamp = MRMInfo[7] + " " + MRMInfo[8]

            if GetDirectoryInfo(METUser + METSubDir, "All") = null then CreateDirectory(METUser + METSubDir)

            METInfo = GetFileInfo(METUser + METSubDir + "\\" + METFiles[i][2][j])
            if METInfo = null
                then METMissing = METMissing + {"copy " + MRMUser + MRMSubDir + "\\" +  METFiles[i][2][j] + " " +  METUser + METSubDir +  "\\" +  METFiles[i][2][j]}
                else do
                    METdatestamp = METInfo[7] + " " + METInfo[8]
                    if MRMdatestamp = null 
                        then do
                            Throw("CreateDir Warning! " + METFiles[i][2][j] + " not found in either MRM or MET, Run Will Bomb if file needed!")
                            // METSignalStatus = 2
                            // Message = Message + {"CreateDir Warning! " + METFiles[i][2][j] + " not found in either MRM or MET, Run Will Bomb if file needed!"}
                        end
                    // else if MRMdatestamp <> METdatestamp
                            // then do
                    else do
                        METMissing = METMissing + {"copy " + MRMUser + MRMSubDir + "\\" +  METFiles[i][2][j] + " " +  METUser + METSubDir +  "\\" +  METFiles[i][2][j]}
                        // Message = Message + {"CreateDir Warning! " + MRMSubDir  + "\\" + METFiles[i][2][j] + " datestamp: " + MRMdatestamp + " replaced MET file - datestamp: " + METdatestamp}
                    end
                end // else METInfo <> null
        end  // for j
        skipsubdir:
    end // for i

//		showarray(METMissing)
    if METMissing = null then goto endMET

    //Add MET files - loaded with subdir into METMissing array in step above

    // DOS copy to preserve file dates
//		batchname = METUser + "\\holdher.txt"
    batchname  = METUser + "\\copy_file.bat"
    exist = GetFileInfo(batchname)
    if (exist <> null) then DeleteFile(batchname)
    batchhandle = OpenFile(batchname, "w")
    for i = 1 to METMissing.length do
        WriteLine(batchhandle, METMissing[i])
    end // for i
    CloseFile(batchhandle)

    status = RunProgram(batchname, )

    if (status <> 0) 
        then do
            Throw("CreateDir WARNING! Error in batch copy from MRM to \\Metrolina, status=" +i2s(status))
            // Message = Message + {"CreateDir WARNING! Error in batch copy from MRM to \\Metrolina, status=" +i2s(status)}
            // METSignalStatus = 2
        end
        else DeleteFile(batchname)
    endMET:
    // ****************Create Run Directory ***************************************************

    //Make sure year exists in MRM
    MRMInfo = GetDirectoryInfo(MRMUser + "\\" + YearUser, "Directory")
    if MRMInfo = null then do
        Throw("CreateDir ERROR! Year: " + YearUser + " does not exist in MRM: " + MRMUser)
        // MRMSignalStatus = 1
        // Message = Message + {"CreateDir ERROR! Year: " + YearUser + " does not exist in MRM: " + MRMUser}
        // goto badCreateDir
    end
    if GetDirectoryInfo(DirUser, "All") = null then CreateDirectory(DirUser)

    LandUseStatus = 1

    RunDirSubDir = 
        {"\\AutoSkims", "\\Ext", "\\HwyAssn", "\\LandUse", "\\ModeSplit", "\\Report", "\\Skims", "\\TD", "\\TG", "\\TOD2",
            "\\TranAssn", "\\TripTables", "\\HwyAssn\\HOT",
            "\\TranAssn\\PPrmW", "\\TranAssn\\PPrmD", "\\TranAssn\\PPrmDrop", "\\TranAssn\\OPPrmW", "\\TranAssn\\OPPrmD",
            "\\TranAssn\\OPPrmDrop", "\\TranAssn\\PBusW", "\\TranAssn\\PBusD", "\\TranAssn\\PBusDrop", "\\TranAssn\\OPBusW", 
            "\\TranAssn\\OPBusD", "\\TranAssn\\OPBusDrop",
            "\\ModeSplit\\Inputs","\\ModeSplit\\Inputs\\Controls", "\\ModeSplit\\Results"}	

    for i = 1 to RunDirSubDir.length do
        if GetDirectoryInfo(DirUser + RunDirSubDir[i], "All") = null then CreateDirectory(DirUser + RunDirSubDir[i])
    end
            
    //Copy files	
    batchname  = DirUser + "\\copy_file.bat"
    exist = GetFileInfo(batchname)
    if (exist <> null) then DeleteFile(batchname)
    batchhandle = OpenFile(batchname, "w")

    // need to add year onto extsta vol files	
    
    YearTwo = Right(YearUser,2)
    rundir_files = 
        {"station_database.dbf", "transit_corridor_id.dbf", "routes.dbf", "Track_ID.dbf", 
            "transys.rtg", "transys.rts","transysc.bin", "transysc.BX", "transysc.DCB", "transysL.bin",
            "transysL.BX", "transysL.DCB", "transysR.bin", "transysR.BX", "transysR.DCB", "transysS.bin",
            "transysS.BX", "transysS.cdd", "transysS.cdk", "transysS.dbd", "transysS.DCB", "transysS.dsc",		
            "transysS.dsk","transysS.grp", "transysS.lok", "transysS.pnk", "transysS.r0"}
    rundir_files = rundir_files + {"Ext\\extstavol" + YearTwo + ".asc"} + {"Ext\\extstavol" + YearTwo + ".dct"}   

    //Standard runyear files
    MRMpath = MRMUser + "\\" + YearUser + "\\"
    for i = 1 to rundir_files.length do	
        MRMInfo = GetFileInfo(MRMpath + rundir_files[i])
        if MRMInfo <> null
            then WriteLine(batchhandle, "copy " + MRMpath + rundir_files[i] + " " + DirUser + "\\" + rundir_files[i])
            else do
                Throw("MRM file: " + YearUser + "\\" + rundir_files[i] + " not found - not copied")
                // Message = Message + {"MRM file: " + YearUser + "\\" + rundir_files[i] + " not found - not copied"}
                // DirSignalStatus = 2
            end
    end // for i
    
    //Everything in TG subdirectory (ONLY for TOUR model files)
    // if modeltype = "Tour" then do
        MRMpath = MRMUser + "\\TG\\"
        MRMInfo = GetDirectoryInfo(MRMpath + "*.*", "File")
        if MRMInfo <> null 
            then do
                for i = 1 to MRMInfo.length do
                    WriteLine(batchhandle, "copy " + MRMpath + MRMInfo[i][1] + " " + DirUser + "\\TG\\" + MRMInfo[i][1])
                end
            end
            else do
                Throw(MRMpath + " files missing, not copied")
                // Message = Message + {MRMPath + " files missing, not copied"}
                // DirSignalStatus = 2
            end
    // end

    // HOT
    hotassn_dcb =
        {"Assn_template.dcb"}
    MRMpath = MRMUser + "\\HOT\\"
    for i = 1 to hotassn_dcb.length do	
        MRMInfo = GetFileInfo(MRMpath + hotassn_dcb[i])
        if MRMInfo <> null
            then WriteLine(batchhandle, "copy " + MRMpath + hotassn_dcb[i] + " " + DirUser + "\\HwyAssn\\HOT\\" + hotassn_dcb[i])
            else do
                Throw("MRM\\HOT dcb: " + hotassn_dcb[i] + " not found - not copied")
                // Message = Message + {"MRM\\HOT dcb: " + hotassn_dcb[i] + " not found - not copied"}
                // DirSignalStatus = 2
            end
    end // for i

    //Everything in landuse subdirectory
    MRMpath = MRMUser + "\\" + YearUser + "\\LandUse\\"
    MRMInfo = GetDirectoryInfo(MRMpath + "*.*", "File")
    if MRMInfo <> null 
        then do
            for i = 1 to MRMInfo.length do
                WriteLine(batchhandle, "copy " + MRMpath + MRMInfo[i][1] + " " + DirUser + "\\LandUse\\" + MRMInfo[i][1])
            end
        end	
        else do
            Throw(MRMPath + " files missing, not copied")
            // Message = Message + {MRMPath + " files missing, not copied"}
            // DirSignalStatus = 2
        end

    // end of copy batch
    CloseFile(batchhandle)
    status = RunProgram(batchname, )
    if (status <> 0) 
        then do
            Throw("Error in batch copy from MRM to " + YearUser)
            // Message = Message + {"Error in batch copy from MRM to " + YearUser}
            // DirSignalStatus = 2
        end
        else DeleteFile(batchname)

    // goto quitCreateDir
    
    // badCreateDir:
    // DirSignalStatus = 1
    // keepgoing = "No"
    
    // quitCreateDir:
    
endmacro // Macro CreateDir

/*

*/

Macro "GetTAZ" (Args)
// Macro to identify TAZ file, copy from MRM if necessary
    keepgoing = "Yes"
    TAZSignalStatus = 3
    on error goto notaz

    MRMUser = Args.[MRM Directory]
    METUser = Args.[MET Directory]
    TAZArgs = Args.[MRM TAZ File]
    TAZUser = Args.[TAZ File]

    // // Pull TAZ from Arguments
    // if TAZUser = null and TAZArgs <> null
    //     then do
    //         TAZUser = TAZArgs
    //         tazpath = SplitPath(TAZUser)
    //         goto gottaz				
    //     end
            
    // if TAZUser <> null and TAZArgs <> null and Upper(TAZUser) <> Upper(TAZArgs)
    //     then do
    //         Message = Message + {"GetTAZ WARNING!  User TAZ file: " + TAZUser + " differs from Args"}
    //         Message = Message + {"GetTAZ WARNING!  User TAZ file: " + TAZUser + " differs from Args"}
    //         PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
    //         TAZSignalStatus = 2
    //     end
            
    // TAZInfo = GetFileInfo(TAZUser)
    // if TAZInfo = null 
    //     then goto gettaz

    // tazpath = SplitPath(TAZUser)
    // if Upper(tazpath[1] + tazpath[2]) = Upper(METUser + "\\TAZ\\") 
    //     then goto gottaz
    
    // gettaz: 
    // on escape goto notaz

    // TAZDir = METDir + "\\TAZ\\*.dbd"
    // dbdexist = GetDirectoryInfo(METDir,"File")
    // if dbdexist = null 
    //     then InitDir = MRMUser + "\\TAZ"
    //     else InitDir = METUser + "\\TAZ"

    // TAZUser = ChooseFile({{"Standard","*.dbd"}},"Choose the TAZ File",{{"Initial Directory", InitDir}})
    // TAZInfo = GetFileInfo(TAZUser)
    // if TAZInfo = null 
    //     then goto gettaz
    //     else do
    //         tazpath = SplitPath(TAZUser)
    //         if Upper(tazpath[1] + tazpath[2]) = Upper(METUser + "\\TAZ\\") 
    //             then goto gottaz
    //             else do
    //                 CopyDataBase(TAZUser, METUser + "\\TAZ\\" + tazpath[3] + tazpath[4])
    //                 TAZUser = METUser + "\\TAZ\\" + tazpath[3] + tazpath[4]
    //                 Message = Message + {"Copied TAZ : " + tazpath[3] + " from MRM to \\Metrolina"} 
    //             end		
    //     end		
    // gottaz:

    
    CopyDataBase(TAZArgs, TAZUser)
    
    // Create/check TAZ template matrix and tazid files (1-good,2-warn,3-bad return)

    TAZrtn = RunMacro("Matrix_template", TAZUser)
    Message = Message + TAZrtn[2]
    TAZSignalStatus = TAZrtn[1]
    if TAZrtn[1] = 1 then goto notaz 
    
    tazpath = SplitPath(TAZUser)
    // TAZID = OpenTable("TAZID", "FFA", {METUser + "\\TAZ\\" + tazpath[3] + "_TAZID.asc",})
    TAZID = OpenTable("TAZID", "FFA", {MRMUser + "\\TAZ\\" + tazpath[3] + "_TAZID.asc",})
    SetView(TAZID)
    selinttaz = "Select * where TAZ < 12000"
    selexttaz = "Select * where TAZ >= 12000"
    NumIntTAZ = Selectbyquery("inttaz", "Several", selinttaz,)
    NumExtTAZ = Selectbyquery("exttaz", "Several", selexttaz,)
    NumTAZ = NumIntTAZ + NumExtTAZ
    Message = Message + {"TAZ file " + tazpath[3] + ": Internal TAZ="+i2s(NumIntTAZ)+" External TAZ="+i2s(NumExtTAZ)+" Total TAZ="+i2s(NumTAZ)}			
    CloseView(TAZID)
    
    goto quitGetTAZ

    notaz:
    TAZSignalStatus = 1
    Message = Message + {"error= " + GetLastError()}
    PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
    keepgoing = "No"	
    goto quitGetTAZ

    quitGetTAZ:
    on error, escape default
    
endmacro  //Macro GetTAZ	

Macro "GetLU" (Args)
// Macro to identify LU file 
    keepgoing = "Yes"
    LUSignalStatus = 3
    checkLUTAZ = "False"

    LUArgs = Args.[LandUse File]
    LUUser = LUArgs
    TAZArgs = Args.[TAZ File]
    TAZUser = TAZArgs

    // // Pull LU from Arguments
    // if LUUser = null and LUArgs <> null
    //     then do
    //         LUUser = LUArgs
    //         goto gotLU
    //     end
    
    // if LUUser <> null and LUArgs <> null and Upper(LUUser) <> Upper(LUArgs)
    //     then do
    //         Message = Message + {"GetLU WARNING!  User Land Use file: " + LUUser + " differs from"}
    //         Message = Message + {"   Args Land Use file: " + LUArgs}
    //         PlaySound(sysdir + "\\media\\Windows Notify.wav", "null")
    //         LUSignalStatus = 2
    //     end

    // LUInfo = GetFileInfo(LUUser)
    // if LUInfo = null 
    //     then goto getLU
    //     else goto gotLU
        
    // // Get land use file
    // getLU:
    // on error goto getLU
    // on escape goto noLU
    // LUUser = ChooseFile({{"DBASE","*.dbf"}},"Choose the Land Use File",{{"Initial Directory", DirUser + "\\LandUse"}})
    // LUInfo = GetFileInfo(LUUser)
    // if LUInfo = null 
    //     then goto getLU
    //     else goto gotLU

    // gotLU:

    // check against TAZ
    checkLUrtn = RunMacro("checkLU", LUUser, TAZUser)
    Message = Message + checkLUrtn[2]
    if checkLUrtn[1] = 0 then goto noLU

    goto quitGetLU
    
    noLU:
    TAZSignalStatus = 1
    PlaySound(sysdir + "\\media\\Windows Critical Stop.wav", "null")
    keepgoing = "No"	
    goto quitGetLU
    
    quitGetLU:
    on error, escape default
endmacro //Macro GetLU

Macro "SetSignals"
    //Set Signals
    for i = 1 to 3 do
        if i = DirSignalStatus  then ShowItem(DirSignals[i])
                                else HideItem(DirSignals[i])
        if i = MRMSignalStatus  then ShowItem(MRMSignals[i])
                                else HideItem(MRMSignals[i])
        if i = YearSignalStatus then ShowItem(YearSignals[i])
                                else HideItem(YearSignals[i])
        if i = TAZSignalStatus  then ShowItem(TAZSignals[i])
                                else HideItem(TAZSignals[i])
        if i = LUSignalStatus   then ShowItem(LUSignals[i])
                                else HideItem(LUSignals[i])
    end							
endmacro  //Macro SetSignals