TYPE dialogType RECORD
    name STRING,
    type STRING,
    title STRING,
    primary_key BOOLEAN
END RECORD
CONSTANT TABLE_LISTING="customer,device_registry,order_header,order_line,phone_home,product,product_group,product_image,supplier"



MAIN
    OPTIONS FIELD ORDER FORM
    OPTIONS INPUT WRAP
    CLOSE WINDOW SCREEN
    
    CALL ui.Dialog.setDefaultUnbuffered(TRUE)
    CALL ui.Interface.loadStyles("kitchenalia_web")
    CALL ui.Interface.loadActionDefaults("kitchenalia_web")
    CALL ui.Interface.setText("Kitchenalia Web Administration")

    CONNECT TO "kitchenalia"
    CALL table_list()
END MAIN



FUNCTION table_list()
DEFINE l_tok base.StringTokenizer
DEFINE l_arr DYNAMIC ARRAY OF RECORD
    name STRING,
    count INTEGER
END RECORD

    --TODO replace with better way by reading catalog.db
    LET l_tok = base.StringTokenizer.create(TABLE_LISTING,",")
    WHILE l_tok.hasMoreTokens()
        LET l_arr[l_arr.getLength()+1].name = l_tok.nextToken()
    END WHILE
        
    OPEN WINDOW kitchenalia_web WITH FORM "kitchenalia_web"
    DISPLAY ARRAY l_arr TO scr.* ATTRIBUTES(DOUBLECLICK=select, ACCEPT=FALSE, CANCEL=FALSE)
        BEFORE DISPLAY
            MESSAGE "Select table to view or maintain"
            CALL populate_row_count(l_arr)
        ON ACTION refresh ATTRIBUTES(TEXT="Refresh")
            CALL populate_row_count(l_arr)
        ON ACTION select ATTRIBUTES(DEFAULTVIEW=NO)
            CALL view_table(l_arr[arr_curr()].name)
            CALL populate_row_count(l_arr)
        ON ACTION close
            EXIT DISPLAY
    END DISPLAY
    LET int_flag = 0
    CLOSE WINDOW kitchenalia_web
END FUNCTION



FUNCTION populate_row_count(l_arr)
DEFINE l_arr DYNAMIC ARRAY OF RECORD
    name STRING,
    count INTEGER
END RECORD
DEFINE i INTEGER
DEFINE l_sql STRING

    FOR i = 1 TO l_arr.getLength()
        LET l_sql = SFMT("SELECT COUNT(*) FROM %1", l_arr[i].name)
        PREPARE count_sql FROM l_sql
        EXECUTE count_sql INTO l_arr[i].count
    END FOR
END FUNCTION



FUNCTION view_table(l_table)
DEFINE l_table STRING

DEFINE l_fields DYNAMIC ARRAY OF dialogType

DEFINE d ui.Dialog
DEFINE w ui.Window
DEFINE f ui.Form

DEFINE l_where STRING
DEFINE i INTEGER
DEFINE l_new_row DYNAMIC ARRAY OF STRING

    CALL populate_fields(l_table, l_fields)
    
    OPEN WINDOW w WITH 1 ROWS, 1 COLUMNS
    LET w = ui.Window.getCurrent()
    CALL w.setText(SFMT("Table: %1",l_table))
    LET f = w.createForm(l_table)
    CALL create_form(f.getNode(), l_table, l_fields)
    
    LET d = ui.Dialog.createDisplayArrayTo(l_fields, "scr")
    CALL d.addTrigger("ON ACTION cancel")
    CALL d.addTrigger("ON ACTION filter")
    CALL d.addTrigger("ON APPEND")
    CALL d.addTrigger("ON UPDATE")
    CALL d.addTrigger("ON DELETE")
    IF l_table = "product_image" THEN
        CALL d.addTrigger("ON ACTION view")
        CALL d.setActionText("view","View Image")
    END IF
    CALL d.addTrigger("ON ACTION close")

    CALL d.setActionText("cancel","Back")
    CALL d.setActionText("filter","Filter")

    CALL populate_array(d, l_table, "")
    WHILE TRUE
        CASE d.nextEvent()
            WHEN "ON ACTION cancel"
                EXIT WHILE
            WHEN "ON ACTION filter"
                LET l_where = input_filter(l_fields, l_table)
                CALL populate_array(d, l_table, l_where) 
                
            WHEN "ON APPEND"
                CALL l_new_row.clear()
                IF edit_row(d, l_fields, l_table, TRUE, l_new_row) THEN
                    CALL d.setCurrentRow("scr", d.getArrayLength("scr"))
                    FOR i = 1 TO l_fields.getLength()
                        CALL d.setFieldValue(l_fields[i].name, l_new_row[i])
                    END FOR
                END IF
                
            WHEN "ON UPDATE"
                CALL l_new_row.clear()
                IF edit_row(d, l_fields, l_table, FALSE, l_new_row) THEN
                    FOR i = 1 TO l_fields.getLength()
                        CALL d.setFieldValue(l_fields[i].name, l_new_row[i])
                    END FOR
                END IF
            WHEN "ON DELETE"
                CALL delete_row(d, l_fields, l_table)

            -- Special case to view image in product_image table
            WHEN "ON ACTION view"
                CALL view_image(d.getFieldValue("pi_filename"))
                
            WHEN "ON ACTION close"
                EXIT WHILE
        END CASE
    END WHILE
    CALL d.close()
    CLOSE WINDOW w
END FUNCTION



--TODO alternate approach using .sch file, can probably remove
FUNCTION populate_fields2(l_table, l_fields)
DEFINE l_table STRING
DEFINE l_fields DYNAMIC ARRAY OF dialogType

DEFINE l_ch base.Channel
DEFINE l_line STRING
DEFINE l_tok base.StringTokenizer
DEFINE l_dummy STRING
DEFINE l_column STRING
DEFINE l_type1 INTEGER
DEFINE l_type2 INTEGER
DEFINE l_type STRING

    LET l_ch = base.Channel.create()
    CALL l_ch.openFile("kitchenalia.sch","r")
    WHILE TRUE
        LET l_line = l_ch.readLine()
        IF l_ch.isEof() THEN
            EXIT WHILE
        END IF
        IF l_line MATCHES l_table||"^*" THEN
            LET l_tok = base.StringTokenizer.create(l_line,"^")
            LET l_dummy =  l_tok.nextToken()
            LET l_column = l_tok.nextToken()
            LET l_type1 = l_tok.nextToken()
            LET l_type2 = l_tok.nextToken()
            CALL l_fields.appendElement()
            LET l_type = get_datatype(l_type1, l_type2)
            LET l_fields[l_fields.getLength()].name = l_column
            LET l_fields[l_fields.getLength()].type = l_type
            DISPLAY l_fields[L_fields.getLength()].*
        END IF
    END WHILE
    LET l_fields[1].primary_key = TRUE
END FUNCTION




FUNCTION populate_fields(l_table, l_fields)
DEFINE l_table STRING
DEFINE l_fields DYNAMIC ARRAY OF dialogType

DEFINE doc om.DomDocument
DEFINE root_node, table_node, column_node, index_node om.DomNode
DEFINE table_list, column_list, index_list om.NodeList
DEFINE c_idx INTEGER
DEFINE l_column, l_type STRING
DEFINE tok base.StringTokenizer
DEFINE l_primarykey_list DYNAMIC ARRAY OF STRING
DEFINE l_primarykey_column STRING
DEFINE i INTEGER

    LET doc= om.DomDocument.createFromXmlFile("kitchenalia.4db")
    LET root_node = doc.getDocumentElement()
    LET table_list = root_node.selectByPath(SFMT("//Table[@name=\"%1\"]",l_table))
    IF table_list.getLength() = 1 THEN
        LET table_node = table_list.item(1)

        -- Determine primary key columns
        CALL l_primarykey_list.clear()
        LET index_list = table_node.selectByPath("//Index[@indexConstraint=\"primaryKey\"]")
        IF index_list.getLength() = 1 THEN
            LET index_node = index_list.item(1)
            LET tok = base.StringTokenizer.create(index_node.getAttribute("indexColumns"),",")
            WHILE tok.hasMoreTokens()
                LET l_primarykey_column = tok.nextToken()
                LET l_primarykey_list[l_primarykey_list.getLength()+1] = l_primarykey_column.trim()
            END WHILE
        END IF

        -- Add columns
        LET column_list = table_node.selectByTagName("Column")
        FOR c_idx = 1 TO column_list.getLength()
            LET column_node = column_list.item(c_idx)
            LET l_column = column_node.getAttribute("name")
            LET l_type = get_datatype(column_node.getAttribute("fglType"), column_node.getAttribute("fglLength"))
            CALL l_fields.appendElement()
            LET l_fields[l_fields.getLength()].name = l_column
            LET l_fields[l_fields.getLength()].type = l_type
            LET l_fields[l_fields.getLength()].primary_key = FALSE
            FOR i = 1 TO l_primarykey_list.getLength()
                IF l_primarykey_list[i] = l_column THEN
                    LET l_fields[l_fields.getLength()].primary_key = TRUE
                END IF
            END FOR
        END FOR
    END IF
END FUNCTION



FUNCTION get_datatype(l_type_int, l_type_precision_scale)
DEFINE l_type_int INTEGER
DEFINE l_type_precision_scale INTEGER
DEFINE l_type_str STRING

DEFINE l_precision, l_scale INTEGER

    IF l_type_int > 255 THEN
        LET l_type_int = l_type_int - 256
    END IF
    CASE l_type_int
        WHEN 0 LET l_type_str=SFMT("CHAR(%1)", l_type_precision_scale USING "<<&")
        WHEN 2 LET l_type_str = "INTEGER"
        WHEN 3 LET l_type_str = "FLOAT"
        WHEN 5 
            LET l_precision = l_type_precision_scale / 256
            LET l_scale = l_type_precision_scale MOD 256
            IF l_scale = 255 THEN
                LET l_type_str = SFMT("DECIMAL(%1)", l_precision)
            ELSE
                LET l_type_str = SFMT("DECIMAL(%1,%2)", l_precision USING "<<&", l_scale USING "<<<<<&")
            END IF
        WHEN 7 
            LET l_type_str = "DATE"
        WHEN 10
            -- Lazy code, I only use DATEIME YEAR TO SECOND, to support others, calculation is more complex
            LET l_type_str = "DATETIME YEAR TO SECOND"
        WHEN 13
            LET l_type_str=SFMT("VARCHAR(%1)", l_type_precision_scale USING "<<&")
        WHEN 45
            LET l_type_str = "BOOLEAN"
        WHEN 201
            LET l_type_str=SFMT("VARCHAR(%1)", l_type_precision_scale USING "<<&")
        OTHERWISE
            LET l_type_str = "STRING"
    END CASE 
    RETURN l_type_str
END FUNCTION



FUNCTION create_form(root_node, l_table, l_fields)
DEFINE l_table STRING
DEFINE l_fields DYNAMIC ARRAY OF dialogType

DEFINE root_node, grid_node, table_node, formfield_node, widget_node om.DomNode
DEFINE i INTEGER

    LET grid_node = root_node.createChild("Grid")
    LET table_node = grid_node.createChild("Table")
    CALL table_node.setAttribute("doubleClick", "update")
    CALL table_node.setAttribute("tabName", "scr")
    CALL table_node.setAttribute("pageSize", 15)

    FOR i = 1 TO l_fields.getLength()
        LET formfield_node = table_node.createChild("TableColumn")
       
        CALL formfield_node.setAttribute("text", l_fields[i].name)
        CALL formfield_node.setAttribute("colName", l_fields[i].name)
        CALL formfield_node.setAttribute("name", "formonly." || l_fields[i].name)
        CALL formfield_node.setAttribute("sqlType", l_fields[i].type)
        CALL formfield_node.setAttribute("tabIndex", i )
        LET widget_node = formfield_node.createChild("Edit")
        CALL widget_node.setAttribute("width", 10)
        CALL widget_node.setAttribute("scroll", 1)
    END FOR
END FUNCTION



FUNCTION populate_array(d, l_table, l_where)
DEFINE d ui.Dialog
DEFINE l_table STRING
DEFINE l_where STRING
DEFINE h base.SqlHandle
DEFINE l_sql STRING
DEFINE l_row INTEGER
DEFINE l_col INTEGER

    LET l_sql = SFMT("SELECT * FROM %1 WHERE %2 ", l_table, IIF(l_where.getLength() > 0, l_where,"1=1"))
    
    LET h = base.SqlHandle.create()
    CALL h.prepare(l_sql)
    CALL h.open()
    
    LET l_row = 0
    CALL d.deleteAllRows("scr")
    WHILE TRUE
        CALL h.fetch()
        IF status = NOTFOUND THEN
            EXIT WHILE
        END IF
        LET l_row = l_row + 1
        CALL d.insertRow("scr",l_row)
        CALL d.setCurrentRow("scr", l_row) -- must set the current row before setting values
        FOR l_col = 1 TO h.getResultCount()
            CALL d.setFieldValue(h.getResultName(l_col), h.getResultValue(l_col))
        END FOR
    END WHILE
    CALL d.setCurrentRow("scr", 1) -- TODO: should be done by the runtime
    CALL h.close()
END FUNCTION



FUNCTION input_filter(l_fields, l_table)
DEFINE l_fields DYNAMIC ARRAY OF dialogType
DEFINE l_table STRING

DEFINE l_where STRING

DEFINE cd ui.Dialog
DEFINE i INTEGER
DEFINE l_field_condition STRING

    LET cd =ui.Dialog.createConstructByName(l_fields)
    CALL cd.addTrigger("ON ACTION accept")
    CALL cd.addTrigger("ON ACTION cancel")
    WHILE TRUE
        CASE cd.nextEvent()
            WHEN "ON ACTION cancel"
                LET int_Flag = TRUE
                EXIT WHILE
            WHEN "ON ACTION accept"
                EXIT WHILE
            WHEN "ON ACTION close"
                LET int_Flag = TRUE
                EXIT WHILE
        END CASE
    END WHILE
    IF int_flag THEN
        LET int_flag = 0
        LET l_where = "1=1"
    ELSE
        FOR i=1 TO l_fields.getLength()
            LET l_field_condition = cd.getQueryFromField(l_fields[i].name)
            IF l_field_condition IS NOT NULL THEN
                IF l_where IS NOT NULL THEN
                    LET l_where = l_where, " AND "
                END IF
                LET l_where = l_where, l_field_condition
            END IF
        END FOR
    END IF
    CALL cd.close()
    RETURN l_where
END FUNCTION



PRIVATE FUNCTION primary_key_where(l_fields, l_table)
DEFINE l_fields DYNAMIC ARRAY OF dialogType
DEFINE l_table STRING

DEFINE i INTEGER
DEFINE sb base.StringBuffer

    LET sb = base.StringBuffer.create()
    FOR i = 1 TO l_fields.getLength()
        IF l_fields[i].primary_key THEN
            IF sb.getLength() > 0 THEN
                CALL sb.append(" AND ")
            END IF
            CALL sb.append(SFMT("%1 = ?", l_fields[i].name))
        END IF
    END FOR
    RETURN sb.toString()
END FUNCTION



FUNCTION edit_row(dad, l_fields, l_table, l_add_flag, l_new_row)
DEFINE dad,id ui.Dialog
DEFINE l_fields DYNAMIC ARRAY OF dialogType
DEFINE l_table STRING
DEFINE l_add_flag BOOLEAN
DEFINE l_new_row DYNAMIC ARRAY OF STRING

DEFINE l_ok BOOLEAN

DEFINE l_sql base.SqlHandle
DEFINE i,j INTEGER
DEFINE sb base.StringBuffer

    --TODO When dynamic dialogs can handle INPUT to row of line of an array, this next line will probably be changed
    LET id = ui.Dialog.createInputByName(l_fields)
    
    CALL id.addTrigger("ON ACTION accept")
    CALL id.addTrigger("ON ACTION cancel")

    WHILE TRUE
        CASE id.nextEvent()
            WHEN "BEFORE INPUT"
               FOR i = 1 TO l_fields.getLength()
                    CALL id.setFieldValue(l_fields[i].name, IIF(l_add_flag,NULL,dad.getFieldValue(l_fields[i].name)))
                    IF NOT l_add_flag AND l_fields[i].primary_key THEN
                        CALL id.setFieldActive(l_fields[i].name, FALSE)
                    END IF
                END FOR
                -- TODO: Remove MESSAGE when this issue is resolved.
                MESSAGE "KNOWN ISSUE: The INPUT is displaying in line 1 rather than the expected line"
                
            WHEN "ON ACTION cancel"
                LET int_Flag = TRUE
                EXIT WHILE
            WHEN "ON ACTION accept"
                EXIT WHILE
            WHEN "ON ACTION close"
                LET int_Flag = TRUE
                EXIT WHILE
        END CASE
    END WHILE
    IF int_flag THEN
        LET int_flag = 0
        LET l_ok = FALSE
    ELSE
        LET l_sql = base.SqlHandle.create()
        LET sb = base.StringBuffer.create()
        IF l_add_flag THEN
            CALL sb.append(SFMT("INSERT INTO %1 (", l_table ))
            FOR i = 1 TO l_fields.getLength()
                IF i > 1 THEN
                    CALL sb.append(", ")
                END IF
                CALL sb.append(l_fields[i].name)
            END FOR
            CALL sb.append(") VALUES (")
            FOR i = 1 TO l_fields.getLength()
                IF i > 1 THEN
                    CALL sb.append(", ")
                END IF
                CALL sb.append("? ")
            END FOR

            CALL sb.append(")")
        ELSE
            CALL sb.append(SFMT("UPDATE %1 SET ", l_table))
            FOR i = 1 TO l_fields.getLength()
                IF i > 1 THEN
                    CALL sb.append(", ")
                END IF
                CALL sb.append(SFMT("%1 = ? ",l_fields[i].name))
            END FOR
            CALL sb.append(" WHERE ")
            CALL sb.append(primary_key_where(l_fields, l_table))
        END IF
        CALL l_sql.prepare(sb.toString())
        
        CALL l_sql.prepare(sb.toString())
        FOR i = 1 TO l_fields.getLength()
            CALL l_sql.setParameter(i, id.getFieldValue(l_fields[i].name))
        END FOR
        IF NOT l_add_flag THEN
            LET j = l_fields.getLength()
            FOR i = 1 TO l_fields.getLength()
                IF l_fields[i].primary_key THEN
                    LET j = j + 1
                    CALL l_sql.setParameter(j,id.getFieldValue(l_fields[i].name))
                END IF
            END FOR
        END IF
        
        CALL l_sql.execute()
        LET l_ok = TRUE
    END IF
    IF l_ok THEN
        FOR i = 1 TO l_fields.getLength()
            LET l_new_row[i] = id.getFieldValue(l_fields[i].name)
        END FOR
    END IF
    CALL id.close()
    MESSAGE ""
    RETURN l_ok
END FUNCTION



FUNCTION delete_row(d, l_fields, l_table)
DEFINE d ui.Dialog
DEFINE l_fields DYNAMIC ARRAY OF dialogType
DEFINE l_table STRING
DEFINE l_sql base.SqlHandle
DEFINE sb base.StringBuffer
DEFINE i,j INTEGER

    LET l_sql = base.Sqlhandle.create()
    LET sb = base.StringBuffer.create()
    CALL sb.append("DELETE FROM ")
    CALL sb.append(l_table)
    CALL sb.append(" WHERE ")
    CALL sb.append(primary_key_where(l_fields, l_table))
    
    CALL l_sql.prepare(sb.toString())

    LET j = 0
    FOR i = 1 TO l_fields.getLength()
        IF l_fields[i].primary_key THEN
            LET j = j + 1
            CALL l_sql.setParameter(j,d.getFieldValue(l_fields[i].name))
        END IF
    END FOR

    CALL l_sql.execute()
END FUNCTION



FUNCTION view_image(l_filename)
DEFINE l_filename STRING
    OPEN WINDOW kitchenalia_web_image WITH FORM "kitchenalia_web_image" ATTRIBUTES(STYLE="dialog", TEXT=l_filename)
    DISPLAY l_filename TO img
    MENU ""
        ON ACTION accept
            EXIT MENU
        ON ACTION close
            EXIT MENU
    END MENU
    LET int_flag = 0
    CLOSE WINDOW kitchenalia_web_image
END FUNCTION