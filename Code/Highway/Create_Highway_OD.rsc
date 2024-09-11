/*
Fills fields in the tour file with PA and AP period info
Period Code: 1: AMPeak, 2: Midday, 3: PMPeak, 4: Night
Use simplified logic from previous version of the model
    - Split tours into one of 4 categories: PK-PK, PK-OP, OP-PK, OP-OP
    - Then apply fractions from input table for each of these cases
        - PK_PK tours have 3 possibilities: AM-AM, AM-PM, PM-PM
        - PK_OP tours have 3 possibilities: AM-MD, AM-NT, PM-NT
        - OP_PK tours have 3 possibilities: MD-PM, NT-AM, NT-PM (Note PreAM period is also classified as NT)
        - OP_OP tours have 4 possibilities: MD-MD, MD-NT, NT-MD, NT-NT
        - These factors vary by purpose, computed from the surveyh
*/
Macro "Tour TOD Combinations"(Args)

    datentime = GetDateandTime()
    AppendToLogFile(1, "Enter Tour TOD Combinations " + datentime)

    purps = {"HBW", "HBU", "SCH", "HBS", "HBO", "ATW"}
    tods = {"OP", "PK"} // {1, 2}
    
    for purp in purps do
        tourFile = Args.[Run Directory] + "\\TD\\dc" + purp + ".bin"
        tour = CreateObject("Table", tourFile)
        flds = {{FieldName: "PATOD", Type: "string"},
                {FieldName: "APTOD", Type: "string"}}
        tour.AddFields({Fields: flds})
        
        for i = 1 to tods.length do
            for j = 1 to tods.length do
                
                n = tour.SelectByQuery({
                    SetName: "Selection",
                    Query: printf("PAper = %lu and APper = %lu", {i,j})
                })

                if n > 0 then do
                    tod_comb = tods[i] + "_" + tods[j]              // e.g. PK_PK
                    factors = Args.(tod_comb + " TOD Factors")
                    tour.ChangeSet("Selection")
                    
                    SetRandomSeed(99999*purps.Position(purp) + 999*i + 99*j)
                    params = null
                    params.population = factors.[TOD Combination]   // e.g. {"AM_AM", "AM_PM", "PM_PM"}
                    params.weight = factors.(purp)                  // e.g. {0.396, 0.252, 0.352}
                    samples = RandSamples(n, "Discrete", params)
                    tour.PATOD = Left(samples, 2)
                    tour.APTOD = Right(samples, 2)
                end

            end // j loop  
        end // i loop
    end // purpose loop

    ret_value = 1
endmacro


/*
Expands the tour files into trip files and creates matrices by period for each trip purpose
*/

Macro "Create Trips" (Args)
    
    datentime = GetDateandTime()
    AppendToLogFile(1, "Enter Create Trip File " + datentime)

    purps = {"HBW", "HBS", "HBO", "Sch", "HBU", "ATW"}
    files = {"dcHBW", "dcHBS", "dcHBO", "dcSch", "dcHBU", "dcATW"}
    out_dir = Args.[Run Directory] + "\\TripTables"

    temp_file = Args.[Run Directory] + "\\TD\\temp.bin"
    for purp in purps do
        dcFile = Args.[Run Directory] + "\\TD\\dc" + purp + ".bin"
        out_file = out_dir + "\\trips_" + purp + ".bin"
        
        // Copy the file
        CopyFile(dcFile, temp_file)
        CopyFile(
            Substitute(dcFile, ".bin", ".dcb", 1), 
            Substitute(temp_file, ".bin", ".dcb", 1)
        )
        tbl = null
        tbl = CreateObject("Table", temp_file)    
        
        // The stop fields are named SL_PA1, SL_PA2, ..., SL_AP1, SL_AP2
        // all the way to SL_AP7. We want to pivot these fields into a single
        // field, but before that, shift all stops as far left as possible
        // to remove gaps. This will make post-pivoting edits easier.
        fields = {
            "ORIG_TAZ", 
            "SL_PA1", "SL_PA2", "SL_PA3", "SL_PA4", "SL_PA5", "SL_PA6", "SL_PA7",
            "DEST_TAZ",
            "SL_AP1", "SL_AP2", "SL_AP3", "SL_AP4", "SL_AP5", "SL_AP6", "SL_AP7"
        }
        tbl.AddField("return_orig")
        tbl.return_orig = tbl.ORIG_TAZ
        fields_add_return = fields + {"return_orig"}

        // Rename fields before pivot to preserve order
        ordered_fields = null
        for i = 1 to fields_add_return.length do
            field = fields_add_return[i]
            num = 100 + i
            ordered_field = String(num) + "_" + field
            tbl.RenameField({FieldName: field, NewName: ordered_field})
            ordered_fields = ordered_fields + {ordered_field}
        end
        pivot = tbl.PivotLonger({
            Fields: ordered_fields,
            NamesTo: "Stop",
            ValuesTo: "TripOrigTAZ"
        })
        // Remove rows where no stop took place
        pivot.SelectByQuery({
            SetName: "notnull",
            Query: "TripOrigTAZ <> null"
        })
        pivot.AddFields({Fields: {
            {FieldName: "TripDestTAZ", Type: "integer"},
            {FieldName: "TOD", Type: "string", Width: 3}
        }})
        
        flds = {"ID", "HHID", "SIZE", "INCOME", "LIFE", "WRKRS", "Purp", "PATOD", "APTOD",
                "TourMode", "Stop", "TripOrigTAZ", "TripDestTAZ", "TOD"}
        export = pivot.Export({ViewName: "exported", FieldNames: flds})
        export.Sort({FieldArray: {{"ID", "Ascending"}, {"Stop", "Ascending"}}})

        // Transfer the TOD info from PATOD and APTOD fields
        data = export.GetDataVectors({FieldNames: {"Stop", "PATOD", "APTOD"}})
        v_stop = data.Stop
        v_pa = data.PATOD
        v_ap = data.APTOD
        v_tod = if Position(v_stop, "_PA") > 0 or Position(v_stop, "ORIG") > 0
                        then v_pa 
                        else v_ap
        export.TOD = v_tod

        // Determine the TripDestTAZ, which is the origin from the next record
        data = export.GetDataVectors({FieldNames: {"ID", "TripOrigTAZ"}})
        v_id = data.ID
        v_otaz = data.TripOrigTAZ
        v_lead_id = SubVector(v_id, 2, )
        v_lead_id = A2V(V2A(v_lead_id) + {null})
        v_lead_otaz = SubVector(v_otaz, 2, )
        v_lead_otaz = A2V(V2A(v_lead_otaz) + {null})
        v_dtaz = if v_id = v_lead_id
            then v_lead_otaz
            else null
        export.TripDestTAZ = v_dtaz


        // The last record in each tour will have a null destination. Remove it.
        export.SelectByQuery({
            SetName: "Trips",
            Query: "TripDestTAZ <> null"
        })

        final = export.Export({FileName: out_file, FieldNames: {
            "ID",
            "HHID",
            "SIZE",
            "INCOME",
            "LIFE",
            "WRKRS",
            "Purp",
            "TourMode",
            "TripOrigTAZ",
            "TripDestTAZ",
            "TOD"
        }})
        final.RenameField({FieldName: "ID", NewName: "TourID"})
        final.RenameField({FieldName: "TourMode", NewName: "Mode"})

        // Create OD matrices for peak and off-peak periods
        final.AddField("one")
        v = Vector(final.GetRecordCount(), "integer", {Constant: 1})
        final.one = v
        modes = final.Mode
        modes = SortArray(v2a(modes), {Unique: 'True'})
        skim_mtx = Args.[Run Directory] + "\\Skims\\offpk_hwyskim.mtx"
        periods = {"AM", "MD", "PM", "NT"}
        for period in periods do
            mtx_file = out_dir + "\\" + purp + "_" + period + ".mtx"
            CopyFile(skim_mtx, mtx_file)
            mtx = CreateObject("Matrix", mtx_file)
            cores_to_drop = mtx.GetCoreNames()
            mtx.AddCores(modes)
            mtx.DropCores(cores_to_drop)
            mtx.UpdateFromTable({
                Table: final,
                Filter: "TOD = '" + period + "'",
                RowIDField: "TripOrigTAZ",
                ColumnIDField: "TripDestTAZ",
                CoreNameField: "Mode",
                ValueField: "one"
            })
            RenameMatrix(mtx.GetMatrixHandle(), purp + " " + period)
        end

        // Clean up
        tbl = null
        pivot = null
        export = null
        final = null
    end
    
    ret_value = 1
endmacro


/*
    Macro replicates IX/XI handling from previous Tour_TripAccumulator and Tour_TripAccumulatorFB macro
    Main code directly copied from those macros. Needs a future re-write.
    Macro uses the dcXIW, dcXIN and dcEXT files to create the IE and EI matrices by time period (AM, PM, MD and NT)
*/
Macro "Create IE EI OD"(Args)
    //************************************************************************************************************************************************************************

	datentime = GetDateandTime()
	AppendToLogFile(1, "Tour Trip Accumulator: " + datentime)
	RunMacro("G30 File Close All")
    
    Dir = Args.[Run Directory]
	DirArray  = Dir + "\\TG"
 	DirOutDC  = Dir + "\\TD"
 	DirOutTripTab  = Dir + "\\TripTables"

    autofree = OpenMatrix(Dir + "\\Skims\\TThwy_free.mtx", "False")			//open as memory-based
	autofreecur = CreateMatrixCurrency(autofree, "TotalTT", "Rows", "Columns", )
    CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\IE_AM.mtx"},{"Label", "IE_AM_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2", "Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\IE_PM.mtx"},{"Label", "IE_PM_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2", "Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\IE_MD.mtx"},{"Label", "IE_MD_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2", "Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\IE_NT.mtx"},{"Label", "IE_NT_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2", "Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\EI_AM.mtx"},{"Label", "EI_AM_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2", "Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\EI_PM.mtx"},{"Label", "EI_PM_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2", "Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\EI_MD.mtx"},{"Label", "EI_MD_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2", "Pool3"}},{"Operation", "Union"}})
	CopyMatrixStructure({autofreecur}, {{"File Name", DirOutTripTab + "\\EI_NT.mtx"},{"Label", "EI_NT_vehicle"},{"Type", "Short"},{"File Based", "No"},{"Tables", {"SOV", "Pool2", "Pool3"}},{"Operation", "Union"}})

    //Trip Accumulator: IX
    //This step converts I/X person tours to vehicle trips by occupancy. 
    //All trips go into the AM/PM/MD/NT IE matrices in the /td folder.  None of these trips go into mode choice.
    CreateProgressBar("Starting Trip Accumulator", "TRUE")
    UpdateProgressBar("Trip Accumulator (IX tours)", 10)

	ix_table = OpenTable("ix_table", "FFB", {DirOutDC + "\\dcEXT.bin",})
 	strct = GetTableStructure("ix_table")		//Fields to store output table number (see below) 			
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"PA_TOD", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"AP_TOD", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"SOV", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"Pool2", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"Pool3", "Integer", 1,,,,,,,,,}}
	ModifyTable("ix_table", strct)

	paper = GetDataVector(ix_table+"|", "PAPER", {{"Sort Order", {{"ID","Ascending"}}}}) 
	apper = GetDataVector(ix_table+"|", "APPER", {{"Sort Order", {{"ID","Ascending"}}}}) 
	PAstops = GetDataVector(ix_table+"|", "IS_PA", {{"Sort Order", {{"ID","Ascending"}}}}) 
	APstops = GetDataVector(ix_table+"|", "IS_AP", {{"Sort Order", {{"ID","Ascending"}}}}) 
	purp_v = GetDataVector(ix_table+"|", "PURP", {{"Sort Order", {{"ID","Ascending"}}}}) 

	//  Look up table with the cumulative probability of person tours by vehicle occupancy, from Metrolina 2012 survey: AVO=1.36 (or 0.7346 veh trip/psn trip)
	//  % psn by occ: 53.8%, 27.9%, 18.3% (1, 2, 3+);  	3+ veh/psn ratio: 0.3125
	//  First, determine the vehicle occupancy of the person tour.  Generate a random number and compare it to the probability distribution in table 'vehOcc'.
    SetRandomSeed(2050)
	rand_num_v = Vector(paper.length, "float", {{"Constant", 1}})
	occ = Vector(paper.length, "short", {{"Constant", 1}})
	for n = 1 to paper.length do
		rand_num_v[n] = RandomNumber()
	end
	occ = if (rand_num_v > 0.538) then 2 else occ			//Occupancy rate--this could change!!
	occ = if (rand_num_v > 0.817) then 3 else occ

	/*Next, convert person tours to vehicle tours.  This is done by randomly selecting a subset of records for output on the vehicle file.  If OCC=1, always output
	  a vehicle record.  If OCC=2, there's a 50% chance of outputting a vehicle record.  If OCC=3, there's a 31.25% chance of outputting a vehicle record.
	  Generate another random number for this purpose.
	*/
	DA_v = Vector(paper.length, "Short", {{"Constant", 0}})
	Pool2_v = Vector(paper.length, "Short", {{"Constant", 0}})
	Pool3_v = Vector(paper.length, "Short", {{"Constant", 0}})
	for n = 1 to PAstops.length do
		if (occ[n] = 1) then do
			DA_v[n] = 1
		end
		else if (occ[n] = 2) then do
			rand_val = RandomNumber()
			Pool2_v[n] = if (0.5 > rand_val) then 1 else 0
		end
		else do
			rand_val = RandomNumber()
			Pool3_v[n] = if (0.3125 > rand_val) then 1 else 0
		end
	end

	SetDataVector(ix_table+"|", "SOV", DA_v, {{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(ix_table+"|", "Pool2", Pool2_v, {{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(ix_table+"|", "Pool3", Pool3_v, {{"Sort Order", {{"ID","Ascending"}}}})

    /* Convert the Peak/Offpeak tours to the four TOD categories. The matrices will be vehicle trips and will feed directly into the TOD2 OD matrices.
        Since Work and Non-Work tours have very different TOD fractions, do each seperately.

    IE TOD fractions (each Peak/Offpeak PA-AP group adds to 1)
        Work	Non-Work
    AM-AM	0.115	0.073		|
    AM-PM	0.851	0.599		|PA = 2, AP = 2
    PM-AM	0.004	0.036		|
    PM-PM	0.030	0.292		|
    AM-MD	0.374	0.446	|
    AM-NT	0.592	0.226	|PA = 2, AP = 1
    PM-MD	0.013	0.218	|
    PM-NT	0.021	0.110	|
    MD-AM	0.054	0.082		|
    MD-PM	0.402	0.676		|PA = 1, AP = 2
    NT-AM	0.065	0.026		|
    NT-PM	0.479	0.216		|
    MD-MD	0.177	0.503	|
    MD-NT	0.279	0.255	|PA = 1, AP = 1
    NT-MD	0.211	0.161	|
    NT-NT	0.333	0.081 */

	ixw_tod_ar = { { {0.177, 0.456, 0.667, 1.0}, {0.054, 0.456, 0.521, 1.0} }, { {0.374, 0.966, 0.979, 1.0}, {0.115, 0.966, 0.970, 1.0} } }
	ixn_tod_ar = { { {0.503, 0.758, 0.919, 1.0}, {0.082, 0.758, 0.784, 1.0} }, { {0.446, 0.672, 0.890, 1.0}, {0.073, 0.672, 0.708, 1.0} } }
	ix_todpa_ar = { { {3, 3, 4, 4}, {3, 3, 4, 4} }, { {1, 1, 2, 2}, {1, 1, 2, 2} } }	//AM=1, PM=2, MD=3,NT=4
	ix_todap_ar = { { {3, 4, 3, 4}, {1, 2, 1, 2} }, { {3, 4, 3, 4}, {1, 2, 1, 2} } }	

	pa_tod_v = Vector(paper.length, "Short",)
	ap_tod_v = Vector(paper.length, "Short",)

	for n = 1 to paper.length do
		for i = 1 to 2 do
			for j = 1 to 2 do
				if (paper[n] = i and apper[n] = j) then do
					for k = 1 to 4 do
						rand_val = RandomNumber()
						if (purp_v[n] = "HBW") then do
							if (ixw_tod_ar[i][j][k] > rand_val) then do
								pa_tod_v[n] = ix_todpa_ar[i][j][k]
								ap_tod_v[n] = ix_todap_ar[i][j][k]
								goto skiptonextrecord	
							end
						end
						else do
							if (ixn_tod_ar[i][j][k] > rand_val) then do
								pa_tod_v[n] = ix_todpa_ar[i][j][k]
								ap_tod_v[n] = ix_todap_ar[i][j][k]
								goto skiptonextrecord	
							end
						end
					end
				end
			end
		end
		skiptonextrecord:
	end

	SetDataVector(ix_table+"|", "PA_TOD", pa_tod_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(ix_table+"|", "AP_TOD", ap_tod_v,{{"Sort Order", {{"ID","Ascending"}}}})

	m_ix_am = OpenMatrix(DirOutTripTab + "\\IE_AM.mtx", "False")			//open as memory-based
	m_ix_pm = OpenMatrix(DirOutTripTab + "\\IE_PM.mtx", "False")			//open as memory-based
	m_ix_md = OpenMatrix(DirOutTripTab + "\\IE_MD.mtx", "False")			//open as memory-based
	m_ix_nt = OpenMatrix(DirOutTripTab + "\\IE_NT.mtx", "False")			//open as memory-based

	vehocc_ar = {"SOV", "Pool2", "Pool3"}
	ixTODmat = {m_ix_am, m_ix_pm, m_ix_md, m_ix_nt}
	slpa_fields = {"SL_PA1", "SL_PA2", "SL_PA3", "SL_PA4", "SL_PA5", "SL_PA6", "SL_PA7"} 
	slap_fields = {"SL_AP1", "SL_AP2", "SL_AP3", "SL_AP4", "SL_AP5", "SL_AP6", "SL_AP7"} 

    //Loop through the number of intermediate stops to fill in the IX TOD matrices.  The matrices will be vehicle trips and will feed directly into the TOD2 OD matrices.
	maxPAstops = r2i(VectorStatistic(PAstops, "Max",))
	maxAPstops = r2i(VectorStatistic(APstops, "Max",))

	//Start in PA direction
	for i = 1 to (maxPAstops + 1) do	
		//loop by the 4 time periods
		for tp = 1 to 4 do
			qry = "Select * where PA_TOD = " + i2s(tp) + " and IS_PA = " + i2s(i - 1)
			SetView(ix_table)
			vehcocc_tod = SelectByQuery("vehcocc_tod", "Several", qry, {{"Index Limit", 0}})

			if i = 1 then do	//zero intermediate IX tours
				UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", "ORIG_TAZ", "DEST_TAZ", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
			end
			if i > 1 then do	
				UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", "ORIG_TAZ", "SL_PA1", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
				for j = 2 to i do
					if j = i then do
						UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", slpa_fields[j-1], "DEST_TAZ", null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
					else do
						UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", slpa_fields[j-1], slpa_fields[j], null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
		end
	end

	//Next do AP direction
	for i = 1 to (maxAPstops + 1) do	
		//loop by the 4 time periods
		for tp = 1 to 4 do
			qry = "Select * where AP_TOD = " + i2s(tp) + " and IS_AP = " + i2s(i - 1)
			SetView(ix_table)
			vehcocc_tod = SelectByQuery("vehcocc_tod", "Several", qry, {{"Index Limit", 0}})
			if i = 1 then do	//zero intermediate stop tours
				UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", "DEST_TAZ", "ORIG_TAZ", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
			end
			if i > 1 then do	
				UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", "DEST_TAZ", "SL_AP1", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
				for j = 2 to i do
					if j = i then do
						UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", slap_fields[j-1], "ORIG_TAZ", null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
					else do
						UpdateMatrixFromView(ixTODmat[tp], ix_table+"|vehcocc_tod", slap_fields[j-1], slap_fields[j], null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
		end
	end

    //****************************************************************
    //Trip Accumulator: XIW
    //This step converts X/I Work vehicle tours to vehicle trips by occupancy. 
    //All trips go into the AM/PM/MD/NT XIW matrices in the /td folder.  None of these trips go into mode choice.

    UpdateProgressBar("Trip Accumulator (XI-WORK tours)", 10) 

	xiw_table = OpenTable("xiw_table", "FFB", {DirOutDC + "\\dcXIW.bin",})
 	strct = GetTableStructure("xiw_table")		//Fields to store output table number (see below) 			
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"PA_TOD", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"AP_TOD", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"SOV", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"Pool2", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"Pool3", "Integer", 1,,,,,,,,,}}
	ModifyTable("xiw_table", strct)

	paper = GetDataVector(xiw_table+"|", "PAPER", {{"Sort Order", {{"ID","Ascending"}}}}) 
	apper = GetDataVector(xiw_table+"|", "APPER", {{"Sort Order", {{"ID","Ascending"}}}}) 
	PAstops = GetDataVector(xiw_table+"|", "IS_PA", {{"Sort Order", {{"ID","Ascending"}}}}) 
	APstops = GetDataVector(xiw_table+"|", "IS_AP", {{"Sort Order", {{"ID","Ascending"}}}}) 

	//  Look up table with the cumulative probability of person tours by vehicle occupancy, from 2014 external survey: AVO=1.179 (or 0.8480 veh trip/psn trip)
	//  % psn by occ: 85.12%, 12.48%, 2.37% (1, 2, 3+);  
	//  First, determine the vehicle occupancy of the person tour.  Generate a random number and compare it to the probability distribution in table 'vehOcc'.
    
    SetRandomSeed(78965)
	rand_num_v = Vector(paper.length, "float", {{"Constant", 1}})
	occ = Vector(paper.length, "short", {{"Constant", 1}})
	for n = 1 to paper.length do
		rand_num_v[n] = RandomNumber()
	end
	occ = if (rand_num_v > 0.8512) then 2 else occ			//Occupancy rate--this could change!!
	occ = if (rand_num_v > 0.9760) then 3 else occ

	/*Next, convert person tours to vehicle tours.  This is done by randomly selecting a subset of records for output on the vehicle file.  If OCC=1, always output
	  a vehicle record.  If OCC=2, there's a 50% chance of outputting a vehicle record.  If OCC=3, there's a 31.25% chance of outputting a vehicle record.
	  Generate another random number for this purpose.
	*/
	DA_v = Vector(paper.length, "Short", {{"Constant", 0}})
	Pool2_v = Vector(paper.length, "Short", {{"Constant", 0}})
	Pool3_v = Vector(paper.length, "Short", {{"Constant", 0}})
	for n = 1 to PAstops.length do
		if (occ[n] = 1) then do
			DA_v[n] = 1
		end
		else if (occ[n] = 2) then do
			Pool2_v[n] = 1
		end
		else do
			Pool3_v[n] = 1
		end
	end

	SetDataVector(xiw_table+"|", "SOV", DA_v, {{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(xiw_table+"|", "Pool2", Pool2_v, {{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(xiw_table+"|", "Pool3", Pool3_v, {{"Sort Order", {{"ID","Ascending"}}}})

    /* Convert the Peak/Offpeak tours to the four TOD categories. The matrices will be vehicle trips and will feed directly into the TOD2 OD matrices.

    IE TOD fractions (each Peak/Offpeak PA-AP group adds to 1)
        Work
    AM-AM	0.101		|
    AM-PM	0.749		|PA = 2, AP = 2
    PM-AM	0.018		|
    PM-PM	0.132		|
    AM-MD	0.330	|
    AM-NT	0.520	|PA = 2, AP = 1
    PM-MD	0.058	|
    PM-NT	0.092	|
    MD-AM	0.067		|
    MD-PM	0.496		|PA = 1, AP = 2
    NT-AM	0.052		|
    NT-PM	0.385		|
    MD-MD	0.218	|
    MD-NT	0.345	|PA = 1, AP = 1
    NT-MD	0.169	|
    NT-NT	0.267	|*/

	xiw_tod_ar = { { {0.218, 0.563, 0.732, 1.0}, {0.067, 0.563, 0.615, 1.0} }, { {0.330, 0.850, 0.908, 1.0}, {0.101, 0.850, 0.868, 1.0} } }
	xi_todpa_ar = { { {3, 3, 4, 4}, {3, 3, 4, 4} }, { {1, 1, 2, 2}, {1, 1, 2, 2} } }	//AM=1, PM=2, MD=3,NT=4
	xi_todap_ar = { { {3, 4, 3, 4}, {1, 2, 1, 2} }, { {3, 4, 3, 4}, {1, 2, 1, 2} } }	

	pa_tod_v = Vector(paper.length, "Short",)
	ap_tod_v = Vector(paper.length, "Short",)

	for n = 1 to paper.length do
		for i = 1 to 2 do
			for j = 1 to 2 do
				if (paper[n] = i and apper[n] = j) then do
					for k = 1 to 4 do
						rand_val = RandomNumber()
						if (xiw_tod_ar[i][j][k] > rand_val) then do
							pa_tod_v[n] = xi_todpa_ar[i][j][k]
							ap_tod_v[n] = xi_todap_ar[i][j][k]
							goto skiptonextxirecord	
						end
					end
				end
			end
		end
		skiptonextxirecord:
	end

	SetDataVector(xiw_table+"|", "PA_TOD", pa_tod_v, {{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(xiw_table+"|", "AP_TOD", ap_tod_v, {{"Sort Order", {{"ID","Ascending"}}}})

	m_xi_am = OpenMatrix(DirOutTripTab + "\\EI_AM.mtx", "False")			//open as memory-based
	m_xi_pm = OpenMatrix(DirOutTripTab + "\\EI_PM.mtx", "False")			//open as memory-based
	m_xi_md = OpenMatrix(DirOutTripTab + "\\EI_MD.mtx", "False")			//open as memory-based
	m_xi_nt = OpenMatrix(DirOutTripTab + "\\EI_NT.mtx", "False")			//open as memory-based

	vehocc_ar = {"SOV", "Pool2", "Pool3"}
	xiTODmat = {m_xi_am, m_xi_pm, m_xi_md, m_xi_nt}
	slpa_fields = {"SL_PA1", "SL_PA2", "SL_PA3", "SL_PA4", "SL_PA5", "SL_PA6", "SL_PA7"} 
	slap_fields = {"SL_AP1", "SL_AP2", "SL_AP3", "SL_AP4", "SL_AP5", "SL_AP6", "SL_AP7"} 

    //Loop through the number of intermediate stops to fill in the XI TOD matrices.  The matrices will be vehicle trips and will feed directly into the TOD2 OD matrices.
	maxPAstops = r2i(VectorStatistic(PAstops, "Max",))
	maxAPstops = r2i(VectorStatistic(APstops, "Max",))

	//Start in PA direction
	for i = 1 to (maxPAstops + 1) do	
		//loop by the 4 time periods
		for tp = 1 to 4 do
			qry = "Select * where PA_TOD = " + i2s(tp) + " and IS_PA = " + i2s(i - 1)
			SetView(xiw_table)
			vehcocc_tod = SelectByQuery("vehcocc_tod", "Several", qry, {{"Index Limit", 0}})

			if i = 1 then do	//zero intermediate XIW tours
				UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", "ORIG_TAZ", "DEST_TAZ", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
			end
			if i > 1 then do	
				UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", "ORIG_TAZ", "SL_PA1", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
				for j = 2 to i do
					if j = i then do
						UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", slpa_fields[j-1], "DEST_TAZ", null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
					else do
						UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", slpa_fields[j-1], slpa_fields[j], null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
		end
	end

	//Next do AP direction
	for i = 1 to (maxAPstops + 1) do	
		//loop by the 4 time periods
		for tp = 1 to 4 do
			qry = "Select * where AP_TOD = " + i2s(tp) + " and IS_AP = " + i2s(i - 1)
			SetView(xiw_table)
			vehcocc_tod = SelectByQuery("vehcocc_tod", "Several", qry, {{"Index Limit", 0}})
			if i = 1 then do	//zero intermediate stop tours
				UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", "DEST_TAZ", "ORIG_TAZ", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
			end
			if i > 1 then do	
				UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", "DEST_TAZ", "SL_AP1", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
				for j = 2 to i do
					if j = i then do
						UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", slap_fields[j-1], "ORIG_TAZ", null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
					else do
						UpdateMatrixFromView(xiTODmat[tp], xiw_table+"|vehcocc_tod", slap_fields[j-1], slap_fields[j], null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
		end
	end

    //****************************************************************
    //Trip Accumulator: XIN
    //original version per Bill Allen:
    /*This step converts X/I non-work vehicle tours to vehicle and person trips by occupancy.  The external legs of each tour are considered vehicle
    trips that bypass mode choice and go into the AM/PM/MD/NT XI matrices in the /td folder.  The internal legs are multiplied by the vehicle 
    occupancy and output as NHB person trips, so that they can go through mode choice.
    */
    //changed 3/30/16 after conversation with Joe McLelland, in which it was decided that losing a small number of NHB trips eligible for transit was more acceptable than having
    //the inner portion of the tour not circling back to pick up the automobile if the inner tour was taken by transit.

    UpdateProgressBar("Trip Accumulator (XI-Non-Work tours)", 10) 

	xin_table = OpenTable("xin_table", "FFB", {DirOutDC + "\\dcXIN.bin",})
 	strct = GetTableStructure("xin_table")		//Fields to store output table number (see below) 			
	for j = 1 to strct.length do
 		strct[j] = strct[j] + {strct[j][1]}
 	end
	strct = strct + {{"PA_TOD", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"AP_TOD", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"SOV", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"Pool2", "Integer", 1,,,,,,,,,}}
	strct = strct + {{"Pool3", "Integer", 1,,,,,,,,,}}
	ModifyTable("xin_table", strct)

	paper = GetDataVector(xin_table+"|", "PAPER", {{"Sort Order", {{"ID","Ascending"}}}}) 
	apper = GetDataVector(xin_table+"|", "APPER", {{"Sort Order", {{"ID","Ascending"}}}}) 
	PAstops = GetDataVector(xin_table+"|", "IS_PA", {{"Sort Order", {{"ID","Ascending"}}}}) 
	APstops = GetDataVector(xin_table+"|", "IS_AP", {{"Sort Order", {{"ID","Ascending"}}}}) 

	//Look up table with the cumulative probability of person tours by vehicle occupancy, from 2014 external survey: AVO=1.519 (or 0.6581 veh trip/psn trip)
	//	    % psn by occ: 60.18%, 31.09%, 8.73% (1, 2, 3+);  
	//First, determine the vehicle occupancy of the person tour.  Generate a random number and compare it to the probability distribution in table 'vehOcc'.
    SetRandomSeed(49561)
	rand_num_v = Vector(paper.length, "float", {{"Constant", 1}})
	occ = Vector(paper.length, "short", {{"Constant", 1}})
	for n = 1 to paper.length do
		rand_num_v[n] = RandomNumber()
	end
	occ = if (rand_num_v > 0.6018) then 2 else occ			//Occupancy rate--this could change!!
	occ = if (rand_num_v > 0.9127) then 3 else occ

	/*Next, convert person tours to vehicle tours.  This is done by randomly selecting a subset of records for output on the vehicle file.  If OCC=1, always output
	  a vehicle record.  If OCC=2, there's a 50% chance of outputting a vehicle record.  If OCC=3, there's a 31.25% chance of outputting a vehicle record.
	  Generate another random number for this purpose.
	*/
	DA_v = Vector(paper.length, "Short", {{"Constant", 0}})
	Pool2_v = Vector(paper.length, "Short", {{"Constant", 0}})
	Pool3_v = Vector(paper.length, "Short", {{"Constant", 0}})
	for n = 1 to PAstops.length do
		if (occ[n] = 1) then do
			DA_v[n] = 1
		end
		else if (occ[n] = 2) then do
			Pool2_v[n] = 1
		end
		else do
			Pool3_v[n] = 1
		end
	end

	SetDataVector(xin_table+"|", "SOV", DA_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(xin_table+"|", "Pool2", Pool2_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(xin_table+"|", "Pool3", Pool3_v,{{"Sort Order", {{"ID","Ascending"}}}})

    /* The first and last legs (the external trips), will skip mode choice and go directly into the TOD2 OD matrices. So, we nned to convert the Peak/Offpeak tours 
    to the four TOD categories. The other trips will not use these TOD categories, and instead be added to the NHB Peak/Offpeak matrices and go through MC.

    IE TOD fractions (each Peak/Offpeak PA-AP group adds to 1)

        Non-Work	
    AM-AM	0.057		|
    AM-PM	0.473		|PA = 2, AP = 2
    PM-AM	0.050		|
    PM-PM	0.420		|
    AM-MD	0.352	|
    AM-NT	0.178	|PA = 2, AP = 1
    PM-MD	0.312	|
    PM-NT	0.158	|
    MD-AM	0.079		|
    MD-PM	0.659		|PA = 1, AP = 2
    NT-AM	0.028		|
    NT-PM	0.233		|
    MD-MD	0.490	|
    MD-NT	0.249	|PA = 1, AP = 1
    NT-MD	0.173	|
    NT-NT	0.088	|*/


	xin_tod_ar = { { {0.490, 0.739, 0.912, 1.0}, {0.079, 0.738, 0.766, 1.0} }, { {0.352, 0.530, 0.842, 1.0}, {0.057, 0.530, 0.580, 1.0} } }
	xi_todpa_ar = { { {3, 3, 4, 4}, {3, 3, 4, 4} }, { {1, 1, 2, 2}, {1, 1, 2, 2} } }	// AM=1, PM=2, MD=3, NT=4
	xi_todap_ar = { { {3, 4, 3, 4}, {1, 2, 1, 2} }, { {3, 4, 3, 4}, {1, 2, 1, 2} } }	

	pa_tod_v = Vector(paper.length, "Short",)
	ap_tod_v = Vector(paper.length, "Short",)

	for n = 1 to paper.length do
		for i = 1 to 2 do
			for j = 1 to 2 do
				if (paper[n] = i and apper[n] = j) then do
					for k = 1 to 4 do
						rand_val = RandomNumber()
						if (xin_tod_ar[i][j][k] > rand_val) then do
							pa_tod_v[n] = xi_todpa_ar[i][j][k]
							ap_tod_v[n] = xi_todap_ar[i][j][k]
							goto skiptonextxinrecord	
						end
					end
				end
			end
		end
		skiptonextxinrecord:
	end

	SetDataVector(xin_table+"|", "PA_TOD", pa_tod_v,{{"Sort Order", {{"ID","Ascending"}}}})
	SetDataVector(xin_table+"|", "AP_TOD", ap_tod_v,{{"Sort Order", {{"ID","Ascending"}}}})

	m_xi_am = OpenMatrix(DirOutTripTab + "\\EI_AM.mtx", "False")		//open as memory-based
	m_xi_pm = OpenMatrix(DirOutTripTab + "\\EI_PM.mtx", "False")		//open as memory-based
	m_xi_md = OpenMatrix(DirOutTripTab + "\\EI_MD.mtx", "False")		//open as memory-based
	m_xi_nt = OpenMatrix(DirOutTripTab + "\\EI_NT.mtx", "False")		//open as memory-based

	vehocc_ar = {"SOV", "Pool2", "Pool3"}
	xiTODmat = {m_xi_am, m_xi_pm, m_xi_md, m_xi_nt}
	slpa_fields = {"SL_PA1", "SL_PA2", "SL_PA3", "SL_PA4", "SL_PA5", "SL_PA6", "SL_PA7"} 
	slap_fields = {"SL_AP1", "SL_AP2", "SL_AP3", "SL_AP4", "SL_AP5", "SL_AP6", "SL_AP7"} 

    //Loop through the number of intermediate stops to fill in the XI TOD matrices.  The matrices will be vehicle trips and will feed directly into the TOD2 OD matrices.
	maxPAstops = r2i(VectorStatistic(PAstops, "Max",))
	maxAPstops = r2i(VectorStatistic(APstops, "Max",))

	//Start in PA direction
	for i = 1 to (maxPAstops + 1) do	
		//loop by the 4 time periods
		for tp = 1 to 4 do
			qry = "Select * where PA_TOD = " + i2s(tp) + " and IS_PA = " + i2s(i - 1)
			SetView(xin_table)
			vehcocc_tod = SelectByQuery("vehcocc_tod", "Several", qry, {{"Index Limit", 0}})

			if i = 1 then do	//zero intermediate XIN tours
				UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", "ORIG_TAZ", "DEST_TAZ", null, vehocc_ar, "Add", 
				{{"Missing is zero", "Yes"}})
			end
			if i > 1 then do	
				UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", "ORIG_TAZ", "SL_PA1", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
				for j = 2 to i do
					if j = i then do
						UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", slpa_fields[j-1], "DEST_TAZ", null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
					else do
						UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", slpa_fields[j-1], slpa_fields[j], null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
		end
	end

	//Next do AP direction
	for i = 1 to (maxAPstops + 1) do	
		//loop by the 4 time periods
		for tp = 1 to 4 do
			qry = "Select * where AP_TOD = " + i2s(tp) + " and IS_AP = " + i2s(i - 1)
			SetView(xin_table)
			vehcocc_tod = SelectByQuery("vehcocc_tod", "Several", qry, {{"Index Limit", 0}})
	
			if i = 1 then do	//zero intermediate XIN tours
				UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", "DEST_TAZ", "ORIG_TAZ", null, vehocc_ar, "Add", 
				{{"Missing is zero", "Yes"}})
			end
			if i > 1 then do	
				UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", "DEST_TAZ", "SL_PA1", null, vehocc_ar, "Add", 
					{{"Missing is zero", "Yes"}})
				for j = 2 to i do
					if j = i then do
						UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", slap_fields[j-1], "ORIG_TAZ", null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
					else do
						UpdateMatrixFromView(xiTODmat[tp], xin_table+"|vehcocc_tod", slap_fields[j-1], slap_fields[j], null, vehocc_ar, "Add", 
							{{"Missing is zero", "Yes"}})	
					end
				end
			end
		end
	end
        
    ret_value = 1
endMacro


/*
    Create OD Highway matrix for a particualr time period
    Use AM/MD/PM/NT matrices for the HBW, HBU, HBShop, HBO, ATW, IE/EI purposes
    Use the commercial and truck matrix
    Logic similar to previous macro 'Tour_Tod2<period>'
*/
Macro "Create Highway OD" (Args, period)
    
    datentime = GetDateandTime()
    AppendToLogFile(1, "Enter Create Highway OD " + datentime)
    out_dir = Args.[Run Directory] + "\\TripTables"
    newCodes = {AM: 'AMPeak', PM: 'PMPeak', MD: 'Midday', NT: 'Night'}
    assnPeriod = newCodes.(period)

    od_matrix = Args.[Run Directory] + "\\tod2\\ODHwyVeh_" + assnPeriod + ".mtx"
    skim_mtx = Args.[Run Directory] + "\\Skims\\offpk_hwyskim.mtx"
    CopyFile(skim_mtx, od_matrix)
    mtx = CreateObject("Matrix", od_matrix)
    cores_to_drop = mtx.GetCoreNames()
    mtx.AddCores({"SOV", "Pool2", "Pool3", "COM", "MTK", "HTK"})
    mtx.DropCores(cores_to_drop)
    RenameMatrix(mtx.GetMatrixHandle(), "ODveh_" + assnPeriod)
    occs = Args.Occupancies
    
    purps = {"HBW", "HBS", "HBO", "SCH", "HBU", "ATW", "IE", "EI"}
    for purp in purps do
        if purp = "IE" or purp = "EI" then do // already vehicle trips
            occ2 = 1
            occ3P = 1
        end
        else do
            occ2 = 2
            occ3P = occs.(purp).Value
        end
        mtx_file = out_dir + "\\" + purp + "_" + period + ".mtx"
        mtxP = CreateObject("Matrix", mtx_file)
        mtx.SOV := nz(mtx.SOV) + nz(mtxP.sov)
        mtx.POOL2 := nz(mtx.POOL2) + nz(mtxP.pool2)/occ2
        mtx.POOL3 := nz(mtx.POOL3) + nz(mtxP.pool3)/occ3P
        cores = mtxP.GetCoreNames()
        if cores.Position("tnc") > 0 then
            mtx.POOL2 := nz(mtx.POOL2) + nz(mtxP.tnc)
    end
    
	ret_value = RunMacro("Add Commerical and Truck OD", Args, assnPeriod)

endmacro


/* 
	Update: August 2024
	Common macro that is now called from the Tour_TOD2_<period> macros
	period argument: One of 'AMPeak', 'PMPeak', 'Midday', 'Night'
	Macro called after creation of OD matrices
	Adds the commercial, truck and ee components to appropriate period specific OD matrix
	Macro will update the 'SOV', 'COM', 'MTK' and 'HTK' cores
*/
Macro "Add Commerical and Truck OD" (Args, period) 
	/* Older comments
	// PA-AP fractions updated 10/2/13; 3+ occupancy rates derived from 2012 HHTS
	// 1/16/18, mk: this version uses the Trip model for commercial vehicles (rewritten in GISDK in the Truck_Trip_for_Tour.rsc macro).  The outputs are identical to the trip model for CVs.
	*/

    datentime = GetDateandTime()
    AppendToLogFile(1, "Tour TOD2_ " + period + ": " + datentime)

    RunMacro("G30 File Close All")
    Dir = Args.[Run Directory]

    // Check for presence of OD matrix
    od = Dir + "\\tod2\\ODHwyVeh_" + period + ".mtx"
    if !GetFileInfo(od) then
        Throw(period + " OD Matrix file not found in macro 'Tour_TOD2'")
    OD = CreateObject("Matrix", od,)

    EEA = CreateObject("Matrix", Dir + "\\tg\\tdeea.mtx")
    TCMH = CreateObject("Matrix", Dir + "\\tod2\\Transpose_COM_MTK_HTK.mtx")
 
    COM = CreateObject("Matrix", Dir + "\\TD\\tdcom.mtx")
    EIC = CreateObject("Matrix", Dir + "\\TD\\tdeic.mtx")
    IEC = CreateObject("Matrix", Dir + "\\TD\\tdiec.mtx")
    EEC = CreateObject("Matrix", Dir + "\\TD\\tdeec.mtx")

    MTK = CreateObject("Matrix", Dir + "\\TD\\tdmtk.mtx")
    EIM = CreateObject("Matrix", Dir + "\\TD\\tdeim.mtx")
    IEM = CreateObject("Matrix", Dir + "\\TD\\tdiem.mtx")
    EEM = CreateObject("Matrix", Dir + "\\TD\\tdeem.mtx")

    HTK = CreateObject("Matrix", Dir + "\\TD\\tdhtk.mtx")
    EIH = CreateObject("Matrix", Dir + "\\TD\\tdeih.mtx")
    IEH = CreateObject("Matrix", Dir + "\\TD\\tdieh.mtx")
    EEH = CreateObject("Matrix", Dir + "\\TD\\tdeeh.mtx")

    factors = Args.[Com and Truck TOD Factors]
    factor1 = factors.(period).IETrips
    factor2 = factors.(period).EETrips
    OD.SOV := nz(OD.SOV) + factor2*nz(EEA.Trips)
    OD.COM := factor1*nz(COM.Trips) + factor1*nz(EIC.Trips) + factor1*nz(IEC.Trips) + factor2*nz(EEC.Trips) + factor1*nz(TCMH.TransposeCOM) 
    OD.MTK := factor1*nz(MTK.Trips) + factor1*nz(EIM.Trips) + factor1*nz(IEM.Trips) + factor2*nz(EEM.Trips) + factor1*nz(TCMH.TransposeMTK)
    OD.HTK := factor1*nz(HTK.Trips) + factor1*nz(EIH.Trips) + factor1*nz(IEH.Trips) + factor2*nz(EEH.Trips) + factor1*nz(TCMH.TransposeHTK)

	ret_value = 1
endmacro
