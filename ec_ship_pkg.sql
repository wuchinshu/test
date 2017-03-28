DECLARE
   wk_received_id NUMBER := 3636;
   wk_txn_type    ec_txn_types%ROWTYPE;
   CURSOR c1 IS
      SELECT pr.received_id,
             pr.vendor_ship_date,
             pl.line_id,
             ph.po_no,
             pr.qty,
             pl.ecommerce
        FROM ec_po_receives pr,
             ec_po_lines    pl,
             ec_po_headers  ph
       WHERE pr.po_line_id = pl.line_id
         AND pl.header_id = ph.header_id
         AND pr.received_id = wk_received_id;
   PROCEDURE gen_txn(p_org_id       NUMBER,
                     p_item_id      NUMBER,
                     p_subinventory VARCHAR2,
                     p_txn_type_id  NUMBER,
                     p_qty          NUMBER,
                     p_txn_date     DATE,
                     p_source_name  VARCHAR2,
                     p_source_id    NUMBER) IS
      wk_qty         NUMBER;
      wk_user        VARCHAR2(30);
      wk_id          NUMBER;
      wk_txn_type    VARCHAR2(100);
      wk_row_id      VARCHAR2(60);
      wk_item_number VARCHAR2(60);
   BEGIN
      SELECT osuser INTO wk_user FROM v$session WHERE audsid = userenv('sessionid');
      SELECT ec_id.nextval INTO wk_id FROM dual;
      SELECT txn_type,
             storage_flag
        INTO wk_txn_type,
             wk_storage_flag
        FROM ec_txn_types
       WHERE txn_type_id = p_txn_type_id;
      IF storage_flag = 2 THEN
         wk_qty = -p_qty;
      ELSE
         wk_qty = p_qty;
      END IF;
      INSERT INTO ec_txns
         (org_id,
          txn_id,
          txn_type_id,
          txn_type,
          txn_date,
          source_name,
          source_id,
          subinventory,
          qty,
          creation_date,
          created_by,
          item_id,
          received_id)
      VALUES
         (p_org_id,
          p_txn_id,
          p_txn_type_id,
          wk_txn_type,
          p_txn_date,
          p_source_name,
          p_source_id,
          p_subinventory,
          p_qty,
          SYSDATE, -- creation_date, 
          wk_user, -- created_by, 
          p_item_id,
          p_received_id);
   
      BEGIN
         SELECT ROWID row_id,
                qty
           INTO o.row_id,
                o_qty
           FROM ec_onhands
          WHERE org_id = p_org_id, item_id = p_item_id, subinventory = p_subinventory;
         UPDATE ec_onhands SET qty = qty WHERE ROWID = wk_row_id;
      
      EXCEPTION
         WHEN no_data_found THEN
            SELECT item_number
              INTO wk_item_number
              FROM ec_item_numbers
             WHERE org_id = p_org_id, item_id = p_item_id;
            INSERT INTO ec_onhands
            VALUES
               (org_id,
                item_id,
                item_number,
                subinventory,
                qty,
                creation_date,
                created_by)
            VALUES
               (p_org_id,
                p_item_id,
                wk_item_number,
                p_subinventory,
                wk_qty,
                SYSDATE,
                wk_user);
      END;
   END gen_txn;
BEGIN
   FOR c1r IN c1 LOOP
      IF c1r.ecommerce IN ('網路家庭國際資訊股份有限公司') THEN
         wk_subinventory = 'T1-PH';
      ELSE
         IF p_org_id = 108 THEN
            wk_subinventory = 'T1-PH';
         ELSIF p_org_id = 107 THEN
            wk_subinventory = 'U1';
         ELSIF p_org_id = 107 THEN
            wk_subinventory = 'H1';
         END IF;
      END IF;
      --        select * from ec_ecommerces 
      gen_txn(p_org_id - > c1r.org_id,
              p_item_id - > c1r.item_id,
              p_subinventory - > wk_subinventory,
              p_txn_type_id - > wk_txn_type_id,
              p_qty - > c1r.qty p_txn_date - > c1r.vendor_ship_date,
              p_source_name - > c1r.po_no,
              p_source_id - > c1r.line_id);
   
   END LOOP;
END;


-- select * from 
