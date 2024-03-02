declare  
   Sequence_Name VARCHAR2(100);
   V_MaxValue NUMBER(8);
begin
   for Seq_Record in (
      select object_name
      from user_objects
      where object_type = 'SEQUENCE'
   ) loop
      Sequence_Name := Seq_Record.object_name;
      execute immediate 'DROP SEQUENCE ' || Sequence_Name;  --Dropping Sequence
   end loop;


--active set to select columns with primarykey constraints
   for C_Record in (
      select acc.column_name as Column_Name, acc.table_name as table_Name
      from all_cons_columns acc, all_constraints ac, user_tab_columns tc
      where acc.constraint_name = ac.constraint_name
         and acc.table_name = tc.table_name
         and acc.column_name = tc.column_name
         and ac.constraint_type = 'P'
         and tc.data_type in ('NUMBER', 'INTEGER')
         and NOT EXISTS (
            SELECT 1
            from user_cons_columns acc2, user_constraints ac2
            where acc2.constraint_name = ac2.constraint_name
               and ac2.constraint_type = 'P'
               and acc.table_name = acc2.table_name
               and acc.column_name <> acc2.column_name
         )
   ) loop
      execute immediate 'select nvl(max(' || C_Record.Column_Name || '), 0) + 1 from ' || C_Record.table_Name into V_MaxValue; 

      execute immediate 'create sequence SEQ_' || C_Record.table_Name || ' start with ' || V_MaxValue || ' increment by 1 maxvalue 9999999999999999999';       --Creating Sequence 
--trigger that assigns the next value from the sequence to the column of the new row being inserted
      execute immediate 'create or replace trigger TRG_' || C_Record.table_Name || '_pk   
                           BEFORE insert ON ' || C_Record.table_Name || '
                           for each row
                           begin
                              :new.' || C_Record.Column_Name || ' := SEQ_' || C_Record.table_Name || '.nextval;
                           end;';
   end loop;
end;
Show errors; 
