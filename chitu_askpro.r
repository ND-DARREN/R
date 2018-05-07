## 抓取商品咨询数据
conn=odbcConnectAccess2007(zydb_dir)

st <- max(as.Date(sqlQuery(conn,'select distinct 日期 from 赤兔_商品咨询')$日期))+1
days <- seq.Date(st+1, Sys.Date()-1, by='day')
chitu_askpro=data.frame()
for (day in as.character(days)){
  b$navigate(paste('https://newkf.topchitu.com/ww/wwitemchat.xlsx?t=',str_sub(as.character(as.numeric(Sys.time())*1000),1,13),'&_csrf=482169615&datepick_type=day&from=',day,'&to=',day,'&monthFrom=2017-01&monthTo=2017-02&quickTime=&wwgroupId=&wangwangNick=&itemGroupSelect=all&itemGroupId=&itemGroupName=&flg=0&groupName=%E5%85%A8%E9%83%A8',sep=''))
  repeat{if(file.exists(paste('客服商品咨询分析_',day,'至',day,'_全部','.xlsx',sep=''))){break()}}
  chitu=read.xlsx(paste('客服商品咨询分析_',day,'至',day,'_全部','.xlsx',sep=''),1, encoding="UTF-8")
  chitu=chitu[1:(nrow(chitu)-2),]
  chitu=data.frame(日期=day,chitu)
  chitu_askpro=rbind(chitu_askpro,chitu)
}
chitu_askpro$购买占比=as.numeric(gsub("%","",chitu_askpro$购买占比))/100

if(nrow(chitu_askpro)>0&ncol(chitu_askpro)==8){
  sqlSave(conn,chitu_askpro,tablename = '赤兔_商品咨询',rownames =FALSE, append = T)
  print(paste('已抓取赤兔商品咨询数据',min(as.Date(chitu_askpro$日期)),'至',max(as.Date(chitu_askpro$日期)),sep=''))
}else{print('数据有误')}
odbcCloseAll()
rm(chitu)
