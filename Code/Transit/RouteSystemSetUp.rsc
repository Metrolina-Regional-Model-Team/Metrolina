Macro "RouteSystemSetUp" (Args)
// 5/30/19, mk: There are now three distinct networks, use offpeak initially for transit set-up

	Dir = Args.[Run Directory]
	METDir = Args.[MET Directory]
	net_file = Args.[Offpeak Hwy Name]
	theyear = Args.[Run Year]

	datentime = GetDateandTime()
	AppendToLogFile(1, "Enter RouteSystemSetUp:  " + datentime)

	routename = "transys"
	route_file = Dir + "\\"+routename+".rts"
	{, , netname, } = SplitPath(net_file)
	map = CreateObject("Map", {FileName: route_file})

	ReloadRouteSystem(route_file)
	VerifyRouteSystem(route_file, "Connected")
	nottagged = TagRouteStopsWithNode("Vehicle Routes", null, "UserID", 0.02)
	if nottagged > 0 
		then do
			Throw("RouteSystemSetUp ERROR!, " + i2s(nottagged) + " stops not tagged to node!")
		end	
	map = null

	datentime = GetDateandTime()
	AppendToLogFile(1, "Build Networks: exit Route System Set Up  " + datentime)
endMacro
