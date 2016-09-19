import util
import os

schema kitchenalia



function get_customer(l_arglist)
define l_arglist string

define j_resp record
    count float,
    results dynamic array of record like customer.*
end record

define l_customer record like customer.*
define i integer
define l_where, l_sql string

define l_json_string string

    case
        #when l_arglist matches "group=*"
        #    let l_pr_pg_code = l_arglist.subString(7, l_arglist.getLength())
        #   let l_where = sfmt("pr_pg_code = '%1' order by pr_code" , l_pr_pg_code clipped)
        when l_arglist.getLength() = 0
            let l_where = "1=1"
        otherwise
            return false, NULL
    end case
    
    let l_sql = "select * from customer where ", l_where
    declare customer_curs cursor from l_sql 
    let i = 0
    foreach customer_curs into l_customer.*
        let i = i + 1
        let j_resp.results[i].* = l_customer.*
        
    end foreach
    let j_resp.count = i

    let l_json_string = util.JSON.stringify(j_resp)
    return true, l_json_string
end function


-- use this for line graph
function get_time_analysis(l_arglist)
define l_arglist string

type result_type record
    year like order_header.oh_year,
    month like order_header.oh_month,
    total_lines integer,
    total_qty like order_line.ol_qty,
    total_value like order_line.ol_line_value
end record
    
define j_resp record
    count float,
    results dynamic array of result_type
end record

define l_result result_type

define l_cu_code like customer.cu_code
define l_pr_code like product.pr_code
define l_pg_code like product_group.pg_code
define i integer
define l_where, l_sql string

define l_json_string string

    case
        when l_arglist matches "cu_code=*"
            let l_cu_code = l_arglist.subString(9, l_arglist.getLength())
           let l_where = sfmt("oh_cu_code = '%1' " , l_cu_code clipped)
        when l_arglist matches "pr_code=*"
            let l_pr_code = l_arglist.subString(9, l_arglist.getLength())
           let l_where = sfmt("ol_pr_code = '%1' " , l_pr_code clipped)
        when l_arglist matches "pg_code=*"
            let l_pg_code = l_arglist.subString(9, l_arglist.getLength())
           let l_where = sfmt("pr_pg_code = '%1' " , l_pg_code clipped)
        --when l_arglist.getLength() = 0
            --let l_where = "1=1"
        otherwise
            return false, NULL
    end case
    
    let l_sql = "select oh_year, oh_month, count(*), sum(ol_qty), sum(ol_line_value) from order_line, order_header, product where oh_code = ol_oh_code and ol_pr_code = pr_code and ", l_where, " group by 1,2 order by 1,2"
    display l_sql
    declare time_analysis_curs cursor from l_sql 
    let i = 0
    foreach time_analysis_curs into l_result.*
        let i = i + 1
        let j_resp.results[i].* = l_result.*
        
    end foreach
    let j_resp.count = i

    let l_json_string = util.JSON.stringify(j_resp)
    return true, l_json_string
end function




-- use this for pie graph
function get_group_analysis(l_arglist)
define l_arglist string

type result_type record
    pg_code like product_group.pg_code,
    total_value like order_line.ol_line_value
end record
    
define j_resp record
    count float,
    results dynamic array of result_type
end record

define l_result result_type

define l_cu_code like customer.cu_code
define i integer
define l_where, l_sql string

define l_json_string string

    case
        when l_arglist matches "cu_code=*"
            let l_cu_code = l_arglist.subString(9, l_arglist.getLength())
           let l_where = sfmt("oh_cu_code = '%1' " , l_cu_code clipped)
        
        --when l_arglist.getLength() = 0
            --let l_where = "1=1"
        otherwise
            return false, NULL
    end case
    
    let l_sql = "select pr_pg_code, sum(ol_line_value) from order_line, order_header, product where oh_code = ol_oh_code and ol_pr_code = pr_code and ", l_where, " group by 1 order by 1"
    display l_sql
    declare group_analysis_curs cursor from l_sql 
    let i = 0
    foreach group_analysis_curs into l_result.*
        let i = i + 1
        let j_resp.results[i].* = l_result.*
        
    end foreach
    let j_resp.count = i

    let l_json_string = util.JSON.stringify(j_resp)
    return true, l_json_string
end function



-- use this for stacked bar graph
function get_time_group_analysis(l_arglist)
define l_arglist string

type result_type record
    oh_year like order_header.oh_year,
    oh_month like order_header.oh_month,
    pg_code like product_group.pg_code,
    total_value like order_line.ol_line_value
end record
    
define j_resp record
    count float,
    results dynamic array of result_type
end record

define l_result result_type

define l_cu_code like customer.cu_code
define l_su_code like supplier.su_code
define i integer
define l_where, l_sql string

define l_json_string string

    case
        when l_arglist matches "cu_code=*"
            let l_cu_code = l_arglist.subString(9, l_arglist.getLength())
            let l_where = sfmt("oh_cu_code = '%1' " , l_cu_code clipped)
        when l_arglist matches "su_code=*"
            let l_su_code = l_arglist.subString(9, l_arglist.getLength())
            let l_where = sfmt("pr_su_code = '%1' " , l_su_code clipped)
        
        when l_arglist.getLength() = 0
            let l_where = "1=1"
        otherwise
            return false, NULL
    end case
    
    let l_sql = "select oh_year, oh_month, pr_pg_code, sum(ol_line_value) from order_line, order_header, product where oh_code = ol_oh_code and ol_pr_code = pr_code and ", l_where, " group by 1,2,3 order by 1,2,3"
    display l_sql
    declare time_group_analysis_curs cursor from l_sql 
    let i = 0
    foreach time_group_analysis_curs into l_result.*
        let i = i + 1
        let j_resp.results[i].* = l_result.*
        
    end foreach
    let j_resp.count = i

    let l_json_string = util.JSON.stringify(j_resp)
    return true, l_json_string
end function



function get_order(l_arglist)
define l_arglist string

define j_resp record
    count float,
    results dynamic array of record
        order record like order_header.*,
        lines dynamic array of record like order_line.*
    end record
end record

define l_oh_code like order_header.oh_code

define l_order_header record like order_header.*
define l_order_line record like order_line.*
define i, j integer
define l_where, l_sql string

define l_json_string string

    case
        when l_arglist matches "oh_code=*"
            let l_oh_code = l_arglist.subString(9, l_arglist.getLength())
            let l_where = sfmt("oh_code = '%1' " , l_oh_code clipped)
        # TODO do we allow all orders?
        #when l_arglist.getLength() = 0
        #    let l_where = "1=1"
        otherwise
            return false, NULL
    end case
    
    let l_sql = "select * from order_header where ", l_where
    declare order_header_curs cursor from l_sql 
    let l_sql = "select * from order_line where ol_oh_code = ? "
    declare order_line_curs cursor from l_sql
    let i = 0
    foreach order_header_curs into l_order_header.*
        let i = i + 1
        let j_resp.results[i].order.* = l_order_header.*
        let j = 0
        foreach order_line_curs using l_order_header.oh_code into l_order_line.*
            let j = j + 1
            let j_resp.results[i].lines[j].* = l_order_line.*
        end foreach
    end foreach
    let j_resp.count = i

    let l_json_string = util.JSON.stringify(j_resp)
    return true, l_json_string
end function



function get_product(l_arglist)
define l_arglist string

define l_pr_pg_code like product.pr_pg_code

define j_resp record
    count float,
    results dynamic array of record like product.*
end record

define l_product record like product.*
define i integer
define l_where, l_sql string

define l_json_string string

    case
        when l_arglist matches "pg_code=*"
            let l_pr_pg_code = l_arglist.subString(8, l_arglist.getLength())
            let l_where = sfmt("pr_pg_code = '%1' order by pr_code" , l_pr_pg_code clipped)
        when l_arglist.getLength() = 0
            let l_where = "1=1"
        otherwise
            return false, NULL
    end case
    
    let l_sql = "select * from product where ", l_where
    declare product_curs cursor from l_sql 
    let i = 0
    foreach product_curs into l_product.*
        let i = i + 1
        let j_resp.results[i].* = l_product.*
        
    end foreach
    let j_resp.count = i

    let l_json_string = util.JSON.stringify(j_resp)
    return true, l_json_string
end function



function get_product_image(l_arglist)
define l_arglist string

define l_pr_pg_code like product.pr_pg_code
define l_pr_code like product.pr_code

define j_resp record
    count float,
    results dynamic array of record like product_image.*
end record

define l_product_image record like product_image.*
define i integer
define l_sql, l_where string

define l_json_string string

    case
        when l_arglist matches "pg_code=*"
            let l_pr_pg_code = l_arglist.subString(8, l_arglist.getLength())
            let l_where = sfmt("pi_pr_code in (select pr_code from product where pr_pg_code = '%1') " , l_pr_pg_code clipped)
        when l_arglist matches "pr_code=*"
            let l_pr_code = l_arglist.subString(8, l_arglist.getLength())
            let l_where = sfmt("pi_pr_code = '%1' " , l_pr_code clipped)
       otherwise
            return false, NULL
    end case
    
    let l_sql = "select * from product_image where ", l_where
    declare product_image_curs cursor from l_sql 
    let i = 0
    foreach product_image_curs into l_product_image.*
        let i = i + 1
        let j_resp.results[i].* = l_product_image.*
    end foreach
    let j_resp.count = i

    let l_json_string = util.JSON.stringify(j_resp)
    return true, l_json_string
end function



function get_product_image_file(l_arglist)
define l_arglist string

define l_filename string

define l_byte BYTE

define l_json_string string

    case
        when l_arglist matches "filename=*"
            let l_filename = l_arglist.subString(10, l_arglist.getLength())
       otherwise
            return false, NULL
    end case

    let l_filename = "img/", l_filename

    if not os.path.exists(l_filename) THEN
        return false, NULL
    end if

    locate l_byte in memory
    call l_byte.readFile(l_filename)

    let l_json_string = util.JSON.stringify(l_byte)
    free l_byte
    return true, l_json_string
end function



function get_product_group()

define j_resp record
    count float,
    results dynamic array of record like product_group.*
end record

define l_product_group record like product_group.*
define i integer
define l_sql string

define l_json_string string

    let l_sql = "select * from product_group order by pg_code "
    declare product_group_curs cursor from l_sql 
    let i = 0
    foreach product_group_curs into l_product_group.*
        let i = i + 1
        let j_resp.results[i].* = l_product_group.*
        
    end foreach
    let j_resp.count = i

    let l_json_string = util.JSON.stringify(j_resp)
    return true, l_json_string
end function



function get_supplier(l_arglist)
define l_arglist string

define j_resp record
    count float,
    results dynamic array of record like supplier.*
end record

define l_supplier record like supplier.*
define i integer
define l_where, l_sql string

define l_json_string string

    case
        #when l_arglist matches "group=*"
        #    let l_pr_pg_code = l_arglist.subString(7, l_arglist.getLength())
        #   let l_where = sfmt("pr_pg_code = '%1' order by pr_code" , l_pr_pg_code clipped)
        when l_arglist.getLength() = 0
            let l_where = "1=1"
        otherwise
            return false, NULL
    end case
    
    let l_sql = "select * from supplier where ", l_where
    declare supplier_curs cursor from l_sql 
    let i = 0
    foreach supplier_curs into l_supplier.*
        let i = i + 1
        let j_resp.results[i].* = l_supplier.*
        
    end foreach
    let j_resp.count = i

    let l_json_string = util.JSON.stringify(j_resp)
    return true, l_json_string
end function



function register_device(l_arglist)
define l_arglist string

define j_resp record
    count float,
    results dynamic array of record like device_registry.*
end record

define l_device_id like device_registry.dr_device_id
define l_device_registry record like device_registry.*

define l_json_string string

    case
        when l_arglist matches "device_id=*"
            let l_device_id = l_arglist.subString(11, l_arglist.getLength())
        otherwise
            return false, NULL
    end case
    
    declare device_registry_curs cursor from "select * from device_registry where dr_device_id = ? "
    open device_registry_curs using l_device_id
    fetch device_registry_curs into l_device_registry.*
    if status = notfound then
        select max(dr_idx)
        into l_device_registry.dr_idx
        from device_registry
        let l_device_registry.dr_idx = nvl(l_device_registry.dr_idx,0) + 1
        let l_device_registry.dr_device_id = l_device_id
        insert into device_registry values(l_device_registry.*)
    end if
    let j_resp.results[1].* = l_device_registry.*
    let j_resp.count = 1

    let l_json_string = util.JSON.stringify(j_resp)
    return true, l_json_string
end function



function phone_home(l_arglist)
define l_arglist string

define l_pos1, l_pos2 integer
define l_phone_home_rec record like phone_home.*

    let l_pos1 = l_arglist.getIndexOf("device_id=",1)
    if l_pos1 <0 then
        return false,"Could not identify device"
    end if
    let l_pos2 = l_arglist.getIndexOf("&", l_pos1+1)
    if l_pos2 = 0 then
        let l_pos2 = l_arglist.getLength()
    end if
    let l_phone_home_rec.ph_device_id = l_arglist.subString(l_pos1+10, l_pos2-1)

    let l_pos1 = l_arglist.getIndexOf("lat=",1)
    if l_pos1 <0 then
        return false,"Could not identify latitude"
    end if
    let l_pos2 = l_arglist.getIndexOf("&", l_pos1+1)
    if l_pos2 = 0 then
        let l_pos2 = l_arglist.getLength()
    end if
    let l_phone_home_rec.ph_lat = l_arglist.subString(l_pos1+4, l_pos2-1)

    let l_pos1 = l_arglist.getIndexOf("lon=",1)
    if l_pos1 <0 then
        return false,"Could not identify longitude"
    end if
    let l_pos2 = l_arglist.getIndexOf("&", l_pos1+1)
    if l_pos2 = 0 then
        let l_pos2 = l_arglist.getLength()
    end if
    let l_phone_home_rec.ph_lon = l_arglist.subString(l_pos1+4, l_pos2-1)

    insert into phone_home values(l_phone_home_rec.*)
    return true, ""
end function



function create_customer(s)
define s string
define j_customer record
    cu_code string,
    cu_name string,
    cu_address string,
    cu_city string,
    cu_state string,
    cu_country string,
    cu_postcode string,
    cu_phone string,
    cu_mobile string,
    cu_email string,
    cu_website string,
    cu_lat float,
    cu_lon float
end record
define l_customer record like customer.*
    display s
    try
        call util.JSON.parse(s, j_customer)
        let l_customer.cu_code = j_customer.cu_code
        let l_customer.cu_name = j_customer.cu_name
        let l_customer.cu_address = j_customer.cu_address
        let l_customer.cu_city = j_customer.cu_city
        let l_customer.cu_state = j_customer.cu_state
        let l_customer.cu_country = j_customer.cu_country
        let l_customer.cu_postcode = j_customer.cu_postcode
        let l_customer.cu_phone = j_customer.cu_phone
        let l_customer.cu_mobile = j_customer.cu_mobile
        let l_customer.cu_email = j_customer.cu_email
        let l_customer.cu_website = j_customer.cu_website
        let l_customer.cu_lat = j_customer.cu_lat
        let l_customer.cu_lon = j_customer.cu_lon 
        insert into customer values l_customer.*
    catch
        return false, "Could not insert customer" #TODO
    end try
    return true, ""
end function



function create_order(s)
define s string
define j_order record
    oh_code string,
    oh_cu_code string,
    oh_order_date string,
    oh_year float,
    oh_month float,
    oh_upload string,
    oh_order_value float,
    oh_delivery_name string,
    oh_delivery_address string,
    oh_delivery_city string,
    oh_delivery_state string,
    oh_delivery_country string,
    oh_delivery_postcode string,
    lines dynamic array of record
        ol_oh_code string,
        ol_idx float,
        ol_pr_code string,
        ol_qty float,
        ol_price float,
        ol_line_value float
    end record
end record

define l_order_header record like order_header.*
define l_order_line record like order_line.*
define i integer

    display s
    try
        begin work
        call util.JSON.parse(s, j_order)
        let l_order_header.oh_code = j_order.oh_code
        let l_order_header.oh_cu_code = j_order.oh_cu_code
        let l_order_header.oh_order_date = j_order.oh_order_date
        let l_order_header.oh_year = j_order.oh_year
        let l_order_header.oh_month = j_order.oh_month
        let l_order_header.oh_upload = j_order.oh_upload
        let l_order_header.oh_order_value = j_order.oh_order_value
        let l_order_header.oh_delivery_name = j_order.oh_delivery_name
        let l_order_header.oh_delivery_address = j_order.oh_delivery_address
        let l_order_header.oh_delivery_city = j_order.oh_delivery_city
        let l_order_header.oh_delivery_state = j_order.oh_delivery_state
        let l_order_header.oh_delivery_country = j_order.oh_delivery_country
        let l_order_header.oh_delivery_postcode = j_order.oh_delivery_postcode
        insert into order_header values (l_order_header.*)
        
        for i = 1 TO j_order.lines.getLength()
            let l_order_line.ol_oh_code = j_order.lines[i].ol_oh_code
            let l_order_line.ol_idx = j_order.lines[i].ol_idx
            let l_order_line.ol_pr_code = j_order.lines[i].ol_pr_code
            let l_order_line.ol_qty = j_order.lines[i].ol_qty
            let l_order_line.ol_price = j_order.lines[i].ol_price
            let l_order_line.ol_line_value = j_order.lines[i].ol_line_value
            
            insert into order_line values (l_order_line.*)
        end for
        commit work
    catch
        rollback work
        return false, "ERROR: Could not insert order" #TODO
    end try
    return true, ""
end function