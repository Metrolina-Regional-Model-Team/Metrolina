Macro "Tour_TOD2_AMPeak" (Args)
    ret = RunMacro("Tour_TOD2", Args, "AMPeak")
    if ret[2] <> null then
        ShowMessage(ret[2])
    return(ret[1])
endmacro

Macro "Tour_TOD2_PMPeak" (Args)
    ret = RunMacro("Tour_TOD2", Args, "PMPeak")
    if ret[2] <> null then
        ShowMessage(ret[2])
    return(ret[1])
endmacro

Macro "Tour_TOD2_Midday" (Args)
    ret = RunMacro("Tour_TOD2", Args, "Midday")
    if ret[2] <> null then
        ShowMessage(ret[2])
    return(ret[1])
endmacro

Macro "Tour_TOD2_Night" (Args)
    ret = RunMacro("Tour_TOD2", Args, "Night")
    if ret[2] <> null then
        ShowMessage(ret[2])
    return(ret[1])
endmacro

/* 
	Update: August 2024
	Common macro that is now called from the Tour_TOD2_<period> macros
	period argument: One of 'AMPeak', 'PMPeak', 'Midday', 'Night'
	Macro called after creation of OD matrices
	Adds the commercial, truck and ee components to appropriate period specific OD matrix
	Macro will update the 'SOV', 'COM', 'MTK' and 'HTK' cores
*/
Macro "Tour_TOD2" (Args, period) 
	/* Older comments
	// PA-AP fractions updated 10/2/13; 3+ occupancy rates derived from 2012 HHTS
	// 1/16/18, mk: this version uses the Trip model for commercial vehicles (rewritten in GISDK in the Truck_Trip_for_Tour.rsc macro).  The outputs are identical to the trip model for CVs.
	*/
    on error goto badquit
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
    OD.SOV := OD.SOV + factor2*EEA.Trips
    OD.COM := factor1*COM.Trips + factor1*EIC.Trips + factor1*IEC.Trips + factor2*EEC.Trips + factor1*TCMH.TransposeCOM 
    OD.MTK := factor1*MTK.Trips + factor1*EIM.Trips + factor1*IEM.Trips + factor2*EEM.Trips + factor1*TCMH.TransposeMTK
    OD.HTK := factor1*HTK.Trips + factor1*EIH.Trips + factor1*IEH.Trips + factor2*EEH.Trips + factor1*TCMH.TransposeHTK

    on error, notfound default
    datentime = GetDateandTime()
    AppendToLogFile(1, "Exit Tour TOD2_ " + period + ": " + datentime)
    return({1, msg})
	
badquit:
    on error, notfound default
    msg = GetLastError()
    AppendToLogFile(1, msg)
    datentime = GetDateandTime()
    AppendToLogFile(1, "Tour TOD2_ " + period + ": " + datentime)
    return({0, msg})
endmacro
