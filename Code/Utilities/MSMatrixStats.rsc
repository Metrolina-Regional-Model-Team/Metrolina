macro "MSMatrixStats" (Args)

	// LogFile = Args.[Log File].value
	// SetLogFileName(LogFile)

	Dir = Args.[Run Directory]
	msg = null
	MSStatsOK = 1

	DirReport  = Dir + "\\Report"
	DirOutTripTab  = Dir + "\\TripTables\\"
	RunMacro("TCB Init")

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter MSMatrixStats: " + datentime)

	TOD = {"_AM.mtx","_MD.mtx","_PM.mtx","_NT.mtx"}
	Purp = {"HBO","HBW","HBS","HBU","Sch"}
	TODCode = {"AM","MD","PM","NT"}

	/*MatArray = {"HBW_Peak_MS.mtx",
		    "HBW_Offpeak_MS.mtx",
		    "HBO_Peak_MS.mtx",
		    "HBO_Offpeak_MS.mtx",
		    "NHB_Peak_MS.mtx",
		    "NHB_Offpeak_MS.mtx",
		    "HBU_Peak_MS.mtx",
		    "HBU_Offpeak_MS.mtx"}
	MatCode = {"HBW Peak   ",
		   "HBW Offpeak",
		   "HBO Peak   ",
		   "HBO Offpeak",
		   "NHB Peak   ",
		   "NHB Offpeak",
		   "HBU Peak   ",
		   "HBU Offpeak"}
	*/

	MS_Statistics = CreateTable("MS_Statistics", DirReport + "\\MS_Statistics.bin", "FFB", {{"Purpose", "String", 16, , "No"}, {"TOD", "String", 16, , "No"}, {"Mode", "String", 8, , "No"}, {"Trips", "Real", 10, 2, "No"}, {"IntraTrips", "Real", 10, 2, "No"}}) 

	for tcnt =  1 to TOD.length do
	
		for pcnt = 1 to Purp.length do

			hit = GetFileInfo(DirOutTripTab  + Purp[pcnt] + TOD[tcnt] )
			if hit = null then goto badmat

			M = OpenMatrix(DirOutTripTab  + Purp[pcnt] + TOD[tcnt],)
			StatArray = MatrixStatistics(M,)
			for j = 1 to StatArray.length do
				Mode = StatArray[j][1]
				Trips = r2s(StatArray[j][2][2][2])
				IntraTrips = r2s(StatArray[j][2][7][2])
				
				rh = AddRecord("MS_Statistics", {{"Purpose",Purp[pcnt]}, {"TOD",TODCode[tcnt]},{"Mode",Mode}, {"Trips",Trips}, {"IntraTrips",IntraTrips}})
			end
		end
	
	end

	MS_Statistics_tab1 = ExportView("MS_Statistics|", "CSV", DirReport + "\\MS_Statistics.csv",{"Purpose", "TOD", "Mode", "Trips", "IntraTrips"}, { {"CSV Header", "True"} } )
	
	RunMacro("G30 File Close All")
	goto quit
		
	badmat: 
	Throw("MSMatrixStats:  Error - matrix " + TOD[tcnt] + " not found")
	AppendToLogFile(1, "MSMatrixStats:  Error - matrix " + TOD[tcnt]  + " not found")
	MSStatsOK = 0
	goto quit 
	
	quit: 
	datentime = GetDateandTime()
	AppendToLogFile(1, "Exit MSMatrixStats: " + datentime)
	return({MSStatsOK, msg})

endmacro