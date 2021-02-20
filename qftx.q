\l cryptoq_binary.q
\l cryptoq.q
\l req_0.1.4.q 

subaccount:""
req.SIGNAL:0
usd:"USD"

settings:`apiHost`apiKey`apiSecret!("ftx.com";"";"")

//qtime2unix .z.Z
qtime2unix:{`long$8.64e4*10957+x};
ts:{(qtime2unix .z.Z)*1000}

//URI escaping for non-safe chars, RFC-3986
hu:.h.hug .Q.an,"-.~"        

/urlencode `abc`def`ghi!(`example;123;5.6) / "abc=example&def=123&ghi=5.6"
urlencode:{[d] /d-dictionary
 k:key d;v:value d;                      //split dictionary into keys & values
 v:enlist each hu each @[v;where 10<>type each v;string];    //string any values that aren't stringed,escape any chars that need it
 k:enlist each $[all 10=type@'k;k;string k];                 //if keys are strings, string them
 :"&" sv "=" sv' k,'v;                //return urlencoded form of dictionary
 }



//signature["";"GET";"/markets";(qtime2unix 2021.02.18T01:55:09) *1000;""] /18018b825b9036fa918535d48e0664b904fa7dabb3d144e19399f022d321fa98
signature:{[secret;verb;path;ts;data]message::`$string[ts],verb,path,data;result:.cryptoq.hmac_sha256[string[`$secret];string[message]];:raze string result};

//1.REST API (https://docs.ftx.com/#overview)

fget:{[path] 
    fullpath:"https://",(settings`apiHost),path;
    timestamp:ts[];
    sign:signature[settings`apiSecret;"GET";path;timestamp;""];
    headerDict:(`$"FTX-KEY";`$"FTX-SIGN";`$"FTX-TS")!(settings`apiKey;sign;string[timestamp]);
    $[subaccount ~ "";"";headerDict:headerDict,(enlist `$"FTX-SUBACCOUNT")!enlist subaccount];
    fr:.req.get[fullpath;headerDict];
    :fr`result; 
    }

fpost:{[path;data] 
    fullpath:"https://",(settings`apiHost),path;
    timestamp:ts[];
    sign:signature[settings`apiSecret;"POST";path;timestamp;data];
    headerDict:(`$"FTX-KEY";`$"FTX-SIGN";`$"FTX-TS";`$"content-type")!(settings`apiKey;sign;string[timestamp];"application/json");
    $[subaccount ~ "";"";headerDict:headerDict,(enlist `$"FTX-SUBACCOUNT")!enlist subaccount];
    0N! data;
    fr:.req.post[fullpath;headerDict;data]; 
    : fr`result; 
    }


lm:listMarkets:{[] lmr::fget["/api/markets"]; :((union/)key each lmr)#/:lmr; }

tb:totalBalance:{[] tbr:fget("/api/wallet/balances");:tbr}
bal:{[]
    tul:tb[];
    balr:select availableWithoutBorrow, coin, usdValue from tul where availableWithoutBorrow > 0;
    :balr
    }

tuv:totalUsdValue:{[]
    t:bal[];
    :flip select sum[usdValue] from t;
    }
/.req.VERBOSE:1 

llt:listLeveragedToken:{[name]
    ltpath:"/api/lt/",name;
    :fget[ltpath]
    }
ltp:leveragedTokenPrice:{[name]
    lltr:llt[name];
    :lltr`pricePerShare
    }
au:availableUsd:{
    b:bal[];
    aur:select free:availableWithoutBorrow from b where coin like "USD";
    :first[aur`free]
    }

scn:showConvertNumber:{[name]
    ltpi:ltp[name];
    aui:au[];
    :aui%ltpi
    }
slcn:showLessConvertNumber:{[name]
    ltpi:ltp[name];
    aui:au[]-500;
    :aui%ltpi
    }

ltc:leveragedTokenCreate:{[name;size]
    fullapi:"/api/lt/",name,"/create";
    params:(enlist `size)!enlist size;
    jParams:.j.j params;
    r:fpost[fullapi;jParams];
    :r
    }

ltr:leveragedTokenReedeem:{[name;size]
    fullapi:"/api/lt/",name,"/redeem";
    params:(enlist `size)!enlist size;
    jParams:.j.j params;
    r:fpost[fullapi;jParams];
    :r
    }


gcq:getConvertQuote:{[fc;tc;size]
    fullapi:"/api/otc/quotes";
    params:`fromCoin`toCoin`size!(fc;tc;size);
    jParams:.j.j params;
    gcpr: fpost[fullapi;jParams];
    : `long$gcpr`quoteId
    }
gqs:getQuoteStatus:{[id]
    fullapi:"/api/otc/quotes/",string[id];
    :fget[fullapi]
    }

//need test
aq:accetpQuote:{[id]
    fullapi:"/api/otc/quotes/",string[id],"/accept";
    :fpost[fullapi]
    }
tbs:transferBetweenSub:{[coin;size;source;dest]
    fullapi:"/api/subaccounts/transfer";
    params:`coin`size`source`destination!(coin;size;source;dest);
    jParams:.j.j params;
    tbsr: fpost[fullapi;jParams];
    :tbsr;
    }

hu2lt:halfUsdToLeverageToken:{[name]
    cn:scn[name];
    size:cn*0.5;
    :ltc[name;size] 
    }

au2lt:allUsdToLeverageToken:{[name]
    cn:scn[name];
    size:cn*0.93;
    :ltc[name;size] 
    }

alt2u:allLeverageTokenToUsd:{[name]
    b:bal[];
    x:select from b where coin like name;
    size:first (flip x)`availableWithoutBorrow;
    :ltr[name;size];
    }


cq:convert_quote:{[fquote;toquote]
    b:bal[];
    a:select from b where cion like fquote;
    s:fisrt first (flip a)`availableWithoutBorrow;
    i = gfq[fquote;toquote;s];
    :aq[i];
    }

/get_with_params
ap:allPerp:{[] lmr:lm[];:flip select name from s where name like "*PERP"}



lh:listLendingHistory:{[]
    path:"/api/spot_margin/lending_history";
    :fget[path]
    }

/ filter usd like/: ("USD";"USDT") 
llr:listLeningRate:{[name]
    path:"/api/spot_margin/lending_rates";
    llrr:fget[path];
    : select coin, estimate: estimate * 24 * 365, previous:previous * 24 * 365 from llrr
    }

gli:getLendingInfo:{[name]
    path:"/api/spot_margin/lending_info";
    :fget[path]
    }

lf:loanOffer:{[coin;size]
    fullapi:"/api/spot_margin/offers";
    rate: (10f%24)%365; 
    params:`coin`size`rate!(coin;size;rate);
    jParams:.j.j params;
    gcpr: fpost[fullapi;jParams];
    :gcpr 
    }
