Macro "Other Summaries" (Args)
    RunMacro("Load Link Layer", Args)
    RunMacro("Calculate Daily Fields", Args)
    RunMacro("Create Count Difference Map", Args)
endmacro

/*
Add assignment results to the AM link layer for easy visualization
*/

Macro "Load Link Layer" (Args)
    
    scen_dir = Args.[Run Directory]
    hwy_dbd = Args.[AM Peak Hwy Name]
    assn_dir = scen_dir + "\\HwyAssn\\HOT"
    periods = {"AM", "MD", "PM", "NT"}

    for period in periods do
        
        file_part = if period = "AM" then "AMPEAK" 
            else if period = "MD" then "Midday"
            else if period = "PM" then "PMPEAK"
            else "Night"
        assn_file = assn_dir + "\\Assn_" + file_part + "hot.bin"

        temp = CreateObject("Table", assn_file)
        // vw = OpenTable("temp", "FFB", {assn_file})
        // {field_names, } = GetFields(vw, "All")
        // CloseView(vw)
        field_names = temp.GetFieldNames()
        temp = null
        RunMacro("Join Table To Layer", hwy_dbd, "ID", assn_file, "ID1")
        
        hwy_tbl = CreateObject("Table", {FileName: hwy_dbd, LayerType: "line"})
        for field_name in field_names do
            if field_name = "ID1" then continue
            // Remove the field if it already exists before renaming
            hwy_tbl.DropFields(field_name + "_" + period)
            hwy_tbl.RenameField({FieldName: field_name, NewName: field_name + "_" + period})
        end

        // Calculate delay by time period and direction
        a_dirs = {"AB", "BA"}
        v_fft = if fft_ab = 0 then fft_ba else fft_ab
        for dir in a_dirs do

            // Add delay field
            delay_field = dir + "_Delay_" + period
            hwy_tbl.AddField({FieldName: delay_field, Description: "Hours of Delay|(CongTime - FFTime) * Flow / 60"})

            // Get data vectors
            v_fft = hwy_tbl.("TTfree" + dir)
            v_ct = hwy_tbl.(dir + "_Time_" + period)
            v_vol = hwy_tbl.(dir + "_Flow_" + period)

            // Calculate delay
            v_delay = (v_ct - v_fft) * v_vol / 60
            v_delay = max(v_delay, 0)
            hwy_tbl.(delay_field) = v_delay
        end
        hwy_tbl = null
    end
endmacro

/*
This macro summarize fields across time period and direction.

The loaded network table will have a volume field for each class that looks like
"AB_Flow_auto_AM". It will also have fields aggregated across classes that look
like "BA_Flow_PM" and "AB_VMT_MD". Direction (AB/BA) and time period (e.g. AM)
will be looped over. Create an array of the rest of the field names to
summarize. e.g. {"Flow_auto", "Flow", "VMT"}.
*/

Macro "Calculate Daily Fields" (Args)

  a_periods = {"AM", "MD", "PM", "NT"}
  hwy_dbd = Args.[AM Peak Hwy Name]
  a_dir = {"AB", "BA"}
  modes = {
    "SOV", "Pool2", "Pool3", "COM", "MTK", "HTK",
    "HOTSOV", "HOTPool2", "HOTPool3", "HOTCOM"
  }

  hwy_tbl = CreateObject("Table", {FileName: hwy_dbd, LayerType: "line"})

  // Sum up the flow fields
  for mode in modes do

    for dir in a_dir do
      out_field = dir + "_" + mode + "_Flow_Daily"
      fields_to_add = fields_to_add + {{FieldName: out_field, Description: "Daily " + dir + " " + mode + " Flow"}}
      v_output = null

      // For this direction and mode, sum every period
      for period in a_periods do
        input_field = dir + "_Flow_" + mode + "_" + period
        v_add = hwy_tbl.(input_field)
        v_output = nz(v_output) + nz(v_add)
      end

      output.(out_field) = v_output
      output.(dir + "_Flow_Daily") = nz(output.(dir + "_Flow_Daily")) + v_output
      output.Total_Flow_Daily = nz(output.Total_Flow_Daily) + v_output
    end
  end
  fields_to_add = fields_to_add + {
    {FieldName: "AB_Flow_Daily", Description: "AB Daily Flow"},
    {FieldName: "BA_Flow_Daily", Description: "BA Daily Flow"},
    {FieldName: "Total_Flow_Daily", Description: "Daily Flow in both direction"}
  }

  // Other fields to sum
  a_fields = {"VMT", "VHT", "Delay"}
  for field in a_fields do
    for dir in a_dir do
      v_output = null
      out_field = dir + "_" + field + "_Daily"
      fields_to_add = fields_to_add + {{FieldName: out_field, Description: "Daily " + dir + " " + field}}
      for period in a_periods do
        input_field = dir + "_" + field + "_" + period
        v_add = hwy_tbl.(input_field)
        v_output = nz(v_output) + nz(v_add)
      end
      output.(out_field) = v_output
      output.("Total_" + field + "_Daily") = nz(output.("Total_" + field + "_Daily")) + v_output
    end

	description = "Daily " + field + " in both directions"
	if field = "Delay" then description = description + " (hours)"
    fields_to_add = fields_to_add + {{FieldName: "Total_" + field + "_Daily", Description: description}}
  end

  // The assignment files don't have total delay by period. Create those.
  for period in a_periods do
    out_field = "Tot_Delay_" + period
    fields_to_add = fields_to_add + {{FieldName: out_field, Description: period + " Total Delay"}}
    data = hwy_tbl.GetDataVectors({FieldNames: {"AB_Delay_" + period, "BA_Delay_" + period}})
    v_ab = data.("AB_Delay_" + period)
    v_ba = data.("BA_Delay_" + period)
    v_output = nz(v_ab) + nz(v_ba)
    output.(out_field) = v_output
  end

  hwy_tbl.AddFields({Fields: fields_to_add})
  hwy_tbl.SetDataVectors({FieldData: output})
EndMacro

/*
Used for validation in the base year only
*/

Macro "Create Count Difference Map" (Args)
  
    scen_dir = Args.[Run Directory]
    output_dir = scen_dir + "\\Report\\maps"
    if GetDirectoryInfo(output_dir, "All") = null then CreateDirectory(output_dir)
    hwy_dbd = Args.[AM Peak Hwy Name]

    // Create total count diff map
    opts = null
    opts.output_file = output_dir + "/Count Difference - Total.map"
    opts.hwy_dbd = hwy_dbd
    opts.count_field = "CNTAAWT22"
    opts.vol_field = "Total_Flow_Daily"
    RunMacro("Count Difference Map", opts)
EndMacro

/*
For base model calibration, maps comparing model and count volumes are required.
This macro creates a standard map to show absolute and percent differences in a
color theme. It also performs maximum desirable deviation calculations and
highlights (in green) links that do not exceed the MDD.

Inputs
  macro_opts
    Named array of macro arguments

    output_file
      String
      Complete path of the output map to create.

    hwy_dbd
      String
      Complete path to the highway geographic file.

    count_id_field
      Optional string
      Field name of the count ID. The count ID field is used to determine
      where a single count has been split between multiple links (like on a
      freeway). If not provided, the link IDs are used as count IDs (on
      links with count volume).

    combine_oneway_pairs
      Optional true/false
      Defaults to true
      Whether or not to combine one-way pair counts and volumes before
      calculating stats.

    count_field
      String
      Name of the field containing the count volume. Can be a daily or period
      count field, but time period between count and volume fields should
      match.

    vol_field
      String
      Name of the field containing the model volume. Can be a daily or period
      count field, but time period between count and volume fields should
      match.

    field_suffix
      Optional string
      "" by default. If provided, will be appended to the fields created by this
      macro. For example, if making a count difference map of SUT vs SUT counts,
      you could provide a suffix of "SUT". This would lead to fields created
      like "Count_SUT", "Volume_SUT", "diff_SUT", etc. This is used to prevent
      repeated calls to this macro from overwriting these fields.
*/

Macro "Count Difference Map" (macro_opts)

    output_file = macro_opts.output_file
    hwy_dbd = macro_opts.hwy_dbd
    count_id_field = macro_opts.count_id_field
    combine_oneway_pairs = macro_opts.combine_oneway_pairs
    count_field = macro_opts.count_field
    vol_field = macro_opts.vol_field
    field_suffix = macro_opts.field_suffix

    if combine_oneway_pairs = null then combine_oneway_pairs = "true"

    // set the field suffix
    if field_suffix = null then field_suffix = ""
    if field_suffix <> "" then do
        if field_suffix[1] <> "_" then field_suffix = "_" + field_suffix
    end

    // Determine output directory (removing trailing backslash)
    a_path = SplitPath(output_file)
    output_dir = a_path[1] + a_path[2]
    len = StringLength(output_dir)
    output_dir = Left(output_dir, len - 1)

    // Create output directory if it doesn't exist
    if GetDirectoryInfo(output_dir, "All") = null then CreateDirectory(output_dir)

    hwy_tbl = CreateObject("Table", {FileName: hwy_dbd, LayerType: "line"})

    // Handle missing count ID field
    if count_id_field = null then do
        combine_oneway_pairs = "false"
        count_id_field = "CountID"
        hwy_tbl.AddField({FieldName: count_id_field, Type: "integer", Description: "Same as link ID for count links"})
        hwy_tbl.SelectByQuery({
            SetName: "counts_links",
            Query: count_field + " <> null"
        })
        hwy_tbl.(count_id_field) = hwy_tbl.ID
    end

    // Add fields for mapping
    a_fields = {
        {FieldName: "NumCountLinks",Type: "Integer", Description: "Number of links with this count ID"},
        {FieldName: "Count",Type: "Integer", Description: "Repeat of the count field"},
        {FieldName: "Volume",Type: "Real", Description: "Total Daily Link Flow"},
        {FieldName: "diff",Type: "Integer", Description: "Volume - Count"},
        {FieldName: "absdiff",Type: "Integer", Description: "abs(diff)"},
        {FieldName: "pctdiff",Type: "Integer", Description: "diff / Count * 100"},
        {FieldName: "MDD",Type: "Integer", Description: "Maximum Desirable Deviation"},
        {FieldName: "ExceedMDD",Type: "Integer", Description: "If link exceeds MDD"}
    }
    hwy_tbl.AddFields({Fields: a_fields})

    hwy_tbl.Count = hwy_tbl.(count_field)
    hwy_tbl.Volume = hwy_tbl.(vol_field)

    if combine_oneway_pairs then do
        agg = hwy_tbl.Aggregate({
            GroupBy: count_id_field,
            FieldStats: {
                Count: "sum",
                Volume: "sum"
            }
        })
        agg.SelectByQuery({
            SetName: "counts_links",
            Query: count_id_field + " <> null"
        })
        agg.RenameField({FieldName: "Count", NewName: "NumCountLinks"})
        temp = agg.Export()

        join = hwy_tbl.Join({
            Table: temp,
            LeftFields: count_id_field,
            RightFields: count_id_field
        })
        join.Count = join.("sum_Count")
        join.Volume = join.("sum_Volume")
        join = null
    end

    // Calculate remaining fields
    hwy_tbl.diff = hwy_tbl.Volume - hwy_tbl.Count
    hwy_tbl.absdiff = abs(hwy_tbl.diff)
    hwy_tbl.pctdiff = hwy_tbl.diff / hwy_tbl.Count * 100
    v_c = hwy_tbl.Count
    v_MDD = if (v_c <= 50000) then (11.65 * Pow(v_c, -.37752)) * 100
        else if (v_c <= 90000) then (400 * Pow(v_c, -.7)) * 100
        else if (v_c <> null)  then (.157 - v_c * .0000002) * 100
        else null
    hwy_tbl.MDD = v_MDD
    v_exceedMDD = if abs(hwy_tbl.pctdiff) > v_MDD then 1 else 0
    hwy_tbl.AddField({FieldName: "ExceedMDD", Type: "Integer", Description: "If link exceeds MDD"})
    hwy_tbl.ExceedMDD = v_exceedMDD

    // Rename fields to add suffix (first remove any that already exist)
    if field_suffix <> "" then do
        for f = 1 to a_fields.length do
            sub_a = a_fields[f]
            cur_field = sub_a.FieldName

            new_field = cur_field + field_suffix
            hwy_tbl.DropFields(new_field)
            hwy_tbl.RenameField({FieldName: cur_field, NewName: new_field})
        end
    end

    // Create a map of the link layer
    hwy_tbl = null
    map = CreateObject("Map", {FileName: hwy_dbd})
    {nlyr, llyr} = map.GetLayerNames()

    // Scaled Symbol Theme
    SetLayer(llyr)
    flds = {llyr + ".absdiff" + field_suffix}
    opts = null
    opts.Title = "Absolute Difference"
    opts.[Data Source] = "All"
    opts.[Minimum Value] = 0
    opts.[Maximum Value] = 50000
    opts.[Minimum Size] = .25
    opts.[Maximum Size] = 12
    theme_name = CreateContinuousTheme("Flows", flds, opts)

    // Set color to white to make it disappear in legend
    dual_colors = {ColorRGB(65535,65535,65535)}
    // without black outlines
    dual_linestyles = {LineStyle({{{1, -1, 0}}})}
    // with black outlines
    /*dual_linestyles = {LineStyle({{{2, -1, 0},{0,0,1},{0,0,-1}}})}*/
    dual_linesizes = {0}
    SetThemeLineStyles(theme_name , dual_linestyles)
    SetThemeLineColors(theme_name , dual_colors)
    SetThemeLineWidths(theme_name , dual_linesizes)

    ShowTheme(, theme_name)

    // Apply the color theme breaks
    cTheme = CreateTheme(
        "Count % Difference", llyr +".pctdiff" + field_suffix, "Manual", 8,{
        {"Values",{
            {-100, "True", -50, "False"},
            {-50, "True", -30, "False"},
            {-30, "True", -10, "False"},
            {-10, "True", 10, "True"},
            {10, "False", 30, "True"},
            {30, "False", 50, "True"},
            {50, "False", 100, "True"},
            {100, "False", 10000, "True"}
            }},
        {"Other", "False"}
        }
    )

    // Set color theme line styles and colors
    line_colors = {
        ColorRGB(17733,30069,46260),
        ColorRGB(29812,44461,53713),
        ColorRGB(43947,55769,59881),
        ColorRGB(0,0,0),
        ColorRGB(65278,57568,37008),
        ColorRGB(65021,44718,24929),
        ColorRGB(62708,28013,17219),
        ColorRGB(55255,12336,10023)
    }
    solidline = LineStyle({{{1, -1, 0}}})
    // This one puts black borders around the line
    /*dualline = LineStyle({{{2, -1, 0},{0,0,1},{0,0,-1}}})*/

    for i = 1 to 8 do
        class_id = GetLayer() +"|" + cTheme + "|" + String(i)
        SetLineStyle(class_id, dualline)
        SetLineColor(class_id, line_colors[i])
        SetLineWidth(class_id, 2)
    end

    // Change the labels of the classes (how the divisions appear in the legend)
    labels = {
        "-100 to -50", "-50 to -30", "-30 to -10",
        "-10 to 10", "10 to 30", "30 to 50",
        "50 to 100", ">100"
    }
    SetThemeClassLabels(cTheme, labels)

    ShowTheme(,cTheme)

    // Create a selection set of the links that do not exceed the MDD
    setname = "Deviation does not exceed MDD"
    RunMacro("G30 create set", setname)
    SelectByQuery(
        setname, "Several",
        "Select * where nz(Count" + field_suffix +
        ") > 0 and ExceedMDD" + field_suffix + " = 0"
    )
    SetLineColor(llyr + "|" + setname, ColorRGB(11308, 41634, 24415))

    // Configure Legend
    RunMacro("G30 create legend", "Theme")
    SetLegendSettings (
        GetMap(),
        {
        "Automatic",
        {0, 1, 0, 1, 1, 4, 0},
        {1, 1, 1},
        {"Arial|Bold|16", "Arial|9", "Arial|Bold|16", "Arial|12"},
        {"", vol_field + " vs " + count_field}
        }
    )
    str1 = "XXXXXXXX"
    solid = FillStyle({str1, str1, str1, str1, str1, str1, str1, str1})
    SetLegendOptions (GetMap(), {{"Background Style", solid}})

    map.HideLayer(nlyr)

    map.View()
    map.Save(output_file)
    map = null
EndMacro

/*
An alternative to to the JoinTableToLayer() GISDK function, which replaces
the existing bin file with a new one (losing original fields).
This version allows you to permanently append new fields while keeping the old.

Inputs
  * masterFile
    * String
    * Full path of master geographic or binary file
  * mID
    * String
    * Name of master field to use for join.
  * slaveFile
    * String
    * Full path of slave table.  Can be FFB or CSV.
  * sID
    * String
    * Name of slave field to use for join.
  * overwrite
    * Boolean
    * Whether or not to replace any existing
    * fields with joined values.  Defaults to true.
    * If false, the fields will be added with ":1".

Returns
Nothing. Permanently appends the slave data to the master table.

Example application
- Loading assignment results to a link layer
- Attaching an SE data table to a TAZ layer
*/

Macro "Join Table To Layer" (masterFile, mID, slaveFile, sID, overwrite)

  if overwrite = null then overwrite = "True"

  // Determine master file type
  path = SplitPath(masterFile)
  if path[4] = ".dbd" then type = "dbd"
  else if path[4] = ".bin" then type = "bin"
  else Throw("Master file must be .dbd or .bin")

  // Open the master file
  if type = "dbd" then do
    {nlyr, master} = GetDBLayers(masterFile)
    master = AddLayerToWorkspace(master, masterFile, master)
    nlyr = AddLayerToWorkspace(nlyr, masterFile, nlyr)
  end else do
    masterDCB = Substitute(masterFile, ".bin", ".DCB", )
    master = OpenTable("master", "FFB", {masterFile, })
  end

  // Determine slave table type and open
  path = SplitPath(slaveFile)
  if path[4] = ".csv" then s_type = "CSV"
  else if path[4] = ".bin" then s_type = "FFB"
  else Throw("Slave file must be .bin or .csv")
  slave = OpenTable("slave", s_type, {slaveFile, })

  // If mID is the same as sID, rename sID
  if mID = sID then do
    // Can only modify FFB tables.  If CSV, must convert.
    if s_type = "CSV" then do
      tempBIN = GetTempFileName("*.bin")
      ExportView(slave + "|", "FFB", tempBIN, , )
      CloseView(slave)
      slave = OpenTable("slave", "FFB", {tempBIN, })
    end

    str = GetTableStructure(slave)
    for s = 1 to str.length do
      str[s] = str[s] + {str[s][1]}

      str[s][1] = if str[s][1] = sID then "slave" + sID
        else str[s][1]
    end
    ModifyTable(slave, str)
    sID = "slave" + sID
  end

  // Remove existing fields from master if overwriting
  if overwrite then do
    {a_mFields, } = GetFields(master, "All")
    {a_sFields, } = GetFields(slave, "All")

    for f = 1 to a_sFields.length do
      field = a_sFields[f]
      if field <> sID & ArrayPosition(a_mFields, {field}, ) <> 0
        then RunMacro("Remove Field", master, field)
    end
  end

  // Join master and slave. Export to a temporary binary file.
  jv = JoinViews("perma jv", master + "." + mID, slave + "." + sID, )
  SetView(jv)
  a_path = SplitPath(masterFile)
  tempBIN = a_path[1] + a_path[2] + "temp.bin"
  tempDCB = a_path[1] + a_path[2] + "temp.DCB"
  ExportView(jv + "|", "FFB", tempBIN, , )
  CloseView(jv)
  CloseView(master)
  CloseView(slave)

  // Swap files.  Master DBD files require a different approach
  // from bin files, as the links between the various database
  // files are more complicated.
  if type = "dbd" then do
    // Join the tempBIN to the DBD. Remove Length/Dir fields which
    // get duplicated by the DBD.
    opts = null
    opts.Ordinal = "True"
    JoinTableToLayer(masterFile, master, "FFB", tempBIN, tempDCB, mID, opts)
    master = AddLayerToWorkspace(master, masterFile, master)
    nlyr = AddLayerToWorkspace(nlyr, masterFile, nlyr)
    RunMacro("Remove Field", master, "Length:1")
    RunMacro("Remove Field", master, "Dir:1")

    // Re-export the table to clean up the bin file
    new_dbd = a_path[1] + a_path[2] + a_path[3] + "_temp" + a_path[4]
    {l_names, l_specs} = GetFields(master, "All")
    {n_names, n_specs} = GetFields(nlyr, "All")
    opts = null
    opts.[Field Spec] = l_specs
    opts.[Node Name] = nlyr
    opts.[Node Field Spec] = n_specs
    ExportGeography(master + "|", new_dbd, opts)
    DropLayerFromWorkspace(master)
    DropLayerFromWorkspace(nlyr)
    DeleteDatabase(masterFile)
    CopyDatabase(new_dbd, masterFile)
    DeleteDatabase(new_dbd)

    // Remove the sID field
    master = AddLayerToWorkspace(master, masterFile, master)
    RunMacro("Remove Field", master, sID)
    DropLayerFromWorkspace(master)

    // Delete the temp binary files
    DeleteFile(tempBIN)
    DeleteFile(tempDCB)
  end else do
    // Remove the master bin files and rename the temp bin files
    DeleteFile(masterFile)
    DeleteFile(masterDCB)
    RenameFile(tempBIN, masterFile)
    RenameFile(tempDCB, masterDCB)

    // Remove the sID field
    view = OpenTable("view", "FFB", {masterFile})
    RunMacro("Remove Field", view, sID)
    CloseView(view)
  end
EndMacro

/*
Removes a field from a view/layer

Input
viewName  Name of view or layer (must be open)
field_name Name of the field to remove. Can pass string or array of strings.
*/

Macro "Remove Field" (viewName, field_name)
  a_str = GetTableStructure(viewName)

  if TypeOf(field_name) = "string" then field_name = {field_name}

  for fn = 1 to field_name.length do
    name = field_name[fn]

    for i = 1 to a_str.length do
      a_str[i] = a_str[i] + {a_str[i][1]}
      if a_str[i][1] = name then position = i
    end
    if position <> null then do
      a_str = ExcludeArrayElements(a_str, position, 1)
      ModifyTable(viewName, a_str)
    end
  end
EndMacro