   select 'alter system kill session ''' || sid || ',' || serial# || ''';' from v$session where username = 'Ora_PayUser01'

     DROP USER Ora_PayUser01 cascade;
