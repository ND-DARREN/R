# b$open(silent=T) 登录唯品会
# b <- remoteDriver(remoteServerAddr = "localhost",port = 4444,browserName = "chrome",extraCapabilities=list(chromeOptions=list(args=list('--always-authorize-plugins=true','start-maximized=true'))))
# b$open(silent=T)
# b$navigate('http://vis.vip.com/index.php')
# b$findElement(using='css selector', value='#userName')$sendKeysToElement(list("xiewei@hanhoo.com"))
# b$findElement(using='css selector', value='#passWord')$sendKeysToElement(list("HANhoo2017@"))

conn=odbcConnectAccess2007(zgdb_dir)
end=strftime(Sys.Date(),'%Y%m%d')
time=round(as.numeric(Sys.time())*1000,0)
b$navigate(paste('http://compass.vis.vip.com/dangqi/details/queryTimeLineDetail?callback=jQuery32108912541698251961_',time,'&brandStoreName=韩后&_=',time+1,sep=''))
pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
pagesource <- substr(pagesource,42,nchar(pagesource)-2)
dqlist<- jsonlite::fromJSON(pagesource)$singleResult
dqlist$part=''
dqlist[grepl("韩后hanhoo化妆品专场| 韩后hanhoo化妆品专场|.韩后hanhoo化妆品专场",dqlist$brandName),'part']='韩后专场'
dqlist[grepl("韩后hanhoo特卖旗舰店",dqlist$brandName),'part']='旗舰店'
dqlist[grepl("美妆热卖排行榜|单品热卖会|美妆热卖（新客推荐）|1月美妆新客秒杀|2月畅销美妆榜单新鲜出炉|3月畅销美妆榜单新鲜出炉|4月畅销美妆榜单新鲜出炉|5月美妆畅销TOP榜尖货|美妆子频道",dqlist$brandName),'part']='子频道'
dqlist[dqlist$part=='','part']='其他资源'
dqlist$brandName1 = gsub(' ','%C2%A0',dqlist$brandName) #将档期名称中的空格替换成编码，否则链接不能正确解析
dqlist <- dqlist[dqlist$lastSellDay>Sys.Date()-2,]

## 确定唯品会是否更新最近1天的数据，若更新则执行爬虫
b$navigate('http://compass.vis.vip.com/newRealTime/comm/queryLastDataTime?callback=jQuery321031565217450366867_1513215430132&moduleType=7&_=1513215430147')
pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
pagesource <- substr(pagesource,43,nchar(pagesource)-2)
day <- jsonlite::fromJSON(pagesource)$singleResult

if(day==Sys.Date()-1){
  
  dqdata=data.frame()
  for(i in 1:nrow(dqlist)){
    try({
      # b$navigate(paste('http://compass.vis.vip.com/dangqi/details/getDangqiDetails?callback=jQuery32108912541698251961_',time,'&brandStoreName=韩后&brandType=',dqlist$brandType[i],'&brandName=',dqlist$brandName[i],'&pageSize=',20000,'&pageNumber=1&sortColumn=logDate&sortType=1&warehouseName=0&optGroup=0&goodsCnt=0&sumType=1&lv3CategoryFlag=1&optGroupFlag=1&warehouseFlag=1&analysisType=2&dateMode=0&dateType=D&detailType=D&beginDate=2017-10-02&endDate=2017-10-31&_=',time,sep=''))  #档期分人群，站点详细数据
      b$navigate(paste('http://compass.vis.vip.com/dangqi/details/getDangqiDetails?callback=jQuery32108912541698251961_',time,'&brandStoreName=韩后&brandType=',dqlist$brandType[i],'&brandName=',dqlist$brandName[i],'&pageSize=',20000,'&pageNumber=1&sortColumn=logDate&sortType=1&warehouseName=0&optGroup=0&goodsCnt=0&sumType=1&lv3CategoryFlag=0&optGroupFlag=0&warehouseFlag=0&analysisType=1&dateMode=0&dateType=D&detailType=D&beginDate=',Sys.Date()-30,'&endDate=',Sys.Date()-1,'&_=',time,sep=''))
      pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
      pagesource <- substr(pagesource,42,nchar(pagesource)-2)
      data <- jsonlite::fromJSON(pagesource)$singleResult$list
      if (length(data)==0){
        b$navigate(paste('http://compass.vis.vip.com/dangqi/details/getDangqiDetails?callback=jQuery32108912541698251961_',time,'&brandStoreName=韩后&brandType=',dqlist$brandType[i],'&brandName=',dqlist$brandName1[i],'&pageSize=',20000,'&pageNumber=1&sortColumn=logDate&sortType=1&warehouseName=0&optGroup=0&goodsCnt=0&sumType=1&lv3CategoryFlag=0&optGroupFlag=0&warehouseFlag=0&analysisType=1&dateMode=0&dateType=D&detailType=D&beginDate=',Sys.Date()-30,'&endDate=',Sys.Date()-1,'&_=',time,sep=''))
        pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
        pagesource <- substr(pagesource,42,nchar(pagesource)-2)
        data <- jsonlite::fromJSON(pagesource)$singleResult$list
      }
      data <- data.frame(档期名称=data$dangqiName,档期id=data$dangqiId,档期分类=dqlist$part[i],档期开始时间=data$saleTimeFrom,档期结束时间=data$saleTimeTo,活动名称=data$activeName,售卖日期=data$logDate,人群类型=data$optGroup,站点类型=data$warehouseName,三级品类类型=data$newCategory3rdName,货值=data$onlineStockAmt,货量=data$onlineStockCnt,订单数=data$orderCnt,购买人数=data$userCnt,销售额扣满减含拒退=data$salesAmount,销售额扣满减不含拒退=data$salesAmountNoCutReject,销售额含满减含拒退=data$goodsMoney,UV=data$uv,转化率=data$uvConvert,销售量不含拒退=data$saleCntNoReject,销量量含拒退=data$goodsCnt,客单价=data$avgOrderAmount,件单价=data$avgGoodsAmount,退货量=data$backGoodsAmount,退货金额=data$backGoodsCutMoney,退货率=data$backGoodsAmountPercent,拒收量=data$rejectedGoodsAmount,拒收金额=data$rejectedGoodsCutMoney,拒收率=data$rejectedGoodsAmountPercent,拒退率=data$backRejectedGoodsAmountPercent)
      dqdata <- rbind(dqdata,data)
      print(paste(dqlist$brandName[i],i))
    })
  }
  names(dqdata)[which(names(dqdata)=='销量量含拒退')]='销售量含拒退'
  for(i in 11:30){
    dqdata[,i] <- as.numeric(as.character(dqdata[,i]))
  }
  for(i in 1:10){
    dqdata[,i] <- as.character(dqdata[,i])
  }
  
  st <- max(as.Date(sqlQuery(conn,'select distinct 售卖日期 from 唯品_档期')$售卖日期))+1 #POSIXct型转换as.date日期会变小一天
  dqdata <- subset(dqdata,dqdata$售卖日期>st)
  
  if(nrow(dqdata)>0){
    sqlSave(conn,dqdata,tablename = '唯品_档期',rownames =FALSE, append = T)
    print('唯品档期数据采集完毕')
  }else{print('未抓取到数据')}
  
  
  
  # 抓取档期商品销售数据
  
  dq_pro=data.frame()
  for(i in 1:nrow(dqlist)){
    b$navigate(paste('http://compass.vis.vip.com/newGoods/details/getDetails?callback=jQuery321008453190423585855_',time,'&brandStoreName=韩后&goodsCode=&pageSize=20000&pageNumber=1&sortColumn=goodsAmt&sortType=1&warehouseName=0&optGroup=0&goodsCnt=0&beginDate=',dqlist$firstSellDay[i],'&endDate=',dqlist$lastSellDay[i],'&brandName=',dqlist$brandName[i],'&sumType=1&goodsType=0&optGroupFlag=0&warehouseFlag=0&analysisType=1&brandType=%E6%99%AE%E9%80%9A%E7%89%B9%E5%8D%96&_=1510813131911',sep=''))
    pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
    pagesource <- substr(pagesource,43,nchar(pagesource)-2)
    data <- jsonlite::fromJSON(pagesource)$singleResult$list
    if(length(data)==0){
      b$navigate(paste('http://compass.vis.vip.com/newGoods/details/getDetails?callback=jQuery321008453190423585855_',time,'&brandStoreName=韩后&goodsCode=&pageSize=20000&pageNumber=1&sortColumn=goodsAmt&sortType=1&warehouseName=0&optGroup=0&goodsCnt=0&beginDate=',dqlist$firstSellDay[i],'&endDate=',dqlist$lastSellDay[i],'&brandName=',dqlist$brandName1[i],'&sumType=1&goodsType=0&optGroupFlag=0&warehouseFlag=0&analysisType=1&brandType=%E6%99%AE%E9%80%9A%E7%89%B9%E5%8D%96&_=1510813131911',sep=''))
      pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
      pagesource <- substr(pagesource,43,nchar(pagesource)-2)
      data <- jsonlite::fromJSON(pagesource)$singleResult$list
    }
    dq_pro <- rbind(dq_pro,data)
    print(paste('档期商品',dqlist$brandName[i],i))
  }
  
  dq_pro=dq_pro[,c('brandName','logDate','goodsUrl','goodsCode','goodsName','lv3Category','vipshopPrice','onSaleStockAmt','onSaleStockCnt','goodsMoney','goodsAmt','goodsAmtWithoutReturn','goodsCnt','goodsCntWithoutReturn','uv','userCnt','conversion','sellingRatio','goodsCtr','brandGoodsAvgCtr','collectUserCnt')]
  names(dq_pro)=c('档期名称','售卖日期','商品详情链接','货号','商品名称','三级品类类型','售卖价','货值','货量','销售额含满减含拒退','销售额扣满减含拒退','销售额扣满减不含拒退','销售量含拒退','销售量不含拒退','UV','购买人数','转化率','售卖比','商品CTR','档期内商品平均CTR','收藏人数')
  for(i in 7:21){
    dq_pro[,i] <- as.numeric(dq_pro[,i] )
  }
  
  st <- max(as.Date(sqlQuery(conn,'select distinct 售卖日期 from 唯品_档期商品')$售卖日期))+1 #POSIXct型转换as.date日期会变小一天
  dq_pro <- subset(dq_pro,dq_pro$售卖日期>st)
  
  if(nrow(dq_pro)>0){
    sqlSave(conn,dq_pro,tablename = '唯品_档期商品',rownames =FALSE, append = T)
    print('唯品档期商品数据采集完毕')
  }else{print('未抓取到数据')}
  
  odbcCloseAll()
}else{print("唯品数据延迟")}













