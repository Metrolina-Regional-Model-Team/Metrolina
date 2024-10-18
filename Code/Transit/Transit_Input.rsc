/*
	Create transit PA matrices for walk access, drive access and PNR from MC results
	Each matrix has cores for Bus/Premium and PK/OP
*/
Macro "Transit_Input" (Args)
	Dir = Args.[Run Directory]
	ok = RunMacro ("Create Transit Assignment Matrices", Dir, Args.[Run Year], Args.[MET Directory])
	if ok[1] = 0 then
		Throw("Prepare Transit Files - error return from Create Transit Assignment Matrices")

	modes = {"Walk", "Drive", "DropOff"}
	mcODTags = {"W", "D", "DropOff"} 	// Abbreviations used in the output OD cores
	mcPATags = {"w", "pnr", "knr"}		// Abbreviations used in mode choice matrix cores
	periods = {"P": {'AM', 'PM'}, "OP": {'MD', 'NT'}}
	purps = {"HBW", "HBS", "HBO", "HBU", "SCH"}
	
	for m = 1 to modes.length do
		tr_mat = printf("%s\\TranAssn\\Transit Assign %s.mtx", {Dir, modes[m]})
		mOD = CreateObject("Matrix", tr_mat)
		for periodOpt in periods do
			periodAbbr = periodOpt[1]
			for subPeriod in periodOpt[2] do
				for purp in purps do
					// Open appropriate sub period and purpose matrix
					// Add data to appropriate transit core
					purp_file = printf("%s\\TripTables\\%s_%s.mtx", {Dir, purp, subPeriod})
					mP = CreateObject("Matrix", purp_file)
					cores = mP.GetCoreNames()

					// bus submode
					paCore = mcPATags[m] + "_bus"
					odCore = periodAbbr + "bus" + mcODTags[m]
					if cores.position(paCore) > 0 then
						mOD.(odCore) := nz(mOD.(odCore)) + nz(mP.(paCore))

					// premium submode
					paCore = mcPATags[m] + "_prem"
					odCore = periodAbbr + "prm" + mcODTags[m]
					if cores.position(paCore) > 0 then
						mOD.(odCore) := nz(mOD.(odCore)) + nz(mP.(paCore))
				end // of purps
			end	// of subperiods
		end	// of main periods
	end // of transit access modes
endmacro
