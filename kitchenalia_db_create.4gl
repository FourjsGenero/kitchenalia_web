
IMPORT util
SCHEMA kitchenalia

MAIN
    CONNECT TO "kitchenalia"
    
    WHENEVER ANY ERROR CONTINUE
    CALL db_drop_tables()

    WHENEVER ANY ERROR STOP
    CALL db_create_tables()
    CALL db_populate()
    CALL db_add_indexes()
    CALL db_randomize()
END MAIN


FUNCTION db_populate()
DEFINE l_count INTEGER
    DISPLAY "Load Product Group"
    LOAD FROM "product_group.unl" INSERT INTO product_group
    SELECT COUNT(*) INTO l_count FROM product_group
    DISPLAY l_count , " rows loaded"
    
    DISPLAY "Load Product"
    LOAD FROM "product.unl" INSERT INTO product
    SELECT COUNT(*) INTO l_count FROM product
    DISPLAY l_count , " rows loaded"
    
    DISPLAY "Load Product Image"
    LOAD FROM "product_image.unl" INSERT INTO product_image
    SELECT COUNT(*) INTO l_count FROM product_image
    DISPLAY l_count , " rows loaded"

    DISPLAY "Load Supplier"
    LOAD FROM "supplier.unl" INSERT INTO supplier
    SELECT COUNT(*) INTO l_count FROM supplier
    DISPLAY l_count , " rows loaded"
    
    DISPLAY "Load Customer"
    LOAD FROM "customer.unl" INSERT INTO customer
    SELECT COUNT(*) INTO l_count FROM customer
    DISPLAY l_count , " rows loaded"
 
END FUNCTION



#+ Create all tables in database.
FUNCTION db_create_tables()
    WHENEVER ERROR STOP
    DISPLAY db_get_database_type()
    -- Note: You need to create the database create script for each database type
    CASE db_get_database_type()
        WHEN "IFX"

    -- Following code is cut and paste from database creation script when Informix specified
    EXECUTE IMMEDIATE "CREATE TABLE product (
        pr_code CHAR(8) NOT NULL,
        pr_desc VARCHAR(80) NOT NULL,
        pr_pg_code CHAR(3) NOT NULL,
        pr_price DECIMAL(11,2) NOT NULL,
        pr_barcode VARCHAR(20),
        pr_su_code CHAR(8))"
    EXECUTE IMMEDIATE "CREATE TABLE product_image (
        pi_pr_code CHAR(8) NOT NULL,
        pi_idx INTEGER NOT NULL,
        pi_filename VARCHAR(80) NOT NULL,
        pi_changed DATETIME YEAR TO SECOND NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE product_group (
        pg_code CHAR(3) NOT NULL,
        pg_desc VARCHAR(80) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE device_registry (
        dr_idx INTEGER NOT NULL,
        dr_device_id VARCHAR(50) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE phone_home (
        ph_device_id VARCHAR(50),
        ph_lat DECIMAL(10,6),
        ph_lon DECIMAL(10,6))"
    EXECUTE IMMEDIATE "CREATE TABLE customer (
        cu_code CHAR(8) NOT NULL,
        cu_name VARCHAR(80) NOT NULL,
        cu_address VARCHAR(255),
        cu_city VARCHAR(80),
        cu_state CHAR(2),
        cu_country VARCHAR(80),
        cu_postcode CHAR(10),
        cu_phone CHAR(15),
        cu_mobile CHAR(15),
        cu_email VARCHAR(30),
        cu_website VARCHAR(40),
        cu_lat DECIMAL(10,6),
        cu_lon DECIMAL(10,6))"
    EXECUTE IMMEDIATE "CREATE TABLE order_header (
        oh_code CHAR(10) NOT NULL,
        oh_cu_code CHAR(8) NOT NULL,
        oh_order_date DATE NOT NULL,
        oh_year SMALLINT,
        oh_month SMALLINT,
        oh_upload DATETIME YEAR TO SECOND,
        oh_order_value DECIMAL(11,2),
        oh_delivery_name VARCHAR(80),
        oh_delivery_address VARCHAR(255),
        oh_delivery_city VARCHAR(80),
        oh_delivery_state CHAR(2),
        oh_delivery_country VARCHAR(80),
        oh_delivery_postcode CHAR(10))"
    EXECUTE IMMEDIATE "CREATE TABLE order_line (
        ol_oh_code CHAR(10) NOT NULL,
        ol_idx INTEGER NOT NULL,
        ol_pr_code CHAR(8) NOT NULL,
        ol_qty DECIMAL(11,2) NOT NULL,
        ol_price DECIMAL(11,2) NOT NULL,
        ol_line_value DECIMAL(11,2) NOT NULL)"
    EXECUTE IMMEDIATE "CREATE TABLE supplier (
        su_code CHAR(8) NOT NULL,
        su_name VARCHAR(80) NOT NULL,
        su_address VARCHAR(255),
        su_city VARCHAR(80),
        su_state CHAR(2),
        su_country VARCHAR(80),
        su_postcode CHAR(10),
        su_phone CHAR(15),
        su_mobille CHAR(15),
        su_email VARCHAR(30),
        su_website VARCHAR(40),
        su_lat DECIMAL(10,6),
        su_lon DECIMAL(10,6))"

        WHEN "SQT"

    -- Following code is cut and paste from database creation script when SQLite specified
   EXECUTE IMMEDIATE "CREATE TABLE product (
        pr_code CHAR(8) NOT NULL,
        pr_desc VARCHAR(80) NOT NULL,
        pr_pg_code CHAR(3) NOT NULL,
        pr_price DECIMAL(11,2) NOT NULL,
        pr_barcode VARCHAR(20),
        pr_su_code CHAR(8),
        CONSTRAINT pk_product_1 PRIMARY KEY(pr_code),
        CONSTRAINT fk_product_product_group_1 FOREIGN KEY(pr_pg_code)
            REFERENCES product_group(pg_code),
        CONSTRAINT fk_product_supplier_1 FOREIGN KEY(pr_su_code)
            REFERENCES supplier(su_code))"
    EXECUTE IMMEDIATE "CREATE TABLE product_image (
        pi_pr_code CHAR(8) NOT NULL,
        pi_idx INTEGER NOT NULL,
        pi_filename VARCHAR(80) NOT NULL,
        pi_changed DATETIME YEAR TO SECOND NOT NULL,
        CONSTRAINT pk_product_image_1 PRIMARY KEY(pi_pr_code, pi_idx),
        CONSTRAINT fk_product_image_product_1 FOREIGN KEY(pi_pr_code)
            REFERENCES product(pr_code))"
    EXECUTE IMMEDIATE "CREATE TABLE product_group (
        pg_code CHAR(3) NOT NULL,
        pg_desc VARCHAR(80) NOT NULL,
        CONSTRAINT pk_product_group_1 PRIMARY KEY(pg_code))"
    EXECUTE IMMEDIATE "CREATE TABLE device_registry (
        dr_idx INTEGER NOT NULL,
        dr_device_id VARCHAR(50) NOT NULL,
        CONSTRAINT pk_device_registry_1 PRIMARY KEY(dr_idx))"
    EXECUTE IMMEDIATE "CREATE TABLE phone_home (
        ph_device_id VARCHAR(50),
        ph_lat DECIMAL(10,6),
        ph_lon DECIMAL(10,6))"
    EXECUTE IMMEDIATE "CREATE TABLE customer (
        cu_code CHAR(8) NOT NULL,
        cu_name VARCHAR(80) NOT NULL,
        cu_address VARCHAR(255),
        cu_city VARCHAR(80),
        cu_state CHAR(2),
        cu_country VARCHAR(80),
        cu_postcode CHAR(10),
        cu_phone CHAR(15),
        cu_mobile CHAR(15),
        cu_email VARCHAR(30),
        cu_website VARCHAR(40),
        cu_lat DECIMAL(10,6),
        cu_lon DECIMAL(10,6),
        CONSTRAINT pk_customer_1 PRIMARY KEY(cu_code))"
    EXECUTE IMMEDIATE "CREATE TABLE order_header (
        oh_code CHAR(10) NOT NULL,
        oh_cu_code CHAR(8) NOT NULL,
        oh_order_date DATE NOT NULL,
        oh_year SMALLINT,
        oh_month SMALLINT,
        oh_upload DATETIME YEAR TO SECOND,
        oh_order_value DECIMAL(11,2),
        oh_delivery_name VARCHAR(80),
        oh_delivery_address VARCHAR(255),
        oh_delivery_city VARCHAR(80),
        oh_delivery_state CHAR(2),
        oh_delivery_country VARCHAR(80),
        oh_delivery_postcode CHAR(10),
        CONSTRAINT pk_order_header_1 PRIMARY KEY(oh_code),
        CONSTRAINT fk_order_header_customer_1 FOREIGN KEY(oh_cu_code)
            REFERENCES customer(cu_code))"
    EXECUTE IMMEDIATE "CREATE TABLE order_line (
        ol_oh_code CHAR(10) NOT NULL,
        ol_idx INTEGER NOT NULL,
        ol_pr_code CHAR(8) NOT NULL,
        ol_qty DECIMAL(11,2) NOT NULL,
        ol_price DECIMAL(11,2) NOT NULL,
        ol_line_value DECIMAL(11,2) NOT NULL,
        CONSTRAINT pk_order_line_1 PRIMARY KEY(ol_oh_code, ol_idx),
        CONSTRAINT fk_order_line_order_header_1 FOREIGN KEY(ol_oh_code)
            REFERENCES order_header(oh_code),
        CONSTRAINT fk_order_line_product_1 FOREIGN KEY(ol_pr_code)
            REFERENCES product(pr_code))"
    EXECUTE IMMEDIATE "CREATE TABLE supplier (
        su_code CHAR(8) NOT NULL,
        su_name VARCHAR(80) NOT NULL,
        su_address VARCHAR(255),
        su_city VARCHAR(80),
        su_state CHAR(2),
        su_country VARCHAR(80),
        su_postcode CHAR(10),
        su_phone CHAR(15),
        su_mobille CHAR(15),
        su_email VARCHAR(30),
        su_website VARCHAR(40),
        su_lat DECIMAL(10,6),
        su_lon DECIMAL(10,6),
        CONSTRAINT pk_supplier_1 PRIMARY KEY(su_code))"
        OTHERWISE
            DISPLAY "ERROR - No Tables Created, unknown database type"
    END CASE
END FUNCTION

#+ Drop all tables from database.
FUNCTION db_drop_tables()
    WHENEVER ERROR CONTINUE

    EXECUTE IMMEDIATE "DROP TABLE product"
    EXECUTE IMMEDIATE "DROP TABLE product_image"
    EXECUTE IMMEDIATE "DROP TABLE product_group"
    EXECUTE IMMEDIATE "DROP TABLE device_registry"
    EXECUTE IMMEDIATE "DROP TABLE phone_home"
    EXECUTE IMMEDIATE "DROP TABLE customer"
    EXECUTE IMMEDIATE "DROP TABLE order_header"
    EXECUTE IMMEDIATE "DROP TABLE order_line"
    EXECUTE IMMEDIATE "DROP TABLE supplier"

END FUNCTION

#+ Add indexes for all tables.
FUNCTION db_add_indexes()
    WHENEVER ERROR STOP

    EXECUTE IMMEDIATE "CREATE INDEX idx_product_1 ON product(pr_desc, pr_code)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_product_2 ON product(pr_pg_code, pr_code)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_product_group_1 ON product_group(pg_desc, pg_code)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_customer_1 ON customer(cu_name, cu_code)"
    EXECUTE IMMEDIATE "CREATE INDEX idx_supplier_1 ON supplier(su_name, su_code)"

END FUNCTION


FUNCTION db_randomize()

DEFINE i,j INTEGER

DEFINE l_supplier_arr DYNAMIC ARRAY OF CHAR(8) 
DEFINE l_customer_arr DYNAMIC ARRAY OF CHAR(8) 
DEFINE l_product_arr DYNAMIC ARRAY OF CHAR(8) 

DEFINE l_pr RECORD LIKE product.*
DEFINE l_cu RECORD LIKE customer.*
DEFINE l_su RECORD LIKE supplier.*
DEFINE l_oh RECORD LIKE order_header.*
DEFINE l_ol RECORD LIKE order_line.*

DEFINE l_oh_line_count INTEGER
CONSTANT TOTAL_ORDERS = 100

    -- Put list into array, makes getting random value easier
    DECLARE supplier_curs CURSOR FROM "SELECT su_code FROM supplier"
    FOREACH supplier_curs INTO l_su.su_code
        LET l_supplier_arr[l_supplier_arr.getLength()+1] = l_su.su_code
    END FOREACH
    
    DECLARE customer_curs CURSOR FROM "SELECT cu_code FROM customer"
    FOREACH customer_curs INTO l_cu.cu_code
        LET l_customer_arr[l_customer_arr.getLength()+1] = l_cu.cu_code
    END FOREACH
    
    DECLARE product_curs  CURSOR FROM "SELECT pr_code FROM product"
    FOREACH product_curs INTO l_pr.pr_code
        LET l_product_arr[l_product_arr.getLength()+1] = l_pr.pr_code
    END FOREACH

    DISPLAY "Update Product data"
    FOR i = 1 TO l_product_arr.getLength()
        LET l_pr.pr_code = l_product_arr[i]
        LET l_pr.pr_price = (util.Math.rand(20000) + 500)/100
        LET l_pr.pr_su_code = l_supplier_arr[util.Math.rand(l_supplier_arr.getLength())+1]
        
        UPDATE product
        SET pr_price = l_pr.pr_price,
            pr_su_code = l_pr.pr_su_code
        WHERE pr_code = l_pr.pr_code
    END FOR

    FOR i = 1 TO TOTAL_ORDERS
        DISPLAY "Insert Order ", i
        LET l_oh.oh_code = "BR", i USING "&&&&&&"
        LET l_oh.oh_cu_code = l_customer_arr[util.Math.rand(l_customer_arr.getLength())+1]

        SELECT cu_address, cu_city, cu_country, cu_name, cu_postcode, cu_state
        INTO l_oh.oh_delivery_address, l_oh.oh_delivery_city, l_oh.oh_delivery_country, l_oh.oh_delivery_name, l_oh.oh_delivery_postcode, l_oh.oh_delivery_state
        FROM customer
        WHERE cu_code = l_oh.oh_cu_code
        
        LET l_oh.oh_order_date = TODAY - 365 + (365*i/TOTAL_ORDERS)
        LET l_oh.oh_year  = YEAR(l_oh.oh_order_date)
        LET l_oh.oh_month = MONTH(l_oh.oh_order_date)
        LET l_oh.oh_order_value = 0
        LET l_oh.oh_upload = CURRENT YEAR TO SECOND

        LET l_oh_line_count = util.Math.rand(45)+5

        INSERT INTO order_header VALUES(l_oh.*)
        
        FOR j = 1 TO l_oh_line_count
            LET l_ol.ol_idx = j
            
            LET l_ol.ol_oh_code = l_oh.oh_code
            LET l_ol.ol_pr_code = l_product_arr[util.Math.rand(l_product_arr.getLength())+1]

            SELECT pr_price
            INTO l_ol.ol_price
            FROM product
            WHERE pr_code = l_ol.ol_pr_code

            LET l_ol.ol_qty = util.math.rand(100)+1
            LET l_ol.ol_line_value = l_ol.ol_price * l_ol.ol_qty
            LET l_oh.oh_order_value = l_oh.oh_order_value + l_ol.ol_line_value
            INSERT INTO order_line VALUES(l_ol.*)
        END FOR

        UPDATE order_header
        SET oh_order_value = l_oh.oh_order_value
        WHERE oh_code = l_oh.oh_code
    END FOR
END FUNCTION