BEGIN
  DBMS_NETWORK_ACL_ADMIN.CREATE_ACL(
    acl         => 'crop_acl.xml',
    description => 'Allow access to Crop API',
    principal   => 'SYSTEM',
    is_grant    => TRUE,
    privilege   => 'connect'
  );
END;
/
BEGIN
  DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(
    acl       => 'crop_acl.xml',
    principal => 'SYSTEM',
    is_grant  => TRUE,
    privilege => 'resolve'
  );
END;
/
BEGIN
  DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(
    acl  => 'crop_acl.xml',
    host => '192.168.137.1'
  );
END;
/
COMMIT;
SELECT acl, host, lower_port, upper_port FROM dba_network_acls;
SELECT * FROM dba_network_acl_privileges WHERE principal = 'SYSTEM';

SET SERVEROUTPUT ON;

DECLARE
  -- User input values
  n_val         NUMBER := &Enter_Nitrogen;
  p_val         NUMBER := &Enter_Phosphorus;
  k_val         NUMBER := &Enter_Potassium;
  temp_val      NUMBER := &Enter_Temperature;
  humidity_val  NUMBER := &Enter_Humidity;
  ph_val        NUMBER := &Enter_pH;
  rain_val      NUMBER := &Enter_Rainfall;

  -- HTTP communication variables
  req           UTL_HTTP.req;
  resp          UTL_HTTP.resp;
  url           VARCHAR2(500) := 'http://192.168.137.1:8000/predict_crop';  -- ✅ Your local FastAPI server IP
  response_text VARCHAR2(32767);
  buffer        VARCHAR2(32767);
  json_body     VARCHAR2(1000);
BEGIN
  -- Prepare JSON payload
  json_body := '{"N":' || n_val ||
               ',"P":' || p_val ||
               ',"K":' || k_val ||
               ',"temperature":' || temp_val ||
               ',"humidity":' || humidity_val ||
               ',"ph":' || ph_val ||
               ',"rainfall":' || rain_val || '}';

  -- Initialize HTTP request
  req := UTL_HTTP.begin_request(url, 'POST', 'HTTP/1.1');
  UTL_HTTP.set_header(req, 'Content-Type', 'application/json');
  UTL_HTTP.write_text(req, json_body);

  -- Get the response
  resp := UTL_HTTP.get_response(req);

  LOOP
    UTL_HTTP.read_line(resp, buffer, TRUE);
    response_text := response_text || buffer;
  END LOOP;

  -- Display response
  DBMS_OUTPUT.put_line('Prediction Result: ' || response_text);

  -- Close response
  UTL_HTTP.end_response(resp);

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.put_line('Error: ' || SQLERRM);
END;
/
