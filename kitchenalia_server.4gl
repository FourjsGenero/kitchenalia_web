import xml
import com
import util

main
define request com.HttpServiceRequest  
define str string
define ok smallint
define desc string 
      
    defer interrupt

    # TODO do I need this?
    call util.math.srand()
    
    # starts the server on the port number specified by the fglappserver environment variable
    display "Starting server..."
    call com.WebServiceEngine.Start()
    display "The server is listening."
    connect to "kitchenalia"

    while true
        try
            let request = com.WebServiceEngine.GetHttpServiceRequest(-1)
        catch
            if int_flag then
                let int_flag = 0
                display "Service Interrupted"
            else
                display "Request Error"
            end if
            exit while
        end try
        if request is null then
            exit while
        end if
        display sfmt("Processing %1", request.geturl())
       
        call process_http_request(request) returning ok, str,  desc

        case
            when str is not null
                call request.sendTextResponse(200, "", str)
            when ok # ok but no xml document, e.g. favicon.ico call
                call request.sendResponse(200, "")
            otherwise # an error of some form, an unspecified method
                call request.sendResponse(400, desc)
        end case
    end while
    display "server stopped"
end main



function process_http_request(request)
define request com.HttpServiceRequest  
define url string

define ok smallint
define str string
define desc string

define address, method, arglist string

    let url = request.getUrl()
    
    
    # turn the url into the address, method, and a list of arguments
    call split_url(url) returning address, method, arglist

    case method
        -- Get Data via URL
        when "get_customer"
            call get_customer(arglist) returning ok, str

        when "get_group_analysis"
            call get_group_analysis(arglist) returning ok, str

        when "get_time_analysis"
            call get_time_analysis(arglist) returning ok, str

        when "get_time_group_analysis"
            call get_time_group_analysis(arglist) returning ok, str

        when "get_order"
            call get_order(arglist) returning ok, str
        
        when "get_product"
            call get_product(arglist) returning ok, str

        when "get_product_group"
            call get_product_group() returning ok, str

        when "get_product_image"
            call get_product_image(arglist) returning ok, str

        when "get_product_image_file"
            call get_product_image_file(arglist) returning ok, str

        when "get_supplier"
            call get_supplier(arglist) returning ok, str

        -- Simple insert via URL
        when "phone_home"
            display arglist
            call phone_home(arglist) returning ok, str

        when "register_device"
            call register_device(arglist) returning ok, str

        -- Complex insert via TextRequest
        when "create_customer"
            call create_customer(request.readTextRequest()) returning ok, str

        when "create_order"
            call create_order(request.readTextRequest()) returning ok, str
            
        -- Miscellaneous
        when "favicon.ico"
            # ignore this method, called if enter url in a browser 
            let ok = true
            let str = null
            let desc = ""
         
        otherwise
            # return some error if any other method is called
            let ok = false
            let str = null
            let desc =  "unspecified method"
    end case
   
    return ok, str, desc
end function



FUNCTION split_url(url)
DEFINE url, address, method, arglist STRING
DEFINE argpos, i INTEGER

    # The argument list is what appears after the ?
    LET argpos = url.getIndexOf("?",1)
    IF argpos > 0 THEN
        LET arglist = url.SubString(argpos+1, url.getLength())
    ELSE
        LET argpos = url.getLength() + 1
        LET arglist = ""
    END IF

    # Before the argument list, the address and method are seperated
    # by the last /
    LET i = argpos
    WHILE i > 0 
        LET i = i - 1
        IF url.getCharAt(i) = "/" THEN
            LET address = url.SubString(1, i-1)
            LET method = url.SubString(i+1, argpos-1)
            EXIT WHILE
        END IF
    END WHILE
    IF i <= 0 THEN
        LET address = url.SubString(1, argpos-1)
        LET method = ""
    END IF
    RETURN address, method, arglist
END FUNCTION



# A lit of test URL's
{
http://localhost:8096/ws/r/kitchenalia/get_product
http://localhost:8096/ws/r/kitchenalia/get_customer
http://localhost:8096/ws/r/kitchenalia/get_supplier
http://localhost:8096/ws/r/kitchenalia/get_product_group
http://localhost:8096/ws/r/kitchenalia/get_product_image?pg_code=114
http://localhost:8096/ws/r/kitchenalia/get_product_image_file?filename=93040500PDM001B.jpg

http://localhost:8096/ws/r/kitchenalia/get_order?cu_code=BRTA0003

http://localhost:8096/ws/r/kitchenalia/get_group_analysis?cu_code=BRTA0003
http://localhost:8096/ws/r/kitchenalia/get_time_analysis?cu_code=BRTA0003
http://localhost:8096/ws/r/kitchenalia/get_time_analysis?pg_code=114




}