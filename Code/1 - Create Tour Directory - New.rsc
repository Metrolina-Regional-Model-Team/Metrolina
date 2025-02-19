/*
Builds a scenario from master files
*/

Macro "Create Scenario" (Args)

  pbar = CreateObject("G30 Progress Bar", "Scenario Creation", "False", )


  RunMacro("Create Scenario Folder Structure", Args)
  RunMacro("Copy Metrolina Files", Args)
  RunMacro("Copy Scenario Files", Args)


EndMacro


/*
Creates input and output folders needed in the scenario directory
*/

Macro "Create Scenario Folder Structure" (Args)

  // Array of output directories to create
a_dir = {
    "/AutoSkims",
    "/Ext",
    "/HwyAssn",
    "/LandUse",
    "/Report",
    "/Skims",
    "/TD",
    "/TG",
    "/TOD2",
    "/TourModeSplit",
    "/TranAssn",
    "/TripTables",
}
  
  for d = 1 to a_dir.length do
    dir = Args.[Run Directory] + a_dir[d]
    RunMacro("Create Directory", dir)
  end

EndMacro

/*
- copies metrolina files into scenario folder

*/

Macro "Copy Metrolina Files" (Args)

  opts = null
  opts.from = Args.[MRM Directory] // this needs updating to point to master folder
  opts.to = Args.[Run Directory] // Metrolina//scenariofolder
  opts.copy_files = "true"
  RunMacro("Copy Directory", opts)
  
m_dir =  {
    "/MS_Control_Template",
    "/TAZ",
    "/Pgm/ModeChoice",
    "/Pgm/CapspdFactors",
    "/Pgm/FrictionFactors",
    "/ExSta",
    "",   
}

  for d = 1 to m_dir.length do
    dir = Args.[Run Directory] + m_dir[d]
    RunMacro("Create Directory", dir)
  end

EndMacro

/*
- copies scenario data
- standardizes name
*/

Macro "Copy Scenario Files" (Args)

opts = null
  opts.from = Args.[Scenario Folder] // 
  opts.to = Args.[Run Directory] // Metrolina//scenariofolder
  opts.copy_files = "true"
  RunMacro("Copy Directory", opts)
  
s_dir =  {
    "/ext",
    "/LandUse",
    "",   
}

  for d = 1 to s_dir.length do
    dir = Args.[Run Directory] + s_dir[d]
    RunMacro("Create Directory", dir)
  end

EndMacro


Macro "Copy Directory" (MacroOpts)

  from = MacroOpts.from
  to = MacroOpts.to
  copy_files = MacroOpts.copy_files
  subdirectories = MacroOpts.subdirectories
  purge = MacroOpts.purge

  if from = null then Throw("Copy Diretory: 'from' not provided") 
  if to = null then Throw("Copy Diretory: 'from' not provided") 
  if copy_files = null then copy_files = "true"
  if subdirectories = null then subdirectories = "true"
  if purge = null then purge = "true"

  RunMacro("Normalize Path", from)
  RunMacro("Normalize Path", to)

  from = "\"" +  from + "\""
  to = "\"" +  to + "\""
  cmd = "cmd /C C:/Windows/System32/Robocopy.exe " + from + " " + to
  if !copy_files then cmd = cmd + " /t"
  if subdirectories then cmd = cmd + " /e"
  if purge then cmd = cmd + " /purge"
  opts.Minimize = "true"
  RunProgram(cmd, opts)
EndMacro

Macro "Create Directory" (dir)
  if dir = null then Throw("Create Directory: 'dir' not provided") 
  dir = RunMacro("Normalize Path", dir)
  if GetDirectoryInfo(dir, "All") = null then CreateDirectory(dir)
EndMacro

Macro "Normalize Path" (rel_path)

  a_parts = ParseString(rel_path, "/\\")
  for i = 1 to a_parts.length do
    part = a_parts[i]

    if part <> ".." then do
      a_path = a_path + {part}
    end else do
      a_path = ExcludeArrayElements(a_path, a_path.length, 1)
    end
  end

  for i = 1 to a_path.length do
    if i = 1
      then path = a_path[i]
      else path = path + "\\" + a_path[i]
  end

  return(path)
EndMacro

Macro "Catalog Files" (MacroOpts)

  dir = MacroOpts.dir
  ext = MacroOpts.ext
  subfolders = MacroOpts.subfolders

  if TypeOf(ext) = "string" then ext = {ext}

  a_dirInfo = GetDirectoryInfo(dir + "/*", "Directory")

  // If there are folders in the current directory,
  // call the macro again for each one.
  if subfolders and a_dirInfo <> null then do
    for d = 1 to a_dirInfo.length do
      path = dir + "/" + a_dirInfo[d][1]

      a_files = a_files + RunMacro("Catalog Files", {
        dir: path, 
        ext: ext, 
        subfolders: subfolders
      })
    end
  end

  // If the ext parameter is used
  if ext <> null then do
    for e = 1 to ext.length do
      if Left(ext[e], 1) = "." 
        then path = dir + "/*" + ext[e]
        else path = dir + "/*." + ext[e]

      a_info = GetDirectoryInfo(path, "File")
      if a_info <> null then do
        for i = 1 to a_info.length do
          a_files = a_files + {dir + "/" + a_info[i][1]}
        end
      end
    end
  // If the ext parameter is not used
  end else do
    a_info = GetDirectoryInfo(dir + "/*", "File")
    if a_info <> null then do
      for i = 1 to a_info.length do
        a_files = a_files + {dir + "/" + a_info[i][1]}
      end
    end
  end

  return(a_files)
EndMacro