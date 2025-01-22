Macro "Drivesheds" (Args)
  
  RunMacro("TCB Init")
  
  Dir = Args.[Run Directory]
  hwy_dbd= Args.[Hwy Name]
  shed_dir = Dir + "\\report\\shed"
  
  if GetDirectoryInfo(shed_dir, "All") = null then CreateDirectory(shed_dir)
  
  //exclusion_file = Args.[Model Folder] + "\\other\\iso_exclusion\\IsochroneExclusionAreas.cdf"
  
  periods = {"Offpeak", "Peak"}
  dirs = {"inbound"}
    //dirs = {"outbound", "inbound"}
  nodes = {
    10686,
    10841,
    10788,
    10821,
    10755,
    10203,
    10002,
    10359,
    5053,
    9094,
    9113,
    5102  
  }
  names = {
    "Ballantyne",
    "RiverDistrict",
    "Whitehall",
    "CLT Airport",
    "Colesium",
    "SouthPark",
    "Uptown",
    "UNCC",
    "Mooresville Airport",
    "Monroe",
    "Union",
    "Statesville" 
  }
  
  //Create a new, blank map
  
  map = CreateObject("Map", {FileName: hwy_dbd})
  {nlyr, llyr} = map.GetLayerNames()
  //SetLayerVisibility(map + "|" + nlyr, "false")
  SetLayer(llyr)

  for period in periods do
    for i = 1 to nodes.length do
      node_id = nodes[i]
      name = names[i]

      SetLayer(nlyr)
      cord = GetPoint(node_id)
      SetLayer(llyr)

      for dir in dirs do
        //map_file = map_dir + "\\iso_" + name + "_" + dir + "_" + period + ".map"
        net_file = Dir + "\\net_highway_am.net"

        nh = ReadNetwork(net_file)
        o = null
        o = CreateObject("Routing.Bands")
        o.NetworkName = net_file
        o.RoutingLayer = GetLayer()
        //o.Minimize = if period = "Offpeak" then "[TTfreeAB / TTfreeBA]" else "[TTPkAssnAB / TTPkAssnBA]" 
        o.Minimize = if period = "Offpeak" then "TTFree*" else "TTPkAssn*" 
        o.Interval = 5
        o.BandMax  = 15
        o.CumulativeBands = "Yes"
        o.InboundBands = if dir = "inbound"
          then true
          else false
        o.CreateTheme = true
        //o.LoadExclusionAreas(exclusion_file)
        o.CreateBands({
          Coords: {cord},
          FileName: shed_dir + name + "_" + period + ".dbd",
          LayerName : name + " " + period 
        })

        //RedrawMap(map)
        //SaveMap(, map_file)
      end
    end
  end

 DestroyProgressBar()

 return(1)
endmacro