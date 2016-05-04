


### postgresql only


#mxCreateViewToken <- function(string,key="hello",view="sampleview",user='1',session="1234"){

  #string <- jsonlite::toJSON(
    #string,
    #auto_unbox=TRUE
    #);

  #q <- sprintf("
    #SELECT jsonb_array_elements(data->'group') 
    #FROM tmp_users 
    #WHERE id = %s ;",)



      ##select convert_from(decrypt(decode('8khnrJBT4V4EgrthLcA71ESJkjsNGSfOA9W6pKJa0EA=','base64'),'hello','aes'),'SQL_ASCII')





      #### R AND NODE



      #encrypt = function(string,password="hello"){

        #string = jsonlite::toJSON(
          #string,
          #auto_unbox=TRUE
          #);

        #key <- digest(
          #password,
          #"sha256",
          #serialize=F,
          #raw=T
          #)
        #print("key:")
        #print(key)
        #print("---")
        #aes <- AES(
          #key,
          #"ECB"
          #)

        #raw <- charToRaw(
          #string
          #)

        #enc <- aes$encrypt(
          #c(
            #raw,
            #as.raw(
              #rep(0,32-length(raw)%%32)
              #)
            #)
          #)
        #return(enc)

      #}


      #decrypt = function(string,password="hello"){

        #key <- digest(
          #password,
          #"sha256",
          #serialize=F,
          #raw=T
          #)

        #aes <- AES(
          #key,
          #"ECB"
          #)
        #dec <- aes$decrypt(string,raw = FALSE)

        #dec <- jsonlite::fromJSON(dec,simplifyVector=FALSE);
        #return(dec)
      #}


      #decrypt(encrypt("ya"))






      ### node js

      #// Part of https://github.com/chris-rock/node-crypto-examples

      #var crypto = require('crypto'),
      #algorithm = 'aes-256-ecb',
      #key = crypto.createHash('sha256').update('hello').digest();

      #function encrypt(text){
        #console.log("key:")
        #console.log(key);
        #console.log("---");
        #iv = new Buffer(0);
        #var cipher = crypto.createCipheriv(algorithm,key,iv)
        #var crypted = cipher.update(text,'utf8','hex')
        #crypted += cipher.final('hex');
        #return crypted;
      #}

      #function decrypt(text){
        #var decipher = crypto.createDecipher(algorithm,key)
        #var dec = decipher.update(text,'hex','utf8')
        #dec += decipher.final('utf8');
        #return dec;
      #}

      #var hw = encrypt("hello world")
      #// outputs hello world
      #console.log(decrypt(hw));
