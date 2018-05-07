#获取生意参谋流量数据数据
conn=odbcConnectAccess2007(zydb_dir)
st <- max(as.Date(sqlQuery(conn,'select distinct 日期 from 参谋_流量来源')$日期))+1 #POSIXct型转换as.date日期会变小一天
days <- seq.Date(st+1, Sys.Date()-1, by='day')

index=data.frame(平台=c('PC端','PC端','PC端','PC端','PC端','PC端','无线端','无线端','无线端','无线端','无线端','无线端','无线端'),来源=c('汇总','自主访问','付费流量','淘宝免费','淘外流量','其他','汇总','自主访问','付费流量','淘宝免费','淘外网站','淘外APP','其他来源'),device=c('1','1','1','1','1','1','2','2','2','2','2','2','2'),id=c('null','1','2','3','4','5','null','21','22','23','24','25','26'))
traffic_res=data.frame()
for (day in as.character(days)){
  tra=data.frame()
  for(i in 1:nrow(index)){
    Sys.sleep(runif(1,0,1))
    b$navigate(paste('https://sycm.taobao.com/bda/flow/flowmap/flowSource.json?cateId=0&dateRange=',day,'%7C',day,'&dateType=day&device=',index[i,3],'&deviceLogicType=',index[i,3],'&id=',index[i,4],'&index=uv,payAmt,payBuyerCnt&isActive=false&sourceDataType=0&token=',Token,'&_=',str_sub(as.character(as.numeric(Sys.time())*1000),1,13),sep='')) #链接只包含访客数，支付买家数，支付金额三个指标（有店铺没有开通流量纵横，只能看访客）
    pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
    data=jsonlite::fromJSON(pagesource)$data$source
    n=nrow(data) #如果其他来源无数据则跳过
    if(length(n)>0){
      tra_all=data.frame()
      for (j in 1:n){
        list<- jsonlite::fromJSON(pagesource)$data$source$indexs[[j]]
        uv=list$value[1]
        payAmt=list$value[2]
        payBuyerCnt=list$value[3]
        traffic=data.frame(访客数=uv,支付买家数=payBuyerCnt,支付金额=payAmt)
        tra_all=rbind(tra_all,traffic)
      }
      if(any(i==c(1,7))){res=data.frame(日期=day,平台=index[i,1],来源=data$name,来源明细=index[i,2],tra_all)}else{res=data.frame(日期=day,平台=index[i,1],来源=index[i,2],来源明细=data$name,tra_all)}
      tra=rbind(tra,res)
    }
  }
  traffic_res=rbind(traffic_res,tra)
}
traffic_res=subset(traffic_res,traffic_res$访客数!=0)
traffic_res$支付转化率=round(traffic_res$支付买家数/traffic_res$访客数,4)

if (min(as.Date(traffic_res$日期))==st+1&ncol(traffic_res)==8){
  sqlSave(conn,traffic_res,tablename = '参谋_流量来源',rownames =FALSE, append = T)
  print(paste('已抓取流量数据',min(as.Date(traffic_res$日期)),'至',max(as.Date(traffic_res$日期)),sep=''))
}else{print("数据有误，请检查")}

odbcCloseAll()

rm(tra)
rm(tra_all)
rm(traffic)
rm(index)
rm(list)
rm(res)
