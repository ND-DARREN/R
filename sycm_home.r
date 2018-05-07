#########爬取生意参谋首页数据########
conn=odbcConnectAccess2007(zydb_dir)
st <- max(as.Date(sqlQuery(conn,'select distinct 统计时段 from 参谋_店铺首页')$统计时段))+1
days <- seq.Date(st+1, Sys.Date()-1, by='day')

b$navigate(paste('https://sycm.taobao.com/bda/decorate/getGeneralTrend.json?dateRange=',Sys.Date()-30,'%7C',Sys.Date()-1,'&dateType=recent30&endDate=',Sys.Date()-1,'&objId=103506130&spmb=undefined&startDate=',Sys.Date()-30,'&t=',str_sub(as.character(as.numeric(Sys.time())*1000),1,13),'&type=0&_=',str_sub(as.character(as.numeric(Sys.time())*1000),1,13),sep=''))  #pc首页
pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
shouye_pc <- jsonlite::fromJSON(pagesource)$data$list
shouye_pc$laiyuan <- "pc"
shouye_pc <- shouye_pc[,c('date','pv','uv','clickCnt','clickUv','clickRate','bounceRate','avgStayTime','leOrderBuyerCnt','leOrderAmt','leOrderRate','lePayBuyerCnt','lePayAmt','lePayRate','laiyuan')]

b$navigate(paste('https://sycm.taobao.com/zxfx/decorate/getGeneralTrend.json?appType=TB_APP&dateRange=',Sys.Date()-30,'%7C',Sys.Date()-1,'&dateType=recent30&endDate=',Sys.Date()-1,'&objId=&spmb=-9999&startDate=',Sys.Date()-30,'&t=',str_sub(as.character(as.numeric(Sys.time())*1000),1,13),'&type=0&_=',str_sub(as.character(as.numeric(Sys.time())*1000),1,13),sep=''))  #淘宝app首页
pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
shouye_tbapp <- jsonlite::fromJSON(pagesource)$content$data$list
shouye_tbapp$laiyuan <- "tbapp"
shouye_tbapp <- shouye_tbapp[,c('date','pv','uv','clickCnt','clickUv','clickRate','bounceRate','avgStayTime','leOrderBuyerCnt','leOrderAmt','leOrderRate','lePayBuyerCnt','lePayAmt','lePayRate','laiyuan')]

b$navigate(paste('https://sycm.taobao.com/zxfx/decorate/getGeneralTrend.json?appType=TM_APP&dateRange=',Sys.Date()-30,'%7C',Sys.Date()-1,'&dateType=recent30&endDate=',Sys.Date()-1,'&objId=&spmb=-9999&startDate=',Sys.Date()-30,'&t=',str_sub(as.character(as.numeric(Sys.time())*1000),1,13),'&type=0&_=',str_sub(as.character(as.numeric(Sys.time())*1000),1,13),sep=''))  #天猫app首页
pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
shouye_tmapp <- jsonlite::fromJSON(pagesource)$content$data$list
shouye_tmapp$laiyuan <- "tmapp"
shouye_tmapp <- shouye_tmapp[,c('date','pv','uv','clickCnt','clickUv','clickRate','bounceRate','avgStayTime','leOrderBuyerCnt','leOrderAmt','leOrderRate','lePayBuyerCnt','lePayAmt','lePayRate','laiyuan')]

#合并数据
shouye_combine=rbind(shouye_pc,shouye_tbapp,shouye_tmapp)
names(shouye_combine)=c('统计时段','浏览量','访客数','点击次数','点击人数','点击率','跳失率','平均停留时长','引导下单买家数','引导下单金额','引导下单转化率','引导支付买家数','引导支付金额','引导支付转化率','来源')
shouye_combine=subset(shouye_combine,shouye_combine$统计时段>st)

if (nrow(shouye_combine)==length(days)*3&ncol(shouye_combine)==15){
  sqlSave(conn,shouye_combine,tablename = '参谋_店铺首页',rownames =FALSE,append = TRUE)
  print(paste('已抓取首页数据',min(shouye_combine$统计时段),'至',max(shouye_combine$统计时段),sep=''))
}else{"数据有误，请检查"}
odbcCloseAll()

rm(shouye_pc)
rm(shouye_tbapp)
rm(shouye_tmapp)

