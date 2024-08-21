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
        data = tbl.GetDataVectors({FieldNames: fields})
        // Add a second origin field, which represents the final return trip
        // of the tour.
        data.return_orig = CopyVector(data.ORIG_TAZ)
        fields_add_return = fields + {"return_orig"}
        // this outer loop just repeats the shifting process 20 times, which
        // should be enough to remove all gaps
        for j = 1 to 20 do
            // this inner loop shifts stops to the left if there is a gap
            for i = 1 to fields_add_return.length - 1 do
                field = fields_add_return[i]
                next_field = fields_add_return[i+1]
                is_null = if data.(field) = null then 1 else 0
                    data.(field) = if is_null then data.(next_field) else data.(field)
                    data.(next_field) = if is_null then null else data.(next_field)
            end
        end
        data.return_orig = null
        tbl.SetDataVectors({FieldData: data})

        // Rename fields before pivot to preserve order
        for i = 1 to fields.length do
            num = 100 + i
            ordered_field = String(num) + "_" + fields[i]
            tbl.RenameField({FieldName: fields[i], NewName: ordered_field})
            ordered_fields = ordered_fields + {ordered_field}
        end
        pivot = tbl.PivotLonger({
            Fields: ordered_fields,
            NamesTo: "Stop",
            ValuesTo: "TripOrigTAZ"
        })
        pivot.Sort({FieldArray: {{"ID", "Ascending"}, {"Stop", "Ascending"}}})

        // Determine the TripDestTAZ, which is the origin from the next record
        pivot.AddField({FieldName: "TripDestTAZ", Type: "integer"})
        v_id = pivot.id
        v_otaz = pivot.TripOrigTAZ
        v_lead_id = SubVector(v_id, 2, )
        v_lead_id = A2V(V2A(v_lead_id) + {null})
        v_lead_otaz = SubVector(v_otaz, 2, )
        v_lead_otaz = A2V(V2A(v_lead_otaz) + {null})
        v_dtaz = if v_id = v_lead_id
            then v_lead_otaz
            else null
        pivot.TripDestTAZ = v_dtaz

        // The last record in each tour will have a null destination. Remove it.
        pivot.SelectByQuery({
            SetName: "Trips",
            Query: "TripDestTAZ <> null"
        })

        final = pivot.Export({FileName: out_file, FieldNames: {
            "ID",
            "HHID",
            "SIZE",
            "INCOME",
            "LIFE",
            "WRKRS",
            "Purp",
            "TourMode",
            "TripOrigTAZ",
            "TripDestTAZ"
        }})
        final.RenameField({FieldName: "ID", NewName: "TourID"})
        final.RenameField({FieldName: "TourMode", NewName: "Mode"})
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