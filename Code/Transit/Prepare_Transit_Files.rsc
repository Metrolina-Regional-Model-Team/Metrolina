macro "Prepare_Transit_Files" (Args)
	// Added NumProcessors check to run 1 or 4+ processors
	// McLelland, Oct, 2011

	// Modified NumProcessors check to run 1 or 8+ processors ; removed choice set and CR path trips configuration for mode choice output and assignment files
	// Modified batch and control file creation process to reflect new ModeChoice program - used Substitute function to simplify creation of batch and control files from the templates
	// Kept the process to create separate skims for rail only and rail+bus
	// Juvva, August, 2015

	//Modified for new UI - McLelland - 10/15
	//Renamed - Prepare_Transit_Files.rsc

	// Modified - Aug 2024 in lieu of updated model that does not require mode choice batch files
	
	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter Prepare Transit Files " + datentime)

	alt_dir =  Args.[Run Directory]
	alt_name = Args.[Run Year]
	METDir = Args.[MET Directory]
	ms_dir = Args.[MET Directory] + "\\MS_Control_Template"
	
	ok4 = RunMacro ("Create Transit Skims Output Matrices", alt_dir, alt_name, METDir)
	if ok4[1] = 0 then
		Throw("Prepare Transit Files - error return from Transit Skims Output Matrices")

	/*ok5 = RunMacro ("Create Transit Assignment Matrices", alt_dir, alt_name, METDir)
	if ok5[1] = 0 then
		Throw("Prepare Transit Files - error return from Create Mode Split Output Matrices")*/
	
	// copy modes.dbf and modexref.dbf from ms_control_template  (v7 have updated transit fares 4/25/17)
	filename_in  = ms_dir  + "\\modes.dbf"
	filename_out = alt_dir + "\\modes.dbf"
	CopyFile(filename_in, filename_out)

	filename_in  = ms_dir  + "\\modexfer.dbf"
	filename_out = alt_dir + "\\modexfer.dbf"
	CopyFile(filename_in, filename_out)

	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit Prepare Transit Files: " + datentime)
	
	RunMacro("G30 File Close All")
	return(1)
endmacro

//---------------------------------------------------------------------
// Macro "Create Transit Skims Output Matrices" 
//---------------------------------------------------------------------
Macro "Create Transit Skims Output Matrices" (alt_dir, alt_name, METDir)
	msg = null
	// on error do
	// 	msg = "Create Transit Skims Outut Matrices - missing \\taz\\matrix_template.mtx"
	// 	goto badquit
	// 	end

	OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
	on error default
	CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\Skims\\PK_WKTRAN_SKIMS.MTX"},
		{"Label", "Peak Walk-to-Transit"},
		{"File Based", "Yes"},
		{"Tables", {"IVTT - Prem Walk", "Approach - Prem Walk", "Cost - Prem Walk", "Transfer Penalty Time - Prem Walk", "Initial Wait - Prem Walk",  "Access Walk Time - Prem Walk", "Egress Walk Time - Prem Walk", "Transfer Walk Time - Prem Walk", "Transfer Wait Time - Prem Walk",
					"IVTT - Bus Walk", "Approach - Bus Walk", "Cost - Bus Walk", "Transfer Penalty Time - Bus Walk", "Initial Wait - Bus Walk", "Access Walk Time - Bus Walk", "Egress Walk Time - Bus Walk", "Transfer Walk Time - Bus Walk", "Transfer Wait Time - Bus Walk",
					"ModeFlag", "Prem IVTT", "SkS Flag", "PrmOnly Flag",
					"IVTT - Prem2 Walk", "Approach - Prem2 Walk", "Cost - Prem2 Walk", "Transfer Penalty Time - Prem2 Walk", "Initial Wait - Prem2 Walk",  "Access Walk Time - Prem2 Walk", "Egress Walk Time - Prem2 Walk", "Transfer Walk Time - Prem2 Walk", "Transfer Wait Time - Prem2 Walk","ModeFlag2", "Prem2 IVTT", "Prm2Only Flag",
					"Total Walk UnWtd - Prem", "Total Walk UnWtd - Prem2", "Total Walk UnWtd - Bus"}},
		{"Operation", "Union"}})

	OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
	on error default
	CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\Skims\\OFFPK_WKTRAN_SKIMS.MTX"},
		{"Label", "OffPeak Walk-to-Transit"},
		{"File Based", "Yes"},
		{"Tables", {"IVTT - Prem Walk", "Approach - Prem Walk", "Cost - Prem Walk", "Transfer Penalty Time - Prem Walk", "Initial Wait - Prem Walk",  "Access Walk Time - Prem Walk", "Egress Walk Time - Prem Walk", "Transfer Walk Time - Prem Walk", "Transfer Wait Time - Prem Walk",
					"IVTT - Bus Walk", "Approach - Bus Walk", "Cost - Bus Walk", "Transfer Penalty Time - Bus Walk", "Initial Wait - Bus Walk", "Access Walk Time - Bus Walk", "Egress Walk Time - Bus Walk", "Transfer Walk Time - Bus Walk", "Transfer Wait Time - Bus Walk",
					"ModeFlag", "Prem IVTT", "SkS Flag", "PrmOnly Flag",
					"IVTT - Prem2 Walk", "Approach - Prem2 Walk", "Cost - Prem2 Walk", "Transfer Penalty Time - Prem2 Walk", "Initial Wait - Prem2 Walk",  "Access Walk Time - Prem2 Walk", "Egress Walk Time - Prem2 Walk", "Transfer Walk Time - Prem2 Walk", "Transfer Wait Time - Prem2 Walk","ModeFlag2", "Prem2 IVTT", "Prm2Only Flag",
					"Total Walk UnWtd - Prem", "Total Walk UnWtd - Prem2", "Total Walk UnWtd - Bus"}},
		{"Operation", "Union"}})

	OM = OpenMatrix(METDir+ "\\TAZ\\matrix_template.mtx", "True")
	mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
	on error default
	CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\Skims\\PK_DRVTRAN_SKIMS.MTX"},
		{"Label", "Peak Drive-to-Transit"},
		{"File Based", "Yes"},
		{"Tables", {"IVTT - Prem Drive", "Approach - Prem Drive", "Cost - Prem Drive", "Transfer Penalty Time - Prem Drive", "Initial Wait - Prem Drive", "Drive Access Time - Prem Drive", "Drive Access Distance - Prem Drive", "Transfer Wait Time - Prem Drive", "Highway OP Time - Prem Drive",
					"IVTT - Bus Drive", "Approach - Bus Drive", "Cost - Bus Drive", "Transfer Penalty Time - Bus Drive", "Initial Wait - Bus Drive", "Drive Access Time - Bus Drive", "Drive Access Distance - Bus Drive", "Transfer Wait Time - Bus Drive", "Highway OP Time - Bus Drive",
					"ModeFlag", "Prem IVTT", "SkS Flag", "PrmOnly Flag",
					"IVTT - Prem2 Drive", "Approach - Prem2 Drive", "Cost - Prem2 Drive", "Transfer Penalty Time - Prem2 Drive", "Initial Wait - Prem2 Drive", "Drive Access Time - Prem2 Drive", "Drive Access Distance - Prem2 Drive", "Transfer Wait Time - Prem2 Drive", "Highway OP Time - Prem2 Drive","ModeFlag2", "Prem2 IVTT", "Prm2Only Flag",
					"Total Walk UnWtd - Prem", "Total Walk UnWtd - Prem2", "Total Walk UnWtd - Bus"}},
		{"Operation", "Union"}})

	OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
	on error default
	CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\Skims\\OFFPK_DRVTRAN_SKIMS.MTX"},
		{"Label", "OffPeak Drive-to-Transit"},
		{"File Based", "Yes"},
		{"Tables", {"IVTT - Prem Drive", "Approach - Prem Drive", "Cost - Prem Drive", "Transfer Penalty Time - Prem Drive", "Initial Wait - Prem Drive", "Drive Access Time - Prem Drive", "Drive Access Distance - Prem Drive", "Transfer Wait Time - Prem Drive", "Highway OP Time - Prem Drive",
					"IVTT - Bus Drive", "Approach - Bus Drive", "Cost - Bus Drive", "Transfer Penalty Time - Bus Drive", "Initial Wait - Bus Drive", "Drive Access Time - Bus Drive", "Drive Access Distance - Bus Drive", "Transfer Wait Time - Bus Drive", "Highway OP Time - Bus Drive",
					"ModeFlag", "Prem IVTT", "SkS Flag", "PrmOnly Flag",
					"IVTT - Prem2 Drive", "Approach - Prem2 Drive", "Cost - Prem2 Drive", "Transfer Penalty Time - Prem2 Drive", "Initial Wait - Prem2 Drive", "Drive Access Time - Prem2 Drive", "Drive Access Distance - Prem2 Drive", "Transfer Wait Time - Prem2 Drive", "Highway OP Time - Prem2 Drive","ModeFlag2", "Prem2 IVTT", "Prm2Only Flag",
					"Total Walk UnWtd - Prem", "Total Walk UnWtd - Prem2", "Total Walk UnWtd - Bus"}},
		{"Operation", "Union"}})

	OM = OpenMatrix(METDir  + "\\TAZ\\matrix_template.mtx", "True")
	mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
	on error default
	CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\Skims\\PK_DROPTRAN_SKIMS.MTX"},
		{"Label", "Peak Drop-Off-to-Transit"},
		{"File Based", "Yes"},
		{"Tables", {"IVTT - Prem DropOff", "Approach - Prem DropOff", "Cost - Prem DropOff", "Transfer Penalty Time - Prem DropOff", "Initial Wait - Prem DropOff", "Drive Access Time - Prem DropOff", "Drive Access Distance - Prem DropOff", "Transfer Wait Time - Prem DropOff", "Highway SkimLength - Prem DropOff", "ParkFlag - Prem DropOff",
					"IVTT - Bus DropOff", "Approach - Bus DropOff", "Cost - Bus DropOff", "Transfer Penalty Time - Bus DropOff" , "Initial Wait - Bus DropOff", "Drive Access Time - Bus DropOff", "Drive Access Distance - Bus DropOff", "Transfer Wait Time - Bus DropOff", "Highway SkimLength - Bus DropOff", "ParkFlag - Bus DropOff",
					"ModeFlag", "Prem IVTT", "SkS Flag", "PrmOnly Flag",
					"IVTT - Prem2 DropOff", "Approach - Prem2 DropOff", "Cost - Prem2 DropOff", "Transfer Penalty Time - Prem2 DropOff", "Initial Wait - Prem2 DropOff", "Drive Access Time - Prem2 DropOff", "Drive Access Distance - Prem2 DropOff", "Transfer Wait Time - Prem2 DropOff", "Highway SkimLength - Prem2 DropOff", "ParkFlag - Prem2 DropOff", "ModeFlag2", "Prem2 IVTT", "Prm2Only Flag",
					"Total Walk UnWtd - Prem", "Total Walk UnWtd - Prem2", "Total Walk UnWtd - Bus"}},
		{"Operation", "Union"}})

	OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
	on error default
	CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\Skims\\OFFPK_DROPTRAN_SKIMS.MTX"},
		{"Label", "OffPeak Drop-Off-to-Transit"},
		{"File Based", "Yes"},
		{"Tables", {"IVTT - Prem DropOff", "Approach - Prem DropOff", "Cost - Prem DropOff", "Transfer Penalty Time - Prem DropOff", "Initial Wait - Prem DropOff", "Drive Access Time - Prem DropOff", "Drive Access Distance - Prem DropOff", "Transfer Wait Time - Prem DropOff", "Highway SkimLength - Prem DropOff", "ParkFlag - Prem DropOff",
					"IVTT - Bus DropOff", "Approach - Bus DropOff", "Cost - Bus DropOff", "Transfer Penalty Time - Bus DropOff" , "Initial Wait - Bus DropOff", "Drive Access Time - Bus DropOff", "Drive Access Distance - Bus DropOff", "Transfer Wait Time - Bus DropOff", "Highway SkimLength - Bus DropOff", "ParkFlag - Bus DropOff",
					"ModeFlag", "Prem IVTT", "SkS Flag", "PrmOnly Flag",
					"IVTT - Prem2 DropOff", "Approach - Prem2 DropOff", "Cost - Prem2 DropOff", "Transfer Penalty Time - Prem2 DropOff", "Initial Wait - Prem2 DropOff", "Drive Access Time - Prem2 DropOff", "Drive Access Distance - Prem2 DropOff", "Transfer Wait Time - Prem2 DropOff", "Highway SkimLength - Prem2 DropOff", "ParkFlag - Prem2 DropOff", "ModeFlag2", "Prem2 IVTT", "Prm2Only Flag",
					"Total Walk UnWtd - Prem", "Total Walk UnWtd - Prem2", "Total Walk UnWtd - Bus"}},
		{"Operation", "Union"}})

	on error default
	return({1, msg})

	badquit:
	on error default
	return({0, msg})
endMacro


//---------------------------------------------------------------------
// Macro "Create Transit Assignment Matrices" 
//---------------------------------------------------------------------

Macro "Create Transit Assignment Matrices" (alt_dir, alt_name, METDir)
	msg = null
	// on error do
	// 	msg = "Create Transit Assignment Matrices - missing \\taz\\matrix_template.mtx"
	// 	goto badquit
	// 	end

	// --- Create From Template Matrix, Output Matrices to store Transit Skims
	OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
	on error default
	CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\tranassn\\Transit Assign Walk.MTX"},
		{"Label", "Walk-to-Transit Assignment"},
		{"File Based", "Yes"},
		{"Tables", {"PprmW", "PbusW", "OPprmW", "OPbusW"}},
		{"Operation", "Union"}})

	OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
	on error default
	CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\tranassn\\Transit Assign Drive.MTX"},
		{"Label", "Drive-to-Transit Assignment"},
		{"File Based", "Yes"},
		{"Tables", {"PprmD", "PbusD", "OPprmD", "OPbusD"}},
		{"Operation", "Union"}})

	OM = OpenMatrix(METDir + "\\TAZ\\matrix_template.mtx", "True")
	mc1 = CreateMatrixCurrency(OM, "Table", "Rows", "Columns", )
	on error default
	CopyMatrixStructure({mc1}, {{"File Name", alt_dir+"\\tranassn\\Transit Assign DropOff.MTX"},
		{"Label", "DriveOff-to-Transit Assignment"},
		{"File Based", "Yes"},
		{"Tables", {"PprmDropOff", "PbusDropOff", "OPprmDropOff", "OPbusDropOff"}},
		{"Operation", "Union"}})

	on error default
	return({1, msg})

	badquit:
	on error default
	return({0, msg})

endMacro
