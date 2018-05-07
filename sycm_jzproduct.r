#获取生意参谋竞争商品数据数据
conn=odbcConnectAccess2007(zydb_dir)
st <- max(as.Date(sqlQuery(conn,'select distinct 日期 from 参谋_竞争商品')$日期))+1 #POSIXct型转换as.date日期会变小一天
days <- seq.Date(st+1, Sys.Date()-1, by='day')

jzres=data.frame()
for(day in as.character(days)){
  b$navigate(paste('https://sycm.taobao.com/ci/excel.do?spm=a21ag.8111947.C_competeItem-lossCustomer.2.5ddc0abaNe6xAp&_path_=excel/item/paylos&dateRange=',day,'|',day,'&dateType=day',sep=''))
  repeat{if(file.exists(paste('【生意参谋平台】竞争情报-竞争商品-顾客流失竞争-',day,'_',day,'.xls',sep=''))){break()}}
  jzproduct <- read_excel(paste('【生意参谋平台】竞争情报-竞争商品-顾客流失竞争-',day,'_',day,'.xls',sep=''),skip = 5)
  jzproduct=data.frame(日期=day,jzproduct)
  jzres=rbind(jzres,jzproduct)
}
for (i in c(4:5,7:13)){
  jzres[,i]=as.numeric(jzres[,i])
}
jzres$流失率=as.numeric(gsub("%","",jzres$流失率))/100

if (min(as.Date(jzres$日期))==st+1&ncol(jzres)==13){
  sqlSave(conn,jzres,tablename = '参谋_竞争商品',rownames =FALSE, append = T)
  print(paste('已抓取竞争商品数据',min(as.Date(jzres$日期)),'至',max(as.Date(jzres$日期)),sep=''))
}else{print("数据有误，请检查")}

odbcCloseAll()
rm(jzproduct)



