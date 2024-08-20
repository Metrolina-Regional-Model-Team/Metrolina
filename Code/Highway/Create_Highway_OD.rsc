/*
Expands the tour file into a trip file
*/

Macro "Create Trip File" (Args)

    purps = {"HBW", "HBS", "HBO", "Sch", "HBU", "ATW"}
    files = {"dcHBW", "dcHBS", "dcHBO", "dcSch", "dcHBU", "dcATW"}
    out_dir = Args.[Run Directory] + "\\TripTables"

    for purp in purps do
        dcFile = Args.[Run Directory] + "\\TD\\dc" + purp + ".bin"
        out_file = out_dir + "\\trips_" + purp + ".bin"
        
        // Copy the file
        CopyFile(dcFile, out_file)
        CopyFile(
            Substitute(dcFile, ".bin", ".dcb", 1), 
            Substitute(out_file, ".bin", ".dcb", 1)
        )
        tbl = null
        tbl = CreateObject("Table", out_file)    
        tbl.AddField({FieldName: "tempid", Type: "integer"})
        v = Vector(tbl.GetRecordCount(), "integer", {{"Sequence", 1, 1}})
        tbl.tempid = v
        // Rename fields before pivot to preserve order
        fields = {"ORIG_TAZ", "IS1", "IS2", "IS3", "IS4", "IS5", "IS6", "IS7", "DEST_TAZ"}
        for i = 1 to fields.length do
            new_fields = new_fields + {"1_" + fields[i]}
        end
        tbl.PivotLonger({
            Fields: new_fields
            NamesTo: "Stop",
            ValuesTo: "TripOrigTAZ"
        })
        // Determine the TripDestTAZ, which is the origin from the next record
        tbl.AddField({FieldName: "TripDestTAZ", Type: "integer"})
        a_tempid = V2A(tbl.tempid)
        a_otaz = V2A(tbl.TripOrigTAZ)
        zip = a_tempid.zip(a_otaz)
        a_dtaz = zip.map(do (a, i) return(
            if i = zip.length then null
            else if a_tempid[i] = a_tempid[i+1] 
                then a_otaz[i+1]
                else null
        ) end)
        tbl.TripDestTAZ = A2V(a_dtaz)
tbl.View()
Throw()
        // The last record in each tour will have a null destination. Remove it.
        tbl.DropFields("tempid")
        tbl.SelectByQuery({
            SetName: "Trips",
            Query: "TripDestTAZ <> null"
        })
        final = tbl.Export({FileName: out_file})
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