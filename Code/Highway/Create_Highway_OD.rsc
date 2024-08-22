/*
Expands the tour file into a trip file
*/

Macro "Create Trip File" (Args)

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
            {FieldName: "TOD", Type: "integer"}
        }})
        export = pivot.Export({ViewName: "exported", FieldNames: {
            "ID",
            "HHID",
            "SIZE",
            "INCOME",
            "LIFE",
            "WRKRS",
            "Purp",
            "PAper",
            "APper",
            "TourMode",
            "Stop",
            "TripOrigTAZ",
            "TripDestTAZ",
            "TOD"
        }})
        export.Sort({FieldArray: {{"ID", "Ascending"}, {"Stop", "Ascending"}}})

        // Transfer the TOD info from PAper and APper fields
        data = export.GetDataVectors({FieldNames: {"PAper", "APper", "Stop"}})
        v_pa = data.PAper
        v_ap = data.APper
        v_stop = data.Stop
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
        modes = V2A(SortVector(modes, {Unique: true}))
        skim_mtx = Args.[Run Directory] + "\\Skims\\offpk_hwyskim.mtx"
        periods = {"OP", "PK"}
        for i = 1 to periods.length do
            period = periods[i]
            mtx_file = out_dir + "\\" + purp + "_" + period + ".mtx"
            CopyFile(skim_mtx, mtx_file)
            mtx = CreateObject("Matrix", mtx_file)
            cores_to_drop = mtx.GetCoreNames()
            mtx.AddCores(modes)
            mtx.DropCores(cores_to_drop)
            mtx.UpdateFromTable({
                Table: final,
                Filter: "TOD = " + String(i),
                RowIDField: "TripOrigTAZ",
                ColumnIDField: "TripDestTAZ",
                CoreNameField: "Mode",
                ValueField: "one"
            })
            RenameMatrix(mtx.GetMatrixHandle(), purp + " " + period)
        end
    end


endmacro

/*

*/

Macro "Create Highway OD" (Args, period)
    
    od_matrix = Args.[Run Directory] + "\\tod2\\ODHwyVeh_" + period + ".mtx"
    files = {"dcHBW", "dcHBS", "dcHBO", "dcSch", "dcHBU", "dcATW"}

    for file in files do
        dcFile = Args.[Run Directory] + "\\TD\\" + files[i] + ".bin"

    end

endmacro