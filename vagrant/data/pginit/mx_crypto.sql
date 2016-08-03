-- encryption

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- http://stackoverflow.com/questions/13598704/pgp-sym-encrypt-pgp-sym-decrypt-error-handling 

CREATE OR REPLACE FUNCTION mx_decrypt(data text, psw text) RETURNS text AS $$
BEGIN
  RETURN pgp_sym_decrypt(decode(data,'hex'),psw);
  EXCEPTION
WHEN others THEN
  RAISE USING
  MESSAGE = format('Decryption failed. sqlstate: %s, message: %s',
    SQLSTATE,SQLERRM);
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION mx_encrypt(data text, psw text) RETURNS text AS $$
BEGIN
  RETURN encode(pgp_sym_encrypt(data,psw),'hex');
  EXCEPTION
WHEN others THEN
  RAISE USING
  MESSAGE = format('Encryption failed. sqlstate: %s, message: %s',
    SQLSTATE,SQLERRM);
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;



