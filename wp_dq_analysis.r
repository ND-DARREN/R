conn=odbcConnectAccess2007(zgdb_dir)
end=strftime(Sys.Date(),'%Y%m%d')
time=round(as.numeric(Sys.time())*1000,0)
#获取档期列表
b$navigate(url=paste('http://compass.vis.vip.com/dangqi/list?callback=jQuery111103240084103308618_',time,'&start=20130101&end=',end,'&_=',time+1,sep='')) #唯品所有档期，帮助获取档期分析中不包含的档期截止时间
pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
pagesource <- substr(pagesource,43,nchar(pagesource)-2)
data<- jsonlite::fromJSON(pagesource)$multipleResult
b$navigate(url=paste('http://compass.vis.vip.com/dangqi/listByOffline?callback=jQuery111105263759922236204_',time,'&_=',time+1,sep='')) #档期分析中档期列表
pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
pagesource <- substr(pagesource,43,nchar(pagesource)-2)
dqlist <- jsonlite::fromJSON(pagesource)$multipleResult
dqlist <- subset(dqlist, select = -c(sellDateEnd))
dqlist=merge(dqlist,data,by=c('dangqiName','sellDateStart'),all.x = TRUE)
dqlist$sellDateStart <- as.POSIXct((dqlist$sellDateStart+0.1)/1000, origin = "1970-01-01")
dqlist$sellDateEnd <- as.POSIXct((dqlist$sellDateEnd+0.1)/1000, origin = "1970-01-01")
dqlist$NameAndDate <- paste(dqlist$dangqiName,dqlist$sellDateStart)
dqlist=dqlist[order(dqlist$sellDateStart,decreasing=TRUE),]
dqlist$dangqiName1 = gsub(' ','%C2%A0',dqlist$dangqiName) #将档期名称中的空格替换成编码，否则链接不能正确解析
dqlist$NameAndDate1=paste(dqlist$dangqiName,gsub('-','',substr(dqlist$sellDateStart,1,10)),sep='-')
dqlist$NameAndDate1=gsub('HANHOO','hanhoo',dqlist$NameAndDate1)
dqlist=dqlist[grepl('韩后HANHOO化妆品专场',dqlist$dangqiName),]

num=30

dq_data=data.frame()
for (i in 1:num){
  b$navigate(paste('http://compass.vis.vip.com/dangqi/linkRatio?callback=jQuery111106389155420474708_',time,'&name=',dqlist$dangqiName[i],'&sellDateStart=',substr(strftime(dqlist$sellDateStart[i],'%Y%m%d%H%M%S'),1,12),'&_=',time+2,sep=''))
  pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
  pagesource <- substr(pagesource,43,nchar(pagesource)-2)
  # data <- data.frame(unlist(josn$currInfo)) 列出信息
  josn <- jsonlite::fromJSON(pagesource)$singleResult$currInfo
  if(length(josn)==0){
    b$navigate(paste('http://compass.vis.vip.com/dangqi/linkRatio?callback=jQuery111106389155420474708_',time,'&name=',dqlist$dangqiName1[i],'&sellDateStart=',substr(strftime(dqlist$sellDateStart[i],'%Y%m%d%H%M%S'),1,12),'&_=',time+2,sep=''))
    pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
    pagesource <- substr(pagesource,43,nchar(pagesource)-2)
    # data <- data.frame(unlist(josn$currInfo)) 列出信息
    josn <- jsonlite::fromJSON(pagesource)$singleResult$currInfo
  }
  sku动销比 <- josn$salesSkuPer
  扣满减销售额 <- josn$salesAmount
  售卖比 <- josn$salesRate
  UV <- josn$uv
  平均点击量 <- josn$pvAvg
  购买人数 <- josn$userNum
  转化率 <- josn$conversionRate
  订单数 <- josn$orderNum
  客单价 <- josn$customSalesAmount
  件单价 <- josn$goodsPriceAvg
  移动端销售占比 <- josn$mobileAmountRate
  data <- data.frame(档期时间=dqlist$NameAndDate1[i],档期=dqlist$dangqiName[i],开始时间=dqlist$sellDateStart[i],结束时间=dqlist$sellDateEnd[i],sku动销比,扣满减销售额,售卖比,UV,平均点击量,购买人数,转化率,订单数,客单价,件单价,移动端销售占比)
  dq_data <- rbind(dq_data,data)
  print(paste(i,' 档期数据 ',dqlist$NameAndDate[i],sep=''))
}
dq_data$sku动销比=dq_data$sku动销比/100
dq_data$售卖比=dq_data$售卖比/100
dq_data$转化率=dq_data$转化率/100
dq_data$移动端销售占比=dq_data$移动端销售占比/100
dq_data=rbind(dq_data,sqlFetch(conn,"档期分析_档期概况"))
dq_data=dq_data[!duplicated(dq_data$档期时间),]
if (nrow(dq_data)>0){
  if (nrow(sqlFetch(conn,'档期分析_档期概况'))!=0){sqlQuery(conn,"delete * from 档期分析_档期概况")}
  repeat{if (nrow(sqlFetch(conn,'档期分析_档期概况'))==0){break()}} #等待数据库清空
  sqlSave(conn,dq_data,tablename = '档期分析_档期概况',rownames =FALSE,append = TRUE)
}else{"档期数据为空，请检查"}



ware_data=data.frame()
for (i in 1:num){
  b$navigate(paste('http://compass.vis.vip.com/dangqi/analysisRegion?callback=jQuery111106389155420474708_',time,'&name=',dqlist$dangqiName[i],'&sellDateStart=',substr(strftime(dqlist$sellDateStart[i],'%Y%m%d%H%M%S'),1,12),'&_=',time+2,sep=''))
  pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
  pagesource <- substr(pagesource,43,nchar(pagesource)-2)
  data <- jsonlite::fromJSON(pagesource)$multipleResult
  if(length(data)==0){
    b$navigate(paste('http://compass.vis.vip.com/dangqi/analysisRegion?callback=jQuery111106389155420474708_',time,'&name=',dqlist$dangqiName1[i],'&sellDateStart=',substr(strftime(dqlist$sellDateStart[i],'%Y%m%d%H%M%S'),1,12),'&_=',time+2,sep=''))
    pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
    pagesource <- substr(pagesource,43,nchar(pagesource)-2)
    data <- jsonlite::fromJSON(pagesource)$multipleResult
  }
  data <- data[c('warehouseName','salesAmountRate','purchaseAmountRate','salesRate','salesAmount','purchaseAmount')]
  names(data) <- c('地区','销售额占比','货值占比','金额售卖比','销售额','货值')
  data <- data.frame(档期时间=dqlist$NameAndDate1[i],档期=dqlist$dangqiName[i],开始时间=dqlist$sellDateStart[i],结束时间=dqlist$sellDateEnd[i],data)
  ware_data=rbind(ware_data,data)
  print(paste(i,' 地区 ',dqlist$NameAndDate[i],sep=''))
}
ware_data$销售额占比=ware_data$销售额占比/100
ware_data$货值占比=ware_data$货值占比/100
ware_data$金额售卖比=ware_data$金额售卖比/100
ware_data=rbind(ware_data,sqlFetch(conn,"档期分析_地区售卖数据"))
ware_data=ware_data[!duplicated(paste(ware_data$档期时间,ware_data$地区,sep='')),]
if (nrow(ware_data)>0){
  if (nrow(sqlFetch(conn,'档期分析_地区售卖数据'))!=0){sqlQuery(conn,"delete * from 档期分析_地区售卖数据")}
  repeat{if (nrow(sqlFetch(conn,'档期分析_地区售卖数据'))==0){break()}} #等待数据库清空
  sqlSave(conn,ware_data,tablename = '档期分析_地区售卖数据',rownames =FALSE,append = TRUE)
}else{"档期数据为空，请检查"}


#价格类目折扣
price_data=data.frame()
cat_data=data.frame()
agio_data=data.frame()
for (i in 1:num){
  b$navigate(paste('http://compass.vis.vip.com/dangqi/analysisAll?callback=jQuery111103258698421996087_',time,'&name=',dqlist$dangqiName[i],'&sellDateStart=',substr(strftime(dqlist$sellDateStart[i],'%Y%m%d%H%M%S'),1,12),'&_=',time+2,sep=''))
  pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
  pagesource <- substr(pagesource,43,nchar(pagesource)-2)
  priceList <- jsonlite::fromJSON(pagesource)$singleResult$priceList
  if(length(priceList)==0){
    b$navigate(paste('http://compass.vis.vip.com/dangqi/analysisAll?callback=jQuery111103258698421996087_',time,'&name=',dqlist$dangqiName1[i],'&sellDateStart=',substr(strftime(dqlist$sellDateStart[i],'%Y%m%d%H%M%S'),1,12),'&_=',time+2,sep=''))
    pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
    pagesource <- substr(pagesource,43,nchar(pagesource)-2)
  }
  try({
    #价格
    priceList <- jsonlite::fromJSON(pagesource)$singleResult$priceList
    priceList <- priceList[c('priceSectionName','salesAmountRate','purchaseAmountRate','salesRate','salesAmount','purchaseAmount')]
    names(priceList) <- c('价格段','销售额占比','货值占比','金额售卖比','销售额','货值')
    priceList <- data.frame(档期时间=dqlist$NameAndDate1[i],档期=dqlist$dangqiName[i],开始时间=dqlist$sellDateStart[i],结束时间=dqlist$sellDateEnd[i],priceList)
    price_data=rbind(price_data,priceList)
    #类目
    cateList <- jsonlite::fromJSON(pagesource)$singleResult$cateList
    cateList <- cateList[,c('categoryThirdName','salesAmountRate','purchaseAmountRate','salesRate','salesAmount','purchaseAmount','uv','conversionsRate')]
    names(cateList) <- c('类目','销售额占比','货值占比','金额售卖比','销售额','货值','uv','转化率')
    cateList <- data.frame(档期时间=dqlist$NameAndDate1[i],档期=dqlist$dangqiName[i],开始时间=dqlist$sellDateStart[i],结束时间=dqlist$sellDateEnd[i],cateList)
    cat_data=rbind(cat_data,cateList)
    #折扣
    agioList <- jsonlite::fromJSON(pagesource)$singleResult$agioList
    agioList <- agioList[c('agioSectionName','salesAmountRate','purchaseAmountRate','salesRate','salesAmount','purchaseAmount')]
    names(agioList) <- c('折扣','销售额占比','货值占比','金额售卖比','销售额','货值')
    agioList <- data.frame(档期时间=dqlist$NameAndDate1[i],档期=dqlist$dangqiName[i],开始时间=dqlist$sellDateStart[i],结束时间=dqlist$sellDateEnd[i],agioList)
    agio_data=rbind(agio_data,agioList)
    print(paste(i,' 价格类目折扣分布 ',dqlist$NameAndDate[i],sep=''))
  })
}

price_data$销售额占比=price_data$销售额占比/100
price_data$货值占比=price_data$货值占比/100
price_data$金额售卖比=price_data$金额售卖比/100
price_data=rbind(price_data,sqlFetch(conn,"档期分析_价格分布数据"))
price_data=price_data[!duplicated(paste(price_data$档期时间,price_data$价格段,sep='')),]
if (nrow(price_data)>0){
  if (nrow(sqlFetch(conn,'档期分析_价格分布数据'))!=0){sqlQuery(conn,"delete * from 档期分析_价格分布数据")}
  repeat{if(nrow(sqlFetch(conn,'档期分析_价格分布数据'))==0){break()}} #等待数据库清空
  sqlSave(conn,price_data,tablename = '档期分析_价格分布数据',rownames =FALSE,append = TRUE)
}else{"档期数据为空，请检查"}

cat_data$销售额占比=cat_data$销售额占比/100
cat_data$货值占比=cat_data$货值占比/100
cat_data$金额售卖比=cat_data$金额售卖比/100
cat_data$转化率=cat_data$转化率/100
cat_data=rbind(cat_data,sqlFetch(conn,"档期分析_类目分布数据"))
cat_data=cat_data[!duplicated(paste(cat_data$档期时间,cat_data$类目,sep='')),]
if (nrow(cat_data)>0){
  if (nrow(sqlFetch(conn,'档期分析_类目分布数据'))!=0){sqlQuery(conn,"delete * from 档期分析_类目分布数据")}
  repeat{if(nrow(sqlFetch(conn,'档期分析_类目分布数据'))==0){break()}} #等待数据库清空
  sqlSave(conn,cat_data,tablename = '档期分析_类目分布数据',rownames =FALSE,append = TRUE)
}else{"档期数据为空，请检查"}

agio_data$销售额占比=agio_data$销售额占比/100
agio_data$货值占比=agio_data$货值占比/100
agio_data$金额售卖比=agio_data$金额售卖比/100
agio_data=rbind(agio_data,sqlFetch(conn,"档期分析_折扣分布数据"))
agio_data=agio_data[!duplicated(paste(agio_data$档期时间,agio_data$折扣,sep='')),]
if (nrow(agio_data)>0){
  if (nrow(sqlFetch(conn,'档期分析_折扣分布数据'))!=0){sqlQuery(conn,"delete * from 档期分析_折扣分布数据")}
  repeat{if(nrow(sqlFetch(conn,'档期分析_折扣分布数据'))==0){break()}} #等待数据库清空
  sqlSave(conn,agio_data,tablename = '档期分析_折扣分布数据',rownames =FALSE,append = TRUE)
}else{"档期数据为空，请检查"}


#人群销售概况
person_data=data.frame()
for (i in 1:num){
  b$navigate(paste('http://compass.vis.vip.com/dangqi/customerDistributed?callback=jQuery11110479359193937853_',time,'&name=',dqlist$dangqiName[i],'&sellDateStart=',substr(strftime(dqlist$sellDateStart[i],'%Y%m%d%H%M%S'),1,12),'&_=',time+2,sep=''))
  pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
  pagesource <- substr(pagesource,42,nchar(pagesource)-2)
  data <- jsonlite::fromJSON(pagesource)$multipleResult
  if(length(data)==0){
    b$navigate(paste('http://compass.vis.vip.com/dangqi/customerDistributed?callback=jQuery11110479359193937853_',time,'&name=',dqlist$dangqiName1[i],'&sellDateStart=',substr(strftime(dqlist$sellDateStart[i],'%Y%m%d%H%M%S'),1,12),'&_=',time+2,sep=''))
    pagesource <- unlist(b$findElement(using='tag name', 'pre')$getElementText())
    pagesource <- substr(pagesource,42,nchar(pagesource)-2)
    data <- jsonlite::fromJSON(pagesource)$multipleResult
  }
  data <- data[c('groupTypeName','salesAmountRate','uvRate')]
  names(data) <- c('人群','销售额占比','uv占比')
  data <- data.frame(档期时间=dqlist$NameAndDate1[i],档期=dqlist$dangqiName[i],开始时间=dqlist$sellDateStart[i],结束时间=dqlist$sellDateEnd[i],data)
  person_data=rbind(person_data,data)
  print(paste(i,' 人群 ',dqlist$NameAndDate[i],sep=''))
}
person_data[is.na(person_data)] <- 0 

person_data=rbind(person_data,sqlFetch(conn,"档期分析_人群售卖数据"))
person_data=person_data[!duplicated(paste(person_data$档期时间,person_data$人群,sep='')),]
if (nrow(person_data)>0){
  if (nrow(sqlFetch(conn,'档期分析_人群售卖数据'))!=0){sqlQuery(conn,"delete * from 档期分析_人群售卖数据")}
  repeat{if(nrow(sqlFetch(conn,'档期分析_人群售卖数据'))==0){break()}} #等待数据库清空
  sqlSave(conn,person_data,tablename = '档期分析_人群售卖数据',rownames =FALSE,append = TRUE)
}else{"档期数据为空，请检查"}

print("唯品档期分析数据抓取完毕")

odbcCloseAll()












