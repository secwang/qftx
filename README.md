# qftx
 kdb+/q interface for FTX API (REST ONLY)

--- 

use CryptoQ: https://github.com/asatirahul/cryptoq for HMACSHA256  
Use req for https/custom header: https://github.com/jonathonmcmurray/reQ  
Special thanks to https://github.com/drzwz/qbitmex  


### First, fill api and sec in settings like.

```
settings:`apiHost`apiKey`apiSecret!("ftx.com";"xxxx";"xxx")   //here

```
Now you can see your balance with 

```
bal[]
```

Play with fget/fpost function.  
```
fget{[path]}
fpost:{[path;data]}
```
Can support most of the restapi, but I did not fully implement, implemented some personal commonly used.

--- 
support subaccount by setting

```
subaccount:"other"
```
